import 'package:cloud_firestore/cloud_firestore.dart';

enum PrescriptionStatus {
  pending,
  active,
  completed,
  cancelled,
  expired,
}

enum RefillStatus {
  available,
  requested,
  approved,
  denied,
  noRefillsLeft,
}

enum PrescriptionType {
  newPrescription,
  refill,
  modification,
  renewal,
}

enum DeliveryMethod {
  pickup,
  delivery,
  mail,
}

enum PrescriptionPriority {
  routine,
  urgent,
  stat,
}

class Prescription {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String medicationName;
  final String? genericName;
  final String? brandName;
  final String dosage;
  final String strength;
  final String form; // tablet, capsule, liquid, injection, etc.
  final String route; // oral, topical, injection, etc.
  final String frequency;
  final int quantity;
  final int? refillsRemaining;
  final int? totalRefills;
  final PrescriptionStatus status;
  final PrescriptionType type;
  final PrescriptionPriority priority;
  final DateTime prescribedDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? expiryDate;
  final String? instructions;
  final String? indication; // reason for prescription
  final String? notes;
  final String? pharmacyId;
  final String? pharmacyName;
  final DeliveryMethod? deliveryMethod;
  final List<String> warnings;
  final List<String> sideEffects;
  final Map<String, dynamic>? insuranceInfo;
  final double? cost;
  final bool isControlledSubstance;
  final String? dea; // DEA number for controlled substances
  final DateTime createdAt;
  final DateTime? updatedAt;

