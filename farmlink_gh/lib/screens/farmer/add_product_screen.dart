import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../services/image_service.dart';
import '../../widgets/image_picker_widget.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedUnit;
  List<Uint8List> _selectedImages = [];
  bool _isLoading = false;
  
  final ProductService _productService = ProductService();
  final ImageService _imageService = ImageService();

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
        _selectedImages = images;
      });
    }
  }

  Future<void> _takePhoto() async {
    final imageBytes = await _imageService.pickImageBytesFromCamera();
    if (imageBytes != null) {
      setState(() {
        _selectedImages = [imageBytes];
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      _showErrorSnackBar('Please select at least one image');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      
      if (userId == null) {
        _showErrorSnackBar('User not authenticated');
        return;
      }

      final product = await _productService.createProduct(
        farmerId: userId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        quantityAvailable: double.tryParse(_quantityController.text) ?? 0.0,
        unit: _selectedUnit ?? 'kg',
        category: _selectedCategory ?? 'Other',
        images: _selectedImages,
      );

      if (product != null) {
        _showSuccessSnackBar('Product added successfully!');
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar('Failed to add product');
      }
    } catch (e) {
      _showErrorSnackBar('Error adding product: $e');
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
        title: const Text('Add New Product'),
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
          'Add up to 5 images of your product',
          style: TextStyle(
            fontSize: AppConstants.fontSizeSmall,
            color: Color(AppConstants.textColorLight),
          ),
        ),
        const SizedBox(height: AppConstants.spacingNormal),
        
        // Image Picker
        if (_selectedImages.isEmpty)
          _buildImagePicker()
        else
          _buildSelectedImages(),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Container(
      height: 200,
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
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          Text(
            'No images selected',
            style: TextStyle(
              fontSize: AppConstants.fontSizeNormal,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingNormal),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConstants.primaryColor),
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConstants.secondaryColor),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImages() {
    return Column(
      children: [
        // Selected Images Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppConstants.spacingSmall,
            mainAxisSpacing: AppConstants.spacingSmall,
            childAspectRatio: 1,
          ),
          itemCount: _selectedImages.length + (_selectedImages.length < 5 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _selectedImages.length) {
              // Add more button
              return _buildAddMoreButton();
            }
            return _buildImageThumbnail(index);
          },
        ),
        
        const SizedBox(height: AppConstants.spacingNormal),
        
        // Image Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library),
              label: const Text('Add More'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppConstants.primaryColor),
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppConstants.secondaryColor),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddMoreButton() {
    return InkWell(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(
          Icons.add,
          size: 32,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
            child: Image.memory(
              _selectedImages[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: () => _removeImage(index),
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
                  hintText: '0.0',
                  prefixIcon: Icon(Icons.inventory),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final quantity = double.tryParse(value);
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
        
        const SizedBox(height: AppConstants.spacingNormal),
        
        // Unit
        DropdownButtonFormField<String>(
          value: _selectedUnit ?? 'kg',
          decoration: const InputDecoration(
            labelText: 'Unit *',
            prefixIcon: Icon(Icons.scale),
          ),
          items: ['kg', 'pieces', 'bags', 'liters', 'tons', 'bundles'].map((unit) {
            return DropdownMenuItem(
              value: unit,
              child: Text(unit),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedUnit = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a unit';
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
              'Add Product',
              style: TextStyle(fontSize: AppConstants.fontSizeLarge),
            ),
          ),
        ),
      ],
    );
  }
}
