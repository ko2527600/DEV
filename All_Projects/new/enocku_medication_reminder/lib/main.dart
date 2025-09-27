import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:take_medication/src/app.dart';
import 'package:take_medication/src/core/config/supabase_config.dart';
import 'package:take_medication/src/core/services/network_service.dart';
import 'package:take_medication/src/core/services/alarm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  
  // Initialize alarm service
  try {
    await AlarmService().initialize();
    debugPrint('✅ Alarm service initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Failed to initialize alarm service: $e');
  }
  
  // Check network connectivity on startup
  try {
    final networkStatus = await NetworkService.getNetworkStatus();
    debugPrint('🌐 Network status: $networkStatus');
  } catch (e) {
    debugPrint('⚠️ Network check failed: $e');
  }
  
  runApp(const ProviderScope(child: EnockuMedicationReminderApp()));
}
