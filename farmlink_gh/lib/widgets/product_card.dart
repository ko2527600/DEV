import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/product_model.dart';
import 'package:intl/intl.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool showActions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.showActions = false,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingNormal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image - Show placeholder since images are in separate table
              _buildPlaceholderImage(),
              
              const SizedBox(height: AppConstants.spacingNormal),
              
              // Product Info
              _buildProductInfo(),
              
              // Actions (if enabled)
              if (showActions) ...[
                const SizedBox(height: AppConstants.spacingNormal),
                _buildActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
      ),
      child: Icon(
        Icons.image_not_supported,
        size: 64,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Name
        Text(
          product.name,
          style: TextStyle(
            fontSize: AppConstants.fontSizeLarge,
            fontWeight: FontWeight.bold,
            color: Color(AppConstants.textColor),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: AppConstants.spacingSmall),
        
        // Product Description
        if (product.description != null && product.description!.isNotEmpty)
          Text(
            product.description!,
            style: TextStyle(
              fontSize: AppConstants.fontSizeNormal,
              color: Color(AppConstants.textColorLight),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        
        const SizedBox(height: AppConstants.spacingSmall),
        
        // Product Details Row
        Row(
          children: [
            // Category
            if (product.category != null)
              Expanded(
                child: _buildDetailChip(
                  product.category!,
                  Icons.category,
                  Color(AppConstants.primaryColor),
                ),
              ),
            
            const SizedBox(width: AppConstants.spacingSmall),
            
            // Quantity
            if (product.quantityAvailable != null)
              Expanded(
                child: _buildDetailChip(
                  '${product.quantityAvailable} available',
                  Icons.inventory,
                  Color(AppConstants.accentColor),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: AppConstants.spacingSmall),
        
        // Price and Date Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Price
            if (product.price != null)
              Text(
                '₵${product.price!.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.primaryColor),
                ),
              ),
            
            // Date
            Text(
              DateFormat('MMM dd, yyyy').format(product.createdAt),
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

  Widget _buildDetailChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppConstants.fontSizeSmall,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(AppConstants.primaryColor),
              side: BorderSide(color: Color(AppConstants.primaryColor)),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spacingSmall),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(AppConstants.errorColor),
              side: BorderSide(color: Color(AppConstants.errorColor)),
            ),
          ),
        ),
      ],
    );
  }
}
