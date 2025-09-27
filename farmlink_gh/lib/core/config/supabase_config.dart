import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env_config.dart';

class SupabaseConfig {
  static SupabaseClient? _client;
  
  // Initialize Supabase
  static Future<void> initialize() async {
    try {
      print('🔍 SupabaseConfig.initialize() called');
      
      // Debug environment variables before initialization
      EnvConfig.debugEnvVars();
      
      final url = EnvConfig.supabaseUrl;
      final anonKey = EnvConfig.supabaseAnonKey;
      
      print('🔍 About to initialize Supabase with:');
      print('URL: $url');
      print('Anon Key: ${anonKey.substring(0, 20)}...');
      
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: kDebugMode,
      );
      
      print('✅ Supabase initialized successfully');
      print('🔗 URL: $url');
      print('🔑 Anon Key: ${anonKey.substring(0, 20)}...');
      
      _client = Supabase.instance.client;
      
    } catch (e) {
      print('❌ SupabaseConfig.initialize() error: $e');
      rethrow;
    }
  }
  
  // Get Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call SupabaseConfig.initialize() first.');
    }
    return _client!;
  }
  
  // Get auth instance
  static GoTrueClient get auth => client.auth;
  
  // Get database instance - use client directly to avoid type issues
  static SupabaseClient get database => client;
  
  // Get storage instance - use client directly to avoid type issues
  static SupabaseClient get storage => client;
  
  // Get realtime instance - use client directly to avoid type issues
  static SupabaseClient get realtime => client;
  
  // Check if user is authenticated
  static bool get isAuthenticated => auth.currentUser != null;
  
  // Get current user
  static User? get currentUser => auth.currentUser;
  
  // Get current user ID
  static String? get currentUserId => currentUser?.id;
  
  // Sign out
  static Future<void> signOut() async {
    try {
      await auth.signOut();
      if (EnvConfig.isDevelopment) {
        print('✅ User signed out successfully');
      }
    } catch (e) {
      if (EnvConfig.isDevelopment) {
        print('❌ Failed to sign out: $e');
      }
      rethrow;
    }
  }
  
  // Check connection status
  static Future<bool> checkConnection() async {
    try {
      // Try to make a simple query to check connection
      await client.from('users').select('id').limit(1);
      return true;
    } catch (e) {
      if (EnvConfig.isDevelopment) {
        print('❌ Database connection failed: $e');
      }
      return false;
    }
  }
}
