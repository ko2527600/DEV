import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../services/image_service.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({
    super.key,
    required this.product,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedUnit;
  List<Uint8List> _newImages = [];
  List<String> _existingImages = [];
  bool _isLoading = false;
  
  final ProductService _productService = ProductService();
  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _nameController.text = widget.product.name;
    _descriptionController.text = widget.product.description ?? '';
    _priceController.text = widget.product.price.toString();
    _quantityController.text = widget.product.quantityAvailable.toString();
    _selectedCategory = widget.product.category;
    _selectedUnit = widget.product.unit;
    _existingImages = []; // Images are now in separate table
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _imageService.pickMultipleImageBytesFromGallery();
    if (images.isNotEmpty) {
      setState(() {
        _newImages.addAll(images);
      });
    }
  }

  Future<void> _takePhoto() async {
    final image = await _imageService.pickImageBytesFromCamera();
    if (image != null) {
      setState(() {
        _newImages.add(image);
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_existingImages.isEmpty && _newImages.isEmpty) {
      _showErrorSnackBar('Please select at least one image');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _productService.updateProduct(
        productId: widget.product.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text),
        quantityAvailable: int.tryParse(_quantityController.text),
        category: _selectedCategory,
        newImages: _newImages.isNotEmpty ? _newImages : null,
      );

      if (success) {
        _showSuccessSnackBar('Product updated successfully!');
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar('Failed to update product');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating product: $e');
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
        title: const Text('Edit Product'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _submitForm,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.spacingNormal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Images Section
                    _buildImagesSection(),
                    
                    const SizedBox(height: AppConstants.spacingLarge),
                    
                    // Product Details Form
                    _buildProductForm(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Images',
          style: TextStyle(
            fontSize: AppConstants.fontSizeLarge,
            fontWeight: FontWeight.bold,
            color: Color(AppConstants.textColor),
          ),
        ),
        const SizedBox(height: AppConstants.spacingSmall),
        Text(
          'Manage your product images',
          style: TextStyle(
            fontSize: AppConstants.fontSizeSmall,
            color: Color(AppConstants.textColorLight),
          ),
        ),
        const SizedBox(height: AppConstants.spacingNormal),
        
        // Existing Images
        if (_existingImages.isNotEmpty) ...[
          Text(
            'Current Images',
            style: TextStyle(
              fontSize: AppConstants.fontSizeNormal,
              fontWeight: FontWeight.w500,
              color: Color(AppConstants.textColor),
            ),
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          _buildExistingImagesGrid(),
          const SizedBox(height: AppConstants.spacingNormal),
        ],
        
        // New Images
        if (_newImages.isNotEmpty) ...[
          Text(
            'New Images',
            style: TextStyle(
              fontSize: AppConstants.fontSizeNormal,
              fontWeight: FontWeight.w500,
              color: Color(AppConstants.textColor),
            ),
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          _buildNewImagesGrid(),
          const SizedBox(height: AppConstants.spacingNormal),
        ],
        
        // Add Images Section
        _buildAddImagesSection(),
      ],
    );
  }

  Widget _buildExistingImagesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppConstants.spacingSmall,
        mainAxisSpacing: AppConstants.spacingSmall,
        childAspectRatio: 1,
      ),
      itemCount: _existingImages.length,
      itemBuilder: (context, index) {
        return _buildExistingImageThumbnail(index);
      },
    );
  }

  Widget _buildExistingImageThumbnail(int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
            image: DecorationImage(
              image: NetworkImage(_existingImages[index]),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: () => _removeExistingImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewImagesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppConstants.spacingSmall,
        mainAxisSpacing: AppConstants.spacingSmall,
        childAspectRatio: 1,
      ),
      itemCount: _newImages.length,
      itemBuilder: (context, index) {
        return _buildNewImageThumbnail(index);
      },
    );
  }

  Widget _buildNewImageThumbnail(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
          child: Image.memory(
            _newImages[index],
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: () => _removeNewImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImagesSection() {
    final totalImages = _existingImages.length + _newImages.length;
    final canAddMore = totalImages < 5;
    
    if (!canAddMore) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.spacingNormal),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: AppConstants.spacingSmall),
            Expanded(
              child: Text(
                'Maximum 5 images allowed. Remove some images to add new ones.',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: AppConstants.fontSizeSmall,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 32,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          Text(
            'Add more images (${5 - totalImages} remaining)',
            style: TextStyle(
              fontSize: AppConstants.fontSizeSmall,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConstants.primaryColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingNormal,
                    vertical: AppConstants.spacingSmall,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConstants.secondaryColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingNormal,
                    vertical: AppConstants.spacingSmall,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductForm() {
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
        
        // Product Name
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Product Name *',
            hintText: 'Enter product name',
            prefixIcon: Icon(Icons.inventory),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Product name is required';
            }
            if (value.trim().length > AppConstants.maxNameLength) {
              return 'Product name is too long';
            }
            return null;
          },
        ),
        
        const SizedBox(height: AppConstants.spacingNormal),
        
        // Description
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Describe your product',
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
          validator: (value) {
            if (value != null && value.length > AppConstants.maxDescriptionLength) {
              return 'Description is too long';
            }
            return null;
          },
        ),
        
        const SizedBox(height: AppConstants.spacingNormal),
        
        // Price and Quantity Row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (₵)',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final price = double.tryParse(value);
                    if (price == null || price < 0) {
                      return 'Enter a valid price';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppConstants.spacingNormal),
            Expanded(
              child: TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity Available',
                  hintText: '0',
                  prefixIcon: Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final quantity = int.tryParse(value);
                    if (quantity == null || quantity < 0) {
                      return 'Enter a valid quantity';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppConstants.spacingNormal),
        
        // Category
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Category',
            prefixIcon: Icon(Icons.category),
          ),
          items: AppConstants.productCategories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),
        
        const SizedBox(height: AppConstants.spacingLarge),
        
        // Submit Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(AppConstants.primaryColor),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.spacingNormal,
              ),
            ),
            child: const Text(
              'Update Product',
              style: TextStyle(fontSize: AppConstants.fontSizeLarge),
            ),
          ),
        ),
      ],
    );
  }
}
