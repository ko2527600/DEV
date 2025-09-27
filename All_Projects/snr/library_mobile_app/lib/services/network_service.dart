import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  Future<bool> hasInternetConnection({String? testHost}) async {
    // On web, skip plugin checks that can be unreliable and assume online.
    if (kIsWeb) return true;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    // Lightweight HTTP ping to Supabase (or a provided host). Do not block if it fails.
    try {
      final url = Uri.parse(testHost != null ? 'https://$testHost' : AppConfig.supabaseUrl);
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      return response.statusCode < 500;
    } catch (_) {
      // Could fail due to captive portal/CORS/SSL; treat as indeterminate rather than offline
      return true;
    }
  }
}


