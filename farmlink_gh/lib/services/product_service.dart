import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // Create a new product
  Future<ProductModel?> createProduct({
    required String farmerId,
    required String name,
    String? description,
    required double price,
    required double quantityAvailable,
    required String unit,
    required String category,
    List<Uint8List> images = const [],
  }) async {
    try {
      // Debug: Log the input parameters
      print('🔍 ProductService.createProduct called with:');
      print('farmerId: $farmerId');
      print('name: $name');
      print('description: $description');
      print('price: $price');
      print('quantityAvailable: $quantityAvailable');
      print('unit: $unit');
      print('category: $category');
      print('images count: ${images.length}');
      
      // Upload images first
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        imageUrls = await _uploadProductImages(images);
        print('🔍 Images uploaded: $imageUrls');
      }

      final productData = {
        'farmer_id': farmerId,
        'name': name,
        'description': description,
        'price': price.toString(), // Convert to string for numeric type
        'quantity_available': quantityAvailable.toString(), // Convert to string for numeric type
        'unit': unit,
        'category': category,
        'is_available': true,
      };
      
      print('🔍 Product data to insert: $productData');

      final response = await _supabase
          .from('products')
          .insert(productData)
          .select()
          .single();
          
      print('🔍 Product created successfully: $response');

      // If images were uploaded, create product_images records
      if (imageUrls.isNotEmpty) {
        for (int i = 0; i < imageUrls.length; i++) {
          await _supabase.from('product_images').insert({
            'product_id': response['id'],
            'image_url': imageUrls[i],
            'is_primary': i == 0, // First image is primary
          });
        }
        print('🔍 Product images created successfully');
      }

      return ProductModel.fromJson(response);
    } catch (e) {
      print('❌ Error creating product: $e');
      developer.log('Error creating product: $e', name: 'ProductService');
      return null;
    }
  }

  // Get all products
  Future<List<ProductModel>> getAllProducts({
    String? category,
    String? searchQuery,
    int page = 0,
    int limit = 20,
    double? minPrice,
    double? maxPrice,
    String? unit,
    bool? isAvailable,
    String? location,
  }) async {
    try {
      var query = _supabase
          .from('products')
          .select('*, users!inner(*)');

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      if (minPrice != null && minPrice > 0) {
        query = query.gte('price', minPrice.toString());
      }

      if (maxPrice != null && maxPrice < 1000) {
        query = query.lte('price', maxPrice.toString());
      }

      if (unit != null && unit.isNotEmpty) {
        query = query.eq('unit', unit);
      }

      if (isAvailable != null) {
        query = query.eq('is_available', isAvailable);
      }

      if (location != null && location.isNotEmpty) {
        // Search in farmer location (this would need to be implemented based on your location data structure)
        // For now, we'll search in the users table location field
        query = query.eq('users.location', location);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      return response.map((product) => ProductModel.fromJson(product)).toList();
    } catch (e) {
      developer.log('Error getting products: $e', name: 'ProductService');
      return [];
    }
  }

  // Get products by farmer
  Future<List<ProductModel>> getProductsByFarmer(String farmerId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);

      return response.map((product) => ProductModel.fromJson(product)).toList();
    } catch (e) {
      developer.log('Error getting farmer products: $e', name: 'ProductService');
      return [];
    }
  }

  // Get product by ID
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, users!inner(*)')
          .eq('id', productId)
          .single();

      return ProductModel.fromJson(response);
    } catch (e) {
      developer.log('Error getting product: $e', name: 'ProductService');
      return null;
    }
  }

  // Update product
  Future<bool> updateProduct({
    required String productId,
    String? name,
    String? description,
    double? price,
    int? quantityAvailable,
    String? category,
    List<Uint8List>? newImages,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (price != null) updates['price'] = price;
      if (quantityAvailable != null) updates['quantity_available'] = quantityAvailable;
      if (category != null) updates['category'] = category;

      // Handle new images if provided: upload and create rows in product_images
      if (newImages != null && newImages.isNotEmpty) {
        final newImageUrls = await _uploadProductImages(newImages);
        for (int i = 0; i < newImageUrls.length; i++) {
          await _supabase.from('product_images').insert({
            'product_id': productId,
            'image_url': newImageUrls[i],
            'is_primary': false,
          });
        }
      }

      await _supabase
          .from('products')
          .update(updates)
          .eq('id', productId);

      return true;
    } catch (e) {
      developer.log('Error updating product: $e', name: 'ProductService');
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(String productId) async {
    try {
      // Get product images from product_images table
      final imagesResponse = await _supabase
          .from('product_images')
          .select('image_url')
          .eq('product_id', productId);
      
      // Delete images from storage
      for (final image in imagesResponse) {
        final imageUrl = image['image_url'];
        if (imageUrl != null) {
          await _deleteImageFromStorage(imageUrl);
        }
      }
      
      // Delete product images records
      await _supabase
          .from('product_images')
          .delete()
          .eq('product_id', productId);

      // Delete the product
      await _supabase
          .from('products')
          .delete()
          .eq('id', productId);

      return true;
    } catch (e) {
      developer.log('Error deleting product: $e', name: 'ProductService');
      return false;
    }
  }

  // Upload product images
  Future<List<String>> _uploadProductImages(List<Uint8List> images) async {
    final List<String> imageUrls = [];
    final String? userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated while uploading images');
    }

    for (final bytes in images) {
      try {
        final fileName = '${_uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        // Storage RLS expects first folder segment to match auth.uid()
        final filePath = '$userId/products/$fileName';

        // Use binary upload to support web and mobile uniformly
        await _supabase.storage
            .from('product-images')
            .uploadBinary(
              filePath,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );

        final imageUrl = _supabase.storage
            .from('product-images')
            .getPublicUrl(filePath);

        imageUrls.add(imageUrl);
      } catch (e) {
        developer.log('Error uploading image: $e', name: 'ProductService');
      }
    }

    return imageUrls;
  }

  // Delete image from storage
  Future<void> _deleteImageFromStorage(String imageUrl) async {
    try {
      // Extract file path from public URL after '/product-images/'
      const marker = '/product-images/';
      final int markerIndex = imageUrl.indexOf(marker);
      if (markerIndex == -1) {
        developer.log('Could not parse image path from URL: $imageUrl', name: 'ProductService');
        return;
      }
      final String filePath = imageUrl.substring(markerIndex + marker.length);
      await _supabase.storage
          .from('product-images')
          .remove([filePath]);
    } catch (e) {
      developer.log('Error deleting image: $e', name: 'ProductService');
    }
  }

  // Search products
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, users!inner(*)')
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);

      return response.map((product) => ProductModel.fromJson(product)).toList();
    } catch (e) {
      developer.log('Error searching products: $e', name: 'ProductService');
      return [];
    }
  }

  // Get products by category
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, users!inner(*)')
          .eq('category', category)
          .order('created_at', ascending: false);

      return response.map((product) => ProductModel.fromJson(product)).toList();
    } catch (e) {
      developer.log('Error getting products by category: $e', name: 'ProductService');
      return [];
    }
  }

  // Get featured products (most recent)
  Future<List<ProductModel>> getFeaturedProducts({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, users!inner(*)')
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((product) => ProductModel.fromJson(product)).toList();
    } catch (e) {
      developer.log('Error getting featured products: $e', name: 'ProductService');
      return [];
    }
  }
}
