import 'package:flutter/material.dart';
import '../services/supabase_database_service.dart';
import 'buyer_profile_screen.dart';

class BuyersListScreen extends StatefulWidget {
  const BuyersListScreen({super.key});

  @override
  State<BuyersListScreen> createState() => _BuyersListScreenState();
}

class _BuyersListScreenState extends State<BuyersListScreen> {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  List<Map<String, dynamic>> _buyers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBuyers();
  }

  Future<void> _loadBuyers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final buyers = await _databaseService.getBuyers();
      setState(() {
        _buyers = buyers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading buyers: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyers List'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBuyers,
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
              onPressed: _loadBuyers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_buyers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No buyers found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Buyers will appear here once they register',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBuyers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _buyers.length,
        itemBuilder: (context, index) {
          final buyer = _buyers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange,
                child: Text(
                  (buyer['company_name'] ?? 'B')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                buyer['company_name'] ?? 'Unknown Company',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (buyer['business_type'] != null)
                    Text('🏢 ${buyer['business_type']}'),
                  if (buyer['location'] != null)
                    Text('📍 ${buyer['location']}'),
                  if (buyer['description'] != null)
                    Text(buyer['description']),
                  if (buyer['interested_crops'] != null && buyer['interested_crops'].isNotEmpty)
                    Text(
                      '🌾 Interested in: ${buyer['interested_crops'].join(', ')}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BuyerProfileScreen(buyerId: buyer['id']),
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
