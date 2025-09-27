import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Supabase configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mnigeltequzxwtymdfqv.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1uaWdlbHRlcXV6eHd0eW1kZnF2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1ODA0MTYsImV4cCI6MjA3MDE1NjQxNn0.jB4s2JnQ-xkrlbfNSy_gHo60Umsi4yWFqIntv4Z-Hms',
  );

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // Get Supabase client
  static SupabaseClient get client => Supabase.instance.client;

  // Get auth client
  static GoTrueClient get auth => Supabase.instance.client.auth;

  // Get database client
  static PostgrestClient get database => Supabase.instance.client.rest;
}
