class DoctorAvailability {
  final String id;
  final String doctorId;
  final String dayOfWeek; // 'monday', 'tuesday', etc.
  final String startTime; // '09:00'
  final String endTime; // '17:00'
  final List<String> breakTimes; // ['12:00-13:00']
  final int slotDuration; // in minutes, e.g., 30
  final bool isActive;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;

  DoctorAvailability({
    required this.id,
    required this.doctorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.breakTimes = const [],
    this.slotDuration = 30,
    this.isActive = true,
    this.effectiveFrom,
    this.effectiveTo,
  });

  factory DoctorAvailability.fromMap(Map<String, dynamic> map) {
    return DoctorAvailability(
      id: map['id'] ?? '',
      doctorId: map['doctorId'] ?? '',
      dayOfWeek: map['dayOfWeek'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      breakTimes: List<String>.from(map['breakTimes'] ?? []),
      slotDuration: map['slotDuration'] ?? 30,
      isActive: map['isActive'] ?? true,
      effectiveFrom: map['effectiveFrom']?.toDate(),
      effectiveTo: map['effectiveTo']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'breakTimes': breakTimes,
      'slotDuration': slotDuration,
      'isActive': isActive,
      'effectiveFrom': effectiveFrom,
      'effectiveTo': effectiveTo,
    };
  }

  List<String> generateTimeSlots() {
    final slots = <String>[];
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    
    DateTime current = start;
    while (current.isBefore(end)) {
      final timeString = _formatTime(current);
      
      // Check if this time slot conflicts with break times
      bool isBreakTime = false;
      for (String breakTime in breakTimes) {
        final breakParts = breakTime.split('-');
        if (breakParts.length == 2) {
          final breakStart = _parseTime(breakParts[0]);
          final breakEnd = _parseTime(breakParts[1]);
          if (!current.isBefore(breakStart) && current.isBefore(breakEnd)) {
            isBreakTime = true;
            break;
          }
        }
      }
      
      if (!isBreakTime) {
        slots.add(timeString);
      }
      
      current = current.add(Duration(minutes: slotDuration));
    }
    
    return slots;
  }

  DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(2024, 1, 1, hour, minute);
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class TimeSlot {
  final String time;
  final bool isAvailable;
  final bool isBooked;
  final String? appointmentId;

  TimeSlot({
    required this.time,
    this.isAvailable = true,
    this.isBooked = false,
    this.appointmentId,
  });

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      time: map['time'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      isBooked: map['isBooked'] ?? false,
      appointmentId: map['appointmentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'isAvailable': isAvailable,
      'isBooked': isBooked,
      'appointmentId': appointmentId,
    };
  }
}

class DoctorSchedule {
  final String doctorId;
  final DateTime date;
  final List<TimeSlot> timeSlots;
  final bool isWorkingDay;
  final String? specialNotes;

  DoctorSchedule({
    required this.doctorId,
    required this.date,
    required this.timeSlots,
    this.isWorkingDay = true,
    this.specialNotes,
  });

  factory DoctorSchedule.fromMap(Map<String, dynamic> map) {
    return DoctorSchedule(
      doctorId: map['doctorId'] ?? '',
      date: map['date']?.toDate() ?? DateTime.now(),
      timeSlots: (map['timeSlots'] as List<dynamic>?)
          ?.map((slot) => TimeSlot.fromMap(slot))
          .toList() ?? [],
      isWorkingDay: map['isWorkingDay'] ?? true,
      specialNotes: map['specialNotes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'date': date,
      'timeSlots': timeSlots.map((slot) => slot.toMap()).toList(),
      'isWorkingDay': isWorkingDay,
      'specialNotes': specialNotes,
    };
  }

  List<TimeSlot> get availableSlots {
    return timeSlots.where((slot) => slot.isAvailable && !slot.isBooked).toList();
  }

  List<TimeSlot> get bookedSlots {
    return timeSlots.where((slot) => slot.isBooked).toList();
  }
}

