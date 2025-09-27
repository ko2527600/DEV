import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  appointment,
  prescription,
  labResult,
  message,
  payment,
  reminder,
  emergency,
  system,
  marketing,
  healthTip,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

enum NotificationStatus {
  pending,
  sent,
  delivered,
  read,
  failed,
  cancelled,
}

enum NotificationChannel {
  inApp,
  push,
  email,
  sms,
  voice,
}

class Notification {
  final String id;
  final String userId;
  final String? doctorId;
  final String? appointmentId;
  final String? prescriptionId;
  final String? paymentId;
  final NotificationType type;
  final NotificationPriority priority;
  final NotificationStatus status;
  final List<NotificationChannel> channels;
  final String title;
  final String body;
  final String? imageUrl;
  final String? actionUrl;
  final Map<String, dynamic>? actionData;
  final Map<String, dynamic>? customData;
  final DateTime scheduledAt;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? expiresAt;
  final bool isRead;
  final bool isArchived;
  final String? failureReason;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Notification({
    required this.id,
    required this.userId,
    this.doctorId,
    this.appointmentId,
    this.prescriptionId,
    this.paymentId,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.status = NotificationStatus.pending,
    this.channels = const [NotificationChannel.inApp, NotificationChannel.push],
    required this.title,
    required this.body,
    this.imageUrl,
    this.actionUrl,
    this.actionData,
    this.customData,
    required this.scheduledAt,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.expiresAt,
    this.isRead = false,
    this.isArchived = false,
    this.failureReason,
    this.retryCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      doctorId: map['doctorId'],
      appointmentId: map['appointmentId'],
      prescriptionId: map['prescriptionId'],
      paymentId: map['paymentId'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${map['type']}',
        orElse: () => NotificationType.system,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString() == 'NotificationPriority.${map['priority']}',
        orElse: () => NotificationPriority.normal,
      ),
      status: NotificationStatus.values.firstWhere(
        (e) => e.toString() == 'NotificationStatus.${map['status']}',
        orElse: () => NotificationStatus.pending,
      ),
      channels: (map['channels'] as List<dynamic>?)
          ?.map((channel) => NotificationChannel.values.firstWhere(
                (e) => e.toString() == 'NotificationChannel.$channel',
                orElse: () => NotificationChannel.inApp,
              ))
          .toList() ?? [NotificationChannel.inApp],
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      imageUrl: map['imageUrl'],
      actionUrl: map['actionUrl'],
      actionData: map['actionData'],
      customData: map['customData'],
      scheduledAt: (map['scheduledAt'] as Timestamp).toDate(),
      sentAt: map['sentAt'] != null ? (map['sentAt'] as Timestamp).toDate() : null,
      deliveredAt: map['deliveredAt'] != null ? (map['deliveredAt'] as Timestamp).toDate() : null,
      readAt: map['readAt'] != null ? (map['readAt'] as Timestamp).toDate() : null,
      expiresAt: map['expiresAt'] != null ? (map['expiresAt'] as Timestamp).toDate() : null,
      isRead: map['isRead'] ?? false,
      isArchived: map['isArchived'] ?? false,
      failureReason: map['failureReason'],
      retryCount: map['retryCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'doctorId': doctorId,
      'appointmentId': appointmentId,
      'prescriptionId': prescriptionId,
      'paymentId': paymentId,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'channels': channels.map((c) => c.toString().split('.').last).toList(),
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'actionData': actionData,
      'customData': customData,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isRead': isRead,
      'isArchived': isArchived,
      'failureReason': failureReason,
      'retryCount': retryCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get typeDisplayText {
    switch (type) {
      case NotificationType.appointment:
        return 'Appointment';
      case NotificationType.prescription:
        return 'Prescription';
      case NotificationType.labResult:
        return 'Lab Result';
      case NotificationType.message:
        return 'Message';
      case NotificationType.payment:
        return 'Payment';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.emergency:
        return 'Emergency';
      case NotificationType.system:
        return 'System';
      case NotificationType.marketing:
        return 'Marketing';
      case NotificationType.healthTip:
        return 'Health Tip';
    }
  }

  String get priorityDisplayText {
    switch (priority) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }

  String get statusDisplayText {
    switch (status) {
      case NotificationStatus.pending:
        return 'Pending';
      case NotificationStatus.sent:
        return 'Sent';
      case NotificationStatus.delivered:
        return 'Delivered';
      case NotificationStatus.read:
        return 'Read';
      case NotificationStatus.failed:
        return 'Failed';
      case NotificationStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isPending => status == NotificationStatus.pending;
  bool get isSent => status == NotificationStatus.sent || status == NotificationStatus.delivered || status == NotificationStatus.read;
  bool get isFailed => status == NotificationStatus.failed;
  bool get isUrgent => priority == NotificationPriority.urgent;
  bool get isHigh => priority == NotificationPriority.high;
  bool get shouldRetry => isFailed && retryCount < 3 && !isExpired;
}

class NotificationPreferences {
  final String id;
  final String userId;
  final bool enableInApp;
  final bool enablePush;
  final bool enableEmail;
  final bool enableSms;
  final Map<NotificationType, bool> typePreferences;
  final Map<NotificationPriority, bool> priorityPreferences;
  final List<String> quietHours; // e.g., ["22:00", "08:00"]
  final List<int> quietDays; // 0-6, Sunday = 0
  final String timezone;
  final DateTime createdAt;
  final DateTime? updatedAt;

  NotificationPreferences({
    required this.id,
    required this.userId,
    this.enableInApp = true,
    this.enablePush = true,
    this.enableEmail = true,
    this.enableSms = false,
    this.typePreferences = const {},
    this.priorityPreferences = const {},
    this.quietHours = const [],
    this.quietDays = const [],
    this.timezone = 'UTC',
    required this.createdAt,
    this.updatedAt,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      enableInApp: map['enableInApp'] ?? true,
      enablePush: map['enablePush'] ?? true,
      enableEmail: map['enableEmail'] ?? true,
      enableSms: map['enableSms'] ?? false,
      typePreferences: Map<NotificationType, bool>.from(
        (map['typePreferences'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            NotificationType.values.firstWhere(
              (e) => e.toString() == 'NotificationType.$key',
              orElse: () => NotificationType.system,
            ),
            value as bool,
          ),
        ) ?? {},
      ),
      priorityPreferences: Map<NotificationPriority, bool>.from(
        (map['priorityPreferences'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            NotificationPriority.values.firstWhere(
              (e) => e.toString() == 'NotificationPriority.$key',
              orElse: () => NotificationPriority.normal,
            ),
            value as bool,
          ),
        ) ?? {},
      ),
      quietHours: List<String>.from(map['quietHours'] ?? []),
      quietDays: List<int>.from(map['quietDays'] ?? []),
      timezone: map['timezone'] ?? 'UTC',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'enableInApp': enableInApp,
      'enablePush': enablePush,
      'enableEmail': enableEmail,
      'enableSms': enableSms,
      'typePreferences': typePreferences.map(
        (key, value) => MapEntry(key.toString().split('.').last, value),
      ),
      'priorityPreferences': priorityPreferences.map(
        (key, value) => MapEntry(key.toString().split('.').last, value),
      ),
      'quietHours': quietHours,
      'quietDays': quietDays,
      'timezone': timezone,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  bool isTypeEnabled(NotificationType type) {
    return typePreferences[type] ?? true;
  }

  bool isPriorityEnabled(NotificationPriority priority) {
    return priorityPreferences[priority] ?? true;
  }

  bool isInQuietHours(DateTime dateTime) {
    if (quietHours.length != 2) return false;
    
    final startTime = quietHours[0];
    final endTime = quietHours[1];
    final currentTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    return currentTime.compareTo(startTime) >= 0 && currentTime.compareTo(endTime) <= 0;
  }

  bool isQuietDay(DateTime dateTime) {
    return quietDays.contains(dateTime.weekday % 7);
  }

  bool shouldSendNotification(Notification notification) {
    // Always send urgent notifications
    if (notification.priority == NotificationPriority.urgent) {
      return true;
    }

    // Check type preferences
    if (!isTypeEnabled(notification.type)) {
      return false;
    }

    // Check priority preferences
    if (!isPriorityEnabled(notification.priority)) {
      return false;
    }

    // Check quiet hours and days
    if (isInQuietHours(notification.scheduledAt) || isQuietDay(notification.scheduledAt)) {
      return false;
    }

    return true;
  }
}

class NotificationTemplate {
  final String id;
  final NotificationType type;
  final String name;
  final String titleTemplate;
  final String bodyTemplate;
  final String? imageUrl;
  final String? actionUrl;
  final Map<String, dynamic>? defaultData;
  final List<NotificationChannel> defaultChannels;
  final NotificationPriority defaultPriority;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  NotificationTemplate({
    required this.id,
    required this.type,
    required this.name,
    required this.titleTemplate,
    required this.bodyTemplate,
    this.imageUrl,
    this.actionUrl,
    this.defaultData,
    this.defaultChannels = const [NotificationChannel.inApp, NotificationChannel.push],
    this.defaultPriority = NotificationPriority.normal,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory NotificationTemplate.fromMap(Map<String, dynamic> map) {
    return NotificationTemplate(
      id: map['id'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${map['type']}',
        orElse: () => NotificationType.system,
      ),
      name: map['name'] ?? '',
      titleTemplate: map['titleTemplate'] ?? '',
      bodyTemplate: map['bodyTemplate'] ?? '',
      imageUrl: map['imageUrl'],
      actionUrl: map['actionUrl'],
      defaultData: map['defaultData'],
      defaultChannels: (map['defaultChannels'] as List<dynamic>?)
          ?.map((channel) => NotificationChannel.values.firstWhere(
                (e) => e.toString() == 'NotificationChannel.$channel',
                orElse: () => NotificationChannel.inApp,
              ))
          .toList() ?? [NotificationChannel.inApp],
      defaultPriority: NotificationPriority.values.firstWhere(
        (e) => e.toString() == 'NotificationPriority.${map['defaultPriority']}',
        orElse: () => NotificationPriority.normal,
      ),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'name': name,
      'titleTemplate': titleTemplate,
      'bodyTemplate': bodyTemplate,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'defaultData': defaultData,
      'defaultChannels': defaultChannels.map((c) => c.toString().split('.').last).toList(),
      'defaultPriority': defaultPriority.toString().split('.').last,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String renderTitle(Map<String, dynamic> data) {
    String result = titleTemplate;
    data.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value.toString());
    });
    return result;
  }

  String renderBody(Map<String, dynamic> data) {
    String result = bodyTemplate;
    data.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value.toString());
    });
    return result;
  }
}

class NotificationBatch {
  final String id;
  final String name;
  final String? description;
  final NotificationType type;
  final List<String> userIds;
  final String titleTemplate;
  final String bodyTemplate;
  final String? imageUrl;
  final String? actionUrl;
  final Map<String, dynamic>? data;
  final List<NotificationChannel> channels;
  final NotificationPriority priority;
  final DateTime scheduledAt;
  final DateTime? sentAt;
  final DateTime? completedAt;
  final int totalCount;
  final int sentCount;
  final int deliveredCount;
  final int failedCount;
  final String status; // pending, sending, completed, failed
  final DateTime createdAt;
  final DateTime? updatedAt;

  NotificationBatch({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.userIds,
    required this.titleTemplate,
    required this.bodyTemplate,
    this.imageUrl,
    this.actionUrl,
    this.data,
    this.channels = const [NotificationChannel.inApp, NotificationChannel.push],
    this.priority = NotificationPriority.normal,
    required this.scheduledAt,
    this.sentAt,
    this.completedAt,
    required this.totalCount,
    this.sentCount = 0,
    this.deliveredCount = 0,
    this.failedCount = 0,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
  });

  factory NotificationBatch.fromMap(Map<String, dynamic> map) {
    return NotificationBatch(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${map['type']}',
        orElse: () => NotificationType.system,
      ),
      userIds: List<String>.from(map['userIds'] ?? []),
      titleTemplate: map['titleTemplate'] ?? '',
      bodyTemplate: map['bodyTemplate'] ?? '',
      imageUrl: map['imageUrl'],
      actionUrl: map['actionUrl'],
      data: map['data'],
      channels: (map['channels'] as List<dynamic>?)
          ?.map((channel) => NotificationChannel.values.firstWhere(
                (e) => e.toString() == 'NotificationChannel.$channel',
                orElse: () => NotificationChannel.inApp,
              ))
          .toList() ?? [NotificationChannel.inApp],
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString() == 'NotificationPriority.${map['priority']}',
        orElse: () => NotificationPriority.normal,
      ),
      scheduledAt: (map['scheduledAt'] as Timestamp).toDate(),
      sentAt: map['sentAt'] != null ? (map['sentAt'] as Timestamp).toDate() : null,
      completedAt: map['completedAt'] != null ? (map['completedAt'] as Timestamp).toDate() : null,
      totalCount: map['totalCount'] ?? 0,
      sentCount: map['sentCount'] ?? 0,
      deliveredCount: map['deliveredCount'] ?? 0,
      failedCount: map['failedCount'] ?? 0,
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'userIds': userIds,
      'titleTemplate': titleTemplate,
      'bodyTemplate': bodyTemplate,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'data': data,
      'channels': channels.map((c) => c.toString().split('.').last).toList(),
      'priority': priority.toString().split('.').last,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'totalCount': totalCount,
      'sentCount': sentCount,
      'deliveredCount': deliveredCount,
      'failedCount': failedCount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  double get successRate => totalCount > 0 ? (deliveredCount / totalCount) * 100 : 0.0;
  double get failureRate => totalCount > 0 ? (failedCount / totalCount) * 100 : 0.0;
  double get completionRate => totalCount > 0 ? (sentCount / totalCount) * 100 : 0.0;
  
  bool get isCompleted => status == 'completed';
  bool get isSending => status == 'sending';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
}

