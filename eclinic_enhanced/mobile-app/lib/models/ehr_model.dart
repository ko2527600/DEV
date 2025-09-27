import 'package:cloud_firestore/cloud_firestore.dart';

enum BloodType {
  aPositive,
  aNegative,
  bPositive,
  bNegative,
  abPositive,
  abNegative,
  oPositive,
  oNegative,
  unknown,
}

enum Gender {
  male,
  female,
  other,
  preferNotToSay,
}

enum AllergyType {
  medication,
  food,
  environmental,
  other,
}

enum AllergySeverity {
  mild,
  moderate,
  severe,
  lifeThreatening,
}

enum VitalType {
  bloodPressure,
  heartRate,
  temperature,
  weight,
  height,
  oxygenSaturation,
  bloodSugar,
  respiratoryRate,
}

enum DiagnosisStatus {
  active,
  resolved,
  chronic,
  suspected,
  ruled_out,
}

enum MedicationStatus {
  active,
  completed,
  discontinued,
  onHold,
}

class PatientProfile {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final Gender gender;
  final BloodType bloodType;
  final String? phoneNumber;
  final String? email;
  final Address? address;
  final EmergencyContact? emergencyContact;
  final String? insuranceProvider;
  final String? insurancePolicyNumber;
  final String? primaryDoctorId;
  final List<String> allergies;
  final List<String> chronicConditions;
  final Map<String, dynamic>? preferences;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PatientProfile({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    this.bloodType = BloodType.unknown,
    this.phoneNumber,
    this.email,
    this.address,
    this.emergencyContact,
    this.insuranceProvider,
    this.insurancePolicyNumber,
    this.primaryDoctorId,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.preferences,
    required this.createdAt,
    this.updatedAt,
  });

  factory PatientProfile.fromMap(Map<String, dynamic> map) {
    return PatientProfile(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      dateOfBirth: (map['dateOfBirth'] as Timestamp).toDate(),
      gender: Gender.values.firstWhere(
        (e) => e.toString() == 'Gender.${map['gender']}',
        orElse: () => Gender.preferNotToSay,
      ),
      bloodType: BloodType.values.firstWhere(
        (e) => e.toString() == 'BloodType.${map['bloodType']}',
        orElse: () => BloodType.unknown,
      ),
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      address: map['address'] != null ? Address.fromMap(map['address']) : null,
      emergencyContact: map['emergencyContact'] != null 
          ? EmergencyContact.fromMap(map['emergencyContact']) 
          : null,
      insuranceProvider: map['insuranceProvider'],
      insurancePolicyNumber: map['insurancePolicyNumber'],
      primaryDoctorId: map['primaryDoctorId'],
      allergies: List<String>.from(map['allergies'] ?? []),
      chronicConditions: List<String>.from(map['chronicConditions'] ?? []),
      preferences: map['preferences'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender.toString().split('.').last,
      'bloodType': bloodType.toString().split('.').last,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address?.toMap(),
      'emergencyContact': emergencyContact?.toMap(),
      'insuranceProvider': insuranceProvider,
      'insurancePolicyNumber': insurancePolicyNumber,
      'primaryDoctorId': primaryDoctorId,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'preferences': preferences,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get fullName => '$firstName $lastName';
  int get age => DateTime.now().difference(dateOfBirth).inDays ~/ 365;

  String get bloodTypeDisplayText {
    switch (bloodType) {
      case BloodType.aPositive:
        return 'A+';
      case BloodType.aNegative:
        return 'A-';
      case BloodType.bPositive:
        return 'B+';
      case BloodType.bNegative:
        return 'B-';
      case BloodType.abPositive:
        return 'AB+';
      case BloodType.abNegative:
        return 'AB-';
      case BloodType.oPositive:
        return 'O+';
      case BloodType.oNegative:
        return 'O-';
      case BloodType.unknown:
        return 'Unknown';
    }
  }

  String get genderDisplayText {
    switch (gender) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
      case Gender.preferNotToSay:
        return 'Prefer not to say';
    }
  }
}

class Address {
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
  });

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      zipCode: map['zipCode'] ?? '',
      country: map['country'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
    };
  }

  String get fullAddress => '$street, $city, $state $zipCode, $country';
}

class EmergencyContact {
  final String name;
  final String relationship;
  final String phoneNumber;
  final String? email;

  EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    this.email,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? '',
      relationship: map['relationship'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relationship': relationship,
      'phoneNumber': phoneNumber,
      'email': email,
    };
  }
}

