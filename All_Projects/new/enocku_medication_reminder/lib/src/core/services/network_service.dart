import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  /// Check if the device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      if (kIsWeb) {
        // For web, assume connection is available
        return true;
      }
      
      // For mobile, try to connect to a reliable host
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('Network connectivity check failed: $e');
      return false;
    }
  }

  /// Check connectivity to Supabase specifically
  static Future<bool> canReachSupabase() async {
    try {
      if (kIsWeb) {
        return true;
      }
      
      // Try to reach Supabase
      final result = await InternetAddress.lookup('supabase.com')
          .timeout(const Duration(seconds: 5));
      
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('Supabase connectivity check failed: $e');
      return false;
    }
  }

  /// Get network status description
  static Future<String> getNetworkStatus() async {
    try {
      final hasInternet = await hasInternetConnection();
      if (!hasInternet) {
        return 'No internet connection';
      }
      
      final canReachSupabase = await NetworkService.canReachSupabase();
      if (!canReachSupabase) {
        return 'Internet available but cannot reach Supabase';
      }
      
      return 'Connected';
    } catch (e) {
      return 'Network check failed: $e';
    }
  }

  /// Retry logic for network operations
  static Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          rethrow;
        }
        
        debugPrint('Operation failed (attempt $attempt/$maxRetries): $e');
        await Future.delayed(delay);
      }
    }
    
    throw Exception('All retry attempts failed');
  }
}
