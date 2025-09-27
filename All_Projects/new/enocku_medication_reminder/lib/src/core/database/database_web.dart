import 'package:drift/drift.dart';
import 'package:drift/web.dart';

LazyDatabase createDatabase() {
  return LazyDatabase(() async {
    // For web, use WebDatabase without inMemory parameter
    // The database will be stored in IndexedDB by default
    return WebDatabase('enocku_medication.db');
  });
} 