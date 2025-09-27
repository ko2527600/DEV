import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class SupabaseStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Upload file to Supabase storage
  Future<String?> uploadFile({
    required String bucket,
    required String path,
    required List<int> bytes,
  }) async {
    try {
      final uint8Bytes = Uint8List.fromList(bytes);
      await _supabase.storage.from(bucket).uploadBinary(path, uint8Bytes);
      return _supabase.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      developer.log('Error uploading file: $e', name: 'SupabaseStorageService');
      return null;
    }
  }

  // Delete file from Supabase storage
  Future<void> deleteFile(String bucket, String path) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      developer.log('Error deleting file: $e', name: 'SupabaseStorageService');
    }
  }
}
