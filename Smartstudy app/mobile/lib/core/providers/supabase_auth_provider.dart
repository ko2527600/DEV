import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseConfig.client;
});

// Auth state changes stream
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final auth = SupabaseConfig.auth;
  return auth.onAuthStateChange.map((event) => event.session?.user);
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return SupabaseConfig.auth.currentUser;
});

// Auth provider for managing authentication operations
class SupabaseAuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final SupabaseClient _supabase;

  SupabaseAuthNotifier(this._supabase) : super(const AsyncValue.loading()) {
    _supabase.auth.onAuthStateChange.listen((event) {
      state = AsyncValue.data(event.session?.user);
    });
  }

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Sign up with email and password
  Future<void> signUpWithEmailAndPassword(
    String email,
    String password,
    String fullName,
    String userType, // 'student' or 'teacher'
  ) async {
    try {
      state = const AsyncValue.loading();

      // Create user in Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'user_type': userType,
        },
      );

      if (response.user != null) {
        // Create user profile in database
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'user_type': userType,
          'created_at': DateTime.now().toIso8601String(),
          'last_login': DateTime.now().toIso8601String(),
          'is_active': true,
        });
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.auth.updateUser(
          UserAttributes(
            data: {
              'full_name': displayName,
              'avatar_url': photoURL,
            },
          ),
        );
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Auth notifier provider
final supabaseAuthNotifierProvider =
    StateNotifierProvider<SupabaseAuthNotifier, AsyncValue<User?>>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseAuthNotifier(supabase);
});

// User profile provider
final userProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  if (userId.isEmpty) return null;

  try {
    final response = await SupabaseConfig.client
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    return response;
  } catch (e) {
    return null;
  }
});