  Prescription({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.medicationName,
    this.genericName,
    this.brandName,
    required this.dosage,
    required this.strength,
    required this.form,
    required this.route,
    required this.frequency,
    required this.quantity,
    this.refillsRemaining,
    this.totalRefills,
    required this.status,
    required this.type,
    this.priority = PrescriptionPriority.routine,
    required this.prescribedDate,
    this.startDate,
    this.endDate,
    this.expiryDate,
    this.instructions,
    this.indication,
    this.notes,
    this.pharmacyId,
    this.pharmacyName,
    this.deliveryMethod,
    this.warnings = const [],
    this.sideEffects = const [],
    this.insuranceInfo,
    this.cost,
    this.isControlledSubstance = false,
    this.dea,
    required this.createdAt,
    this.updatedAt,
  });

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      medicationName: map['medicationName'] ?? '',
      genericName: map['genericName'],
      brandName: map['brandName'],
      dosage: map['dosage'] ?? '',
      strength: map['strength'] ?? '',
      form: map['form'] ?? '',
      route: map['route'] ?? '',
      frequency: map['frequency'] ?? '',
      quantity: map['quantity'] ?? 0,
      refillsRemaining: map['refillsRemaining'],
      totalRefills: map['totalRefills'],
      status: PrescriptionStatus.values.firstWhere(
        (e) => e.toString() == 'PrescriptionStatus.${map['status']}',
        orElse: () => PrescriptionStatus.pending,
      ),
      type: PrescriptionType.values.firstWhere(
        (e) => e.toString() == 'PrescriptionType.${map['type']}',
        orElse: () => PrescriptionType.newPrescription,
      ),
      priority: PrescriptionPriority.values.firstWhere(
        (e) => e.toString() == 'PrescriptionPriority.${map['priority']}',
        orElse: () => PrescriptionPriority.routine,
      ),
      prescribedDate: (map['prescribedDate'] as Timestamp).toDate(),
      startDate: map['startDate'] != null ? (map['startDate'] as Timestamp).toDate() : null,
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      expiryDate: map['expiryDate'] != null ? (map['expiryDate'] as Timestamp).toDate() : null,
      instructions: map['instructions'],
      indication: map['indication'],
      notes: map['notes'],
      pharmacyId: map['pharmacyId'],
      pharmacyName: map['pharmacyName'],
      deliveryMethod: map['deliveryMethod'] != null
          ? DeliveryMethod.values.firstWhere(
              (e) => e.toString() == 'DeliveryMethod.${map['deliveryMethod']}',
              orElse: () => DeliveryMethod.pickup,
            )
          : null,
      warnings: List<String>.from(map['warnings'] ?? []),
      sideEffects: List<String>.from(map['sideEffects'] ?? []),
      insuranceInfo: map['insuranceInfo'],
      cost: map['cost']?.toDouble(),
      isControlledSubstance: map['isControlledSubstance'] ?? false,
      dea: map['dea'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'medicationName': medicationName,
      'genericName': genericName,
      'brandName': brandName,
      'dosage': dosage,
      'strength': strength,
      'form': form,
      'route': route,
      'frequency': frequency,
      'quantity': quantity,
      'refillsRemaining': refillsRemaining,
      'totalRefills': totalRefills,
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'prescribedDate': Timestamp.fromDate(prescribedDate),
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'instructions': instructions,
      'indication': indication,
      'notes': notes,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'deliveryMethod': deliveryMethod?.toString().split('.').last,
      'warnings': warnings,
      'sideEffects': sideEffects,
      'insuranceInfo': insuranceInfo,
      'cost': cost,
      'isControlledSubstance': isControlledSubstance,
      'dea': dea,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get statusDisplayText {
    switch (status) {
      case PrescriptionStatus.pending:
        return 'Pending';
      case PrescriptionStatus.active:
        return 'Active';
      case PrescriptionStatus.completed:
        return 'Completed';
      case PrescriptionStatus.cancelled:
        return 'Cancelled';
      case PrescriptionStatus.expired:
        return 'Expired';
    }
  }

  String get typeDisplayText {
    switch (type) {
      case PrescriptionType.newPrescription:
        return 'New Prescription';
      case PrescriptionType.refill:
        return 'Refill';
      case PrescriptionType.modification:
        return 'Modification';
      case PrescriptionType.renewal:
        return 'Renewal';
    }
  }

  String get priorityDisplayText {
    switch (priority) {
      case PrescriptionPriority.routine:
        return 'Routine';
      case PrescriptionPriority.urgent:
        return 'Urgent';
      case PrescriptionPriority.stat:
        return 'STAT';
    }
  }

  String get deliveryMethodDisplayText {
    switch (deliveryMethod) {
      case DeliveryMethod.pickup:
        return 'Pickup';
      case DeliveryMethod.delivery:
        return 'Delivery';
      case DeliveryMethod.mail:
        return 'Mail';
      case null:
        return 'Not specified';
    }
  }

  String get displayName {
    if (brandName != null && brandName!.isNotEmpty) {
      return '$brandName ($medicationName)';
    } else if (genericName != null && genericName!.isNotEmpty) {
      return '$medicationName ($genericName)';
    }
    return medicationName;
  }

  String get fullDosageInfo => '$dosage $strength $form';

  bool get canRefill => 
      status == PrescriptionStatus.active && 
      refillsRemaining != null && 
      refillsRemaining! > 0 &&
      (expiryDate == null || expiryDate!.isAfter(DateTime.now()));

  bool get isExpired => 
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  bool get isActive => status == PrescriptionStatus.active && !isExpired;

  int get daysRemaining {
    if (endDate == null) return -1;
    return endDate!.difference(DateTime.now()).inDays;
  }

  RefillStatus get refillStatus {
    if (refillsRemaining == null || refillsRemaining! <= 0) {
      return RefillStatus.noRefillsLeft;
    }
    if (isExpired) {
      return RefillStatus.noRefillsLeft;
    }
    return RefillStatus.available;
  }
}

class RefillRequest {
  final String id;
  final String prescriptionId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String medicationName;
  final RefillStatus status;
  final DateTime requestedDate;
  final DateTime? approvedDate;
  final DateTime? deniedDate;
  final String? denialReason;
  final String? pharmacyId;
  final String? pharmacyName;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RefillRequest({
    required this.id,
    required this.prescriptionId,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.medicationName,
    required this.status,
    required this.requestedDate,
    this.approvedDate,
    this.deniedDate,
    this.denialReason,
    this.pharmacyId,
    this.pharmacyName,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory RefillRequest.fromMap(Map<String, dynamic> map) {
    return RefillRequest(
      id: map['id'] ?? '',
      prescriptionId: map['prescriptionId'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      medicationName: map['medicationName'] ?? '',
      status: RefillStatus.values.firstWhere(
        (e) => e.toString() == 'RefillStatus.${map['status']}',
        orElse: () => RefillStatus.requested,
      ),
      requestedDate: (map['requestedDate'] as Timestamp).toDate(),
      approvedDate: map['approvedDate'] != null ? (map['approvedDate'] as Timestamp).toDate() : null,
      deniedDate: map['deniedDate'] != null ? (map['deniedDate'] as Timestamp).toDate() : null,
      denialReason: map['denialReason'],
      pharmacyId: map['pharmacyId'],
      pharmacyName: map['pharmacyName'],
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prescriptionId': prescriptionId,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'medicationName': medicationName,
      'status': status.toString().split('.').last,
      'requestedDate': Timestamp.fromDate(requestedDate),
      'approvedDate': approvedDate != null ? Timestamp.fromDate(approvedDate!) : null,
      'deniedDate': deniedDate != null ? Timestamp.fromDate(deniedDate!) : null,
      'denialReason': denialReason,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get statusDisplayText {
    switch (status) {
      case RefillStatus.available:
        return 'Available';
      case RefillStatus.requested:
        return 'Requested';
      case RefillStatus.approved:
        return 'Approved';
      case RefillStatus.denied:
        return 'Denied';
      case RefillStatus.noRefillsLeft:
        return 'No Refills Left';
    }
  }
}

class Pharmacy {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String phoneNumber;
  final String? email;
  final String? website;
  final List<String> services; // delivery, 24hour, compounding, etc.
  final Map<String, String> hours; // day -> hours
  final bool isActive;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.phoneNumber,
    this.email,
    this.website,
    this.services = const [],
    this.hours = const {},
    this.isActive = true,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.updatedAt,
  });

  factory Pharmacy.fromMap(Map<String, dynamic> map) {
    return Pharmacy(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      zipCode: map['zipCode'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'],
      website: map['website'],
      services: List<String>.from(map['services'] ?? []),
      hours: Map<String, String>.from(map['hours'] ?? {}),
      isActive: map['isActive'] ?? true,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'phoneNumber': phoneNumber,
      'email': email,
      'website': website,
      'services': services,
      'hours': hours,
      'isActive': isActive,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get fullAddress => '$address, $city, $state $zipCode';

  bool get hasDelivery => services.contains('delivery');
  bool get is24Hour => services.contains('24hour');
  bool get hasCompounding => services.contains('compounding');
}

class DrugInteraction {
  final String id;
  final String drug1;
  final String drug2;
  final String severity; // minor, moderate, major
  final String description;
  final String? recommendation;
  final List<String> effects;
  final DateTime createdAt;

  DrugInteraction({
    required this.id,
    required this.drug1,
    required this.drug2,
    required this.severity,
    required this.description,
    this.recommendation,
    this.effects = const [],
    required this.createdAt,
  });

  factory DrugInteraction.fromMap(Map<String, dynamic> map) {
    return DrugInteraction(
      id: map['id'] ?? '',
      drug1: map['drug1'] ?? '',
      drug2: map['drug2'] ?? '',
      severity: map['severity'] ?? '',
      description: map['description'] ?? '',
      recommendation: map['recommendation'],
      effects: List<String>.from(map['effects'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'drug1': drug1,
      'drug2': drug2,
      'severity': severity,
      'description': description,
      'recommendation': recommendation,
      'effects': effects,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class MedicationAdherence {
  final String id;
  final String prescriptionId;
  final String patientId;
  final DateTime date;
  final bool taken;
  final DateTime? takenTime;
  final String? notes;
  final DateTime createdAt;

  MedicationAdherence({
    required this.id,
    required this.prescriptionId,
    required this.patientId,
    required this.date,
    required this.taken,
    this.takenTime,
    this.notes,
    required this.createdAt,
  });

  factory MedicationAdherence.fromMap(Map<String, dynamic> map) {
    return MedicationAdherence(
      id: map['id'] ?? '',
      prescriptionId: map['prescriptionId'] ?? '',
      patientId: map['patientId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      taken: map['taken'] ?? false,
      takenTime: map['takenTime'] != null ? (map['takenTime'] as Timestamp).toDate() : null,
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prescriptionId': prescriptionId,
      'patientId': patientId,
      'date': Timestamp.fromDate(date),
      'taken': taken,
      'takenTime': takenTime != null ? Timestamp.fromDate(takenTime!) : null,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

