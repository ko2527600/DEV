import 'package:flutter/material.dart';
import 'package:farmlink_gh/services/supabase_database_service.dart';
import 'farmers_list_screen.dart';
import 'buyers_list_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      DashboardScreen(
        databaseService: _databaseService,
        onProfileTap: () {
          setState(() {
            _selectedIndex = 3; // Switch to profile tab
          });
        },
      ),
      const FarmersListScreen(),
      const BuyersListScreen(),
      const ProfileScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Farmers'),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart),
            label: 'Buyers',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final SupabaseDatabaseService databaseService;
  final VoidCallback onProfileTap;

  const DashboardScreen({
    super.key, 
    required this.databaseService,
    required this.onProfileTap,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Map<String, dynamic>>> _farmersFuture;
  late Future<List<Map<String, dynamic>>> _buyersFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _farmersFuture = widget.databaseService.getFarmers();
    _buyersFuture = widget.databaseService.getBuyers();
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadData();
    });
  }

  int _countUniqueCrops(List<Map<String, dynamic>> farmers) {
    final crops = <String>{};
    for (final farmer in farmers) {
      final farmerCrops = farmer['crops'] as List<dynamic>? ?? [];
      crops.addAll(farmerCrops.map((crop) => crop.toString()));
    }
    return crops.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FarmLink Dashboard'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
                     IconButton(
             icon: const Icon(Icons.person),
             onPressed: widget.onProfileTap,
           ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to FarmLink Ghana',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connect farmers with buyers across Ghana',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _buildStatsCard(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return FutureBuilder(
      future: Future.wait([_farmersFuture, _buyersFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading stats: ${snapshot.error}'),
            ),
          );
        }

        final farmers = snapshot.data![0];
        final buyers = snapshot.data![1];

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Farmers', '${farmers.length}', Icons.people),
                _buildStatItem(
                  'Buyers',
                  '${buyers.length}',
                  Icons.shopping_cart,
                ),
                _buildStatItem(
                  'Products',
                  '${_countUniqueCrops(farmers)}+',
                  Icons.grass,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildQuickActionButton(
              'Find Farmers',
              Icons.search,
              () => Navigator.pushNamed(context, '/farmers'),
            ),
            _buildQuickActionButton(
              'Find Buyers',
              Icons.store,
              () => Navigator.pushNamed(context, '/buyers'),
            ),
            _buildQuickActionButton(
              'Post Product',
              Icons.add,
              () => _showPostProductDialog(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
                         _buildQuickActionButton(
               'My Profile',
               Icons.person,
               widget.onProfileTap,
             ),
            _buildQuickActionButton(
              'Settings',
              Icons.settings,
              () {
                // TODO: Navigate to settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon!')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.green, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        FutureBuilder(
          future: _farmersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('Error loading recent activity: ${snapshot.error}');
            }

            final farmers = snapshot.data as List<Map<String, dynamic>>;
            final recentFarmers = farmers.take(3).toList();

            if (recentFarmers.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No recent activity'),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentFarmers.length,
              itemBuilder: (context, index) {
                final farmer = recentFarmers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text('New farmer joined: ${farmer['name']}'),
                    subtitle: Text('Location: ${farmer['location']}'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showPostProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post Product'),
        content: const Text('Product posting feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
