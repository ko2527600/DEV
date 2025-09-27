import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final Map<String, Timer> _activeTimers = {};
  final Map<String, int> _activeNotificationIds = {};

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Initialize notifications
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions - handled automatically by the plugin
    // The plugin will request permissions when needed during initialization
    // No need to manually call requestPermission() in newer versions

    _isInitialized = true;
  }

  Future<void> scheduleMedicationReminder({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required TimeOfDay time,
    required List<int> daysOfWeek, // 1 = Monday, 7 = Sunday
    required bool soundEnabled,
    required bool vibrationEnabled,
  }) async {
    await initialize();

    // Cancel existing reminder for this medication
    await cancelMedicationReminder(medicationId);

    // Schedule for each day of the week
    for (int dayOfWeek in daysOfWeek) {
      await _scheduleDailyReminder(
        medicationId: medicationId,
        medicationName: medicationName,
        dosage: dosage,
        time: time,
        dayOfWeek: dayOfWeek,
        soundEnabled: soundEnabled,
        vibrationEnabled: vibrationEnabled,
      );
    }

    // Also schedule a timer for immediate testing (if today matches)
    _scheduleImmediateTimer(
      medicationId: medicationId,
      medicationName: medicationName,
      dosage: dosage,
      time: time,
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
    );
  }

  Future<void> _scheduleDailyReminder({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required TimeOfDay time,
    required int dayOfWeek,
    required bool soundEnabled,
    required bool vibrationEnabled,
  }) async {
    final now = DateTime.now();
    final scheduledDate = _nextInstanceOfDayAndTime(dayOfWeek, time);
    
    if (scheduledDate.isBefore(now)) {
      // Schedule for next week
      final nextWeek = scheduledDate.add(const Duration(days: 7));
      await _scheduleNotification(
        id: '${medicationId}_${dayOfWeek}_${nextWeek.millisecondsSinceEpoch}',
        title: 'Medication Reminder',
        body: 'Time to take $medicationName - $dosage',
        scheduledDate: nextWeek,
        soundEnabled: soundEnabled,
        vibrationEnabled: vibrationEnabled,
        payload: 'medication_reminder:$medicationId',
      );
    } else {
      await _scheduleNotification(
        id: '${medicationId}_${dayOfWeek}_${scheduledDate.millisecondsSinceEpoch}',
        title: 'Medication Reminder',
        body: 'Time to take $medicationName - $dosage',
        scheduledDate: scheduledDate,
        soundEnabled: soundEnabled,
        vibrationEnabled: vibrationEnabled,
        payload: 'medication_reminder:$medicationId',
      );
    }
  }

  void _scheduleImmediateTimer({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required TimeOfDay time,
    required bool soundEnabled,
    required bool vibrationEnabled,
  }) {
    // For testing purposes, schedule a reminder in 10 seconds
    final timer = Timer(const Duration(seconds: 10), () {
      _showImmediateReminder(
        medicationId: medicationId,
        medicationName: medicationName,
        dosage: dosage,
        soundEnabled: soundEnabled,
        vibrationEnabled: vibrationEnabled,
      );
    });

    _activeTimers[medicationId] = timer;
  }

  Future<void> _scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required bool soundEnabled,
    required bool vibrationEnabled,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Notifications for medication reminders',
      importance: Importance.high,
      priority: Priority.high,
      sound: soundEnabled ? RawResourceAndroidNotificationSound('notification_sound') : null,
      enableVibration: vibrationEnabled,
      enableLights: true,
      color: Colors.blue,
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: soundEnabled,
      sound: soundEnabled ? 'notification_sound.wav' : null,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Generate a unique notification ID
    final notificationId = id.hashCode.abs() % 2147483647; // Ensure it's within int range
    
    // Store the notification ID for later cancellation
    _activeNotificationIds[id] = notificationId;

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  void _showImmediateReminder({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required bool soundEnabled,
    required bool vibrationEnabled,
  }) {
    // Generate a unique notification ID for immediate reminder
    final notificationId = '${medicationId}_immediate'.hashCode.abs() % 2147483647;
    
    // Show an immediate notification for testing
    _notifications.show(
      notificationId,
      'Medication Reminder',
      'Time to take $medicationName - $dosage',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.high,
          priority: Priority.high,
          sound: soundEnabled ? RawResourceAndroidNotificationSound('notification_sound') : null,
          enableVibration: vibrationEnabled,
          enableLights: true,
          color: Colors.blue,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: soundEnabled,
        ),
      ),
      payload: 'medication_reminder:$medicationId',
    );
  }

  DateTime _nextInstanceOfDayAndTime(int dayOfWeek, TimeOfDay time) {
    final now = DateTime.now();
    final today = now.weekday;
    
    int daysUntilNext = dayOfWeek - today;
    if (daysUntilNext <= 0) {
      daysUntilNext += 7;
    }
    
    final nextDate = DateTime(
      now.year,
      now.month,
      now.day + daysUntilNext,
      time.hour,
      time.minute,
    );
    
    return nextDate;
  }

  Future<void> cancelMedicationReminder(String medicationId) async {
    // Cancel all notifications for this medication
    for (final entry in _activeNotificationIds.entries) {
      if (entry.key.startsWith(medicationId)) {
        await _notifications.cancel(entry.value);
      }
    }
    _activeNotificationIds.removeWhere((key, value) => key.startsWith(medicationId));

    // Cancel active timer
    final timer = _activeTimers[medicationId];
    if (timer != null) {
      timer.cancel();
      _activeTimers.remove(medicationId);
    }
  }

  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
    _activeNotificationIds.clear();
    
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    if (response.payload != null && response.payload!.startsWith('medication_reminder:')) {
      final medicationId = response.payload!.split(':')[1];
      // TODO: Navigate to medication detail or mark as taken
      debugPrint('Notification tapped for medication: $medicationId');
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> testNotification() async {
    await initialize();
    
    await _notifications.show(
      0,
      'Test Notification',
      'This is a test notification for medication reminders',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
