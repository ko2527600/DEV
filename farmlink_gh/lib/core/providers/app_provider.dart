import 'package:flutter/material.dart';
import '../config/env_config.dart';

class AppProvider extends ChangeNotifier {
  // App State
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOnline = true;
  
  // Theme
  bool _isDarkMode = false;
  
  // Language
  String _currentLanguage = 'en';
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _isOnline;
  bool get isDarkMode => _isDarkMode;
  String get currentLanguage => _currentLanguage;
  
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
  
  // Network State
  void setOnlineStatus(bool online) {
    _isOnline = online;
    notifyListeners();
  }
  
  // Theme Management
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
  
  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
  
  // Language Management
  void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
    notifyListeners();
  }
  
  // App Configuration
  bool get isConfigured => EnvConfig.isConfigured;
  String get configurationError => EnvConfig.configurationError;
  
  // Reset App State
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _isOnline = true;
    notifyListeners();
  }
}
