import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class AppointmentService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<AppointmentModel> _appointments = [];
  bool _isLoading = false;

  List<AppointmentModel> get appointments => _appointments;
  bool get isLoading => _isLoading;

  Future<String?> bookAppointment({
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required DateTime appointmentDate,
    required String timeSlot,
    required String reason,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final appointment = AppointmentModel(
        id: '',
        patientId: patientId,
        patientName: patientName,
        doctorId: doctorId,
        doctorName: doctorName,
        appointmentDate: appointmentDate,
        timeSlot: timeSlot,
        reason: reason,
        status: AppointmentStatus.pending,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('appointments').add(appointment.toMap());
      await loadAppointments(patientId);
      return null; // Success
    } catch (e) {
      debugPrint('Error booking appointment: $e');
      return 'Failed to book appointment. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAppointments(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final query = await _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: userId)
          .orderBy('appointmentDate', descending: true)
          .get();

      _appointments = query.docs
          .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error loading appointments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDoctorAppointments(String doctorId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final query = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('appointmentDate', descending: false)
          .get();

      _appointments = query.docs
          .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error loading doctor appointments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateAppointmentStatus(String appointmentId, AppointmentStatus status) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': status.toString().split('.').last,
      });

      // Update local list
      final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(status: status);
        notifyListeners();
      }

      return null; // Success
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
      return 'Failed to update appointment status.';
    }
  }

  Future<List<String>> getAvailableTimeSlots(DateTime date) async {
    // This would typically check against doctor availability and existing appointments
    // For now, returning static time slots
    return [
      '09:00 AM',
      '10:00 AM',
      '11:00 AM',
      '02:00 PM',
      '03:00 PM',
      '04:00 PM',
    ];
  }

  Future<List<Map<String, String>>> getAvailableDoctors() async {
    try {
      final query = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'specialization': data['specialization'] ?? 'General Practice',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading doctors: $e');
      return [];
    }
  }
}

