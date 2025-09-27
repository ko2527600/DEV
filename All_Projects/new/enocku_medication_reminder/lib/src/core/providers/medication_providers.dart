import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:take_medication/src/core/database/app_database.dart';
import 'package:take_medication/src/core/database/daos/medication_dao.dart';
import 'package:take_medication/src/core/database/tables/medications.dart';

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// DAO providers
final medicationDaoProvider = Provider<MedicationDao>((ref) {
  final database = ref.watch(databaseProvider);
  return MedicationDao(database);
});

final medicationScheduleDaoProvider = Provider<MedicationScheduleDao>((ref) {
  final database = ref.watch(databaseProvider);
  return MedicationScheduleDao(database);
});

final medicationLogDaoProvider = Provider<MedicationLogDao>((ref) {
  final database = ref.watch(databaseProvider);
  return MedicationLogDao(database);
});

// Medication providers
final medicationsProvider = FutureProvider<List<Medication>>((ref) async {
  final dao = ref.watch(medicationDaoProvider);
  return await dao.getAllMedications();
});

final medicationByIdProvider = FutureProvider.family<Medication?, String>((ref, id) async {
  final dao = ref.watch(medicationDaoProvider);
  return await dao.getMedicationById(id);
});

final medicationsNeedingRefillProvider = FutureProvider<List<Medication>>((ref) async {
  final dao = ref.watch(medicationDaoProvider);
  return await dao.getMedicationsNeedingRefill();
});

// Schedule providers
final schedulesForMedicationProvider = FutureProvider.family<List<MedicationSchedule>, String>((ref, medicationId) async {
  final dao = ref.watch(medicationScheduleDaoProvider);
  return await dao.getSchedulesForMedication(medicationId);
});

final activeSchedulesProvider = FutureProvider<List<MedicationSchedule>>((ref) async {
  final dao = ref.watch(medicationScheduleDaoProvider);
  return await dao.getActiveSchedules();
});

// Log providers
final logsForMedicationProvider = FutureProvider.family<List<MedicationLog>, String>((ref, medicationId) async {
  final dao = ref.watch(medicationLogDaoProvider);
  return await dao.getLogsForMedication(medicationId);
});

final todaysLogsProvider = FutureProvider<List<MedicationLog>>((ref) async {
  final dao = ref.watch(medicationLogDaoProvider);
  return await dao.getTodaysLogs();
});

