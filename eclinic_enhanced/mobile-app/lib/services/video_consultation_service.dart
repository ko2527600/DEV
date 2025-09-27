import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_consultation_model.dart';
import '../models/appointment_model.dart';

class VideoConsultationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a video consultation from an appointment
  Future<String> createVideoConsultation(Appointment appointment, {
    ConsultationType type = ConsultationType.newConsultation,
    int estimatedDuration = 30,
    bool isRecorded = false,
  }) async {
    try {
      // Generate room ID and meeting credentials
      final roomId = _generateRoomId();
      final meetingCredentials = await _generateMeetingCredentials(roomId);
      
      final consultation = VideoConsultation(
        id: '',
        appointmentId: appointment.id,
        patientId: appointment.patientId,
        doctorId: appointment.doctorId,
        patientName: 'Patient Name', // This should come from user data
        doctorName: appointment.doctorName,
        type: type,
        status: ConsultationStatus.scheduled,
        scheduledTime: appointment.appointmentDate,
        estimatedDuration: estimatedDuration,
        roomId: roomId,
        meetingUrl: _generateMeetingUrl(roomId),
        meetingCredentials: meetingCredentials,
        participants: [appointment.patientId, appointment.doctorId],
        isRecorded: isRecorded,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('video_consultations')
          .add(consultation.toMap());

      // Update appointment with video consultation ID
      await _firestore
          .collection('appointments')
          .doc(appointment.id)
          .update({
        'videoConsultationId': docRef.id,
        'isVideoConsultation': true,
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating video consultation: $e');
      rethrow;
    }
  }

  /// Gets a video consultation by ID
  Future<VideoConsultation?> getVideoConsultation(String consultationId) async {
    try {
      final doc = await _firestore
          .collection('video_consultations')
          .doc(consultationId)
          .get();

      if (doc.exists) {
        return VideoConsultation.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      debugPrint('Error getting video consultation: $e');
      rethrow;
    }
  }

  /// Gets video consultations for a patient
  Future<List<VideoConsultation>> getPatientConsultations(String patientId) async {
    try {
      final query = await _firestore
          .collection('video_consultations')
          .where('patientId', isEqualTo: patientId)
          .orderBy('scheduledTime', descending: true)
          .get();

      return query.docs
          .map((doc) => VideoConsultation.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting patient consultations: $e');
      rethrow;
    }
  }

  /// Gets video consultations for a doctor
  Future<List<VideoConsultation>> getDoctorConsultations(String doctorId) async {
    try {
      final query = await _firestore
          .collection('video_consultations')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('scheduledTime', descending: true)
          .get();

      return query.docs
          .map((doc) => VideoConsultation.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting doctor consultations: $e');
      rethrow;
    }
  }

  /// Gets upcoming consultations for a user
  Future<List<VideoConsultation>> getUpcomingConsultations(String userId, {bool isDoctor = false}) async {
    try {
      final field = isDoctor ? 'doctorId' : 'patientId';
      final now = DateTime.now();
      
      final query = await _firestore
          .collection('video_consultations')
          .where(field, isEqualTo: userId)
          .where('scheduledTime', isGreaterThan: Timestamp.fromDate(now))
          .where('status', whereIn: ['scheduled', 'waiting'])
          .orderBy('scheduledTime')
          .get();

      return query.docs
          .map((doc) => VideoConsultation.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting upcoming consultations: $e');
      rethrow;
    }
  }

  /// Starts a video consultation
  Future<void> startConsultation(String consultationId, String userId) async {
    try {
      final consultation = await getVideoConsultation(consultationId);
      if (consultation == null) {
        throw Exception('Consultation not found');
      }

      // Check if user is authorized to start the consultation
      if (consultation.doctorId != userId && consultation.patientId != userId) {
        throw Exception('Unauthorized to start this consultation');
      }

      // Update consultation status
      await _firestore
          .collection('video_consultations')
          .doc(consultationId)
          .update({
        'status': 'inProgress',
        'startTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add participant
      await _addParticipant(consultationId, userId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error starting consultation: $e');
      rethrow;
    }
  }

  /// Joins a video consultation
  Future<void> joinConsultation(String consultationId, String userId) async {
    try {
      final consultation = await getVideoConsultation(consultationId);
      if (consultation == null) {
        throw Exception('Consultation not found');
      }

      // Check if user is authorized to join
      if (!consultation.participants.contains(userId)) {
        throw Exception('Unauthorized to join this consultation');
      }

      // Update consultation status to waiting if not already started
      if (consultation.status == ConsultationStatus.scheduled) {
        await _firestore
            .collection('video_consultations')
            .doc(consultationId)
            .update({
          'status': 'waiting',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Add participant
      await _addParticipant(consultationId, userId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error joining consultation: $e');
      rethrow;
    }
  }

  /// Ends a video consultation
  Future<void> endConsultation(String consultationId, String userId, {
    String? notes,
    String? prescription,
  }) async {
    try {
      final consultation = await getVideoConsultation(consultationId);
      if (consultation == null) {
        throw Exception('Consultation not found');
      }

      // Only doctor can end the consultation
      if (consultation.doctorId != userId) {
        throw Exception('Only the doctor can end the consultation');
      }

      final updateData = {
        'status': 'completed',
        'endTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null) updateData['notes'] = notes;
      if (prescription != null) updateData['prescription'] = prescription;

      await _firestore
          .collection('video_consultations')
          .doc(consultationId)
          .update(updateData);

      // Remove all participants
      await _removeAllParticipants(consultationId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error ending consultation: $e');
      rethrow;
    }
  }

  /// Cancels a video consultation
  Future<void> cancelConsultation(String consultationId, String userId, String reason) async {
    try {
      final consultation = await getVideoConsultation(consultationId);
      if (consultation == null) {
        throw Exception('Consultation not found');
      }

      // Check if user is authorized to cancel
      if (consultation.doctorId != userId && consultation.patientId != userId) {
        throw Exception('Unauthorized to cancel this consultation');
      }

      await _firestore
          .collection('video_consultations')
          .doc(consultationId)
          .update({
        'status': 'cancelled',
        'metadata': {
          'cancellationReason': reason,
          'cancelledBy': userId,
          'cancelledAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error cancelling consultation: $e');
      rethrow;
    }
  }

  /// Adds a participant to the consultation
  Future<void> _addParticipant(String consultationId, String userId) async {
    try {
      final participant = ConsultationParticipant(
        userId: userId,
        name: 'User Name', // This should come from user data
        role: ParticipantRole.patient, // This should be determined based on user
        joinedAt: DateTime.now(),
        isActive: true,
        connectionQuality: ConnectionQuality.good,
        audioEnabled: true,
        videoEnabled: true,
      );

      await _firestore
          .collection('video_consultations')
          .doc(consultationId)
          .collection('participants')
          .doc(userId)
          .set(participant.toMap());
    } catch (e) {
      debugPrint('Error adding participant: $e');
      rethrow;
    }
  }

  /// Removes a participant from the consultation
  Future<void> removeParticipant(String consultationId, String userId) async {
    try {
      await _firestore
          .collection('video_consultations')
          .doc(consultationId)
          .collection('participants')
          .doc(userId)
          .update({
        'isActive': false,
        'leftAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error removing participant: $e');
      rethrow;
    }
  }

  /// Removes all participants from the consultation
  Future<void> _removeAllParticipants(String consultationId) async {
    try {
      final participants = await _firestore
          .collection('video_consultations')
          .doc(consultationId)
          .collection('participants')
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in participants.docs) {
        batch.update(doc.reference, {
          'isActive': false,
          'leftAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error removing all participants: $e');
    }
  }

  /// Gets active participants in a consultation
  Future<List<ConsultationParticipant>> getActiveParticipants(String consultationId) async {
    try {
      final query = await _firestore
          .collection('video_consultations')
          .doc(consultationId)
          .collection('participants')
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs
          .map((doc) => ConsultationParticipant.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting active participants: $e');
      rethrow;
    }
  }

  /// Updates participant status (audio/video/screen sharing)
  Future<void> updateParticipantStatus(
    String consultationId,
    String userId, {
    bool? audioEnabled,
    bool? videoEnabled,
    bool? screenSharing,
    ConnectionQuality? connectionQuality,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (audioEnabled != null) updateData['audioEnabled'] = audioEnabled;
      if (videoEnabled != null) updateData['videoEnabled'] = videoEnabled;
      if (screenSharing != null) updateData['screenSharing'] = screenSharing;
      if (connectionQuality != null) {
        updateData['connectionQuality'] = connectionQuality.toString().split('.').last;
      }

      if (updateData.isNotEmpty) {
        await _firestore
            .collection('video_consultations')
            .doc(consultationId)
            .collection('participants')
            .doc(userId)
            .update(updateData);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating participant status: $e');
      rethrow;
    }
  }

  /// Sends a message in the consultation chat
  Future<void> sendMessage(String consultationId, String senderId, String message) async {
    try {
      final chatMessage = ConsultationMessage(
        id: '',
        consultationId: consultationId,
        senderId: senderId,
        senderName: 'User Name', // This should come from user data
        senderRole: ParticipantRole.patient, // This should be determined
        message: message,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('video_consultations')
          .doc(consultationId)
          .collection('messages')
          .add(chatMessage.toMap());
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// Gets messages for a consultation
  Stream<List<ConsultationMessage>> getConsultationMessages(String consultationId) {
    return _firestore
        .collection('video_consultations')
        .doc(consultationId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConsultationMessage.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Checks technical requirements
  Future<TechnicalRequirements> checkTechnicalRequirements() async {
    // This would typically check device capabilities
    // For now, return mock data
    return TechnicalRequirements(
      platform: 'mobile',
      version: '1.0.0',
      hasCamera: true,
      hasMicrophone: true,
      hasSpeakers: true,
      networkType: 'wifi',
      bandwidth: 5.0,
      latency: 50,
    );
  }

  /// Tests connection quality
  Future<ConnectionQuality> testConnectionQuality() async {
    try {
      // This would perform actual network tests
      // For now, return mock data based on random conditions
      final requirements = await checkTechnicalRequirements();
      return requirements.recommendedQuality;
    } catch (e) {
      debugPrint('Error testing connection quality: $e');
      return ConnectionQuality.poor;
    }
  }

  /// Generates a unique room ID
  String _generateRoomId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'room_$timestamp$random';
  }

  /// Generates meeting credentials
  Future<Map<String, dynamic>> _generateMeetingCredentials(String roomId) async {
    // This would integrate with your video service provider (Jitsi, Agora, etc.)
    return {
      'roomId': roomId,
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      'serverUrl': 'https://meet.eclinic.com',
      'apiKey': 'mock_api_key',
    };
  }

  /// Generates meeting URL
  String _generateMeetingUrl(String roomId) {
    return 'https://meet.eclinic.com/$roomId';
  }

  /// Gets consultation statistics
  Future<Map<String, dynamic>> getConsultationStatistics(String userId, {bool isDoctor = false}) async {
    try {
      final field = isDoctor ? 'doctorId' : 'patientId';
      final consultations = await _firestore
          .collection('video_consultations')
          .where(field, isEqualTo: userId)
          .get();

      final stats = {
        'total': consultations.docs.length,
        'completed': 0,
        'cancelled': 0,
        'noShow': 0,
        'totalDuration': 0, // in minutes
        'averageDuration': 0.0,
      };

      int totalMinutes = 0;
      int completedCount = 0;

      for (final doc in consultations.docs) {
        final consultation = VideoConsultation.fromMap({...doc.data(), 'id': doc.id});
        
        switch (consultation.status) {
          case ConsultationStatus.completed:
            stats['completed'] = (stats['completed'] as int) + 1;
            completedCount++;
            if (consultation.actualDuration != null) {
              totalMinutes += consultation.actualDuration!.inMinutes;
            }
            break;
          case ConsultationStatus.cancelled:
            stats['cancelled'] = (stats['cancelled'] as int) + 1;
            break;
          case ConsultationStatus.noShow:
            stats['noShow'] = (stats['noShow'] as int) + 1;
            break;
          default:
            break;
        }
      }

      stats['totalDuration'] = totalMinutes;
      stats['averageDuration'] = completedCount > 0 ? totalMinutes / completedCount : 0.0;

      return stats;
    } catch (e) {
      debugPrint('Error getting consultation statistics: $e');
      rethrow;
    }
  }

  /// Schedules a follow-up consultation
  Future<String> scheduleFollowUp(
    String originalConsultationId,
    DateTime scheduledTime,
    int estimatedDuration,
  ) async {
    try {
      final originalConsultation = await getVideoConsultation(originalConsultationId);
      if (originalConsultation == null) {
        throw Exception('Original consultation not found');
      }

      final followUpConsultation = originalConsultation.copyWith(
        id: '',
        type: ConsultationType.followUp,
        status: ConsultationStatus.scheduled,
        scheduledTime: scheduledTime,
        estimatedDuration: estimatedDuration,
        startTime: null,
        endTime: null,
        roomId: _generateRoomId(),
        notes: null,
        prescription: null,
        createdAt: DateTime.now(),
        updatedAt: null,
        metadata: {
          'originalConsultationId': originalConsultationId,
          'isFollowUp': true,
        },
      );

      final docRef = await _firestore
          .collection('video_consultations')
          .add(followUpConsultation.toMap());

      return docRef.id;
    } catch (e) {
      debugPrint('Error scheduling follow-up: $e');
      rethrow;
    }
  }
}

