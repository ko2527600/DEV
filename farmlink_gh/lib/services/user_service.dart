import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/farmer_model.dart';
import '../models/buyer_model.dart';
import 'dart:developer' as developer;

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      developer.log('Error getting user profile: $e', name: 'UserService');
      return null;
    }
  }

  // Create user profile after registration
  Future<bool> createUserProfile({
    required String userId,
    required String email,
    required String fullName,
    required String phoneNumber,
    required String userType,
  }) async {
    try {
      await _supabase.from('users').insert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'user_type': userType,
      });

      return true;
    } catch (e) {
      developer.log('Error creating user profile: $e', name: 'UserService');
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (profileImageUrl != null) updates['profile_image_url'] = profileImageUrl;

      await _supabase
          .from('users')
          .update(updates)
          .eq('id', userId);

      return true;
    } catch (e) {
      developer.log('Error updating user profile: $e', name: 'UserService');
      return false;
    }
  }

  // Create farmer profile
  Future<bool> createFarmerProfile({
    required String userId,
    required String farmName,
    required String farmLocation,
    required String farmSize,
    String? description,
  }) async {
    try {
      await _supabase.from('farmers').insert({
        'id': userId,
        'farm_name': farmName,
        'farm_location': farmLocation,
        'farm_size': farmSize,
        'description': description,
      });

      return true;
    } catch (e) {
      developer.log('Error creating farmer profile: $e', name: 'UserService');
      return false;
    }
  }

  // Get farmer profile
  Future<FarmerModel?> getFarmerProfile(String userId) async {
    try {
      final response = await _supabase
          .from('farmers')
          .select('id, farm_name, farm_description, farm_size, farm_location, latitude, longitude, business_hours, created_at, updated_at')
          .eq('id', userId)
          .single();

      return FarmerModel.fromJson(response);
    } catch (e) {
      developer.log('Error getting farmer profile: $e', name: 'UserService');
      return null;
    }
  }

  // Update farmer profile
  Future<bool> updateFarmerProfile({
    required String userId,
    String? farmName,
    String? farmLocation,
    String? farmSize,
    String? description,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (farmName != null) updates['farm_name'] = farmName;
      if (farmLocation != null) updates['farm_location'] = farmLocation;
      if (farmSize != null) updates['farm_size'] = farmSize;
      if (description != null) updates['description'] = description;

      await _supabase
          .from('farmers')
          .update(updates)
          .eq('id', userId);

      return true;
    } catch (e) {
      developer.log('Error updating farmer profile: $e', name: 'UserService');
      return false;
    }
  }

  // Create buyer profile
  Future<bool> createBuyerProfile({
    required String userId,
    required String companyName,
    required String businessType,
    required String location,
    String? description,
  }) async {
    try {
      await _supabase.from('buyers').insert({
        'id': userId,
        'company_name': companyName,
        'business_type': businessType,
        'location': location,
        'description': description,
      });

      return true;
    } catch (e) {
      developer.log('Error creating buyer profile: $e', name: 'UserService');
      return false;
    }
  }

  // Get buyer profile
  Future<BuyerModel?> getBuyerProfile(String userId) async {
    try {
      final response = await _supabase
          .from('buyers')
          .select('id, company_name, business_type, business_location, latitude, longitude, created_at, updated_at')
          .eq('id', userId)
          .single();

      return BuyerModel.fromJson(response);
    } catch (e) {
      developer.log('Error getting buyer profile: $e', name: 'UserService');
      return null;
    }
  }

  // Update buyer profile
  Future<bool> updateBuyerProfile({
    required String userId,
    String? companyName,
    String? businessType,
    String? location,
    String? description,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (companyName != null) updates['company_name'] = companyName;
      if (businessType != null) updates['business_type'] = businessType;
      if (location != null) updates['location'] = location;
      if (description != null) updates['description'] = description;

      await _supabase
          .from('buyers')
          .update(updates)
          .eq('id', userId);

      return true;
    } catch (e) {
      developer.log('Error updating buyer profile: $e', name: 'UserService');
      return false;
    }
  }

  // Get all farmers
  Future<List<UserModel>> getAllFarmers() async {
    try {
      final response = await _supabase
          .from('users')
          .select('*, farmers(*)')
          .eq('user_type', 'farmer');

      return response.map((user) => UserModel.fromJson(user)).toList();
    } catch (e) {
      developer.log('Error getting farmers: $e', name: 'UserService');
      return [];
    }
  }

  // Get all buyers
  Future<List<UserModel>> getAllBuyers() async {
    try {
      final response = await _supabase
          .from('users')
          .select('*, buyers(*)')
          .eq('user_type', 'buyer');

      return response.map((user) => UserModel.fromJson(user)).toList();
    } catch (e) {
      developer.log('Error getting buyers: $e', name: 'UserService');
      return [];
    }
  }
}
