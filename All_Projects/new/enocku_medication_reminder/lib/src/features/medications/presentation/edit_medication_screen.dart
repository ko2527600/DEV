import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditMedicationScreen extends ConsumerWidget {
  final String medicationId;

  const EditMedicationScreen({super.key, required this.medicationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Medication')),
      body: Center(child: Text('Edit Medication Screen - ID: $medicationId')),
    );
  }
}
