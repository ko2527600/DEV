import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/availability_service.dart';
import '../../utils/app_theme.dart';
import '../../models/availability_model.dart';

class AvailabilityManagementScreen extends StatefulWidget {
  const AvailabilityManagementScreen({super.key});

  @override
  State<AvailabilityManagementScreen> createState() => _AvailabilityManagementScreenState();
}

class _AvailabilityManagementScreenState extends State<AvailabilityManagementScreen> {
  final Map<String, DoctorAvailability> _weeklySchedule = {};
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _daysOfWeek = [
    'monday', 'tuesday', 'wednesday', 'thursday', 
    'friday', 'saturday', 'sunday'
  ];

  final List<String> _timeOptions = [
    '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
    '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
    '18:00', '19:00', '20:00', '21:00', '22:00'
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentAvailability();
  }

  Future<void> _loadCurrentAvailability() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final availabilityService = context.read<AvailabilityService>();
      const currentDoctorId = 'current_doctor_id'; // Replace with actual doctor ID
      
      final availabilities = await availabilityService.getAllDoctorAvailability(currentDoctorId);
      
      // Initialize default schedule
      for (String day in _daysOfWeek) {
        _weeklySchedule[day] = DoctorAvailability(
          id: '${currentDoctorId}_$day',
          doctorId: currentDoctorId,
          dayOfWeek: day,
          startTime: '09:00',
          endTime: '17:00',
          breakTimes: ['12:00-13:00'],
          slotDuration: 30,
          isActive: day != 'saturday' && day != 'sunday', // Default: weekdays only
        );
      }

      // Override with existing data
      for (final availability in availabilities) {
        _weeklySchedule[availability.dayOfWeek] = availability;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading availability: $e'),
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

  Future<void> _saveAvailability() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final availabilityService = context.read<AvailabilityService>();
      await availabilityService.updateWeeklyAvailability('current_doctor_id', _weeklySchedule);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving availability: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Availability'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Set your weekly availability. Patients will only see available time slots.',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),

