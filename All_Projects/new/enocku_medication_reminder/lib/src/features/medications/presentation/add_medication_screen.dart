import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:take_medication/src/core/providers/supabase_providers.dart';
import 'package:take_medication/src/core/services/alarm_service.dart';

class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  ConsumerState<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _quantityController = TextEditingController();
  final _refillThresholdController = TextEditingController();
  
  String _selectedUnit = 'mg';
  String _selectedForm = 'tablet';
  bool _isLoading = false;
  
  // Alarm settings
  bool _enableAlarm = false;
  TimeOfDay _alarmTime = const TimeOfDay(hour: 9, minute: 0);
  final List<bool> _alarmDays = List.generate(7, (index) => index < 5); // Mon-Fri by default
  final List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final List<String> _units = ['mg', 'mcg', 'g', 'ml', 'units', 'puffs'];
  final List<String> _forms = ['tablet', 'capsule', 'liquid', 'injection', 'inhaler', 'cream', 'drops'];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _quantityController.dispose();
    _refillThresholdController.dispose();
    super.dispose();
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final actions = ref.read(supabaseMedicationActionsProvider);
      // Get current user ID
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final medicationId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final medication = {
        'id': medicationId,
        'name': _nameController.text.trim(),
        'dosage': _dosageController.text.trim(),
        'unit': _selectedUnit,
        'form': _selectedForm,
        'instructions': _instructionsController.text.trim().isEmpty 
          ? null 
          : _instructionsController.text.trim(),
        'quantity': int.parse(_quantityController.text),
        'remaining_quantity': int.parse(_quantityController.text),
        'refill_threshold': int.parse(_refillThresholdController.text),
        'is_active': true,
        'user_id': currentUser.id, // Add user_id for RLS
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await actions.addMedication(medication);
      
      // Schedule alarm if enabled
      if (_enableAlarm) {
        await _scheduleMedicationAlarm(medicationId);
      }
      
      if (mounted) {
        // Force refresh the medications list
        ref.read(medicationsRefreshProvider.notifier).state++;
        
        // Navigate back to home
        if (mounted) {
          context.go('/');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medication added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding medication: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _scheduleMedicationAlarm(String medicationId) async {
    try {
      final alarmService = AlarmService();
      await alarmService.initialize();
      
      // Get selected days (convert to 1-7 format where 1=Monday)
      final selectedDays = <int>[];
      for (int i = 0; i < _alarmDays.length; i++) {
        if (_alarmDays[i]) {
          selectedDays.add(i + 1); // Convert to 1-7 format
        }
      }
      
      if (selectedDays.isNotEmpty) {
        await alarmService.scheduleMedicationReminder(
          medicationId: medicationId,
          medicationName: _nameController.text.trim(),
          dosage: '${_dosageController.text.trim()} ${_selectedUnit}',
          time: _alarmTime,
          daysOfWeek: selectedDays,
          soundEnabled: true,
          vibrationEnabled: true,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling alarm: $e');
      // Don't fail the medication save if alarm scheduling fails
    }
  }

  Widget _buildAlarmSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Set Medication Reminder',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Enable Reminder'),
          value: _enableAlarm,
          onChanged: (value) {
            setState(() => _enableAlarm = value);
          },
        ),
        if (_enableAlarm) ...[
          const SizedBox(height: 16),
          Text(
            'Reminder Time',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<TimeOfDay>(
            value: _alarmTime,
            decoration: const InputDecoration(
              labelText: 'Time',
            ),
            items: List.generate(24, (hour) => hour).map((hour) {
              return DropdownMenuItem(
                value: TimeOfDay(hour: hour, minute: 0),
                child: Text('$hour:00'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _alarmTime = value!);
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Remind on',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: List.generate(_dayNames.length, (index) {
              final dayName = _dayNames[index];
              return ChoiceChip(
                label: Text(dayName),
                selected: _alarmDays[index],
                onSelected: (selected) {
                  setState(() {
                    _alarmDays[index] = selected;
                  });
                },
              );
            }),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Medication'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Medication Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name',
                hintText: 'e.g., Aspirin, Metformin',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter medication name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Dosage and Unit Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosage',
                      hintText: 'e.g., 500',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter dosage';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                                      child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                      ),
                    items: _units.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedUnit = value!);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Form
            DropdownButtonFormField<String>(
              value: _selectedForm,
              decoration: const InputDecoration(
                labelText: 'Form',
              ),
              items: _forms.map((form) {
                return DropdownMenuItem(
                  value: form,
                  child: Text(form.capitalize()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedForm = value!);
              },
            ),
            const SizedBox(height: 16),

            // Quantity
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Total Quantity',
                hintText: 'e.g., 30',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter quantity';
                }
                final quantity = int.tryParse(value);
                if (quantity == null || quantity <= 0) {
                  return 'Please enter a valid positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Refill Threshold
            TextFormField(
              controller: _refillThresholdController,
              decoration: const InputDecoration(
                labelText: 'Refill Threshold',
                hintText: 'e.g., 5 (refill when this many remain)',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter refill threshold';
                }
                final threshold = int.tryParse(value);
                if (threshold == null || threshold < 0) {
                  return 'Please enter a valid non-negative number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Instructions
            TextFormField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                labelText: 'Instructions (Optional)',
                hintText: 'e.g., Take with food, Avoid alcohol',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Alarm Settings Section
            _buildAlarmSection(),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveMedication,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Medication'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
