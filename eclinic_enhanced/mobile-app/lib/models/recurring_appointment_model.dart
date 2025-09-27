import 'package:cloud_firestore/cloud_firestore.dart';

enum RecurrenceType {
  daily,
  weekly,
  biweekly,
  monthly,
  custom,
}

enum RecurrenceEndType {
  never,
  afterOccurrences,
  onDate,
}

class RecurringAppointment {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String specialization;
  final DateTime startDate;
  final String timeSlot;
  final RecurrenceType recurrenceType;
  final int recurrenceInterval; // e.g., every 2 weeks
  final List<int> daysOfWeek; // For weekly: [1,3,5] = Mon, Wed, Fri
  final RecurrenceEndType endType;
  final int? maxOccurrences;
  final DateTime? endDate;
  final String status; // 'active', 'paused', 'completed', 'cancelled'
  final String? reason;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? lastGeneratedDate;
  final int generatedCount;

  RecurringAppointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.specialization,
    required this.startDate,
    required this.timeSlot,
    required this.recurrenceType,
    this.recurrenceInterval = 1,
    this.daysOfWeek = const [],
    required this.endType,
    this.maxOccurrences,
    this.endDate,
    this.status = 'active',
    this.reason,
    this.metadata,
    required this.createdAt,
    this.lastGeneratedDate,
    this.generatedCount = 0,
  });

  factory RecurringAppointment.fromMap(Map<String, dynamic> map) {
    return RecurringAppointment(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      specialization: map['specialization'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      timeSlot: map['timeSlot'] ?? '',
      recurrenceType: RecurrenceType.values.firstWhere(
        (e) => e.toString() == 'RecurrenceType.${map['recurrenceType']}',
        orElse: () => RecurrenceType.weekly,
      ),
      recurrenceInterval: map['recurrenceInterval'] ?? 1,
      daysOfWeek: List<int>.from(map['daysOfWeek'] ?? []),
      endType: RecurrenceEndType.values.firstWhere(
        (e) => e.toString() == 'RecurrenceEndType.${map['endType']}',
        orElse: () => RecurrenceEndType.never,
      ),
      maxOccurrences: map['maxOccurrences'],
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      status: map['status'] ?? 'active',
      reason: map['reason'],
      metadata: map['metadata'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastGeneratedDate: map['lastGeneratedDate'] != null 
          ? (map['lastGeneratedDate'] as Timestamp).toDate() 
          : null,
      generatedCount: map['generatedCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'specialization': specialization,
      'startDate': Timestamp.fromDate(startDate),
      'timeSlot': timeSlot,
      'recurrenceType': recurrenceType.toString().split('.').last,
      'recurrenceInterval': recurrenceInterval,
      'daysOfWeek': daysOfWeek,
      'endType': endType.toString().split('.').last,
      'maxOccurrences': maxOccurrences,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'status': status,
      'reason': reason,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastGeneratedDate': lastGeneratedDate != null 
          ? Timestamp.fromDate(lastGeneratedDate!) 
          : null,
      'generatedCount': generatedCount,
    };
  }

  /// Generates the next appointment dates based on recurrence pattern
  List<DateTime> generateNextDates({int count = 10, DateTime? fromDate}) {
    final dates = <DateTime>[];
    final startFrom = fromDate ?? lastGeneratedDate ?? startDate;
    DateTime current = startFrom;

    // If we've reached the maximum occurrences, return empty list
    if (endType == RecurrenceEndType.afterOccurrences && 
        maxOccurrences != null && 
        generatedCount >= maxOccurrences!) {
      return dates;
    }

    int generated = 0;
    while (generated < count) {
      DateTime? nextDate;

      switch (recurrenceType) {
        case RecurrenceType.daily:
          nextDate = current.add(Duration(days: recurrenceInterval));
          break;

        case RecurrenceType.weekly:
          if (daysOfWeek.isEmpty) {
            // Same day of week
            nextDate = current.add(Duration(days: 7 * recurrenceInterval));
          } else {
            // Specific days of week
            nextDate = _getNextWeeklyDate(current);
          }
          break;

        case RecurrenceType.biweekly:
          nextDate = current.add(Duration(days: 14 * recurrenceInterval));
          break;

        case RecurrenceType.monthly:
          nextDate = DateTime(
            current.year,
            current.month + recurrenceInterval,
            current.day,
            current.hour,
            current.minute,
          );
          break;

        case RecurrenceType.custom:
          // Custom logic can be implemented based on metadata
          nextDate = current.add(Duration(days: recurrenceInterval));
          break;
      }

      if (nextDate == null) break;

      // Check if we've reached the end date
      if (endType == RecurrenceEndType.onDate && 
          endDate != null && 
          nextDate.isAfter(endDate!)) {
        break;
      }

      // Check if we've reached the maximum occurrences
      if (endType == RecurrenceEndType.afterOccurrences && 
          maxOccurrences != null && 
          (generatedCount + generated + 1) > maxOccurrences!) {
        break;
      }

      dates.add(nextDate);
      current = nextDate;
      generated++;
    }

    return dates;
  }

  DateTime? _getNextWeeklyDate(DateTime current) {
    // Find the next occurrence based on daysOfWeek
    for (int i = 1; i <= 7; i++) {
      final candidate = current.add(Duration(days: i));
      if (daysOfWeek.contains(candidate.weekday)) {
        return candidate;
      }
    }
    
    // If no day found in current week, move to next week
    final nextWeek = current.add(Duration(days: 7 * recurrenceInterval));
    for (int dayOfWeek in daysOfWeek) {
      final daysToAdd = (dayOfWeek - nextWeek.weekday) % 7;
      final candidate = nextWeek.add(Duration(days: daysToAdd));
      return candidate;
    }
    
    return null;
  }

  /// Checks if the recurring appointment should continue
  bool shouldContinue() {
    if (status != 'active') return false;

    switch (endType) {
      case RecurrenceEndType.never:
        return true;
      case RecurrenceEndType.afterOccurrences:
        return maxOccurrences == null || generatedCount < maxOccurrences!;
      case RecurrenceEndType.onDate:
        return endDate == null || DateTime.now().isBefore(endDate!);
    }
  }

  /// Creates a copy with updated fields
  RecurringAppointment copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? doctorName,
    String? specialization,
    DateTime? startDate,
    String? timeSlot,
    RecurrenceType? recurrenceType,
    int? recurrenceInterval,
    List<int>? daysOfWeek,
    RecurrenceEndType? endType,
    int? maxOccurrences,
    DateTime? endDate,
    String? status,
    String? reason,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? lastGeneratedDate,
    int? generatedCount,
  }) {
    return RecurringAppointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      specialization: specialization ?? this.specialization,
      startDate: startDate ?? this.startDate,
      timeSlot: timeSlot ?? this.timeSlot,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      endType: endType ?? this.endType,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      generatedCount: generatedCount ?? this.generatedCount,
    );
  }

  /// Gets a human-readable description of the recurrence pattern
  String getRecurrenceDescription() {
    switch (recurrenceType) {
      case RecurrenceType.daily:
        return recurrenceInterval == 1 
            ? 'Daily' 
            : 'Every $recurrenceInterval days';
      
      case RecurrenceType.weekly:
        if (daysOfWeek.isEmpty) {
          return recurrenceInterval == 1 
              ? 'Weekly' 
              : 'Every $recurrenceInterval weeks';
        } else {
          final dayNames = daysOfWeek.map(_getDayName).join(', ');
          return 'Weekly on $dayNames';
        }
      
      case RecurrenceType.biweekly:
        return recurrenceInterval == 1 
            ? 'Every 2 weeks' 
            : 'Every ${recurrenceInterval * 2} weeks';
      
      case RecurrenceType.monthly:
        return recurrenceInterval == 1 
            ? 'Monthly' 
            : 'Every $recurrenceInterval months';
      
      case RecurrenceType.custom:
        return 'Custom pattern';
    }
  }

  String _getDayName(int dayOfWeek) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dayOfWeek - 1];
  }

  /// Gets the end condition description
  String getEndDescription() {
    switch (endType) {
      case RecurrenceEndType.never:
        return 'Never ends';
      case RecurrenceEndType.afterOccurrences:
        return 'After $maxOccurrences appointments';
      case RecurrenceEndType.onDate:
        return 'Ends on ${endDate?.toString().split(' ')[0]}';
    }
  }
}

