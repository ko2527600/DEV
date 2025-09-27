import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/recurring_appointment_service.dart';
import '../../services/availability_service.dart';
import '../../utils/app_theme.dart';
import '../../models/recurring_appointment_model.dart';

class CreateRecurringAppointmentScreen extends StatefulWidget {
  const CreateRecurringAppointmentScreen({super.key});

  @override
  State<CreateRecurringAppointmentScreen> createState() => _CreateRecurringAppointmentScreenState();
}

class _CreateRecurringAppointmentScreenState extends State<CreateRecurringAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  String _selectedSpecialization = 'General Practice';
  String? _selectedDoctorId;
  String? _selectedDoctorName;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;
  RecurrenceType _recurrenceType = RecurrenceType.weekly;
  int _recurrenceInterval = 1;
  List<int> _selectedDaysOfWeek = [];
  RecurrenceEndType _endType = RecurrenceEndType.never;
  int? _maxOccurrences;
  DateTime? _endDate;
  String _reason = '';

  // UI state
  List<Map<String, dynamic>> _availableDoctors = [];
  List<String> _availableTimeSlots = [];
  bool _isLoading = false;

  final List<String> _specializations = [
    'General Practice',
    'Cardiology',
    'Dermatology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'Psychiatry',
    'Radiology',
  ];

  final List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadAvailableDoctors();
  }

  Future<void> _loadAvailableDoctors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final availabilityService = context.read<AvailabilityService>();
      final doctors = await availabilityService.getAvailableDoctors(
        _selectedSpecialization,
        _startDate,
      );

      setState(() {
        _availableDoctors = doctors;
        _selectedDoctorId = null;
        _selectedDoctorName = null;
        _selectedTimeSlot = null;
        _availableTimeSlots = [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading doctors: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTimeSlots(String doctorId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final availabilityService = context.read<AvailabilityService>();
      final timeSlots = await availabilityService.getAvailableTimeSlots(
        doctorId,
        _startDate,
      );

      setState(() {
        _availableTimeSlots = timeSlots;
        _selectedTimeSlot = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading time slots: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createRecurringAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDoctorId == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a doctor and time slot'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final recurringService = context.read<RecurringAppointmentService>();
      
      final recurringAppointment = RecurringAppointment(
        id: '',
        patientId: 'current_user_id', // Replace with actual user ID
        doctorId: _selectedDoctorId!,
        doctorName: _selectedDoctorName!,
        specialization: _selectedSpecialization,
        startDate: _startDate,
        timeSlot: _selectedTimeSlot!,
        recurrenceType: _recurrenceType,
        recurrenceInterval: _recurrenceInterval,
        daysOfWeek: _selectedDaysOfWeek,
        endType: _endType,
        maxOccurrences: _maxOccurrences,
        endDate: _endDate,
        reason: _reason.isNotEmpty ? _reason : null,
        createdAt: DateTime.now(),
      );

      await recurringService.createRecurringAppointment(recurringAppointment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recurring appointment created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating recurring appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Recurring Appointment'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    Card(
                      color: Colors.blue.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Set up a recurring appointment pattern. Individual appointments will be automatically created based on your schedule.',
                                style: TextStyle(color: Colors.blue[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Specialization & Doctor Selection
                    _buildDoctorSelectionSection(),
                    const SizedBox(height: 24),

                    // Start Date & Time
                    _buildDateTimeSection(),
                    const SizedBox(height: 24),

                    // Recurrence Pattern
                    _buildRecurrenceSection(),
                    const SizedBox(height: 24),

                    // End Condition
                    _buildEndConditionSection(),
                    const SizedBox(height: 24),

                    // Reason (Optional)
                    _buildReasonSection(),
                    const SizedBox(height: 24),

                    // Preview
                    _buildPreviewSection(),
                  ],
                ),
              ),
            ),

            // Create Button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createRecurringAppointment,
                  child: const Text('Create Recurring Appointment'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorSelectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doctor Selection',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Specialization
            DropdownButtonFormField<String>(
              value: _selectedSpecialization,
              decoration: const InputDecoration(
                labelText: 'Specialization',
                border: OutlineInputBorder(),
              ),
              items: _specializations.map((spec) =>
                DropdownMenuItem(value: spec, child: Text(spec))
              ).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSpecialization = value;
                    _selectedDoctorId = null;
                    _selectedDoctorName = null;
                  });
                  _loadAvailableDoctors();
                }
              },
            ),
            const SizedBox(height: 16),

            // Doctor Selection
            if (_availableDoctors.isNotEmpty) ...[
              const Text('Select Doctor:'),
              const SizedBox(height: 8),
              ..._availableDoctors.map((doctor) => _buildDoctorCard(doctor)),
            ] else if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('No doctors available for selected specialization'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final isSelected = _selectedDoctorId == doctor['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDoctorId = doctor['id'];
            _selectedDoctorName = doctor['name'];
          });
          _loadTimeSlots(doctor['id']);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  doctor['name'][0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '⭐ ${doctor['rating']?.toStringAsFixed(1) ?? '0.0'} • ${doctor['availableSlots']?.length ?? 0} slots',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppTheme.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start Date & Time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Calendar
            TableCalendar<Event>(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _startDate,
              selectedDayPredicate: (day) => isSameDay(_startDate, day),
              calendarFormat: CalendarFormat.month,
              onDaySelected: (selectedDay, focusedDay) {
                if (!selectedDay.isBefore(DateTime.now())) {
                  setState(() {
                    _startDate = selectedDay;
                    _selectedTimeSlot = null;
                  });
                  if (_selectedDoctorId != null) {
                    _loadTimeSlots(_selectedDoctorId!);
                  }
                }
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Time Slots
            if (_selectedDoctorId != null) ...[
              const Text('Available Time Slots:'),
              const SizedBox(height: 8),
              if (_availableTimeSlots.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableTimeSlots.map((slot) =>
                    _buildTimeSlotChip(slot)
                  ).toList(),
                )
              else
                const Text('No available time slots for this date'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotChip(String timeSlot) {
    final isSelected = _selectedTimeSlot == timeSlot;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTimeSlot = timeSlot;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          timeSlot,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRecurrenceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recurrence Pattern',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Recurrence Type
            DropdownButtonFormField<RecurrenceType>(
              value: _recurrenceType,
              decoration: const InputDecoration(
                labelText: 'Repeat',
                border: OutlineInputBorder(),
              ),
              items: RecurrenceType.values.map((type) =>
                DropdownMenuItem(
                  value: type,
                  child: Text(_getRecurrenceTypeLabel(type)),
                )
              ).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _recurrenceType = value;
                    _selectedDaysOfWeek = [];
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Interval
            if (_recurrenceType != RecurrenceType.weekly || _selectedDaysOfWeek.isEmpty) ...[
              TextFormField(
                initialValue: _recurrenceInterval.toString(),
                decoration: InputDecoration(
                  labelText: 'Every ${_getIntervalLabel()}',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final interval = int.tryParse(value);
                  if (interval == null || interval < 1) return 'Must be at least 1';
                  return null;
                },
                onChanged: (value) {
                  final interval = int.tryParse(value);
                  if (interval != null) {
                    _recurrenceInterval = interval;
                  }
                },
              ),
              const SizedBox(height: 16),
            ],

            // Days of Week (for weekly)
            if (_recurrenceType == RecurrenceType.weekly) ...[
              const Text('Select days of the week:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  final dayIndex = index + 1;
                  final isSelected = _selectedDaysOfWeek.contains(dayIndex);
                  
                  return FilterChip(
                    label: Text(_dayNames[index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDaysOfWeek.add(dayIndex);
                        } else {
                          _selectedDaysOfWeek.remove(dayIndex);
                        }
                        _selectedDaysOfWeek.sort();
                      });
                    },
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEndConditionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'End Condition',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // End Type
            DropdownButtonFormField<RecurrenceEndType>(
              value: _endType,
              decoration: const InputDecoration(
                labelText: 'Ends',
                border: OutlineInputBorder(),
              ),
              items: RecurrenceEndType.values.map((type) =>
                DropdownMenuItem(
                  value: type,
                  child: Text(_getEndTypeLabel(type)),
                )
              ).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _endType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Additional fields based on end type
            if (_endType == RecurrenceEndType.afterOccurrences) ...[
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Number of appointments',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final count = int.tryParse(value);
                  if (count == null || count < 1) return 'Must be at least 1';
                  return null;
                },
                onChanged: (value) {
                  _maxOccurrences = int.tryParse(value);
                },
              ),
            ] else if (_endType == RecurrenceEndType.onDate) ...[
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (date != null) {
                    setState(() {
                      _endDate = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Text(
                        _endDate != null
                            ? 'End date: ${_endDate!.toString().split(' ')[0]}'
                            : 'Select end date',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReasonSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reason (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                hintText: 'e.g., Regular check-up, Physical therapy, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) {
                _reason = value;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    if (_selectedDoctorName == null || _selectedTimeSlot == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Doctor: $_selectedDoctorName'),
            Text('Specialization: $_selectedSpecialization'),
            Text('Start: ${_startDate.toString().split(' ')[0]} at $_selectedTimeSlot'),
            Text('Pattern: ${_getRecurrenceDescription()}'),
            Text('End: ${_getEndDescription()}'),
            if (_reason.isNotEmpty) Text('Reason: $_reason'),
          ],
        ),
      ),
    );
  }

  String _getRecurrenceTypeLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.biweekly:
        return 'Every 2 weeks';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.custom:
        return 'Custom';
    }
  }

  String _getEndTypeLabel(RecurrenceEndType type) {
    switch (type) {
      case RecurrenceEndType.never:
        return 'Never';
      case RecurrenceEndType.afterOccurrences:
        return 'After number of appointments';
      case RecurrenceEndType.onDate:
        return 'On specific date';
    }
  }

  String _getIntervalLabel() {
    switch (_recurrenceType) {
      case RecurrenceType.daily:
        return 'day(s)';
      case RecurrenceType.weekly:
        return 'week(s)';
      case RecurrenceType.biweekly:
        return '2 week period(s)';
      case RecurrenceType.monthly:
        return 'month(s)';
      case RecurrenceType.custom:
        return 'interval(s)';
    }
  }

  String _getRecurrenceDescription() {
    switch (_recurrenceType) {
      case RecurrenceType.daily:
        return _recurrenceInterval == 1 ? 'Daily' : 'Every $_recurrenceInterval days';
      case RecurrenceType.weekly:
        if (_selectedDaysOfWeek.isNotEmpty) {
          final dayNames = _selectedDaysOfWeek.map((day) => _dayNames[day - 1]).join(', ');
          return 'Weekly on $dayNames';
        }
        return _recurrenceInterval == 1 ? 'Weekly' : 'Every $_recurrenceInterval weeks';
      case RecurrenceType.biweekly:
        return _recurrenceInterval == 1 ? 'Every 2 weeks' : 'Every ${_recurrenceInterval * 2} weeks';
      case RecurrenceType.monthly:
        return _recurrenceInterval == 1 ? 'Monthly' : 'Every $_recurrenceInterval months';
      case RecurrenceType.custom:
        return 'Custom pattern';
    }
  }

  String _getEndDescription() {
    switch (_endType) {
      case RecurrenceEndType.never:
        return 'Never ends';
      case RecurrenceEndType.afterOccurrences:
        return 'After $_maxOccurrences appointments';
      case RecurrenceEndType.onDate:
        return _endDate != null ? 'Ends on ${_endDate!.toString().split(' ')[0]}' : 'No end date set';
    }
  }
}

class Event {
  final String title;
  Event(this.title);
}

