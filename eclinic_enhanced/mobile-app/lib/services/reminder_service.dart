import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/reminder_model.dart';
import '../models/appointment_model.dart';

class ReminderService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Creates reminders for an appointment
  Future<void> createAppointmentReminders(Appointment appointment) async {
    try {
      // Get user's reminder preferences
      final preferences = await getUserReminderPreferences(appointment.patientId);
      
      if (!preferences.enableAppointmentReminders) return;

      final reminderTimes = preferences.getReminderTimingForType(ReminderType.appointment);
      
      for (final hoursBeforeAppointment in reminderTimes) {
        final reminderTime = appointment.appointmentDate.subtract(
          Duration(hours: hoursBeforeAppointment),
        );

        // Don't create reminders for past times
        if (reminderTime.isBefore(DateTime.now())) continue;

        // Check if it's during quiet hours or disabled day
        if (preferences.isQuietTime(reminderTime) || !preferences.isDayEnabled(reminderTime)) {
          // Adjust to next available time
          final adjustedTime = _adjustReminderTime(reminderTime, preferences);
          if (adjustedTime == null) continue;
        }

        final reminder = AppointmentReminder(
          id: '',
          appointmentId: appointment.id,
          patientId: appointment.patientId,
          doctorId: appointment.doctorId,
          type: ReminderType.appointment,
          title: _generateReminderTitle(appointment, hoursBeforeAppointment),
          message: _generateReminderMessage(appointment, hoursBeforeAppointment),
          scheduledTime: reminderTime,
          appointmentTime: appointment.appointmentDate,
          methods: preferences.preferredMethods,
          createdAt: DateTime.now(),
          isRecurring: appointment.isRecurring,
          recurringAppointmentId: appointment.recurringAppointmentId,
        );

        await _createReminder(reminder);
      }
    } catch (e) {
      debugPrint('Error creating appointment reminders: $e');
      rethrow;
    }
  }

  /// Creates a custom reminder
  Future<String> createCustomReminder(AppointmentReminder reminder) async {
    try {
      return await _createReminder(reminder);
    } catch (e) {
      debugPrint('Error creating custom reminder: $e');
      rethrow;
    }
  }

  /// Internal method to create a reminder
  Future<String> _createReminder(AppointmentReminder reminder) async {
    final docRef = await _firestore.collection('appointment_reminders').add(reminder.toMap());
    
    // Schedule the reminder for processing
    await _scheduleReminderProcessing(reminder.copyWith(id: docRef.id));
    
    return docRef.id;
  }

  /// Gets all reminders for a user
  Future<List<AppointmentReminder>> getUserReminders(String userId) async {
    try {
      final query = await _firestore
          .collection('appointment_reminders')
          .where('patientId', isEqualTo: userId)
          .orderBy('scheduledTime', descending: false)
          .get();

      return query.docs
          .map((doc) => AppointmentReminder.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting user reminders: $e');
      rethrow;
    }
  }

  /// Gets pending reminders for a user
  Future<List<AppointmentReminder>> getPendingReminders(String userId) async {
    try {
      final query = await _firestore
          .collection('appointment_reminders')
          .where('patientId', isEqualTo: userId)
          .where('status', isEqualTo: 'scheduled')
          .where('scheduledTime', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('scheduledTime', descending: false)
          .get();

      return query.docs
          .map((doc) => AppointmentReminder.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting pending reminders: $e');
      rethrow;
    }
  }

  /// Updates a reminder
  Future<void> updateReminder(AppointmentReminder reminder) async {
    try {
      await _firestore
          .collection('appointment_reminders')
          .doc(reminder.id)
          .update(reminder.toMap());

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating reminder: $e');
      rethrow;
    }
  }

  /// Cancels a reminder
  Future<void> cancelReminder(String reminderId) async {
    try {
      await _firestore
          .collection('appointment_reminders')
          .doc(reminderId)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error cancelling reminder: $e');
      rethrow;
    }
  }

  /// Cancels all reminders for an appointment
  Future<void> cancelAppointmentReminders(String appointmentId) async {
    try {
      final reminders = await _firestore
          .collection('appointment_reminders')
          .where('appointmentId', isEqualTo: appointmentId)
          .where('status', isEqualTo: 'scheduled')
          .get();

      final batch = _firestore.batch();
      for (final doc in reminders.docs) {
        batch.update(doc.reference, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      notifyListeners();
    } catch (e) {
      debugPrint('Error cancelling appointment reminders: $e');
      rethrow;
    }
  }

  /// Gets user's reminder preferences
  Future<ReminderPreferences> getUserReminderPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection('reminder_preferences')
          .doc(userId)
          .get();

      if (doc.exists) {
        return ReminderPreferences.fromMap({...doc.data()!, 'userId': userId});
      } else {
        // Return default preferences
        return ReminderPreferences(userId: userId);
      }
    } catch (e) {
      debugPrint('Error getting reminder preferences: $e');
      // Return default preferences on error
      return ReminderPreferences(userId: userId);
    }
  }

  /// Updates user's reminder preferences
  Future<void> updateReminderPreferences(ReminderPreferences preferences) async {
    try {
      await _firestore
          .collection('reminder_preferences')
          .doc(preferences.userId)
          .set(preferences.toMap(), SetOptions(merge: true));

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating reminder preferences: $e');
      rethrow;
    }
  }

  /// Processes due reminders (should be called periodically)
  Future<void> processDueReminders() async {
    try {
      final now = DateTime.now();
      final dueReminders = await _firestore
          .collection('appointment_reminders')
          .where('status', isEqualTo: 'scheduled')
          .where('scheduledTime', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      for (final doc in dueReminders.docs) {
        final reminder = AppointmentReminder.fromMap({...doc.data(), 'id': doc.id});
        await _sendReminder(reminder);
      }
    } catch (e) {
      debugPrint('Error processing due reminders: $e');
    }
  }

  /// Sends a reminder using specified methods
  Future<void> _sendReminder(AppointmentReminder reminder) async {
    try {
      bool success = false;
      String? failureReason;

      for (final method in reminder.methods) {
        try {
          switch (method) {
            case ReminderMethod.push:
              await _sendPushNotification(reminder);
              success = true;
              break;
            case ReminderMethod.email:
              await _sendEmailReminder(reminder);
              success = true;
              break;
            case ReminderMethod.sms:
              await _sendSMSReminder(reminder);
              success = true;
              break;
            case ReminderMethod.inApp:
              await _createInAppNotification(reminder);
              success = true;
              break;
          }
        } catch (e) {
          debugPrint('Error sending reminder via $method: $e');
          failureReason = e.toString();
        }
      }

      // Update reminder status
      await _firestore.collection('appointment_reminders').doc(reminder.id).update({
        'status': success ? 'sent' : 'failed',
        'sentAt': success ? FieldValue.serverTimestamp() : null,
        'failureReason': success ? null : failureReason,
        'retryCount': reminder.retryCount + (success ? 0 : 1),
      });

      // Schedule retry if failed and retry count is less than 3
      if (!success && reminder.retryCount < 2) {
        await _scheduleReminderRetry(reminder);
      }
    } catch (e) {
      debugPrint('Error sending reminder: $e');
    }
  }

  /// Sends push notification
  Future<void> _sendPushNotification(AppointmentReminder reminder) async {
    // This would integrate with Firebase Cloud Messaging
    // For now, we'll create a local notification entry
    await _firestore.collection('push_notifications').add({
      'userId': reminder.patientId,
      'title': reminder.title,
      'body': reminder.message,
      'data': {
        'type': 'appointment_reminder',
        'appointmentId': reminder.appointmentId,
        'reminderId': reminder.id,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Sends email reminder
  Future<void> _sendEmailReminder(AppointmentReminder reminder) async {
    // This would integrate with an email service
    await _firestore.collection('email_queue').add({
      'to': reminder.patientId, // This should be email address
      'subject': reminder.title,
      'body': reminder.message,
      'template': 'appointment_reminder',
      'data': {
        'appointmentId': reminder.appointmentId,
        'reminderId': reminder.id,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Sends SMS reminder
  Future<void> _sendSMSReminder(AppointmentReminder reminder) async {
    // This would integrate with an SMS service
    await _firestore.collection('sms_queue').add({
      'to': reminder.patientId, // This should be phone number
      'message': reminder.message,
      'data': {
        'appointmentId': reminder.appointmentId,
        'reminderId': reminder.id,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Creates in-app notification
  Future<void> _createInAppNotification(AppointmentReminder reminder) async {
    await _firestore.collection('in_app_notifications').add({
      'userId': reminder.patientId,
      'title': reminder.title,
      'message': reminder.message,
      'type': 'appointment_reminder',
      'data': {
        'appointmentId': reminder.appointmentId,
        'reminderId': reminder.id,
      },
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Schedules reminder processing
  Future<void> _scheduleReminderProcessing(AppointmentReminder reminder) async {
    // This would typically integrate with a job scheduler
    // For now, we'll add it to a processing queue
    await _firestore.collection('reminder_processing_queue').add({
      'reminderId': reminder.id,
      'scheduledTime': Timestamp.fromDate(reminder.scheduledTime),
      'status': 'queued',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Schedules reminder retry
  Future<void> _scheduleReminderRetry(AppointmentReminder reminder) async {
    final retryTime = DateTime.now().add(Duration(minutes: 15 * (reminder.retryCount + 1)));
    
    await _firestore.collection('reminder_processing_queue').add({
      'reminderId': reminder.id,
      'scheduledTime': Timestamp.fromDate(retryTime),
      'status': 'retry',
      'retryCount': reminder.retryCount + 1,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Adjusts reminder time to avoid quiet hours
  DateTime? _adjustReminderTime(DateTime originalTime, ReminderPreferences preferences) {
    if (!preferences.quietHoursEnabled) return originalTime;

    DateTime adjustedTime = originalTime;
    
    // If it's during quiet hours, move to the end of quiet hours
    if (preferences.isQuietTime(adjustedTime)) {
      adjustedTime = DateTime(
        adjustedTime.year,
        adjustedTime.month,
        adjustedTime.day,
        preferences.quietHoursEnd,
        0,
      );
      
      // If quiet hours end is the next day
      if (preferences.quietHoursEnd < preferences.quietHoursStart) {
        adjustedTime = adjustedTime.add(const Duration(days: 1));
      }
    }

    // Check if the adjusted day is enabled
    if (!preferences.isDayEnabled(adjustedTime)) {
      // Find next enabled day
      for (int i = 1; i <= 7; i++) {
        final candidateTime = adjustedTime.add(Duration(days: i));
        if (preferences.isDayEnabled(candidateTime)) {
          adjustedTime = candidateTime;
          break;
        }
      }
    }

    // Don't adjust if it's too close to the appointment
    final appointmentTime = originalTime.add(const Duration(hours: 1)); // Assuming 1 hour before appointment
    if (adjustedTime.isAfter(appointmentTime)) {
      return null; // Skip this reminder
    }

    return adjustedTime;
  }

  /// Generates reminder title
  String _generateReminderTitle(Appointment appointment, int hoursBeforeAppointment) {
    if (hoursBeforeAppointment >= 24) {
      return 'Appointment Tomorrow';
    } else if (hoursBeforeAppointment >= 2) {
      return 'Appointment in $hoursBeforeAppointment hours';
    } else {
      return 'Appointment Soon';
    }
  }

  /// Generates reminder message
  String _generateReminderMessage(Appointment appointment, int hoursBeforeAppointment) {
    final timeString = _formatAppointmentTime(appointment.appointmentDate);
    
    if (hoursBeforeAppointment >= 24) {
      return 'You have an appointment with Dr. ${appointment.doctorName} tomorrow at $timeString. Please arrive 15 minutes early.';
    } else if (hoursBeforeAppointment >= 2) {
      return 'Your appointment with Dr. ${appointment.doctorName} is in $hoursBeforeAppointment hours at $timeString. Don\'t forget to bring your insurance card.';
    } else {
      return 'Your appointment with Dr. ${appointment.doctorName} is starting soon at $timeString. Please head to the clinic now.';
    }
  }

  /// Formats appointment time
  String _formatAppointmentTime(DateTime appointmentTime) {
    final hour = appointmentTime.hour;
    final minute = appointmentTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    
    return '$displayHour:$displayMinute $period';
  }

  /// Gets reminder statistics
  Future<Map<String, dynamic>> getReminderStatistics(String userId) async {
    try {
      final reminders = await getUserReminders(userId);
      
      final stats = {
        'total': reminders.length,
        'scheduled': reminders.where((r) => r.status == ReminderStatus.scheduled).length,
        'sent': reminders.where((r) => r.status == ReminderStatus.sent).length,
        'delivered': reminders.where((r) => r.status == ReminderStatus.delivered).length,
        'failed': reminders.where((r) => r.status == ReminderStatus.failed).length,
        'cancelled': reminders.where((r) => r.status == ReminderStatus.cancelled).length,
      };

      // Calculate success rate
      final totalSent = stats['sent']! + stats['delivered']! + stats['failed']!;
      stats['successRate'] = totalSent > 0 
          ? ((stats['sent']! + stats['delivered']!) / totalSent * 100).round()
          : 0;

      return stats;
    } catch (e) {
      debugPrint('Error getting reminder statistics: $e');
      rethrow;
    }
  }
}

