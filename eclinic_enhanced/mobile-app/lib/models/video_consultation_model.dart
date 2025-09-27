import 'package:cloud_firestore/cloud_firestore.dart';

enum ConsultationStatus {
  scheduled,
  waiting,
  inProgress,
  completed,
  cancelled,
  noShow,
}

enum ConsultationType {
  followUp,
  newConsultation,
  emergency,
  secondOpinion,
  prescription,
}

enum ParticipantRole {
  patient,
  doctor,
  nurse,
  observer,
}

enum ConnectionQuality {
  excellent,
  good,
  fair,
  poor,
  disconnected,
}

class VideoConsultation {
  final String id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final String patientName;
  final String doctorName;
  final ConsultationType type;
  final ConsultationStatus status;
  final DateTime scheduledTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final int estimatedDuration; // in minutes
  final String? roomId;
  final String? meetingUrl;
  final Map<String, dynamic>? meetingCredentials;
  final List<String> participants;
  final String? notes;
  final String? prescription;
  final List<String> attachments;
  final Map<String, dynamic>? technicalInfo;
  final bool isRecorded;
  final String? recordingUrl;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  VideoConsultation({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    required this.doctorName,
    required this.type,
    this.status = ConsultationStatus.scheduled,
    required this.scheduledTime,
    this.startTime,
    this.endTime,
    this.estimatedDuration = 30,
    this.roomId,
    this.meetingUrl,
    this.meetingCredentials,
    this.participants = const [],
    this.notes,
    this.prescription,
    this.attachments = const [],
    this.technicalInfo,
    this.isRecorded = false,
    this.recordingUrl,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  factory VideoConsultation.fromMap(Map<String, dynamic> map) {
    return VideoConsultation(
      id: map['id'] ?? '',
      appointmentId: map['appointmentId'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorName: map['doctorName'] ?? '',
      type: ConsultationType.values.firstWhere(
        (e) => e.toString() == 'ConsultationType.${map['type']}',
        orElse: () => ConsultationType.newConsultation,
      ),
      status: ConsultationStatus.values.firstWhere(
        (e) => e.toString() == 'ConsultationStatus.${map['status']}',
        orElse: () => ConsultationStatus.scheduled,
      ),
      scheduledTime: (map['scheduledTime'] as Timestamp).toDate(),
      startTime: map['startTime'] != null ? (map['startTime'] as Timestamp).toDate() : null,
      endTime: map['endTime'] != null ? (map['endTime'] as Timestamp).toDate() : null,
      estimatedDuration: map['estimatedDuration'] ?? 30,
      roomId: map['roomId'],
      meetingUrl: map['meetingUrl'],
      meetingCredentials: map['meetingCredentials'],
      participants: List<String>.from(map['participants'] ?? []),
      notes: map['notes'],
      prescription: map['prescription'],
      attachments: List<String>.from(map['attachments'] ?? []),
      technicalInfo: map['technicalInfo'],
      isRecorded: map['isRecorded'] ?? false,
      recordingUrl: map['recordingUrl'],
      metadata: map['metadata'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'patientId': patientId,
      'doctorId': doctorId,
      'patientName': patientName,
      'doctorName': doctorName,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'estimatedDuration': estimatedDuration,
      'roomId': roomId,
      'meetingUrl': meetingUrl,
      'meetingCredentials': meetingCredentials,
      'participants': participants,
      'notes': notes,
      'prescription': prescription,
      'attachments': attachments,
      'technicalInfo': technicalInfo,
      'isRecorded': isRecorded,
      'recordingUrl': recordingUrl,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  VideoConsultation copyWith({
    String? id,
    String? appointmentId,
    String? patientId,
    String? doctorId,
    String? patientName,
    String? doctorName,
    ConsultationType? type,
    ConsultationStatus? status,
    DateTime? scheduledTime,
    DateTime? startTime,
    DateTime? endTime,
    int? estimatedDuration,
    String? roomId,
    String? meetingUrl,
    Map<String, dynamic>? meetingCredentials,
    List<String>? participants,
    String? notes,
    String? prescription,
    List<String>? attachments,
    Map<String, dynamic>? technicalInfo,
    bool? isRecorded,
    String? recordingUrl,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VideoConsultation(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      patientName: patientName ?? this.patientName,
      doctorName: doctorName ?? this.doctorName,
      type: type ?? this.type,
      status: status ?? this.status,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      roomId: roomId ?? this.roomId,
      meetingUrl: meetingUrl ?? this.meetingUrl,
      meetingCredentials: meetingCredentials ?? this.meetingCredentials,
      participants: participants ?? this.participants,
      notes: notes ?? this.notes,
      prescription: prescription ?? this.prescription,
      attachments: attachments ?? this.attachments,
      technicalInfo: technicalInfo ?? this.technicalInfo,
      isRecorded: isRecorded ?? this.isRecorded,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive => status == ConsultationStatus.inProgress;
  bool get isWaiting => status == ConsultationStatus.waiting;
  bool get isCompleted => status == ConsultationStatus.completed;
  bool get canStart => status == ConsultationStatus.scheduled || status == ConsultationStatus.waiting;
  bool get canJoin => status == ConsultationStatus.waiting || status == ConsultationStatus.inProgress;

  Duration? get actualDuration {
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!);
    }
    return null;
  }

  Duration get timeUntilStart => scheduledTime.difference(DateTime.now());
  bool get isOverdue => DateTime.now().isAfter(scheduledTime.add(const Duration(minutes: 15)));

  String get statusDisplayText {
    switch (status) {
      case ConsultationStatus.scheduled:
        return 'Scheduled';
      case ConsultationStatus.waiting:
        return 'Waiting Room';
      case ConsultationStatus.inProgress:
        return 'In Progress';
      case ConsultationStatus.completed:
        return 'Completed';
      case ConsultationStatus.cancelled:
        return 'Cancelled';
      case ConsultationStatus.noShow:
        return 'No Show';
    }
  }

  String get typeDisplayText {
    switch (type) {
      case ConsultationType.followUp:
        return 'Follow-up';
      case ConsultationType.newConsultation:
        return 'New Consultation';
      case ConsultationType.emergency:
        return 'Emergency';
      case ConsultationType.secondOpinion:
        return 'Second Opinion';
      case ConsultationType.prescription:
        return 'Prescription Review';
    }
  }
}

class ConsultationParticipant {
  final String userId;
  final String name;
  final ParticipantRole role;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final bool isActive;
  final ConnectionQuality connectionQuality;
  final Map<String, dynamic>? deviceInfo;
  final bool audioEnabled;
  final bool videoEnabled;
  final bool screenSharing;

  ConsultationParticipant({
    required this.userId,
    required this.name,
    required this.role,
    required this.joinedAt,
    this.leftAt,
    this.isActive = true,
    this.connectionQuality = ConnectionQuality.good,
    this.deviceInfo,
    this.audioEnabled = true,
    this.videoEnabled = true,
    this.screenSharing = false,
  });

  factory ConsultationParticipant.fromMap(Map<String, dynamic> map) {
    return ConsultationParticipant(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      role: ParticipantRole.values.firstWhere(
        (e) => e.toString() == 'ParticipantRole.${map['role']}',
        orElse: () => ParticipantRole.patient,
      ),
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
      leftAt: map['leftAt'] != null ? (map['leftAt'] as Timestamp).toDate() : null,
      isActive: map['isActive'] ?? true,
      connectionQuality: ConnectionQuality.values.firstWhere(
        (e) => e.toString() == 'ConnectionQuality.${map['connectionQuality']}',
        orElse: () => ConnectionQuality.good,
      ),
      deviceInfo: map['deviceInfo'],
      audioEnabled: map['audioEnabled'] ?? true,
      videoEnabled: map['videoEnabled'] ?? true,
      screenSharing: map['screenSharing'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'role': role.toString().split('.').last,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'leftAt': leftAt != null ? Timestamp.fromDate(leftAt!) : null,
      'isActive': isActive,
      'connectionQuality': connectionQuality.toString().split('.').last,
      'deviceInfo': deviceInfo,
      'audioEnabled': audioEnabled,
      'videoEnabled': videoEnabled,
      'screenSharing': screenSharing,
    };
  }

  Duration? get sessionDuration {
    final endTime = leftAt ?? DateTime.now();
    return endTime.difference(joinedAt);
  }
}

class ConsultationMessage {
  final String id;
  final String consultationId;
  final String senderId;
  final String senderName;
  final ParticipantRole senderRole;
  final String message;
  final DateTime timestamp;
  final bool isSystemMessage;
  final Map<String, dynamic>? metadata;

  ConsultationMessage({
    required this.id,
    required this.consultationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.timestamp,
    this.isSystemMessage = false,
    this.metadata,
  });

  factory ConsultationMessage.fromMap(Map<String, dynamic> map) {
    return ConsultationMessage(
      id: map['id'] ?? '',
      consultationId: map['consultationId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderRole: ParticipantRole.values.firstWhere(
        (e) => e.toString() == 'ParticipantRole.${map['senderRole']}',
        orElse: () => ParticipantRole.patient,
      ),
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isSystemMessage: map['isSystemMessage'] ?? false,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'consultationId': consultationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole.toString().split('.').last,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSystemMessage': isSystemMessage,
      'metadata': metadata,
    };
  }
}

class TechnicalRequirements {
  final String platform; // 'web', 'mobile', 'desktop'
  final String browser; // For web platform
  final String version;
  final bool hasCamera;
  final bool hasMicrophone;
  final bool hasSpeakers;
  final String networkType; // 'wifi', '4g', '5g', 'ethernet'
  final double bandwidth; // Mbps
  final int latency; // ms
  final Map<String, dynamic>? additionalInfo;

  TechnicalRequirements({
    required this.platform,
    this.browser = '',
    required this.version,
    this.hasCamera = false,
    this.hasMicrophone = false,
    this.hasSpeakers = false,
    this.networkType = 'unknown',
    this.bandwidth = 0.0,
    this.latency = 0,
    this.additionalInfo,
  });

  factory TechnicalRequirements.fromMap(Map<String, dynamic> map) {
    return TechnicalRequirements(
      platform: map['platform'] ?? '',
      browser: map['browser'] ?? '',
      version: map['version'] ?? '',
      hasCamera: map['hasCamera'] ?? false,
      hasMicrophone: map['hasMicrophone'] ?? false,
      hasSpeakers: map['hasSpeakers'] ?? false,
      networkType: map['networkType'] ?? 'unknown',
      bandwidth: (map['bandwidth'] ?? 0.0).toDouble(),
      latency: map['latency'] ?? 0,
      additionalInfo: map['additionalInfo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      'browser': browser,
      'version': version,
      'hasCamera': hasCamera,
      'hasMicrophone': hasMicrophone,
      'hasSpeakers': hasSpeakers,
      'networkType': networkType,
      'bandwidth': bandwidth,
      'latency': latency,
      'additionalInfo': additionalInfo,
    };
  }

  bool get meetsMinimumRequirements {
    return hasCamera && hasMicrophone && hasSpeakers && bandwidth >= 1.0;
  }

  ConnectionQuality get recommendedQuality {
    if (bandwidth >= 5.0 && latency < 100) {
      return ConnectionQuality.excellent;
    } else if (bandwidth >= 2.0 && latency < 200) {
      return ConnectionQuality.good;
    } else if (bandwidth >= 1.0 && latency < 500) {
      return ConnectionQuality.fair;
    } else {
      return ConnectionQuality.poor;
    }
  }
}

