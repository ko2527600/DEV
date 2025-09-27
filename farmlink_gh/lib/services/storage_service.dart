import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> uploadFile(
    File file,
    String path, {
    String bucket = 'avatars',
  }) async {
    try {
      final bytes = await file.readAsBytes();
      await _supabase.storage.from(bucket).uploadBinary(path, bytes);
      return _supabase.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  Future<void> deleteFile(String bucket, String path) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  Future<String?> uploadFarmerImage(File imageFile, String farmerId) async {
    return await uploadFile(
      imageFile,
      'farmers/$farmerId/profile.jpg',
      bucket: 'avatars',
    );
  }

  Future<String?> uploadBuyerImage(File imageFile, String buyerId) async {
    return await uploadFile(
      imageFile,
      'buyers/$buyerId/profile.jpg',
      bucket: 'avatars',
    );
  }

  Future<String?> uploadProductImage(File imageFile, String productId) async {
    return await uploadFile(
      imageFile,
      'products/$productId.jpg',
      bucket: 'products',
    );
  }
}
