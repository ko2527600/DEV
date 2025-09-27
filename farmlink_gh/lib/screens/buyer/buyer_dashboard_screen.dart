import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../widgets/product_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/category_filter_widget.dart';
import '../../widgets/advanced_filter_widget.dart';
import '../../widgets/filter_button_widget.dart';
import 'product_detail_screen.dart';
import '../auth_screen.dart';

class BuyerDashboardScreen extends StatefulWidget {
  const BuyerDashboardScreen({super.key});

  @override
  State<BuyerDashboardScreen> createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends State<BuyerDashboardScreen> {
  final ProductService _productService = ProductService();
  
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;
  int _currentPage = 0;
  bool _hasMoreProducts = true;
  
  // Advanced filtering
  Map<String, dynamic> _advancedFilters = {};
  bool _showAdvancedFilters = false;
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
    
    // Listen to auth state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.addListener(_onAuthStateChanged);
    });
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

  @override
  void dispose() {
    // Remove auth listener
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.removeListener(_onAuthStateChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _productService.getAllProducts(
        page: 0,
        limit: AppConstants.itemsPerPage,
        category: _selectedCategory,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        minPrice: _advancedFilters['minPrice']?.toDouble(),
        maxPrice: _advancedFilters['maxPrice']?.toDouble(),
        unit: _advancedFilters['unit'],
        isAvailable: _advancedFilters['isAvailable'] ?? true,
        location: _advancedFilters['hasLocationFilter'] == true ? _advancedFilters['location'] : null,
      );
      
      setState(() {
        _products = products;
        _filteredProducts = products;
        _currentPage = 0;
        _hasMoreProducts = products.length >= AppConstants.itemsPerPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load products');
    }
  }

  Future<void> _loadMoreProducts() async {
    if (!_hasMoreProducts || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final moreProducts = await _productService.getAllProducts(
        page: nextPage,
        limit: AppConstants.itemsPerPage,
        category: _selectedCategory,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        minPrice: _advancedFilters['minPrice']?.toDouble(),
        maxPrice: _advancedFilters['maxPrice']?.toDouble(),
        unit: _advancedFilters['unit'],
        isAvailable: _advancedFilters['isAvailable'] ?? true,
        location: _advancedFilters['hasLocationFilter'] == true ? _advancedFilters['location'] : null,
      );
      
      if (moreProducts.isNotEmpty) {
        setState(() {
          _products.addAll(moreProducts);
          _filteredProducts = _products;
          _currentPage = nextPage;
          _hasMoreProducts = moreProducts.length >= AppConstants.itemsPerPage;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasMoreProducts = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchProducts(String query) async {
    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });

    try {
      if (query.isEmpty) {
        // Reset to all products
        final products = await _productService.getAllProducts(
          page: 0,
          limit: AppConstants.itemsPerPage,
          category: _selectedCategory,
        );
        setState(() {
          _products = products;
          _filteredProducts = products;
          _currentPage = 0;
          _hasMoreProducts = products.length >= AppConstants.itemsPerPage;
          _isLoading = false;
        });
      } else {
        // Search products
        final searchResults = await _productService.searchProducts(query);
        setState(() {
          _filteredProducts = searchResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Search failed');
    }
  }

  Future<void> _filterByCategory(String? category) async {
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });

    try {
      final products = await _productService.getAllProducts(
        page: 0,
        limit: AppConstants.itemsPerPage,
        category: category,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        minPrice: _advancedFilters['minPrice']?.toDouble(),
        maxPrice: _advancedFilters['maxPrice']?.toDouble(),
        unit: _advancedFilters['unit'],
        isAvailable: _advancedFilters['isAvailable'] ?? true,
        location: _advancedFilters['hasLocationFilter'] == true ? _advancedFilters['location'] : null,
      );
      
      setState(() {
        _products = products;
        _filteredProducts = products;
        _currentPage = 0;
        _hasMoreProducts = products.length >= AppConstants.itemsPerPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to filter products');
    }
  }

  void _onAdvancedFiltersChanged(Map<String, dynamic> filters) {
    setState(() {
      _advancedFilters = filters;
    });
    _loadProducts();
  }

  void _onClearAdvancedFilters() {
    setState(() {
      _advancedFilters = {};
    });
    _loadProducts();
  }

  void _toggleAdvancedFilters() {
    setState(() {
      _showAdvancedFilters = !_showAdvancedFilters;
    });
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedCategory != null) count++;
    if (_advancedFilters['minPrice'] != null && _advancedFilters['minPrice'] > 0) count++;
    if (_advancedFilters['maxPrice'] != null && _advancedFilters['maxPrice'] < 1000) count++;
    if (_advancedFilters['unit'] != null) count++;
    if (_advancedFilters['hasLocationFilter'] == true && _advancedFilters['location'] != null) count++;
    return count;
  }

  void _navigateToProductDetail(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(AppConstants.errorColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingNormal),
            decoration: BoxDecoration(
              color: Colors.white,
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
                // Search Bar
                SearchBarWidget(
                  onSearch: _searchProducts,
                  hintText: 'Search for products...',
                ),
                
                const SizedBox(height: AppConstants.spacingNormal),
                
                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: CategoryFilterWidget(
                        selectedCategory: _selectedCategory,
                        onCategorySelected: _filterByCategory,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingNormal),
                    FilterButtonWidget(
                      filterCount: _getActiveFilterCount(),
                      onTap: _toggleAdvancedFilters,
                      isExpanded: _showAdvancedFilters,
                    ),
                  ],
                ),
                
                // Advanced Filters
                if (_showAdvancedFilters) ...[
                  const SizedBox(height: AppConstants.spacingNormal),
                  AdvancedFilterWidget(
                    currentFilters: _advancedFilters,
                    onFiltersChanged: _onAdvancedFiltersChanged,
                    onClearFilters: _onClearAdvancedFilters,
                  ),
                ],
              ],
            ),
          ),
          
          // Products List
          Expanded(
            child: _isLoading && _products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(AppConstants.spacingNormal),
                          itemCount: _filteredProducts.length + (_hasMoreProducts ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _filteredProducts.length) {
                              return _buildLoadMoreIndicator();
                            }
                            
                            final product = _filteredProducts[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppConstants.spacingNormal),
                              child: ProductCard(
                                product: product,
                                onTap: () => _navigateToProductDetail(product),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty || _selectedCategory != null) {
      return _buildNoResultsState();
    }
    
    return _buildNoProductsState();
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppConstants.spacingNormal),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: AppConstants.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: Color(AppConstants.textColorLight),
            ),
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: AppConstants.fontSizeNormal,
              color: Color(AppConstants.textColorLight),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingLarge),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _selectedCategory = null;
              });
              _loadProducts();
            },
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProductsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppConstants.spacingNormal),
          Text(
            'No products available',
            style: TextStyle(
              fontSize: AppConstants.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: Color(AppConstants.textColorLight),
            ),
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          Text(
            'Check back later for new products from farmers',
            style: TextStyle(
              fontSize: AppConstants.fontSizeNormal,
              color: Color(AppConstants.textColorLight),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (!_hasMoreProducts) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingNormal),
      child: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _loadMoreProducts,
                child: const Text('Load More Products'),
              ),
      ),
    );
  }
}
