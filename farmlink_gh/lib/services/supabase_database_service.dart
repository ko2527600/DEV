import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmlink_gh/utils/logger.dart';

class SupabaseDatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Insert user into users table
  Future<void> insertUser(Map<String, dynamic> userData) async {
    try {
      await _supabase.from('users').insert(userData);
    } catch (e) {
      AppLogger.e('Error inserting user', e);
      rethrow;
    }
  }

  // Insert farmer profile
  Future<void> insertFarmer(Map<String, dynamic> farmerData) async {
    try {
      // Ensure the data matches the database schema
      final data = {
        'id': farmerData['id'],
        'farm_name': farmerData['farm_name'],
        'farm_location': farmerData['farm_location'],
        'farm_size': farmerData['farm_size'] ?? '',
        'description': farmerData['description'] ?? '',
        'verified': farmerData['verified'] ?? false,
        'created_at': farmerData['created_at'],
        'updated_at': farmerData['updated_at'] ?? DateTime.now().toIso8601String(),
      };
      
      await _supabase.from('farmers').insert(data);
    } catch (e) {
      AppLogger.e('Error inserting farmer', e);
      rethrow;
    }
  }

  // Insert buyer profile
  Future<void> insertBuyer(Map<String, dynamic> buyerData) async {
    try {
      // Ensure the data matches the database schema
      final data = {
        'id': buyerData['id'],
        'company_name': buyerData['company_name'],
        'business_type': buyerData['business_type'],
        'location': buyerData['location'] ?? '',
        'description': buyerData['description'] ?? '',
        'created_at': buyerData['created_at'],
        'updated_at': buyerData['updated_at'] ?? DateTime.now().toIso8601String(),
      };
      
      await _supabase.from('buyers').insert(data);
    } catch (e) {
      AppLogger.e('Error inserting buyer', e);
      rethrow;
    }
  }

  // Create a new farmer profile
  Future<void> createFarmerProfile({
    required String userId,
    required String name,
    required String location,
    required String phoneNumber,
    required List<String> crops,
  }) async {
    try {
      await _supabase.from('farmers').insert({
        'id': userId,
        'name': name,
        'location': location,
        'phone_number': phoneNumber,
        'crops': crops,
        'created_at': DateTime.now().toIso8601String(),
        'user_type': 'farmer',
      });
    } catch (e) {
      AppLogger.e('Error creating farmer profile', e);
      rethrow;
    }
  }

  // Create a new buyer profile
  Future<void> createBuyerProfile({
    required String userId,
    required String name,
    required String location,
    required String phoneNumber,
    required List<String> interestedCrops,
  }) async {
    try {
      await _supabase.from('buyers').insert({
        'id': userId,
        'name': name,
        'location': location,
        'phone_number': phoneNumber,
        'interested_crops': interestedCrops,
        'created_at': DateTime.now().toIso8601String(),
        'user_type': 'buyer',
      });
    } catch (e) {
      AppLogger.e('Error creating buyer profile', e);
      rethrow;
    }
  }

  // Get all farmers
  Future<List<Map<String, dynamic>>> getFarmers() async {
    try {
      final response = await _supabase.from('farmers').select();
      return response;
    } catch (e) {
      AppLogger.e('Error getting farmers', e);
      rethrow;
    }
  }

  // Get all buyers
  Future<List<Map<String, dynamic>>> getBuyers() async {
    try {
      final response = await _supabase.from('buyers').select();
      return response;
    } catch (e) {
      AppLogger.e('Error getting buyers', e);
      rethrow;
    }
  }

  // Get farmers by crop
  Future<List<Map<String, dynamic>>> getFarmersByCrop(String crop) async {
    try {
      final response = await _supabase.from('farmers').select().contains(
        'crops',
        [crop],
      );
      return response;
    } catch (e) {
      AppLogger.e('Error getting farmers by crop', e);
      rethrow;
    }
  }

  // Get buyers by interested crop
  Future<List<Map<String, dynamic>>> getBuyersByInterestedCrop(
    String crop,
  ) async {
    try {
      final response = await _supabase.from('buyers').select().contains(
        'interested_crops',
        [crop],
      );
      return response;
    } catch (e) {
      AppLogger.e('Error getting buyers by crop', e);
      rethrow;
    }
  }

  // Update farmer profile
  Future<void> updateFarmerProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _supabase.from('farmers').update(data).eq('id', userId);
    } catch (e) {
      AppLogger.e('Error updating farmer profile', e);
      rethrow;
    }
  }

  // Update buyer profile
  Future<void> updateBuyerProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _supabase.from('buyers').update(data).eq('id', userId);
    } catch (e) {
      AppLogger.e('Error updating buyer profile', e);
      rethrow;
    }
  }

  // Real-time subscriptions
  Stream<List<Map<String, dynamic>>> subscribeToFarmers() {
    return _supabase
        .from('farmers')
        .stream(primaryKey: ['id'])
        .map((event) => event.map((row) => row).toList());
  }

  Stream<List<Map<String, dynamic>>> subscribeToBuyers() {
    return _supabase
        .from('buyers')
        .stream(primaryKey: ['id'])
        .map((event) => event.map((row) => row).toList());
  }

  // For filtered subscriptions, we'll use regular queries instead of streams
  Future<List<Map<String, dynamic>>> getFarmerById(String farmerId) async {
    try {
      final response = await _supabase
          .from('farmers')
          .select('''
            *,
            users!inner(
              id,
              email,
              full_name,
              phone_number,
              user_type,
              profile_image_url
            )
          ''')
          .eq('id', farmerId);
      return response;
    } catch (e) {
      AppLogger.e('Error getting farmer by ID', e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProductsByFarmer(String farmerId) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .eq('farmer_id', farmerId);
      return response;
    } catch (e) {
      AppLogger.e('Error getting products by farmer', e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMessagesByUser(String userId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('''
            *,
            sender:users!inner(
              id,
              full_name,
              profile_image_url
            ),
            receiver:users!inner(
              id,
              full_name,
              profile_image_url
            )
          ''')
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .order('created_at');
      return response;
    } catch (e) {
      AppLogger.e('Error getting messages by user', e);
      return [];
    }
  }

  // Get user profile by ID
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      AppLogger.e('Error getting user profile', e);
      return null;
    }
  }

  // Get farmer profile by ID
  Future<Map<String, dynamic>?> getFarmerProfile(String userId) async {
    try {
      final response = await _supabase
          .from('farmers')
          .select('''
            *,
            users!inner(
              id,
              email,
              full_name,
              phone_number,
              user_type,
              profile_image_url
            )
          ''')
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      AppLogger.e('Error getting farmer profile', e);
      return null;
    }
  }

  // Get buyer profile by ID
  Future<Map<String, dynamic>?> getBuyerProfile(String userId) async {
    try {
      final response = await _supabase
          .from('buyers')
          .select('''
            *,
            users!inner(
              id,
              email,
              full_name,
              phone_number,
              user_type,
              profile_image_url
            )
          ''')
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      AppLogger.e('Error getting buyer profile', e);
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('users').update(data).eq('id', userId);
    } catch (e) {
      AppLogger.e('Error updating user profile', e);
      rethrow;
    }
  }
}
