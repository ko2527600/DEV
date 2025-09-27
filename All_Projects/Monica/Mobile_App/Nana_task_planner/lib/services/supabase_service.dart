import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../models/user.dart' as app_user;

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient _client;
  
  // Your Supabase project details
  static const String supabaseUrl = 'https://vsrnofsufipqmsbztzoa.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZzcm5vZnN1ZmlwcW1zYnp0em9hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUzMzc2ODQsImV4cCI6MjA3MDkxMzY4NH0.MjmFYI2byVBMQ5q49_wJMJZ1iQKh8J2j3Uw7cYSAvQI';

  void initialize() {
    _client = Supabase.instance.client;
    print('SupabaseService initialized with URL: $supabaseUrl');
  }

  // Test connection to Supabase
  Future<bool> testConnection() async {
    try {
      print('Testing connection to Supabase...');
      // Try to make a simple query to test the connection
      await _client.from('profiles').select('count').limit(1);
      print('✅ Supabase connection successful!');
      return true;
    } catch (e) {
      print('❌ Supabase connection failed: $e');
      return false;
    }
  }

  SupabaseClient get client {
    if (_client == null) {
      throw Exception('SupabaseService not initialized. Call initialize() first.');
    }
    return _client;
  }

  // Authentication methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    print('Starting signup process...');
    
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    
    print('Signup response: ${response.user?.id}');
    
    // If signup is successful, create a profile
    if (response.user != null) {
      try {
        print('Creating user profile for ID: ${response.user!.id}');
        
        final user = app_user.User(
          id: response.user!.id,
          email: email,
          fullName: fullName,
          avatarUrl: null,
          createdAt: DateTime.parse(response.user!.createdAt),
          updatedAt: DateTime.parse(response.user!.updatedAt ?? response.user!.createdAt),
          preferences: {},
          timezone: 'UTC',
        );
        
        print('User object created, calling createUser...');
        final createdProfile = await createUser(user);
        print('Profile created successfully: ${createdProfile.id}');
        
      } catch (e) {
        print('Failed to create profile: $e');
        print('Stack trace: ${StackTrace.current}');
        // Don't fail the signup, but log the error
      }
    } else {
      print('No user in signup response');
    }
    
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    // If signin is successful, ensure profile exists
    if (response.user != null) {
      try {
        // Check if profile exists
        final existingProfile = await getCurrentUserProfile();
        if (existingProfile == null) {
          // Create profile if it doesn't exist (for users who signed up before profile creation was implemented)
          final user = app_user.User(
            id: response.user!.id,
            email: email,
            fullName: response.user!.userMetadata?['full_name'],
            avatarUrl: null,
            createdAt: DateTime.parse(response.user!.createdAt),
            updatedAt: DateTime.parse(response.user!.updatedAt ?? response.user!.createdAt),
            preferences: {},
            timezone: 'UTC',
          );
          
          await createUser(user);
        }
      } catch (e) {
        // Log the error but don't fail the signin
        print('Failed to ensure profile exists: $e');
      }
    }
    
    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  app_user.User? get currentUser {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        return app_user.User(
          id: user.id,
          email: user.email ?? '',
          fullName: user.userMetadata?['full_name'],
          avatarUrl: user.userMetadata?['avatar_url'],
          createdAt: DateTime.parse(user.createdAt),
          updatedAt: DateTime.parse(user.updatedAt ?? user.createdAt),
          preferences: user.userMetadata?['preferences'] ?? {},
          timezone: user.userMetadata?['timezone'] ?? 'UTC',
        );
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Get current user profile from database
  Future<app_user.User?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user != null) {
      try {
        final response = await _client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();
        
        return app_user.User.fromJson(response);
      } catch (e) {
        print('Failed to fetch user profile: $e');
        return null;
      }
    }
    return null;
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Task methods
  Future<List<Task>> getTasks() async {
    final response = await _client
        .from('tasks')
        .select('*, categories(*)')
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Task.fromJson(json)).toList();
  }

  Future<Task> createTask(Task task) async {
    try {
      // Ensure the user profile exists before creating a task
      final userProfile = await getCurrentUserProfile();
      if (userProfile == null) {
        throw Exception('User profile not found. Please ensure you are properly authenticated.');
      }
      
      final response = await _client
          .from('tasks')
          .insert(task.toJson())
          .select()
          .single();
      
      return Task.fromJson(response);
    } catch (e) {
      if (e.toString().contains('foreign key constraint')) {
        throw Exception('User profile not found in database. Please try signing out and signing in again.');
      }
      rethrow;
    }
  }

  Future<Task> updateTask(Task task) async {
    final response = await _client
        .from('tasks')
        .update(task.toJson())
        .eq('id', task.id)
        .select()
        .single();
    
    return Task.fromJson(response);
  }

  Future<void> deleteTask(String taskId) async {
    await _client
        .from('tasks')
        .delete()
        .eq('id', taskId);
  }

  // Category methods
  Future<List<Category>> getCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .order('name');
    
    return (response as List).map((json) => Category.fromJson(json)).toList();
  }

  Future<Category> createCategory(Category category) async {
    final response = await _client
        .from('categories')
        .insert(category.toJson())
        .select()
        .single();
    
    return Category.fromJson(response);
  }

  Future<Category> updateCategory(Category category) async {
    final response = await _client
        .from('categories')
        .update(category.toJson())
        .eq('id', category.id)
        .select()
        .single();
    
    return Category.fromJson(response);
  }

  Future<void> deleteCategory(String categoryId) async {
    await _client
        .from('categories')
        .delete()
        .eq('id', categoryId);
  }

  // User methods
  Future<app_user.User> createUser(app_user.User user) async {
    print('createUser called with: ${user.toJson()}');
    
    try {
      final response = await _client
          .from('profiles')
          .insert(user.toJson())
          .select()
          .single();
      
      print('Profile inserted successfully: $response');
      return app_user.User.fromJson(response);
    } catch (e) {
      print('Error in createUser: $e');
      print('User data being inserted: ${user.toJson()}');
      rethrow;
    }
  }

  Future<app_user.User> updateUser(app_user.User user) async {
    final response = await _client
        .from('profiles')
        .update(user.toJson())
        .eq('id', user.id)
        .select()
        .single();
    
    return app_user.User.fromJson(response);
  }

  // TODO: Implement realtime subscriptions when Supabase Flutter API is stable
  // For now, we'll use polling or manual refresh
}
