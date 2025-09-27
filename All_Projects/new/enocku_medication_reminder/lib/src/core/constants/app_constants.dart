class AppConstants {
  static const String appName = 'Enocku Medication Reminder';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String databaseName = 'medication_reminder.db';
  static const int databaseVersion = 1;
  
  // Notifications
  static const String notificationChannelId = 'medication_reminders';
  static const String notificationChannelName = 'Medication Reminders';
  static const String notificationChannelDescription = 'Notifications for medication reminders';
  
  // Scheduling
  static const String androidAlarmTag = 'medication_alarm';
  static const String iosBackgroundTaskId = 'com.enocku.medication.reminder';
  
  // Dose frequencies
  static const List<String> frequencies = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Four times daily',
    'Every 4 hours',
    'Every 6 hours',
    'Every 8 hours',
    'Every 12 hours',
    'As needed',
  ];
  
  // Medication types
  static const List<String> medicationTypes = [
    'Tablet',
    'Capsule',
    'Liquid',
    'Injection',
    'Inhaler',
    'Cream',
    'Drops',
    'Patch',
    'Other',
  ];
}
