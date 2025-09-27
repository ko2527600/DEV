import 'package:drift/drift.dart';
import 'package:take_medication/src/core/database/tables/medications.dart';
import 'package:take_medication/src/core/database/daos/medication_dao.dart';
import 'package:flutter/foundation.dart';

// Conditional imports for platform-specific database implementations
import 'database_web.dart' if (dart.library.io) 'database_mobile.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Medications, MedicationSchedules, MedicationLogs],
  daos: [MedicationDao, MedicationScheduleDao, MedicationLogDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(createDatabase());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future migrations
      },
    );
  }
}
