import 'package:drift/drift.dart';
import 'package:take_medication/src/core/database/app_database.dart';
import 'package:take_medication/src/core/database/tables/medications.dart';

part 'medication_dao.g.dart';

@DriftAccessor(tables: [Medications])
class MedicationDao extends DatabaseAccessor<AppDatabase>
    with _$MedicationDaoMixin {
  MedicationDao(AppDatabase db) : super(db);

  // Get all active medications
  Future<List<Medication>> getAllMedications() {
    return (select(medications)..where((tbl) => tbl.isActive)).get();
  }

  // Get medication by ID
  Future<Medication?> getMedicationById(String id) {
    return (select(
      medications,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  // Insert new medication
  Future<int> insertMedication(Insertable<Medication> medication) {
    return into(medications).insert(medication);
  }

  // Update medication
  Future<bool> updateMedication(Insertable<Medication> medication) {
    return update(medications).replace(medication);
  }

  // Soft delete medication (set isActive to false)
  Future<int> deleteMedication(String id) {
    return (update(medications)..where((tbl) => tbl.id.equals(id))).write(
      const MedicationsCompanion(isActive: Value(false)),
    );
  }

  // Get medications that need refill
  Future<List<Medication>> getMedicationsNeedingRefill() {
    return (select(medications)
          ..where((tbl) => tbl.isActive))
        .get();
  }
}

@DriftAccessor(tables: [MedicationSchedules])
class MedicationScheduleDao extends DatabaseAccessor<AppDatabase>
    with _$MedicationScheduleDaoMixin {
  MedicationScheduleDao(AppDatabase db) : super(db);

  // Get schedules for a medication
  Future<List<MedicationSchedule>> getSchedulesForMedication(
    String medicationId,
  ) {
    return (select(medicationSchedules)
          ..where((tbl) => tbl.medicationId.equals(medicationId))
          ..where((tbl) => tbl.isActive))
        .get();
  }

  // Insert new schedule
  Future<int> insertSchedule(Insertable<MedicationSchedule> schedule) {
    return into(medicationSchedules).insert(schedule);
  }

  // Update schedule
  Future<bool> updateSchedule(Insertable<MedicationSchedule> schedule) {
    return update(medicationSchedules).replace(schedule);
  }

  // Delete schedule
  Future<int> deleteSchedule(String id) {
    return (delete(
      medicationSchedules,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  // Get active schedules
  Future<List<MedicationSchedule>> getActiveSchedules() {
    return (select(medicationSchedules)..where((tbl) => tbl.isActive)).get();
  }
}

@DriftAccessor(tables: [MedicationLogs])
class MedicationLogDao extends DatabaseAccessor<AppDatabase>
    with _$MedicationLogDaoMixin {
  MedicationLogDao(AppDatabase db) : super(db);

  // Log medication action
  Future<int> logMedication(Insertable<MedicationLog> log) {
    return into(medicationLogs).insert(log);
  }

  // Get logs for a medication
  Future<List<MedicationLog>> getLogsForMedication(String medicationId) {
    return (select(medicationLogs)
          ..where((tbl) => tbl.medicationId.equals(medicationId))
          ..orderBy([(t) => OrderingTerm.desc(t.scheduledTime)]))
        .get();
  }

  // Get logs for a date range
  Future<List<MedicationLog>> getLogsForDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(medicationLogs)
          ..where((tbl) => tbl.scheduledTime.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.scheduledTime)]))
        .get();
  }

  // Get today's logs
  Future<List<MedicationLog>> getTodaysLogs() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return getLogsForDateRange(startOfDay, endOfDay);
  }

  // Check if medication was taken at specific time
  Future<bool> wasMedicationTaken(
    String medicationId,
    DateTime scheduledTime,
  ) async {
    final log =
        await (select(medicationLogs)
              ..where((tbl) => tbl.medicationId.equals(medicationId))
              ..where((tbl) => tbl.scheduledTime.equals(scheduledTime))
              ..where((tbl) => tbl.action.equals('taken')))
            .getSingleOrNull();

    return log != null;
  }
}
