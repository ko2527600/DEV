import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthProvider extends ChangeNotifier {
  // Auth State
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _userType; // 'farmer' or 'buyer'
  
  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userType => _userType;
  bool get isAuthenticated => _currentUser != null;
  bool get isFarmer => _userType == 'farmer';
  bool get isBuyer => _userType == 'buyer';
  
  // Initialize auth state
  Future<void> initialize() async {
    try {
      setLoading(true);
      
      // Test database connection and tables
      await _testDatabaseConnection();
      
      // Check if user is already signed in
      final user = SupabaseConfig.currentUser;
      if (user != null) {
        _currentUser = user;
        await _loadUserType();
      }
      
      // Listen to auth state changes
      SupabaseConfig.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        
        switch (event) {
          case AuthChangeEvent.signedIn:
            _currentUser = session?.user;
            _loadUserType();
            break;
          case AuthChangeEvent.signedOut:
            _currentUser = null;
            _userType = null;
            break;
          case AuthChangeEvent.tokenRefreshed:
            _currentUser = session?.user;
            break;
          default:
            break;
        }
        
        notifyListeners();
      });
      
    } catch (e) {
      setError('Failed to initialize authentication: $e');
    } finally {
      setLoading(false);
    }
  }

  // Test database connection and tables
  Future<void> _testDatabaseConnection() async {
    try {
      // Test if users table exists
      await SupabaseConfig.database
          .from('users')
          .select('count')
          .limit(1);
      
      // Test if farmers table exists
      await SupabaseConfig.database
          .from('farmers')
          .select('count')
          .limit(1);
      
      // Test if buyers table exists
      await SupabaseConfig.database
          .from('buyers')
          .select('count')
          .limit(1);
      
    } catch (e) {
      // Silently fail - tables might not exist yet
    }
  }
  
  // Load user type from database
  Future<void> _loadUserType() async {
    try {
      if (_currentUser != null) {
        final response = await SupabaseConfig.database
            .from('users')
            .select('user_type')
            .eq('id', _currentUser!.id)
            .single();
        
        _userType = response['user_type'];
        notifyListeners();
      }
    } catch (e) {
      // User type not found, will be set during registration
      _userType = null;
    }
  }
  
  // Sign Up
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String userType,
    required String location,
  }) async {
    try {
      setLoading(true);
      clearError();
      
      print('🔍 Starting signup for: $email, type: $userType');
      
      // Create auth account
      final response = await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone_number': phoneNumber,
          'user_type': userType,
          'location': location,
        },
      );
      
      if (response.user != null) {
        _currentUser = response.user;
        _userType = userType;
        
        print('✅ Auth account created, now creating profile...');
        
        // Create user profile
        try {
          await _createUserProfile(userType);
          print('✅ Profile creation completed successfully');
        } catch (profileError) {
          print('❌ Profile creation failed: $profileError');
          // Don't fail the entire signup, but log the error
          setError('Account created but profile setup failed: $profileError');
        }
        
        notifyListeners();
        return true;
      } else {
        setError('Failed to create account');
        return false;
      }
      
    } catch (e) {
      print('❌ Signup failed: $e');
      setError('Sign up failed: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
  
  // Create user profile
  Future<void> _createUserProfile(String userType) async {
    try {
      if (_currentUser == null) return;
      
      print('🔍 Creating user profile for: ${_currentUser!.id}');
      print('🔍 User type: $userType');
      
      // Create or update base user profile (idempotent)
      final userProfile = await SupabaseConfig.database
          .from('users')
          .upsert({
            'id': _currentUser!.id,
            'email': _currentUser!.email,
            'full_name': _currentUser!.userMetadata?['full_name'] ?? '',
            'phone_number': _currentUser!.userMetadata?['phone_number'] ?? '',
            'user_type': userType,
            'location': _currentUser!.userMetadata?['location'] ?? '',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'id')
          .select()
          .single();
      
      print('✅ User profile created: $userProfile');
      
      // Create type-specific profile
      if (userType == 'farmer') {
        print('🔍 Creating farmer profile...');
        final farmerProfile = await SupabaseConfig.database
            .from('farmers')
            .upsert({
              'id': _currentUser!.id,
              'farm_name': 'My Farm',
              'farm_location': _currentUser!.userMetadata?['location'] ?? '',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            }, onConflict: 'id')
            .select()
            .single();
        print('✅ Farmer profile created: $farmerProfile');
      } else if (userType == 'buyer') {
        print('🔍 Creating buyer profile...');
        final buyerProfile = await SupabaseConfig.database
            .from('buyers')
            .upsert({
              'id': _currentUser!.id,
              'business_location': _currentUser!.userMetadata?['location'] ?? '',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            }, onConflict: 'id')
            .select()
            .single();
        print('✅ Buyer profile created: $buyerProfile');
      }
      
    } catch (e) {
      print('❌ Error creating user profile: $e');
      setError('Failed to create user profile: $e');
      rethrow; // Re-throw to handle it in the calling method
    }
  }
  
  // Sign In
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      setLoading(true);
      clearError();
      
      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        _currentUser = response.user;
        await _loadUserType();
        // Ensure related profile exists (farmer/buyer) for existing accounts
        await _ensureTypeSpecificProfile();
        notifyListeners();
        return true;
      } else {
        setError('Invalid email or password');
        return false;
      }
      
    } catch (e) {
      setError('Sign in failed: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Ensure farmer/buyer profile exists for current user
  Future<void> _ensureTypeSpecificProfile() async {
    try {
      if (_currentUser == null || _userType == null) return;

      if (_userType == 'farmer') {
        try {
          await SupabaseConfig.database
              .from('farmers')
              .select('id')
              .eq('id', _currentUser!.id)
              .single();
        } catch (_) {
          // Create minimal farmer profile if missing
          await SupabaseConfig.database
              .from('farmers')
              .upsert({
                'id': _currentUser!.id,
                'farm_name': 'My Farm',
                'farm_location': _currentUser!.userMetadata?['location'] ?? '',
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              }, onConflict: 'id');
        }
      } else if (_userType == 'buyer') {
        try {
          await SupabaseConfig.database
              .from('buyers')
              .select('id')
              .eq('id', _currentUser!.id)
              .single();
        } catch (_) {
          // Create minimal buyer profile if missing
          await SupabaseConfig.database
              .from('buyers')
              .upsert({
                'id': _currentUser!.id,
                'business_location': _currentUser!.userMetadata?['location'] ?? '',
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              }, onConflict: 'id');
        }
      }
    } catch (e) {
      // Non-fatal; product creation will still fail if this did not succeed
    }
  }
  
  // Sign Out
  Future<void> signOut() async {
    try {
      setLoading(true);
      await SupabaseConfig.signOut();
      _currentUser = null;
      _userType = null;
      notifyListeners();
      
      // Emit a signout event that UI can listen to
      // The UI should navigate to auth screen after this
    } catch (e) {
      setError('Sign out failed: $e');
    } finally {
      setLoading(false);
    }
  }
  
  // Password Reset
  Future<bool> resetPassword(String email) async {
    try {
      setLoading(true);
      clearError();
      
      await SupabaseConfig.auth.resetPasswordForEmail(email);
      return true;
      
    } catch (e) {
      setError('Password reset failed: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
  
  // Loading State
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Error Handling
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Update User Type
  void updateUserType(String userType) {
    _userType = userType;
    notifyListeners();
  }
}
