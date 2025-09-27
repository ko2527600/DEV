import 'package:flutter/material.dart';
import '../services/supabase_database_service.dart';
import 'farmer_profile_screen.dart';

class FarmersListScreen extends StatefulWidget {
  const FarmersListScreen({super.key});

  @override
  State<FarmersListScreen> createState() => _FarmersListScreenState();
}

class _FarmersListScreenState extends State<FarmersListScreen> {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  List<Map<String, dynamic>> _farmers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFarmers();
  }

  Future<void> _loadFarmers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final farmers = await _databaseService.getFarmers();
      setState(() {
        _farmers = farmers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading farmers: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmers List'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFarmers,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFarmers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_farmers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No farmers found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Farmers will appear here once they register',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFarmers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _farmers.length,
        itemBuilder: (context, index) {
          final farmer = _farmers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                child: Text(
                  (farmer['farm_name'] ?? 'F')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                farmer['farm_name'] ?? 'Unknown Farm',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (farmer['farm_location'] != null)
                    Text('📍 ${farmer['farm_location']}'),
                  if (farmer['description'] != null)
                    Text(farmer['description']),
                  if (farmer['verified'] == true)
                    const Row(
                      children: [
                        Icon(Icons.verified, color: Colors.blue, size: 16),
                        SizedBox(width: 4),
                        Text('Verified', style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FarmerProfileScreen(farmerId: farmer['id']),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