                // Weekly Schedule
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _daysOfWeek.length,
                    itemBuilder: (context, index) {
                      final day = _daysOfWeek[index];
                      return _buildDayCard(day);
                    },
                  ),
                ),

                // Save Button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAvailability,
                      child: _isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Saving...'),
                              ],
                            )
                          : const Text('Save Availability'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDayCard(String day) {
    final availability = _weeklySchedule[day]!;
    final dayName = day[0].toUpperCase() + day.substring(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: availability.isActive,
                  onChanged: (value) {
                    setState(() {
                      _weeklySchedule[day] = DoctorAvailability(
                        id: availability.id,
                        doctorId: availability.doctorId,
                        dayOfWeek: availability.dayOfWeek,
                        startTime: availability.startTime,
                        endTime: availability.endTime,
                        breakTimes: availability.breakTimes,
                        slotDuration: availability.slotDuration,
                        isActive: value,
                      );
                    });
                  },
                ),
              ],
            ),

            if (availability.isActive) ...[
              const SizedBox(height: 16),

              // Working Hours
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Time'),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: availability.startTime,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: _timeOptions.map((time) => 
                            DropdownMenuItem(value: time, child: Text(time))
                          ).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _updateAvailability(day, startTime: value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Time'),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: availability.endTime,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: _timeOptions.map((time) => 
                            DropdownMenuItem(value: time, child: Text(time))
                          ).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _updateAvailability(day, endTime: value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Slot Duration
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Appointment Duration'),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<int>(
                          value: availability.slotDuration,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 15, child: Text('15 minutes')),
                            DropdownMenuItem(value: 30, child: Text('30 minutes')),
                            DropdownMenuItem(value: 45, child: Text('45 minutes')),
                            DropdownMenuItem(value: 60, child: Text('1 hour')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _updateAvailability(day, slotDuration: value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Break Times
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Break Times'),
                      TextButton.icon(
                        onPressed: () => _addBreakTime(day),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Break'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...availability.breakTimes.map((breakTime) => 
                    _buildBreakTimeRow(day, breakTime)
                  ),
                  if (availability.breakTimes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'No break times set',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Preview Time Slots
              ExpansionTile(
                title: const Text('Preview Time Slots'),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availability.generateTimeSlots().map((slot) =>
                        Chip(
                          label: Text(slot),
                          backgroundColor: Colors.green.withOpacity(0.1),
                        )
                      ).toList(),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.block, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Not available on this day',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreakTimeRow(String day, String breakTime) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.coffee, color: Colors.brown[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(breakTime),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () => _removeBreakTime(day, breakTime),
          ),
        ],
      ),
    );
  }

  void _updateAvailability(String day, {
    String? startTime,
    String? endTime,
    int? slotDuration,
  }) {
    final current = _weeklySchedule[day]!;
    setState(() {
      _weeklySchedule[day] = DoctorAvailability(
        id: current.id,
        doctorId: current.doctorId,
        dayOfWeek: current.dayOfWeek,
        startTime: startTime ?? current.startTime,
        endTime: endTime ?? current.endTime,
        breakTimes: current.breakTimes,
        slotDuration: slotDuration ?? current.slotDuration,
        isActive: current.isActive,
      );
    });
  }

  void _addBreakTime(String day) {
    showDialog(
      context: context,
      builder: (context) => _BreakTimeDialog(
        onBreakTimeAdded: (breakTime) {
          final current = _weeklySchedule[day]!;
          setState(() {
            _weeklySchedule[day] = DoctorAvailability(
              id: current.id,
              doctorId: current.doctorId,
              dayOfWeek: current.dayOfWeek,
              startTime: current.startTime,
              endTime: current.endTime,
              breakTimes: [...current.breakTimes, breakTime],
              slotDuration: current.slotDuration,
              isActive: current.isActive,
            );
          });
        },
      ),
    );
  }

  void _removeBreakTime(String day, String breakTime) {
    final current = _weeklySchedule[day]!;
    setState(() {
      _weeklySchedule[day] = DoctorAvailability(
        id: current.id,
        doctorId: current.doctorId,
        dayOfWeek: current.dayOfWeek,
        startTime: current.startTime,
        endTime: current.endTime,
        breakTimes: current.breakTimes.where((bt) => bt != breakTime).toList(),
        slotDuration: current.slotDuration,
        isActive: current.isActive,
      );
    });
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Availability Management'),
        content: const Text(
          'Set your weekly availability to let patients know when you\'re available for appointments.\n\n'
          '• Toggle days on/off\n'
          '• Set working hours\n'
          '• Add break times\n'
          '• Choose appointment duration\n'
          '• Preview available time slots\n\n'
          'Patients will only see and book available time slots.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _BreakTimeDialog extends StatefulWidget {
  final Function(String) onBreakTimeAdded;

  const _BreakTimeDialog({required this.onBreakTimeAdded});

  @override
  State<_BreakTimeDialog> createState() => _BreakTimeDialogState();
}

class _BreakTimeDialogState extends State<_BreakTimeDialog> {
  String _startTime = '12:00';
  String _endTime = '13:00';

  final List<String> _timeOptions = [
    '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
    '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
    '18:00', '19:00', '20:00', '21:00', '22:00'
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Break Time'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Start Time'),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _startTime,
                      items: _timeOptions.map((time) => 
                        DropdownMenuItem(value: time, child: Text(time))
                      ).toList(),
                      onChanged: (value) {
                        setState(() {
                          _startTime = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('End Time'),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _endTime,
                      items: _timeOptions.map((time) => 
                        DropdownMenuItem(value: time, child: Text(time))
                      ).toList(),
                      onChanged: (value) {
                        setState(() {
                          _endTime = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onBreakTimeAdded('$_startTime-$_endTime');
            Navigator.of(context).pop();
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

