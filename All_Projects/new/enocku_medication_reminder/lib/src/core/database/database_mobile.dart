import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

LazyDatabase createDatabase() {
  return LazyDatabase(() async {
    // For mobile platforms, use NativeDatabase
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'enocku_medication.db'));
    return NativeDatabase(file);
  });
} 