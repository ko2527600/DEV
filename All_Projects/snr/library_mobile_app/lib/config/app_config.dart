class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://agyxwfynycvaswzdclnc.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFneXh3ZnlueWN2YXN3emRjbG5jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2ODA5NDEsImV4cCI6MjA3MTI1Njk0MX0.HGZWdksvHx7WlT1kx4cVIjZiBsEPkm6WzBCKzBwLVv4';
  
  // App Configuration
  static const String appName = 'Community Library';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'A comprehensive community library mobile app for everyone';
  
  // API Configuration
  static const int apiTimeout = 30000; // 30 seconds
  static const int maxRetries = 3;
  
  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double defaultElevation = 4.0;
  
  // Library Configuration
  static const int maxBooksPerPage = 20;
  static const int maxLoanDays = 14;
  static const int maxRenewals = 2;
  
  // Feature Flags
  static const bool enableNotifications = true;
  static const bool enableOfflineMode = false;
  static const bool enableSocialLogin = false;
  
  // Development Configuration
  static const bool isDevelopment = true;
  static const bool enableDebugLogs = true;
  static const bool enableAnalytics = false;
}
