import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';
import '../services/network_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  User? _currentUser;
  bool _isLoading = true;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() async {
    try {
      _currentUser = _supabaseService.currentUser;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final online = await NetworkService()
          .hasInternetConnection(testHost: 'supabase.com');
      if (!online) {
        _error =
            'No internet connection. Please check your network and try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUser = _supabaseService.currentUser;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Sign in failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(
      String email, String password, String fullName, String memberId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final online = await NetworkService()
          .hasInternetConnection(testHost: 'supabase.com');
      if (!online) {
        _error =
            'No internet connection. Please check your network and try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        userData: {
          'full_name': fullName,
          'member_id': memberId,
          'role': 'member',
        },
      );

      if (response.user != null) {
        _currentUser = _supabaseService.currentUser;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Sign up failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabaseService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> updateUser({String? fullName, String? email}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_currentUser == null) {
        _error = 'No user logged in';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Update user data in Supabase
      final success = await _supabaseService.updateUser(
        fullName: fullName,
        email: email,
      );

      if (success) {
        // Refresh current user data
        _currentUser = _supabaseService.currentUser;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update user';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Theme management
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
}
