import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'] ?? 'PLACEHOLDER_URL_NOT_FOUND';
    print('🔍 EnvConfig.supabaseUrl called: $url');
    return url;
  }

  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'] ?? 'PLACEHOLDER_KEY_NOT_FOUND';
    print('🔍 EnvConfig.supabaseAnonKey called: ${key.substring(0, 20)}...');
    return key;
  }

  static String get supabaseServiceRoleKey {
    final key = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? 'PLACEHOLDER_SERVICE_KEY_NOT_FOUND';
    print('🔍 EnvConfig.supabaseServiceRoleKey called: ${key.substring(0, 20)}...');
    return key;
  }

  // Debug method to check all environment variables
  static void debugEnvVars() {
    print('🔍 === ENVIRONMENT VARIABLES DEBUG ===');
    print('SUPABASE_URL: ${dotenv.env['SUPABASE_URL'] ?? 'NULL'}');
    print('SUPABASE_ANON_KEY: ${dotenv.env['SUPABASE_ANON_KEY']?.substring(0, 20) ?? 'NULL'}...');
    print('SUPABASE_SERVICE_ROLE_KEY: ${dotenv.env['SUPABASE_SERVICE_ROLE_KEY']?.substring(0, 20) ?? 'NULL'}...');
    print('All env vars: ${dotenv.env}');
    print('=====================================');
  }
  
  // Environment Detection
  static bool get isDevelopment => 
      const bool.fromEnvironment('dart.vm.product') == false;
  
  static bool get isProduction => 
      const bool.fromEnvironment('dart.vm.product') == true;
  
  // App Configuration
  static const String appName = 'FarmLink Ghana';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const int apiTimeoutSeconds = 30;
  static const int maxRetries = 3;
  
  // Storage Configuration
  static const String productImagesBucket = 'product-images';
  static const String profileImagesBucket = 'profile-images';
  
  // Validation
  static bool get isConfigured {
    return supabaseUrl != 'https://your-project.supabase.co' &&
           supabaseAnonKey != 'your-anon-key';
  }
  
  // Error Messages
  static String get configurationError {
    if (!isConfigured) {
      return 'Supabase configuration is missing. Please check your .env file.';
    }
    return '';
  }
}
