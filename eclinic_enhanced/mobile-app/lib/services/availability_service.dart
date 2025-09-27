import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/availability_model.dart';

class AvailabilityService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates or updates doctor availability
  Future<void> setDoctorAvailability(DoctorAvailability availability) async {
    try {
      await _firestore
          .collection('doctor_availability')
          .doc(availability.id)
          .set(availability.toMap());
    } catch (e) {
      debugPrint('Error setting doctor availability: $e');
      rethrow;
    }
  }

  /// Gets doctor availability for a specific day
  Future<DoctorAvailability?> getDoctorAvailability(String doctorId, String dayOfWeek) async {
    try {
      final query = await _firestore
          .collection('doctor_availability')
          .where('doctorId', isEqualTo: doctorId)
          .where('dayOfWeek', isEqualTo: dayOfWeek.toLowerCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return DoctorAvailability.fromMap(query.docs.first.data());
      }
      return null;
    } catch (e) {
      debugPrint('Error getting doctor availability: $e');
      rethrow;
    }
  }

  /// Gets all availability for a doctor
  Future<List<DoctorAvailability>> getAllDoctorAvailability(String doctorId) async {
    try {
      final query = await _firestore
          .collection('doctor_availability')
          .where('doctorId', isEqualTo: doctorId)
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs
          .map((doc) => DoctorAvailability.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting all doctor availability: $e');
      rethrow;
    }
  }

  /// Generates schedule for a specific date
  Future<DoctorSchedule> generateDoctorSchedule(String doctorId, DateTime date) async {
    try {
      final dayOfWeek = _getDayOfWeek(date);
      final availability = await getDoctorAvailability(doctorId, dayOfWeek);

      if (availability == null) {
        return DoctorSchedule(
          doctorId: doctorId,
          date: date,
          timeSlots: [],
          isWorkingDay: false,
        );
      }

      // Generate time slots based on availability
      final timeSlots = availability.generateTimeSlots().map((time) {
        return TimeSlot(time: time);
      }).toList();

      // Check for existing appointments on this date
      final existingAppointments = await _getExistingAppointments(doctorId, date);
      
      // Mark booked slots
      for (final appointment in existingAppointments) {
        final slotIndex = timeSlots.indexWhere((slot) => slot.time == appointment['timeSlot']);
        if (slotIndex != -1) {
          timeSlots[slotIndex] = TimeSlot(
            time: timeSlots[slotIndex].time,
            isAvailable: false,
            isBooked: true,
            appointmentId: appointment['id'],
          );
        }
      }

      return DoctorSchedule(
        doctorId: doctorId,
        date: date,
        timeSlots: timeSlots,
        isWorkingDay: true,
      );
    } catch (e) {
      debugPrint('Error generating doctor schedule: $e');
      rethrow;
    }
  }

  /// Gets available time slots for a doctor on a specific date
  Future<List<String>> getAvailableTimeSlots(String doctorId, DateTime date) async {
    try {
      final schedule = await generateDoctorSchedule(doctorId, date);
      return schedule.availableSlots.map((slot) => slot.time).toList();
    } catch (e) {
      debugPrint('Error getting available time slots: $e');
      rethrow;
    }
  }

  /// Books a time slot
  Future<bool> bookTimeSlot(String doctorId, DateTime date, String timeSlot, String appointmentId) async {
    try {
      // Check if slot is still available
      final availableSlots = await getAvailableTimeSlots(doctorId, date);
      if (!availableSlots.contains(timeSlot)) {
        return false; // Slot no longer available
      }

      // The appointment booking is handled by AppointmentService
      // This method just validates availability
      return true;
    } catch (e) {
      debugPrint('Error booking time slot: $e');
      rethrow;
    }
  }

  /// Gets doctor's schedule for a date range
  Future<Map<DateTime, DoctorSchedule>> getDoctorScheduleRange(
    String doctorId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final schedules = <DateTime, DoctorSchedule>{};
      
      DateTime currentDate = startDate;
      while (!currentDate.isAfter(endDate)) {
        final schedule = await generateDoctorSchedule(doctorId, currentDate);
        schedules[currentDate] = schedule;
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      return schedules;
    } catch (e) {
      debugPrint('Error getting doctor schedule range: $e');
      rethrow;
    }
  }

  /// Sets doctor as unavailable for a specific date/time
  Future<void> setDoctorUnavailable(
    String doctorId, 
    DateTime date, 
    String? timeSlot, 
    String reason
  ) async {
    try {
      final unavailabilityData = {
        'doctorId': doctorId,
        'date': date,
        'timeSlot': timeSlot, // null means entire day
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('doctor_unavailability')
          .add(unavailabilityData);
    } catch (e) {
      debugPrint('Error setting doctor unavailable: $e');
      rethrow;
    }
  }

  /// Gets doctors available for a specific specialization and date
  Future<List<Map<String, dynamic>>> getAvailableDoctors(
    String specialization, 
    DateTime date
  ) async {
    try {
      // Get doctors with the required specialization
      final doctorsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('specialization', isEqualTo: specialization)
          .get();

      final availableDoctors = <Map<String, dynamic>>[];

      for (final doctorDoc in doctorsQuery.docs) {
        final doctorData = doctorDoc.data();
        final doctorId = doctorDoc.id;

        // Check if doctor has availability on this date
        final availableSlots = await getAvailableTimeSlots(doctorId, date);
        
        if (availableSlots.isNotEmpty) {
          availableDoctors.add({
            'id': doctorId,
            'name': doctorData['name'] ?? 'Unknown Doctor',
            'specialization': doctorData['specialization'],
            'availableSlots': availableSlots,
            'rating': doctorData['rating'] ?? 0.0,
            'experience': doctorData['experience'] ?? 0,
          });
        }
      }

      // Sort by rating and available slots
      availableDoctors.sort((a, b) {
        final ratingComparison = (b['rating'] as double).compareTo(a['rating'] as double);
        if (ratingComparison != 0) return ratingComparison;
        return (b['availableSlots'] as List).length.compareTo((a['availableSlots'] as List).length);
      });

      return availableDoctors;
    } catch (e) {
      debugPrint('Error getting available doctors: $e');
      rethrow;
    }
  }

  /// Updates doctor availability for multiple days
  Future<void> updateWeeklyAvailability(String doctorId, Map<String, DoctorAvailability> weeklySchedule) async {
    try {
      final batch = _firestore.batch();

      for (final availability in weeklySchedule.values) {
        final docRef = _firestore.collection('doctor_availability').doc(availability.id);
        batch.set(docRef, availability.toMap());
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error updating weekly availability: $e');
      rethrow;
    }
  }

  /// Helper method to get existing appointments for a date
  Future<List<Map<String, dynamic>>> _getExistingAppointments(String doctorId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final query = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('appointmentDate', isGreaterThanOrEqualTo: startOfDay)
          .where('appointmentDate', isLessThan: endOfDay)
          .where('status', whereIn: ['confirmed', 'pending'])
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting existing appointments: $e');
      return [];
    }
  }

  /// Helper method to get day of week string
  String _getDayOfWeek(DateTime date) {
    const days = [
      'monday', 'tuesday', 'wednesday', 'thursday', 
      'friday', 'saturday', 'sunday'
    ];
    return days[date.weekday - 1];
  }

  /// Gets next available appointment slot for a doctor
  Future<Map<String, dynamic>?> getNextAvailableSlot(String doctorId, {int daysToCheck = 30}) async {
    try {
      final today = DateTime.now();
      
      for (int i = 0; i < daysToCheck; i++) {
        final checkDate = today.add(Duration(days: i));
        final availableSlots = await getAvailableTimeSlots(doctorId, checkDate);
        
        if (availableSlots.isNotEmpty) {
          return {
            'date': checkDate,
            'timeSlot': availableSlots.first,
            'allSlots': availableSlots,
          };
        }
      }
      
      return null; // No available slots found
    } catch (e) {
      debugPrint('Error getting next available slot: $e');
      rethrow;
    }
  }

  /// Gets appointment statistics for a doctor
  Future<Map<String, dynamic>> getDoctorAppointmentStats(String doctorId, DateTime date) async {
    try {
      final schedule = await generateDoctorSchedule(doctorId, date);
      
      return {
        'totalSlots': schedule.timeSlots.length,
        'bookedSlots': schedule.bookedSlots.length,
        'availableSlots': schedule.availableSlots.length,
        'utilizationRate': schedule.timeSlots.isNotEmpty 
            ? (schedule.bookedSlots.length / schedule.timeSlots.length * 100).round()
            : 0,
      };
    } catch (e) {
      debugPrint('Error getting doctor appointment stats: $e');
      rethrow;
    }
  }
}

