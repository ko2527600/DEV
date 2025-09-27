import 'package:drift/drift.dart';

class Medications extends Table {
  TextColumn get id => text().customConstraint('UNIQUE')();
  TextColumn get name => text()();
  TextColumn get dosage => text()();
  TextColumn get unit => text()();
  TextColumn get form => text()(); // tablet, capsule, liquid, etc.
  TextColumn get instructions => text().nullable()();
  IntColumn get quantity => integer()();
  IntColumn get remainingQuantity => integer()();
  IntColumn get refillThreshold => integer().withDefault(const Constant(5))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class MedicationSchedules extends Table {
  TextColumn get id => text().customConstraint('UNIQUE')();
  TextColumn get medicationId => text().references(Medications, #id)();
  TextColumn get scheduleType => text()(); // daily, weekly, monthly, as_needed
  TextColumn get frequency => text()(); // once, twice, three_times, four_times
  TextColumn get daysOfWeek =>
      text().nullable()(); // JSON array for weekly schedules
  TextColumn get timesOfDay => text()(); // JSON array of times
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class MedicationLogs extends Table {
  TextColumn get id => text().customConstraint('UNIQUE')();
  TextColumn get medicationId => text().references(Medications, #id)();
  TextColumn get scheduleId =>
      text().references(MedicationSchedules, #id).nullable()();
  TextColumn get action => text()(); // taken, skipped, missed
  DateTimeColumn get scheduledTime => dateTime()();
  DateTimeColumn get actualTime => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
