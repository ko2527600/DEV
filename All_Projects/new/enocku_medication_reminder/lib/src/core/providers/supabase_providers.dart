import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:take_medication/src/core/services/supabase_service.dart';

// Supabase-based providers
final supabaseMedicationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // This will be refreshed when invalidated
  return await SupabaseService.getMedications();
});

// Provider to force refresh medications
final medicationsRefreshProvider = StateProvider<int>((ref) => 0);

final supabaseMedicationsWithRefreshProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Watch the refresh counter to trigger rebuilds
  ref.watch(medicationsRefreshProvider);
  return await SupabaseService.getMedications();
});

final supabaseMedicationByIdProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  return await SupabaseService.getMedicationById(id);
});

final supabaseMedicationsNeedingRefillProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await SupabaseService.getMedicationsNeedingRefill();
});

final supabaseSchedulesForMedicationProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, medicationId) async {
  return await SupabaseService.getSchedulesForMedication(medicationId);
});

final supabaseLogsForMedicationProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, medicationId) async {
  return await SupabaseService.getLogsForMedication(medicationId);
});

final supabaseTodaysLogsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await SupabaseService.getTodaysLogs();
});

// Authentication providers
final supabaseAuthStateProvider = StreamProvider((ref) {
  return SupabaseService.authStateChanges;
});

final supabaseCurrentUserProvider = Provider((ref) {
  return SupabaseService.getCurrentUser();
});

// Medication actions
final supabaseMedicationActionsProvider = Provider((ref) {
  return SupabaseMedicationActions();
});

class SupabaseMedicationActions {
  Future<void> addMedication(Map<String, dynamic> medication) async {
    await SupabaseService.insertMedication(medication);
  }

  Future<void> updateMedication(String id, Map<String, dynamic> medication) async {
    await SupabaseService.updateMedication(id, medication);
  }

  Future<void> deleteMedication(String id) async {
    await SupabaseService.deleteMedication(id);
  }

  Future<void> addSchedule(Map<String, dynamic> schedule) async {
    await SupabaseService.insertSchedule(schedule);
  }

  Future<void> logMedication(Map<String, dynamic> log) async {
    await SupabaseService.logMedication(log);
  }
}
