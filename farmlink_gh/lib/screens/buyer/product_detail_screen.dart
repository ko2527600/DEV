import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../models/product_model.dart';
import '../../services/message_service.dart';
import '../../services/user_service.dart';
import '../../widgets/image_carousel_widget.dart';
import 'package:intl/intl.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final MessageService _messageService = MessageService();
  final UserService _userService = UserService();
  
  bool _isLoading = false;
  String? _farmerName;
  String? _farmerLocation;

  @override
  void initState() {
    super.initState();
    _loadFarmerInfo();
  }

  Future<void> _loadFarmerInfo() async {
    try {
      final farmer = await _userService.getFarmerProfile(widget.product.farmerId);
      if (farmer != null) {
        setState(() {
          _farmerName = farmer.farmName;
          _farmerLocation = farmer.farmLocation;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _contactFarmer() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    if (currentUser == null) {
      _showErrorSnackBar('Please login to contact the farmer');
      return;
    }

    if (currentUser.id == widget.product.farmerId) {
      _showErrorSnackBar('You cannot contact yourself');
      return;
    }

    _showContactDialog();
  }

  void _showContactDialog() {
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Farmer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Send a message to ${_farmerName ?? 'the farmer'} about this product.',
              style: TextStyle(
                fontSize: AppConstants.fontSizeNormal,
                color: Color(AppConstants.textColorLight),
              ),
            ),
            const SizedBox(height: AppConstants.spacingNormal),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Ask about pricing, availability, or any questions...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _sendMessage(messageController.text, context),
            child: const Text('Send Message'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String message, BuildContext context) async {
    if (message.trim().isEmpty) {
      _showErrorSnackBar('Please enter a message');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) return;

      final sentMessage = await _messageService.sendMessage(
        senderId: currentUser.id,
        receiverId: widget.product.farmerId,
        content: message.trim(),
      );

      if (sentMessage != null) {
        Navigator.pop(context);
        _showSuccessSnackBar('Message sent successfully!');
      } else {
        _showErrorSnackBar('Failed to send message');
      }
    } catch (e) {
      _showErrorSnackBar('Error sending message');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // TODO: Implement favorites functionality
              _showErrorSnackBar('Favorites coming soon!');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Images - Show placeholder since images are in separate table
                  _buildPlaceholderImage(),
                  
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingNormal),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Header
                        _buildProductHeader(),
                        
                        const SizedBox(height: AppConstants.spacingLarge),
                        
                        // Product Details
                        _buildProductDetails(),
                        
                        const SizedBox(height: AppConstants.spacingLarge),
                        
                        // Farmer Information
                        _buildFarmerInfo(),
                        
                        const SizedBox(height: AppConstants.spacingLarge),
                        
                        // Contact Button
                        _buildContactButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppConstants.borderRadiusLarge),
          bottomRight: Radius.circular(AppConstants.borderRadiusLarge),
        ),
      ),
      child: Icon(
        Icons.image_not_supported,
        size: 64,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildProductHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Name
        Text(
          widget.product.name,
          style: TextStyle(
            fontSize: AppConstants.fontSizeExtraLarge,
            fontWeight: FontWeight.bold,
            color: Color(AppConstants.textColor),
          ),
        ),
        
        const SizedBox(height: AppConstants.spacingSmall),
        
        // Price and Category Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Price
            if (widget.product.price != null)
              Text(
                '₵${widget.product.price!.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.primaryColor),
                ),
              ),
            
            // Category
            if (widget.product.category != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingNormal,
                  vertical: AppConstants.spacingSmall,
                ),
                decoration: BoxDecoration(
                  color: Color(AppConstants.primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
                  border: Border.all(
                    color: Color(AppConstants.primaryColor).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  widget.product.category!,
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeSmall,
                    color: Color(AppConstants.primaryColor),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Details',
          style: TextStyle(
            fontSize: AppConstants.fontSizeLarge,
            fontWeight: FontWeight.bold,
            color: Color(AppConstants.textColor),
          ),
        ),
        
        const SizedBox(height: AppConstants.spacingNormal),
        
        // Description
        if (widget.product.description != null && 
            widget.product.description!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeNormal,
                  fontWeight: FontWeight.w500,
                  color: Color(AppConstants.textColor),
                ),
              ),
              const SizedBox(height: AppConstants.spacingSmall),
              Text(
                widget.product.description!,
                style: TextStyle(
                  fontSize: AppConstants.fontSizeNormal,
                  color: Color(AppConstants.textColorLight),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppConstants.spacingNormal),
            ],
          ),
        
        // Quantity Available
        if (widget.product.quantityAvailable != null)
          _buildDetailRow(
            'Quantity Available',
            '${widget.product.quantityAvailable} units',
            Icons.inventory,
          ),
        
        // Date Added
        _buildDetailRow(
          'Date Added',
          DateFormat('MMM dd, yyyy').format(widget.product.createdAt),
          Icons.calendar_today,
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingNormal),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Color(AppConstants.textColorLight),
          ),
          const SizedBox(width: AppConstants.spacingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeSmall,
                    color: Color(AppConstants.textColorLight),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeNormal,
                    fontWeight: FontWeight.w500,
                    color: Color(AppConstants.textColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerInfo() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingNormal),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Farmer Information',
            style: TextStyle(
              fontSize: AppConstants.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: Color(AppConstants.textColor),
            ),
          ),
          
          const SizedBox(height: AppConstants.spacingNormal),
          
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(AppConstants.primaryColor).withOpacity(0.1),
                child: Icon(
                  Icons.agriculture,
                  color: Color(AppConstants.primaryColor),
                ),
              ),
              const SizedBox(width: AppConstants.spacingNormal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _farmerName ?? 'Farm Name',
                      style: TextStyle(
                        fontSize: AppConstants.fontSizeNormal,
                        fontWeight: FontWeight.w500,
                        color: Color(AppConstants.textColor),
                      ),
                    ),
                    if (_farmerLocation != null)
                      Text(
                        _farmerLocation!,
                        style: TextStyle(
                          fontSize: AppConstants.fontSizeSmall,
                          color: Color(AppConstants.textColorLight),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _contactFarmer,
        icon: const Icon(Icons.message),
        label: const Text('Contact Farmer'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(AppConstants.primaryColor),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.spacingNormal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
          ),
        ),
      ),
    );
  }
}
