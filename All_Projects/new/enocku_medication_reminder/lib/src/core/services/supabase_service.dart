import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:take_medication/src/core/config/supabase_config.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Medications
  static Future<List<Map<String, dynamic>>> getMedications() async {
    try {
      final response = await _client
          .from(SupabaseConfig.medicationsTable)
          .select()
          .eq('is_active', true)
          .order('name');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch medications: $e');
    }
  }

  static Future<Map<String, dynamic>?> getMedicationById(String id) async {
    try {
      final response = await _client
          .from(SupabaseConfig.medicationsTable)
          .select()
          .eq('id', id)
          .single();
      
      return response;
    } catch (e) {
      if (e.toString().contains('No rows returned')) {
        return null;
      }
      throw Exception('Failed to fetch medication: $e');
    }
  }

  static Future<void> insertMedication(Map<String, dynamic> medication) async {
    try {
      await _client
          .from(SupabaseConfig.medicationsTable)
          .insert(medication);
    } catch (e) {
      throw Exception('Failed to insert medication: $e');
    }
  }

  static Future<void> updateMedication(String id, Map<String, dynamic> medication) async {
    try {
      await _client
          .from(SupabaseConfig.medicationsTable)
          .update(medication)
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to update medication: $e');
    }
  }

  static Future<void> deleteMedication(String id) async {
    try {
      await _client
          .from(SupabaseConfig.medicationsTable)
          .update({'is_active': false})
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete medication: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getMedicationsNeedingRefill() async {
    try {
      final response = await _client
          .from(SupabaseConfig.medicationsTable)
          .select()
          .eq('is_active', true)
          .lte('remaining_quantity', 'refill_threshold');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch medications needing refill: $e');
    }
  }

  // Medication Schedules
  static Future<List<Map<String, dynamic>>> getSchedulesForMedication(String medicationId) async {
    try {
      final response = await _client
          .from(SupabaseConfig.medicationSchedulesTable)
          .select()
          .eq('medication_id', medicationId)
          .eq('is_active', true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch schedules: $e');
    }
  }

  static Future<void> insertSchedule(Map<String, dynamic> schedule) async {
    try {
      await _client
          .from(SupabaseConfig.medicationSchedulesTable)
          .insert(schedule);
    } catch (e) {
      throw Exception('Failed to insert schedule: $e');
    }
  }

  // Medication Logs
  static Future<void> logMedication(Map<String, dynamic> log) async {
    try {
      await _client
          .from(SupabaseConfig.medicationLogsTable)
          .insert(log);
    } catch (e) {
      throw Exception('Failed to log medication: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getLogsForMedication(String medicationId) async {
    try {
      final response = await _client
          .from(SupabaseConfig.medicationLogsTable)
          .select()
          .eq('medication_id', medicationId)
          .order('scheduled_time', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch logs: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getTodaysLogs() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      final response = await _client
          .from(SupabaseConfig.medicationLogsTable)
          .select()
          .gte('scheduled_time', startOfDay.toIso8601String())
          .lte('scheduled_time', endOfDay.toIso8601String())
          .order('scheduled_time', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch today\'s logs: $e');
    }
  }

  // Authentication
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signUp(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