class MedicalHistory {
  final String id;
  final String patientId;
  final String title;
  final String description;
  final DateTime date;
  final String? doctorId;
  final String? doctorName;
  final List<String> attachments;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  MedicalHistory({
    required this.id,
    required this.patientId,
    required this.title,
    required this.description,
    required this.date,
    this.doctorId,
    this.doctorName,
    this.attachments = const [],
    this.metadata,
    required this.createdAt,
  });

  factory MedicalHistory.fromMap(Map<String, dynamic> map) {
    return MedicalHistory(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      doctorId: map['doctorId'],
      doctorName: map['doctorName'],
      attachments: List<String>.from(map['attachments'] ?? []),
      metadata: map['metadata'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'doctorId': doctorId,
      'doctorName': doctorName,
      'attachments': attachments,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class Allergy {
  final String id;
  final String patientId;
  final String allergen;
  final AllergyType type;
  final AllergySeverity severity;
  final String? reaction;
  final String? notes;
  final DateTime? onsetDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Allergy({
    required this.id,
    required this.patientId,
    required this.allergen,
    required this.type,
    required this.severity,
    this.reaction,
    this.notes,
    this.onsetDate,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Allergy.fromMap(Map<String, dynamic> map) {
    return Allergy(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      allergen: map['allergen'] ?? '',
      type: AllergyType.values.firstWhere(
        (e) => e.toString() == 'AllergyType.${map['type']}',
        orElse: () => AllergyType.other,
      ),
      severity: AllergySeverity.values.firstWhere(
        (e) => e.toString() == 'AllergySeverity.${map['severity']}',
        orElse: () => AllergySeverity.mild,
      ),
      reaction: map['reaction'],
      notes: map['notes'],
      onsetDate: map['onsetDate'] != null ? (map['onsetDate'] as Timestamp).toDate() : null,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'allergen': allergen,
      'type': type.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'reaction': reaction,
      'notes': notes,
      'onsetDate': onsetDate != null ? Timestamp.fromDate(onsetDate!) : null,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get typeDisplayText {
    switch (type) {
      case AllergyType.medication:
        return 'Medication';
      case AllergyType.food:
        return 'Food';
      case AllergyType.environmental:
        return 'Environmental';
      case AllergyType.other:
        return 'Other';
    }
  }

  String get severityDisplayText {
    switch (severity) {
      case AllergySeverity.mild:
        return 'Mild';
      case AllergySeverity.moderate:
        return 'Moderate';
      case AllergySeverity.severe:
        return 'Severe';
      case AllergySeverity.lifeThreatening:
        return 'Life Threatening';
    }
  }
}

class VitalSigns {
  final String id;
  final String patientId;
  final DateTime recordedAt;
  final String? recordedBy;
  final double? systolicBP;
  final double? diastolicBP;
  final double? heartRate;
  final double? temperature;
  final double? weight;
  final double? height;
  final double? oxygenSaturation;
  final double? bloodSugar;
  final double? respiratoryRate;
  final String? notes;
  final DateTime createdAt;

  VitalSigns({
    required this.id,
    required this.patientId,
    required this.recordedAt,
    this.recordedBy,
    this.systolicBP,
    this.diastolicBP,
    this.heartRate,
    this.temperature,
    this.weight,
    this.height,
    this.oxygenSaturation,
    this.bloodSugar,
    this.respiratoryRate,
    this.notes,
    required this.createdAt,
  });

  factory VitalSigns.fromMap(Map<String, dynamic> map) {
    return VitalSigns(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      recordedAt: (map['recordedAt'] as Timestamp).toDate(),
      recordedBy: map['recordedBy'],
      systolicBP: map['systolicBP']?.toDouble(),
      diastolicBP: map['diastolicBP']?.toDouble(),
      heartRate: map['heartRate']?.toDouble(),
      temperature: map['temperature']?.toDouble(),
      weight: map['weight']?.toDouble(),
      height: map['height']?.toDouble(),
      oxygenSaturation: map['oxygenSaturation']?.toDouble(),
      bloodSugar: map['bloodSugar']?.toDouble(),
      respiratoryRate: map['respiratoryRate']?.toDouble(),
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'recordedBy': recordedBy,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'heartRate': heartRate,
      'temperature': temperature,
      'weight': weight,
      'height': height,
      'oxygenSaturation': oxygenSaturation,
      'bloodSugar': bloodSugar,
      'respiratoryRate': respiratoryRate,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String? get bloodPressure {
    if (systolicBP != null && diastolicBP != null) {
      return '${systolicBP!.toInt()}/${diastolicBP!.toInt()}';
    }
    return null;
  }

  double? get bmi {
    if (weight != null && height != null && height! > 0) {
      final heightInMeters = height! / 100;
      return weight! / (heightInMeters * heightInMeters);
    }
    return null;
  }

  String? get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return null;
    
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }
}

class Diagnosis {
  final String id;
  final String patientId;
  final String condition;
  final String? icdCode;
  final DiagnosisStatus status;
  final DateTime diagnosedDate;
  final String? diagnosedBy;
  final String? notes;
  final DateTime? resolvedDate;
  final List<String> symptoms;
  final List<String> treatments;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Diagnosis({
    required this.id,
    required this.patientId,
    required this.condition,
    this.icdCode,
    required this.status,
    required this.diagnosedDate,
    this.diagnosedBy,
    this.notes,
    this.resolvedDate,
    this.symptoms = const [],
    this.treatments = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory Diagnosis.fromMap(Map<String, dynamic> map) {
    return Diagnosis(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      condition: map['condition'] ?? '',
      icdCode: map['icdCode'],
      status: DiagnosisStatus.values.firstWhere(
        (e) => e.toString() == 'DiagnosisStatus.${map['status']}',
        orElse: () => DiagnosisStatus.active,
      ),
      diagnosedDate: (map['diagnosedDate'] as Timestamp).toDate(),
      diagnosedBy: map['diagnosedBy'],
      notes: map['notes'],
      resolvedDate: map['resolvedDate'] != null ? (map['resolvedDate'] as Timestamp).toDate() : null,
      symptoms: List<String>.from(map['symptoms'] ?? []),
      treatments: List<String>.from(map['treatments'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'condition': condition,
      'icdCode': icdCode,
      'status': status.toString().split('.').last,
      'diagnosedDate': Timestamp.fromDate(diagnosedDate),
      'diagnosedBy': diagnosedBy,
      'notes': notes,
      'resolvedDate': resolvedDate != null ? Timestamp.fromDate(resolvedDate!) : null,
      'symptoms': symptoms,
      'treatments': treatments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get statusDisplayText {
    switch (status) {
      case DiagnosisStatus.active:
        return 'Active';
      case DiagnosisStatus.resolved:
        return 'Resolved';
      case DiagnosisStatus.chronic:
        return 'Chronic';
      case DiagnosisStatus.suspected:
        return 'Suspected';
      case DiagnosisStatus.ruled_out:
        return 'Ruled Out';
    }
  }

  bool get isActive => status == DiagnosisStatus.active || status == DiagnosisStatus.chronic;
}

class Medication {
  final String id;
  final String patientId;
  final String medicationName;
  final String? genericName;
  final String dosage;
  final String frequency;
  final String route; // oral, injection, topical, etc.
  final MedicationStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final String? prescribedBy;
  final String? instructions;
  final String? sideEffects;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Medication({
    required this.id,
    required this.patientId,
    required this.medicationName,
    this.genericName,
    required this.dosage,
    required this.frequency,
    required this.route,
    required this.status,
    required this.startDate,
    this.endDate,
    this.prescribedBy,
    this.instructions,
    this.sideEffects,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      medicationName: map['medicationName'] ?? '',
      genericName: map['genericName'],
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      route: map['route'] ?? '',
      status: MedicationStatus.values.firstWhere(
        (e) => e.toString() == 'MedicationStatus.${map['status']}',
        orElse: () => MedicationStatus.active,
      ),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      prescribedBy: map['prescribedBy'],
      instructions: map['instructions'],
      sideEffects: map['sideEffects'],
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'medicationName': medicationName,
      'genericName': genericName,
      'dosage': dosage,
      'frequency': frequency,
      'route': route,
      'status': status.toString().split('.').last,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'prescribedBy': prescribedBy,
      'instructions': instructions,
      'sideEffects': sideEffects,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get statusDisplayText {
    switch (status) {
      case MedicationStatus.active:
        return 'Active';
      case MedicationStatus.completed:
        return 'Completed';
      case MedicationStatus.discontinued:
        return 'Discontinued';
      case MedicationStatus.onHold:
        return 'On Hold';
    }
  }

  bool get isActive => status == MedicationStatus.active;
  
  String get displayName => genericName != null && genericName!.isNotEmpty 
      ? '$medicationName ($genericName)' 
      : medicationName;
}

