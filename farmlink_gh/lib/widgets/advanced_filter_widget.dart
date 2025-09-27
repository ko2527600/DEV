import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class AdvancedFilterWidget extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onFiltersChanged;
  final VoidCallback onClearFilters;

  const AdvancedFilterWidget({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
    required this.onClearFilters,
  });

  @override
  State<AdvancedFilterWidget> createState() => _AdvancedFilterWidgetState();
}

class _AdvancedFilterWidgetState extends State<AdvancedFilterWidget> {
  late RangeValues _priceRange;
  late String? _selectedCategory;
  late String? _selectedUnit;
  late bool _isAvailable;
  late String? _selectedLocation;
  late bool _hasLocationFilter;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  void _initializeFilters() {
    _priceRange = RangeValues(
      widget.currentFilters['minPrice']?.toDouble() ?? 0.0,
      widget.currentFilters['maxPrice']?.toDouble() ?? 1000.0,
    );
    _selectedCategory = widget.currentFilters['category'];
    _selectedUnit = widget.currentFilters['unit'];
    _isAvailable = widget.currentFilters['isAvailable'] ?? true;
    _selectedLocation = widget.currentFilters['location'];
    _hasLocationFilter = widget.currentFilters['hasLocationFilter'] ?? false;
  }

  void _applyFilters() {
    final filters = <String, dynamic>{
      'minPrice': _priceRange.start,
      'maxPrice': _priceRange.end,
      'category': _selectedCategory,
      'unit': _selectedUnit,
      'isAvailable': _isAvailable,
      'location': _selectedLocation,
      'hasLocationFilter': _hasLocationFilter,
    };
    
    widget.onFiltersChanged(filters);
  }

  void _clearAllFilters() {
    setState(() {
      _priceRange = const RangeValues(0.0, 1000.0);
      _selectedCategory = null;
      _selectedUnit = null;
      _isAvailable = true;
      _selectedLocation = null;
      _hasLocationFilter = false;
    });
    
    widget.onClearFilters();
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
                'Advanced Filters',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.textColor),
                ),
              ),
              TextButton(
                onPressed: _clearAllFilters,
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    color: Color(AppConstants.errorColor),
                    fontSize: AppConstants.fontSizeNormal,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingLarge),
          
          // Price Range Filter
          _buildPriceRangeFilter(),
          
          const SizedBox(height: AppConstants.spacingLarge),
          
          // Category Filter
          _buildCategoryFilter(),
          
          const SizedBox(height: AppConstants.spacingLarge),
          
          // Unit Filter
          _buildUnitFilter(),
          
          const SizedBox(height: AppConstants.spacingLarge),
          
          // Availability Filter
          _buildAvailabilityFilter(),
          
          const SizedBox(height: AppConstants.spacingLarge),
          
          // Location Filter
          _buildLocationFilter(),
          
          const SizedBox(height: AppConstants.spacingLarge),
          
          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppConstants.primaryColor),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacingNormal,
                ),
              ),
              child: Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeNormal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range (GHS)',
          style: TextStyle(
            fontSize: AppConstants.fontSizeNormal,
            fontWeight: FontWeight.w500,
            color: Color(AppConstants.textColor),
          ),
        ),
        const SizedBox(height: AppConstants.spacingSmall),
        RangeSlider(
          values: _priceRange,
          min: 0.0,
          max: 1000.0,
          divisions: 100,
          labels: RangeLabels(
            'GHS ${_priceRange.start.round()}',
            'GHS ${_priceRange.end.round()}',
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _priceRange = values;
            });
          },
          activeColor: Color(AppConstants.primaryColor),
          inactiveColor: Colors.grey.shade300,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'GHS ${_priceRange.start.round()}',
              style: TextStyle(
                fontSize: AppConstants.fontSizeSmall,
                color: Color(AppConstants.textColorLight),
              ),
            ),
            Text(
              'GHS ${_priceRange.end.round()}',
              style: TextStyle(
                fontSize: AppConstants.fontSizeSmall,
                color: Color(AppConstants.textColorLight),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Category',
          style: TextStyle(
            fontSize: AppConstants.fontSizeNormal,
            fontWeight: FontWeight.w500,
            color: Color(AppConstants.textColor),
          ),
        ),
        const SizedBox(height: AppConstants.spacingSmall),
        Wrap(
          spacing: AppConstants.spacingSmall,
          runSpacing: AppConstants.spacingSmall,
          children: [
            _buildFilterChip(
              'All',
              null,
              _selectedCategory == null,
            ),
            ...AppConstants.productCategories.map((category) {
              return _buildFilterChip(
                category,
                category,
                _selectedCategory == category,
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildUnitFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Unit',
          style: TextStyle(
            fontSize: AppConstants.fontSizeNormal,
            fontWeight: FontWeight.w500,
            color: Color(AppConstants.textColor),
          ),
        ),
        const SizedBox(height: AppConstants.spacingSmall),
        Wrap(
          spacing: AppConstants.spacingSmall,
          runSpacing: AppConstants.spacingSmall,
          children: [
            _buildFilterChip(
              'All',
              null,
              _selectedUnit == null,
            ),
            ...AppConstants.productUnits.map((unit) {
              return _buildFilterChip(
                unit,
                unit,
                _selectedUnit == unit,
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailabilityFilter() {
    return Row(
      children: [
        Checkbox(
          value: _isAvailable,
          onChanged: (value) {
            setState(() {
              _isAvailable = value ?? true;
            });
          },
          activeColor: Color(AppConstants.primaryColor),
        ),
        Text(
          'Show only available products',
          style: TextStyle(
            fontSize: AppConstants.fontSizeNormal,
            color: Color(AppConstants.textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _hasLocationFilter,
              onChanged: (value) {
                setState(() {
                  _hasLocationFilter = value ?? false;
                  if (!_hasLocationFilter) {
                    _selectedLocation = null;
                  }
                });
              },
              activeColor: Color(AppConstants.primaryColor),
            ),
            Text(
              'Filter by location',
              style: TextStyle(
                fontSize: AppConstants.fontSizeNormal,
                color: Color(AppConstants.textColor),
              ),
            ),
          ],
        ),
        if (_hasLocationFilter) ...[
          const SizedBox(height: AppConstants.spacingSmall),
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter location (e.g., Accra, Kumasi)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
              ),
              prefixIcon: const Icon(Icons.location_on),
            ),
            onChanged: (value) {
              _selectedLocation = value.isNotEmpty ? value : null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChip(String label, String? value, bool isSelected) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Color(AppConstants.textColor),
          fontSize: AppConstants.fontSizeSmall,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (label == 'All') {
            if (value == null) {
              // Category filter
              _selectedCategory = null;
            } else if (value == 'All') {
              // Unit filter
              _selectedUnit = null;
            }
          } else {
            if (value != null) {
              // Category filter
              _selectedCategory = selected ? value : null;
            } else {
              // Unit filter
              _selectedUnit = selected ? label : null;
            }
          }
        });
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Color(AppConstants.primaryColor),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected 
            ? Color(AppConstants.primaryColor) 
            : Colors.grey.shade300,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingNormal,
        vertical: AppConstants.spacingSmall,
      ),
    );
  }
}
