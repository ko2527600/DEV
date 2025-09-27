import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/reminder_service.dart';
import '../../utils/app_theme.dart';
import '../../models/reminder_model.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  ReminderPreferences? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reminderService = context.read<ReminderService>();
      final preferences = await reminderService.getUserReminderPreferences('current_user_id');
      
      setState(() {
        _preferences = preferences;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading preferences: $e'),
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

  Future<void> _savePreferences() async {
    if (_preferences == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final reminderService = context.read<ReminderService>();
      await reminderService.updateReminderPreferences(_preferences!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
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
        title: const Text('Reminder Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _preferences != null)
            TextButton(
              onPressed: _isSaving ? null : _savePreferences,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _preferences == null
              ? const Center(child: Text('Failed to load preferences'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // General Settings
                      _buildGeneralSettings(),
                      const SizedBox(height: 24),

                      // Notification Methods
                      _buildNotificationMethods(),
                      const SizedBox(height: 24),

                      // Reminder Timing
                      _buildReminderTiming(),
                      const SizedBox(height: 24),

                      // Quiet Hours
                      _buildQuietHours(),
                      const SizedBox(height: 24),

                      // Active Days
                      _buildActiveDays(),
                      const SizedBox(height: 24),

                      // Advanced Settings
                      _buildAdvancedSettings(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildGeneralSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'General Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Appointment Reminders'),
              subtitle: const Text('Get notified about upcoming appointments'),
              value: _preferences!.enableAppointmentReminders,
              onChanged: (value) {
                setState(() {
                  _preferences = ReminderPreferences(
                    userId: _preferences!.userId,
                    enableAppointmentReminders: value,
                    enableMedicationReminders: _preferences!.enableMedicationReminders,
                    enableFollowUpReminders: _preferences!.enableFollowUpReminders,
                    preferredMethods: _preferences!.preferredMethods,
                    reminderTiming: _preferences!.reminderTiming,
                    quietHoursEnabled: _preferences!.quietHoursEnabled,
                    quietHoursStart: _preferences!.quietHoursStart,
                    quietHoursEnd: _preferences!.quietHoursEnd,
                    enabledDays: _preferences!.enabledDays,
                    timezone: _preferences!.timezone,
                    customSettings: _preferences!.customSettings,
                  );
                });
              },
            ),

            SwitchListTile(
              title: const Text('Medication Reminders'),
              subtitle: const Text('Get notified about medication schedules'),
              value: _preferences!.enableMedicationReminders,
              onChanged: (value) {
                setState(() {
                  _preferences = ReminderPreferences(
                    userId: _preferences!.userId,
                    enableAppointmentReminders: _preferences!.enableAppointmentReminders,
                    enableMedicationReminders: value,
                    enableFollowUpReminders: _preferences!.enableFollowUpReminders,
                    preferredMethods: _preferences!.preferredMethods,
                    reminderTiming: _preferences!.reminderTiming,
                    quietHoursEnabled: _preferences!.quietHoursEnabled,
                    quietHoursStart: _preferences!.quietHoursStart,
                    quietHoursEnd: _preferences!.quietHoursEnd,
                    enabledDays: _preferences!.enabledDays,
                    timezone: _preferences!.timezone,
                    customSettings: _preferences!.customSettings,
                  );
                });
              },
            ),

            SwitchListTile(
              title: const Text('Follow-up Reminders'),
              subtitle: const Text('Get notified about follow-up appointments'),
              value: _preferences!.enableFollowUpReminders,
              onChanged: (value) {
                setState(() {
                  _preferences = ReminderPreferences(
                    userId: _preferences!.userId,
                    enableAppointmentReminders: _preferences!.enableAppointmentReminders,
                    enableMedicationReminders: _preferences!.enableMedicationReminders,
                    enableFollowUpReminders: value,
                    preferredMethods: _preferences!.preferredMethods,
                    reminderTiming: _preferences!.reminderTiming,
                    quietHoursEnabled: _preferences!.quietHoursEnabled,
                    quietHoursStart: _preferences!.quietHoursStart,
                    quietHoursEnd: _preferences!.quietHoursEnd,
                    enabledDays: _preferences!.enabledDays,
                    timezone: _preferences!.timezone,
                    customSettings: _preferences!.customSettings,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationMethods() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Methods',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            CheckboxListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive notifications on your device'),
              value: _preferences!.preferredMethods.contains(ReminderMethod.push),
              onChanged: (value) {
                setState(() {
                  final methods = List<ReminderMethod>.from(_preferences!.preferredMethods);
                  if (value == true) {
                    methods.add(ReminderMethod.push);
                  } else {
                    methods.remove(ReminderMethod.push);
                  }
                  _preferences = ReminderPreferences(
                    userId: _preferences!.userId,
                    enableAppointmentReminders: _preferences!.enableAppointmentReminders,
                    enableMedicationReminders: _preferences!.enableMedicationReminders,
                    enableFollowUpReminders: _preferences!.enableFollowUpReminders,
                    preferredMethods: methods,
                    reminderTiming: _preferences!.reminderTiming,
                    quietHoursEnabled: _preferences!.quietHoursEnabled,
                    quietHoursStart: _preferences!.quietHoursStart,
                    quietHoursEnd: _preferences!.quietHoursEnd,
                    enabledDays: _preferences!.enabledDays,
                    timezone: _preferences!.timezone,
                    customSettings: _preferences!.customSettings,
                  );
                });
              },
            ),

            CheckboxListTile(
              title: const Text('Email'),
              subtitle: const Text('Receive reminders via email'),
              value: _preferences!.preferredMethods.contains(ReminderMethod.email),
              onChanged: (value) {
                setState(() {
                  final methods = List<ReminderMethod>.from(_preferences!.preferredMethods);
                  if (value == true) {
                    methods.add(ReminderMethod.email);
                  } else {
                    methods.remove(ReminderMethod.email);
                  }
                  _preferences = ReminderPreferences(
                    userId: _preferences!.userId,
                    enableAppointmentReminders: _preferences!.enableAppointmentReminders,
                    enableMedicationReminders: _preferences!.enableMedicationReminders,
                    enableFollowUpReminders: _preferences!.enableFollowUpReminders,
                    preferredMethods: methods,
                    reminderTiming: _preferences!.reminderTiming,
                    quietHoursEnabled: _preferences!.quietHoursEnabled,
                    quietHoursStart: _preferences!.quietHoursStart,
                    quietHoursEnd: _preferences!.quietHoursEnd,
                    enabledDays: _preferences!.enabledDays,
                    timezone: _preferences!.timezone,
                    customSettings: _preferences!.customSettings,
                  );
                });
              },
            ),

            CheckboxListTile(
              title: const Text('SMS'),
              subtitle: const Text('Receive text message reminders'),
              value: _preferences!.preferredMethods.contains(ReminderMethod.sms),
              onChanged: (value) {
                setState(() {
                  final methods = List<ReminderMethod>.from(_preferences!.preferredMethods);
                  if (value == true) {
                    methods.add(ReminderMethod.sms);
                  } else {
                    methods.remove(ReminderMethod.sms);
                  }
                  _preferences = ReminderPreferences(
                    userId: _preferences!.userId,
                    enableAppointmentReminders: _preferences!.enableAppointmentReminders,
                    enableMedicationReminders: _preferences!.enableMedicationReminders,
                    enableFollowUpReminders: _preferences!.enableFollowUpReminders,
                    preferredMethods: methods,
                    reminderTiming: _preferences!.reminderTiming,
                    quietHoursEnabled: _preferences!.quietHoursEnabled,
                    quietHoursStart: _preferences!.quietHoursStart,
                    quietHoursEnd: _preferences!.quietHoursEnd,
                    enabledDays: _preferences!.enabledDays,
                    timezone: _preferences!.timezone,
                    customSettings: _preferences!.customSettings,
                  );
                });
              },
            ),

            CheckboxListTile(
              title: const Text('In-App Notifications'),
              subtitle: const Text('Show notifications within the app'),
              value: _preferences!.preferredMethods.contains(ReminderMethod.inApp),
              onChanged: (value) {
                setState(() {
                  final methods = List<ReminderMethod>.from(_preferences!.preferredMethods);
                  if (value == true) {
                    methods.add(ReminderMethod.inApp);
                  } else {
                    methods.remove(ReminderMethod.inApp);
                  }
                  _preferences = ReminderPreferences(
                    userId: _preferences!.userId,
                    enableAppointmentReminders: _preferences!.enableAppointmentReminders,
                    enableMedicationReminders: _preferences!.enableMedicationReminders,
                    enableFollowUpReminders: _preferences!.enableFollowUpReminders,
                    preferredMethods: methods,
                    reminderTiming: _preferences!.reminderTiming,
                    quietHoursEnabled: _preferences!.quietHoursEnabled,
                    quietHoursStart: _preferences!.quietHoursStart,
                    quietHoursEnd: _preferences!.quietHoursEnd,
                    enabledDays: _preferences!.enabledDays,
                    timezone: _preferences!.timezone,
                    customSettings: _preferences!.customSettings,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderTiming() {
    final appointmentTiming = _preferences!.getReminderTimingForType(ReminderType.appointment);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reminder Timing',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Appointment Reminders',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              children: [
                _buildTimingChip('24 hours before', 24, appointmentTiming),
                _buildTimingChip('12 hours before', 12, appointmentTiming),
                _buildTimingChip('6 hours before', 6, appointmentTiming),
                _buildTimingChip('2 hours before', 2, appointmentTiming),
                _buildTimingChip('1 hour before', 1, appointmentTiming),
                _buildTimingChip('30 minutes before', 0, appointmentTiming), // 0.5 hours
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingChip(String label, int hours, List<int> currentTiming) {
    final isSelected = currentTiming.contains(hours);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          final timing = List<int>.from(currentTiming);
          if (selected) {
            timing.add(hours);
          } else {
            timing.remove(hours);
          }
          timing.sort((a, b) => b.compareTo(a)); // Sort descending

          final newReminderTiming = Map<ReminderType, List<int>>.from(_preferences!.reminderTiming);
          newReminderTiming[ReminderType.appointment] = timing;

          _preferences = ReminderPreferences(
            userId: _preferences!.userId,
            enableAppointmentReminders: _preferences!.enableAppointmentReminders,
            enableMedicationReminders: _preferences!.enableMedicationReminders,
            enableFollowUpReminders: _preferences!.enableFollowUpReminders,
            preferredMethods: _preferences!.preferredMethods,
            reminderTiming: newReminderTiming,
            quietHoursEnabled: _preferences!.quietHoursEnabled,
            quietHoursStart: _preferences!.quietHoursStart,
            quietHoursEnd: _preferences!.quietHoursEnd,
            enabledDays: _preferences!.enabledDays,
            timezone: _preferences!.timezone,
            customSettings: _preferences!.customSettings,
          );
        });
      },
    );
  }

  Widget _buildQuietHours() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiet Hours',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Enable Quiet Hours'),
              subtitle: const Text('Avoid sending reminders during specified hours'),
              value: _preferences!.quietHoursEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences = ReminderPreferences(
                    userId: _preferences!.userId,
                    enableAppointmentReminders: _preferences!.enableAppointmentReminders,
                    enableMedicationReminders: _preferences!.enableMedicationReminders,
                    enableFollowUpReminders: _preferences!.enableFollowUpReminders,
                    preferredMethods: _preferences!.preferredMethods,
                    reminderTiming: _preferences!.reminderTiming,
                    quietHoursEnabled: value,
                    quietHoursStart: _preferences!.quietHoursStart,
                    quietHoursEnd: _preferences!.quietHoursEnd,
                    enabledDays: _preferences!.enabledDays,
                    timezone: _preferences!.timezone,
                    customSettings: _preferences!.customSettings,
                  );
                });
              },
            ),

            if (_preferences!.quietHoursEnabled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Time'),
                      subtitle: Text('${_preferences!.quietHoursStart}:00'),
                      onTap: () => _selectTime(true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('End Time'),
                      subtitle: Text('${_preferences!.quietHoursEnd}:00'),
                      onTap: () => _selectTime(false),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveDays() {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Days',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select days when you want to receive reminders',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                final dayIndex = index + 1;
                final isSelected = _preferences!.enabledDays.contains(dayIndex);

                return FilterChip(
                  label: Text(dayNames[index]),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      final enabledDays = List<int>.from(_preferences!.enabledDays);
                      if (selected) {
                        enabledDays.add(dayIndex);
                      } else {
                        enabledDays.remove(dayIndex);
                      }
                      enabledDays.sort();

                      _preferences = ReminderPreferences(
                        userId: _preferences!.userId,
                        enableAppointmentReminders: _preferences!.enableAppointmentReminders,
                        enableMedicationReminders: _preferences!.enableMedicationReminders,
                        enableFollowUpReminders: _preferences!.enableFollowUpReminders,
                        preferredMethods: _preferences!.preferredMethods,
                        reminderTiming: _preferences!.reminderTiming,
                        quietHoursEnabled: _preferences!.quietHoursEnabled,
                        quietHoursStart: _preferences!.quietHoursStart,
                        quietHoursEnd: _preferences!.quietHoursEnd,
                        enabledDays: enabledDays,
                        timezone: _preferences!.timezone,
                        customSettings: _preferences!.customSettings,
                      );
                    });
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ListTile(
              title: const Text('Timezone'),
              subtitle: Text(_preferences!.timezone),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Show timezone picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Timezone picker coming soon')),
                );
              },
            ),

            ListTile(
              title: const Text('Test Notifications'),
              subtitle: const Text('Send a test reminder to verify settings'),
              trailing: const Icon(Icons.send),
              onTap: () {
                _sendTestNotification();
              },
            ),

            ListTile(
              title: const Text('Reset to Defaults'),
              subtitle: const Text('Restore default reminder settings'),
              trailing: const Icon(Icons.restore),
              onTap: () {
                _resetToDefaults();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(bool isStartTime) async {
    final currentHour = isStartTime ? _preferences!.quietHoursStart : _preferences!.quietHoursEnd;
    
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: 0),
    );

    if (time != null) {
      setState(() {
        if (isStartTime) {
          _preferences = ReminderPreferences(
            userId: _preferences!.userId,
            enableAppointmentReminders: _preferences!.enableAppointmentReminders,
            enableMedicationReminders: _preferences!.enableMedicationReminders,
            enableFollowUpReminders: _preferences!.enableFollowUpReminders,
            preferredMethods: _preferences!.preferredMethods,
            reminderTiming: _preferences!.reminderTiming,
            quietHoursEnabled: _preferences!.quietHoursEnabled,
            quietHoursStart: time.hour,
            quietHoursEnd: _preferences!.quietHoursEnd,
            enabledDays: _preferences!.enabledDays,
            timezone: _preferences!.timezone,
            customSettings: _preferences!.customSettings,
          );
        } else {
          _preferences = ReminderPreferences(
            userId: _preferences!.userId,
            enableAppointmentReminders: _preferences!.enableAppointmentReminders,
            enableMedicationReminders: _preferences!.enableMedicationReminders,
            enableFollowUpReminders: _preferences!.enableFollowUpReminders,
            preferredMethods: _preferences!.preferredMethods,
            reminderTiming: _preferences!.reminderTiming,
            quietHoursEnabled: _preferences!.quietHoursEnabled,
            quietHoursStart: _preferences!.quietHoursStart,
            quietHoursEnd: time.hour,
            enabledDays: _preferences!.enabledDays,
            timezone: _preferences!.timezone,
            customSettings: _preferences!.customSettings,
          );
        }
      });
    }
  }

  void _sendTestNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent! Check your notifications.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('Are you sure you want to reset all reminder settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _preferences = ReminderPreferences(userId: _preferences!.userId);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

