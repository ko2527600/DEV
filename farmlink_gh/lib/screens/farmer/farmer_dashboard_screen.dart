import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../services/user_service.dart';
import '../../widgets/product_card.dart';
import '../../widgets/stats_card.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import '../auth_screen.dart';

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  final ProductService _productService = ProductService();
  final UserService _userService = UserService();
  
  List<ProductModel> _products = [];
  bool _isLoading = true;
  int _totalProducts = 0;
  int _totalViews = 0; // Placeholder for analytics
  String _farmerName = 'Farmer';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    
    // Listen to auth state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.addListener(_onAuthStateChanged);
    });
  }

  @override
  void dispose() {
    // Remove auth listener
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated && mounted) {
      // User signed out, navigate to auth screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AuthScreen(),
        ),
      );
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      
      if (userId != null) {
        // Load farmer profile to get the name
        try {
          final farmerProfile = await _userService.getFarmerProfile(userId);
          if (farmerProfile != null) {
            _farmerName = farmerProfile.farmName;
          }
        } catch (e) {
          // If farmer profile not found, try to get user profile
          try {
            final userProfile = await _userService.getCurrentUserProfile();
            if (userProfile != null) {
              _farmerName = userProfile.fullName ?? 'Farmer';
            }
          } catch (e) {
            // Keep default name
          }
        }
        
        final products = await _productService.getProductsByFarmer(userId);
        setState(() {
          _products = products;
          _totalProducts = products.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load dashboard data');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(AppConstants.errorColor),
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    await _loadDashboardData();
  }

  void _navigateToAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    ).then((_) => _refreshDashboard());
  }

  void _navigateToEditProduct(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: product),
      ),
    ).then((_) => _refreshDashboard());
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Color(AppConstants.errorColor),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _productService.deleteProduct(product.id);
        if (success) {
          _showSuccessSnackBar('Product deleted successfully');
          _refreshDashboard();
        } else {
          _showErrorSnackBar('Failed to delete product');
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting product');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(AppConstants.successColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.signOut(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshDashboard,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.spacingNormal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    _buildWelcomeSection(_farmerName),
                    
                    const SizedBox(height: AppConstants.spacingLarge),
                    
                    // Stats Section
                    _buildStatsSection(),
                    
                    const SizedBox(height: AppConstants.spacingLarge),
                    
                    // Quick Actions
                    _buildQuickActions(),
                    
                    const SizedBox(height: AppConstants.spacingLarge),
                    
                    // Products Section
                    _buildProductsSection(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddProduct,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildWelcomeSection(String farmerName) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(AppConstants.primaryColor),
            Color(AppConstants.secondaryColor),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.agriculture,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(width: AppConstants.spacingNormal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: AppConstants.fontSizeNormal,
                  ),
                ),
                Text(
                  farmerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppConstants.fontSizeExtraLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingSmall),
                Text(
                  'Manage your products and connect with buyers',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: AppConstants.fontSizeSmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: StatsCard(
            title: 'Total Products',
            value: _totalProducts.toString(),
            icon: Icons.inventory,
            color: Color(AppConstants.primaryColor),
          ),
        ),
        const SizedBox(width: AppConstants.spacingNormal),
        Expanded(
          child: StatsCard(
            title: 'Total Views',
            value: _totalViews.toString(),
            icon: Icons.visibility,
            color: Color(AppConstants.accentColor),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: AppConstants.fontSizeLarge,
            fontWeight: FontWeight.bold,
            color: Color(AppConstants.textColor),
          ),
        ),
        const SizedBox(height: AppConstants.spacingNormal),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_circle,
                title: 'Add Product',
                subtitle: 'List new items',
                onTap: _navigateToAddProduct,
                color: Color(AppConstants.primaryColor),
              ),
            ),
            const SizedBox(width: AppConstants.spacingNormal),
            Expanded(
              child: _buildActionCard(
                icon: Icons.analytics,
                title: 'Analytics',
                subtitle: 'View insights',
                onTap: () {
                  // TODO: Navigate to analytics screen
                },
                color: Color(AppConstants.secondaryColor),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingNormal),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: AppConstants.spacingSmall),
            Text(
              title,
              style: TextStyle(
                fontSize: AppConstants.fontSizeNormal,
                fontWeight: FontWeight.bold,
                color: Color(AppConstants.textColor),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingSmall),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: AppConstants.fontSizeSmall,
                color: Color(AppConstants.textColorLight),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Products',
              style: TextStyle(
                fontSize: AppConstants.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: Color(AppConstants.textColor),
              ),
            ),
            Text(
              '${_products.length} products',
              style: TextStyle(
                fontSize: AppConstants.fontSizeSmall,
                color: Color(AppConstants.textColorLight),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingNormal),
        if (_products.isEmpty)
          _buildEmptyProductsState()
        else
          _buildProductsList(),
      ],
    );
  }

  Widget _buildEmptyProductsState() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingExtraLarge),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppConstants.spacingNormal),
          Text(
            'No products yet',
            style: TextStyle(
              fontSize: AppConstants.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: Color(AppConstants.textColorLight),
            ),
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          Text(
            'Start by adding your first product to connect with buyers',
            style: TextStyle(
              fontSize: AppConstants.fontSizeNormal,
              color: Color(AppConstants.textColorLight),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingLarge),
          ElevatedButton.icon(
            onPressed: _navigateToAddProduct,
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Product'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.spacingNormal),
          child: ProductCard(
            product: product,
            showActions: true,
            onEdit: () => _navigateToEditProduct(product),
            onDelete: () => _deleteProduct(product),
          ),
        );
      },
    );
  }
}
