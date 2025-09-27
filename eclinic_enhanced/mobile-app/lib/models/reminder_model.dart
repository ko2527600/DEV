import 'package:cloud_firestore/cloud_firestore.dart';

enum ReminderType {
  appointment,
  medication,
  followUp,
  labResults,
  custom,
}

enum ReminderMethod {
  push,
  email,
  sms,
  inApp,
}

enum ReminderStatus {
  scheduled,
  sent,
  delivered,
  failed,
  cancelled,
}

class AppointmentReminder {
  final String id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final ReminderType type;
  final String title;
  final String message;
  final DateTime scheduledTime;
  final DateTime appointmentTime;
  final List<ReminderMethod> methods;
  final ReminderStatus status;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final String? failureReason;
  final int retryCount;
  final bool isRecurring;
  final String? recurringAppointmentId;

  AppointmentReminder({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.type,
    required this.title,
    required this.message,
    required this.scheduledTime,
    required this.appointmentTime,
    required this.methods,
    this.status = ReminderStatus.scheduled,
    this.metadata,
    required this.createdAt,
    this.sentAt,
    this.deliveredAt,
    this.failureReason,
    this.retryCount = 0,
    this.isRecurring = false,
    this.recurringAppointmentId,
  });

  factory AppointmentReminder.fromMap(Map<String, dynamic> map) {
    return AppointmentReminder(
      id: map['id'] ?? '',
      appointmentId: map['appointmentId'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      type: ReminderType.values.firstWhere(
        (e) => e.toString() == 'ReminderType.${map['type']}',
        orElse: () => ReminderType.appointment,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      scheduledTime: (map['scheduledTime'] as Timestamp).toDate(),
      appointmentTime: (map['appointmentTime'] as Timestamp).toDate(),
      methods: (map['methods'] as List<dynamic>?)
          ?.map((method) => ReminderMethod.values.firstWhere(
                (e) => e.toString() == 'ReminderMethod.$method',
                orElse: () => ReminderMethod.push,
              ))
          .toList() ?? [ReminderMethod.push],
      status: ReminderStatus.values.firstWhere(
        (e) => e.toString() == 'ReminderStatus.${map['status']}',
        orElse: () => ReminderStatus.scheduled,
      ),
      metadata: map['metadata'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      sentAt: map['sentAt'] != null ? (map['sentAt'] as Timestamp).toDate() : null,
      deliveredAt: map['deliveredAt'] != null ? (map['deliveredAt'] as Timestamp).toDate() : null,
      failureReason: map['failureReason'],
      retryCount: map['retryCount'] ?? 0,
      isRecurring: map['isRecurring'] ?? false,
      recurringAppointmentId: map['recurringAppointmentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'patientId': patientId,
      'doctorId': doctorId,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'appointmentTime': Timestamp.fromDate(appointmentTime),
      'methods': methods.map((method) => method.toString().split('.').last).toList(),
      'status': status.toString().split('.').last,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'failureReason': failureReason,
      'retryCount': retryCount,
      'isRecurring': isRecurring,
      'recurringAppointmentId': recurringAppointmentId,
    };
  }

  AppointmentReminder copyWith({
    String? id,
    String? appointmentId,
    String? patientId,
    String? doctorId,
    ReminderType? type,
    String? title,
    String? message,
    DateTime? scheduledTime,
    DateTime? appointmentTime,
    List<ReminderMethod>? methods,
    ReminderStatus? status,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? sentAt,
    DateTime? deliveredAt,
    String? failureReason,
    int? retryCount,
    bool? isRecurring,
    String? recurringAppointmentId,
  }) {
    return AppointmentReminder(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      methods: methods ?? this.methods,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      failureReason: failureReason ?? this.failureReason,
      retryCount: retryCount ?? this.retryCount,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringAppointmentId: recurringAppointmentId ?? this.recurringAppointmentId,
    );
  }

  bool get isPending => status == ReminderStatus.scheduled;
  bool get isSent => status == ReminderStatus.sent || status == ReminderStatus.delivered;
  bool get isFailed => status == ReminderStatus.failed;
  bool get shouldRetry => isFailed && retryCount < 3;

  Duration get timeUntilReminder => scheduledTime.difference(DateTime.now());
  Duration get timeUntilAppointment => appointmentTime.difference(DateTime.now());

  String get formattedScheduledTime {
    final now = DateTime.now();
    final difference = scheduledTime.difference(now);
    
    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inMinutes < 60) {
      return 'In ${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return 'In ${difference.inHours} hours';
    } else {
      return 'In ${difference.inDays} days';
    }
  }
}

class ReminderPreferences {
  final String userId;
  final bool enableAppointmentReminders;
  final bool enableMedicationReminders;
  final bool enableFollowUpReminders;
  final List<ReminderMethod> preferredMethods;
  final Map<ReminderType, List<int>> reminderTiming; // Hours before appointment
  final bool quietHoursEnabled;
  final int quietHoursStart; // Hour (0-23)
  final int quietHoursEnd; // Hour (0-23)
  final List<int> enabledDays; // Days of week (1-7)
  final String timezone;
  final Map<String, dynamic>? customSettings;

  ReminderPreferences({
    required this.userId,
    this.enableAppointmentReminders = true,
    this.enableMedicationReminders = true,
    this.enableFollowUpReminders = true,
    this.preferredMethods = const [ReminderMethod.push, ReminderMethod.email],
    this.reminderTiming = const {
      ReminderType.appointment: [24, 2], // 24 hours and 2 hours before
    },
    this.quietHoursEnabled = false,
    this.quietHoursStart = 22, // 10 PM
    this.quietHoursEnd = 8, // 8 AM
    this.enabledDays = const [1, 2, 3, 4, 5, 6, 7], // All days
    this.timezone = 'UTC',
    this.customSettings,
  });

  factory ReminderPreferences.fromMap(Map<String, dynamic> map) {
    return ReminderPreferences(
      userId: map['userId'] ?? '',
      enableAppointmentReminders: map['enableAppointmentReminders'] ?? true,
      enableMedicationReminders: map['enableMedicationReminders'] ?? true,
      enableFollowUpReminders: map['enableFollowUpReminders'] ?? true,
      preferredMethods: (map['preferredMethods'] as List<dynamic>?)
          ?.map((method) => ReminderMethod.values.firstWhere(
                (e) => e.toString() == 'ReminderMethod.$method',
                orElse: () => ReminderMethod.push,
              ))
          .toList() ?? [ReminderMethod.push, ReminderMethod.email],
      reminderTiming: (map['reminderTiming'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          ReminderType.values.firstWhere(
            (e) => e.toString() == 'ReminderType.$key',
            orElse: () => ReminderType.appointment,
          ),
          List<int>.from(value),
        ),
      ) ?? {ReminderType.appointment: [24, 2]},
      quietHoursEnabled: map['quietHoursEnabled'] ?? false,
      quietHoursStart: map['quietHoursStart'] ?? 22,
      quietHoursEnd: map['quietHoursEnd'] ?? 8,
      enabledDays: List<int>.from(map['enabledDays'] ?? [1, 2, 3, 4, 5, 6, 7]),
      timezone: map['timezone'] ?? 'UTC',
      customSettings: map['customSettings'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'enableAppointmentReminders': enableAppointmentReminders,
      'enableMedicationReminders': enableMedicationReminders,
      'enableFollowUpReminders': enableFollowUpReminders,
      'preferredMethods': preferredMethods.map((method) => method.toString().split('.').last).toList(),
      'reminderTiming': reminderTiming.map(
        (key, value) => MapEntry(key.toString().split('.').last, value),
      ),
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'enabledDays': enabledDays,
      'timezone': timezone,
      'customSettings': customSettings,
    };
  }

  bool isQuietTime(DateTime time) {
    if (!quietHoursEnabled) return false;
    
    final hour = time.hour;
    if (quietHoursStart < quietHoursEnd) {
      return hour >= quietHoursStart && hour < quietHoursEnd;
    } else {
      // Quiet hours span midnight
      return hour >= quietHoursStart || hour < quietHoursEnd;
    }
  }

  bool isDayEnabled(DateTime date) {
    return enabledDays.contains(date.weekday);
  }

  List<int> getReminderTimingForType(ReminderType type) {
    return reminderTiming[type] ?? [24, 2]; // Default: 24 hours and 2 hours before
  }
}

