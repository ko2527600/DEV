import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recurring_appointment_model.dart';
import '../models/appointment_model.dart';
import 'appointment_service.dart';
import 'availability_service.dart';

class RecurringAppointmentService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AppointmentService _appointmentService = AppointmentService();
  final AvailabilityService _availabilityService = AvailabilityService();

  /// Creates a new recurring appointment
  Future<String> createRecurringAppointment(RecurringAppointment recurringAppointment) async {
    try {
      final docRef = await _firestore
          .collection('recurring_appointments')
          .add(recurringAppointment.toMap());

      // Generate initial appointments
      await _generateUpcomingAppointments(recurringAppointment.copyWith(id: docRef.id));

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating recurring appointment: $e');
      rethrow;
    }
  }

  /// Gets all recurring appointments for a patient
  Future<List<RecurringAppointment>> getPatientRecurringAppointments(String patientId) async {
    try {
      final query = await _firestore
          .collection('recurring_appointments')
          .where('patientId', isEqualTo: patientId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => RecurringAppointment.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting patient recurring appointments: $e');
      rethrow;
    }
  }

  /// Gets all recurring appointments for a doctor
  Future<List<RecurringAppointment>> getDoctorRecurringAppointments(String doctorId) async {
    try {
      final query = await _firestore
          .collection('recurring_appointments')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => RecurringAppointment.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting doctor recurring appointments: $e');
      rethrow;
    }
  }

  /// Updates a recurring appointment
  Future<void> updateRecurringAppointment(RecurringAppointment recurringAppointment) async {
    try {
      await _firestore
          .collection('recurring_appointments')
          .doc(recurringAppointment.id)
          .update(recurringAppointment.toMap());

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating recurring appointment: $e');
      rethrow;
    }
  }

  /// Pauses a recurring appointment
  Future<void> pauseRecurringAppointment(String recurringAppointmentId, String reason) async {
    try {
      await _firestore
          .collection('recurring_appointments')
          .doc(recurringAppointmentId)
          .update({
        'status': 'paused',
        'reason': reason,
        'pausedAt': FieldValue.serverTimestamp(),
      });

      // Cancel future appointments that haven't occurred yet
      await _cancelFutureAppointments(recurringAppointmentId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error pausing recurring appointment: $e');
      rethrow;
    }
  }

  /// Resumes a paused recurring appointment
  Future<void> resumeRecurringAppointment(String recurringAppointmentId) async {
    try {
      await _firestore
          .collection('recurring_appointments')
          .doc(recurringAppointmentId)
          .update({
        'status': 'active',
        'reason': null,
        'resumedAt': FieldValue.serverTimestamp(),
      });

      // Get the recurring appointment and generate new appointments
      final doc = await _firestore
          .collection('recurring_appointments')
          .doc(recurringAppointmentId)
          .get();

      if (doc.exists) {
        final recurringAppointment = RecurringAppointment.fromMap({
          ...doc.data()!,
          'id': doc.id,
        });
        await _generateUpcomingAppointments(recurringAppointment);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error resuming recurring appointment: $e');
      rethrow;
    }
  }

  /// Cancels a recurring appointment
  Future<void> cancelRecurringAppointment(String recurringAppointmentId, String reason) async {
    try {
      await _firestore
          .collection('recurring_appointments')
          .doc(recurringAppointmentId)
          .update({
        'status': 'cancelled',
        'reason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // Cancel all future appointments
      await _cancelFutureAppointments(recurringAppointmentId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error cancelling recurring appointment: $e');
      rethrow;
    }
  }

  /// Generates upcoming appointments for a recurring appointment
  Future<void> _generateUpcomingAppointments(RecurringAppointment recurringAppointment) async {
    if (!recurringAppointment.shouldContinue()) return;

    try {
      // Generate next 12 appointments (3 months ahead)
      final nextDates = recurringAppointment.generateNextDates(count: 12);
      
      for (final date in nextDates) {
        // Check if appointment already exists for this date
        final existingQuery = await _firestore
            .collection('appointments')
            .where('recurringAppointmentId', isEqualTo: recurringAppointment.id)
            .where('appointmentDate', isEqualTo: Timestamp.fromDate(date))
            .limit(1)
            .get();

        if (existingQuery.docs.isEmpty) {
          // Check if the time slot is still available
          final availableSlots = await _availabilityService.getAvailableTimeSlots(
            recurringAppointment.doctorId,
            date,
          );

          if (availableSlots.contains(recurringAppointment.timeSlot)) {
            // Create the appointment
            final appointment = Appointment(
              id: '',
              patientId: recurringAppointment.patientId,
              doctorId: recurringAppointment.doctorId,
              doctorName: recurringAppointment.doctorName,
              specialization: recurringAppointment.specialization,
              appointmentDate: date,
              timeSlot: recurringAppointment.timeSlot,
              status: 'confirmed',
              isRecurring: true,
              recurringAppointmentId: recurringAppointment.id,
            );

            await _appointmentService.createAppointment(appointment);
          } else {
            // Time slot not available, create a notification or handle conflict
            await _handleSchedulingConflict(recurringAppointment, date);
          }
        }
      }

      // Update the recurring appointment with last generated date
      await _firestore
          .collection('recurring_appointments')
          .doc(recurringAppointment.id)
          .update({
        'lastGeneratedDate': nextDates.isNotEmpty 
            ? Timestamp.fromDate(nextDates.last) 
            : null,
        'generatedCount': FieldValue.increment(nextDates.length),
      });
    } catch (e) {
      debugPrint('Error generating upcoming appointments: $e');
      rethrow;
    }
  }

  /// Handles scheduling conflicts for recurring appointments
  Future<void> _handleSchedulingConflict(
    RecurringAppointment recurringAppointment, 
    DateTime conflictDate
  ) async {
    try {
      // Create a conflict notification
      await _firestore.collection('appointment_conflicts').add({
        'recurringAppointmentId': recurringAppointment.id,
        'patientId': recurringAppointment.patientId,
        'doctorId': recurringAppointment.doctorId,
        'conflictDate': Timestamp.fromDate(conflictDate),
        'requestedTimeSlot': recurringAppointment.timeSlot,
        'reason': 'Time slot not available',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Try to find alternative time slots
      final availableSlots = await _availabilityService.getAvailableTimeSlots(
        recurringAppointment.doctorId,
        conflictDate,
      );

      if (availableSlots.isNotEmpty) {
        // Suggest alternative slots
        await _firestore.collection('appointment_suggestions').add({
          'recurringAppointmentId': recurringAppointment.id,
          'patientId': recurringAppointment.patientId,
          'doctorId': recurringAppointment.doctorId,
          'originalDate': Timestamp.fromDate(conflictDate),
          'originalTimeSlot': recurringAppointment.timeSlot,
          'suggestedTimeSlots': availableSlots,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error handling scheduling conflict: $e');
    }
  }

  /// Cancels future appointments for a recurring appointment
  Future<void> _cancelFutureAppointments(String recurringAppointmentId) async {
    try {
      final now = DateTime.now();
      final futureAppointments = await _firestore
          .collection('appointments')
          .where('recurringAppointmentId', isEqualTo: recurringAppointmentId)
          .where('appointmentDate', isGreaterThan: Timestamp.fromDate(now))
          .where('status', whereIn: ['confirmed', 'pending'])
          .get();

      final batch = _firestore.batch();
      for (final doc in futureAppointments.docs) {
        batch.update(doc.reference, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancellationReason': 'Recurring appointment cancelled',
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error cancelling future appointments: $e');
    }
  }

  /// Gets upcoming appointments for a recurring appointment
  Future<List<Appointment>> getUpcomingRecurringAppointments(String recurringAppointmentId) async {
    try {
      final now = DateTime.now();
      final query = await _firestore
          .collection('appointments')
          .where('recurringAppointmentId', isEqualTo: recurringAppointmentId)
          .where('appointmentDate', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('appointmentDate')
          .limit(10)
          .get();

      return query.docs
          .map((doc) => Appointment.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting upcoming recurring appointments: $e');
      rethrow;
    }
  }

  /// Modifies a single occurrence of a recurring appointment
  Future<void> modifyRecurringAppointmentOccurrence(
    String appointmentId,
    DateTime newDate,
    String newTimeSlot,
  ) async {
    try {
      // Check if new slot is available
      final appointment = await _appointmentService.getAppointment(appointmentId);
      if (appointment == null) throw Exception('Appointment not found');

      final availableSlots = await _availabilityService.getAvailableTimeSlots(
        appointment.doctorId,
        newDate,
      );

      if (!availableSlots.contains(newTimeSlot)) {
        throw Exception('Selected time slot is not available');
      }

      // Update the appointment
      await _firestore.collection('appointments').doc(appointmentId).update({
        'appointmentDate': Timestamp.fromDate(newDate),
        'timeSlot': newTimeSlot,
        'isModified': true,
        'modifiedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error modifying recurring appointment occurrence: $e');
      rethrow;
    }
  }

  /// Skips a single occurrence of a recurring appointment
  Future<void> skipRecurringAppointmentOccurrence(String appointmentId, String reason) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'skipped',
        'skipReason': reason,
        'skippedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error skipping recurring appointment occurrence: $e');
      rethrow;
    }
  }

  /// Gets recurring appointment statistics
  Future<Map<String, dynamic>> getRecurringAppointmentStats(String patientId) async {
    try {
      final recurringAppointments = await getPatientRecurringAppointments(patientId);
      
      final stats = {
        'total': recurringAppointments.length,
        'active': recurringAppointments.where((ra) => ra.status == 'active').length,
        'paused': recurringAppointments.where((ra) => ra.status == 'paused').length,
        'cancelled': recurringAppointments.where((ra) => ra.status == 'cancelled').length,
        'completed': recurringAppointments.where((ra) => ra.status == 'completed').length,
      };

      // Get upcoming appointments count
      int upcomingCount = 0;
      for (final ra in recurringAppointments.where((ra) => ra.status == 'active')) {
        final upcoming = await getUpcomingRecurringAppointments(ra.id);
        upcomingCount += upcoming.length;
      }
      stats['upcomingAppointments'] = upcomingCount;

      return stats;
    } catch (e) {
      debugPrint('Error getting recurring appointment stats: $e');
      rethrow;
    }
  }

  /// Processes recurring appointments (should be called periodically)
  Future<void> processRecurringAppointments() async {
    try {
      // Get all active recurring appointments
      final activeRecurringAppointments = await _firestore
          .collection('recurring_appointments')
          .where('status', isEqualTo: 'active')
          .get();

      for (final doc in activeRecurringAppointments.docs) {
        final recurringAppointment = RecurringAppointment.fromMap({
          ...doc.data(),
          'id': doc.id,
        });

        // Check if we need to generate more appointments
        final lastGenerated = recurringAppointment.lastGeneratedDate ?? recurringAppointment.startDate;
        final daysSinceLastGenerated = DateTime.now().difference(lastGenerated).inDays;

        // Generate new appointments if it's been more than 30 days since last generation
        if (daysSinceLastGenerated > 30) {
          await _generateUpcomingAppointments(recurringAppointment);
        }

        // Check if recurring appointment should be completed
        if (!recurringAppointment.shouldContinue()) {
          await _firestore.collection('recurring_appointments').doc(doc.id).update({
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('Error processing recurring appointments: $e');
    }
  }
}

