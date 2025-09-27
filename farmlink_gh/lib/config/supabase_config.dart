import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Supabase configuration
  static String get supabaseUrl => 
      dotenv.env['SUPABASE_URL'] ?? '';
  
  static String get supabaseAnonKey => 
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Database table names
  static const String usersTable = 'users';
  static const String farmersTable = 'farmers';
  static const String buyersTable = 'buyers';
  static const String productsTable = 'products';
  static const String messagesTable = 'messages';
}
