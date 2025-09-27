import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../core/constants/app_constants.dart';

class SavedSearchWidget extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onLoadSearch;

  const SavedSearchWidget({
    super.key,
    required this.currentFilters,
    required this.onLoadSearch,
  });

  @override
  State<SavedSearchWidget> createState() => _SavedSearchWidgetState();
}

class _SavedSearchWidgetState extends State<SavedSearchWidget> {
  List<Map<String, dynamic>> _savedSearches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedSearches();
  }

  Future<void> _loadSavedSearches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSearchesJson = prefs.getStringList('saved_searches') ?? [];
      
      setState(() {
        _savedSearches = savedSearchesJson
            .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCurrentSearch() async {
    if (widget.currentFilters.isEmpty) return;

    final searchName = await _showSaveSearchDialog();
    if (searchName == null || searchName.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final searchData = {
        'name': searchName.trim(),
        'filters': widget.currentFilters,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final savedSearchesJson = prefs.getStringList('saved_searches') ?? [];
      savedSearchesJson.add(jsonEncode(searchData));
      
      // Keep only the last 10 saved searches
      if (savedSearchesJson.length > 10) {
        savedSearchesJson.removeRange(0, savedSearchesJson.length - 10);
      }
      
      await prefs.setStringList('saved_searches', savedSearchesJson);
      await _loadSavedSearches();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search "$searchName" saved successfully'),
            backgroundColor: Color(AppConstants.successColor),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save search: $e'),
            backgroundColor: Color(AppConstants.errorColor),
          ),
        );
      }
    }
  }

  Future<String?> _showSaveSearchDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Search'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Give this search a name:'),
            const SizedBox(height: AppConstants.spacingNormal),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g., Fresh Vegetables in Accra',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSavedSearch(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSearchesJson = prefs.getStringList('saved_searches') ?? [];
      
      if (index < savedSearchesJson.length) {
        savedSearchesJson.removeAt(index);
        await prefs.setStringList('saved_searches', savedSearchesJson);
        await _loadSavedSearches();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Search deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete search: $e'),
            backgroundColor: Color(AppConstants.errorColor),
          ),
        );
      }
    }
  }

  void _loadSearch(Map<String, dynamic> searchData) {
    final filters = searchData['filters'] as Map<String, dynamic>;
    widget.onLoadSearch(filters);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loaded search: ${searchData['name']}'),
          backgroundColor: Color(AppConstants.successColor),
        ),
      );
    }
  }

  String _getFilterSummary(Map<String, dynamic> filters) {
    final parts = <String>[];
    
    if (filters['category'] != null) {
      parts.add('Category: ${filters['category']}');
    }
    if (filters['minPrice'] != null && filters['maxPrice'] != null) {
      parts.add('Price: GHS ${filters['minPrice']} - ${filters['maxPrice']}');
    }
    if (filters['unit'] != null) {
      parts.add('Unit: ${filters['unit']}');
    }
    if (filters['location'] != null) {
      parts.add('Location: ${filters['location']}');
    }
    
    return parts.isEmpty ? 'No filters' : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingNormal),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved Searches',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.textColor),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _saveCurrentSearch,
                icon: const Icon(Icons.save),
                label: const Text('Save Current'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConstants.primaryColor),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingLarge),
          
          // Saved Searches List
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_savedSearches.isEmpty)
            _buildEmptyState()
          else
            _buildSavedSearchesList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.bookmark_border,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppConstants.spacingNormal),
          Text(
            'No saved searches yet',
            style: TextStyle(
              fontSize: AppConstants.fontSizeNormal,
              color: Color(AppConstants.textColorLight),
            ),
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          Text(
            'Save your current search to quickly access it later',
            style: TextStyle(
              fontSize: AppConstants.fontSizeSmall,
              color: Color(AppConstants.textColorLight),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSavedSearchesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _savedSearches.length,
      itemBuilder: (context, index) {
        final search = _savedSearches[index];
        final timestamp = DateTime.parse(search['timestamp']);
        
        return Card(
          margin: const EdgeInsets.only(bottom: AppConstants.spacingSmall),
          child: ListTile(
            title: Text(
              search['name'],
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(AppConstants.textColor),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getFilterSummary(search['filters']),
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeSmall,
                    color: Color(AppConstants.textColorLight),
                  ),
                ),
                Text(
                  'Saved ${_formatTimestamp(timestamp)}',
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeSmall,
                    color: Color(AppConstants.textColorLight),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => _loadSearch(search),
                  tooltip: 'Load Search',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteSavedSearch(index),
                  tooltip: 'Delete Search',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
