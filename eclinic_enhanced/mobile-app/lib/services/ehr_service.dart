import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ehr_model.dart';

class EHRService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Patient Profile Management
  Future<String> createPatientProfile(PatientProfile profile) async {
    try {
      final docRef = await _firestore
          .collection('patient_profiles')
          .add(profile.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating patient profile: $e');
      rethrow;
    }
  }

  Future<PatientProfile?> getPatientProfile(String patientId) async {
    try {
      final doc = await _firestore
          .collection('patient_profiles')
          .doc(patientId)
          .get();

      if (doc.exists) {
        return PatientProfile.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      debugPrint('Error getting patient profile: $e');
      rethrow;
    }
  }

  Future<PatientProfile?> getPatientProfileByUserId(String userId) async {
    try {
      final query = await _firestore
          .collection('patient_profiles')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return PatientProfile.fromMap({...doc.data(), 'id': doc.id});
      }
      return null;
    } catch (e) {
      debugPrint('Error getting patient profile by user ID: $e');
      rethrow;
    }
  }

  Future<void> updatePatientProfile(PatientProfile profile) async {
    try {
      await _firestore
          .collection('patient_profiles')
          .doc(profile.id)
          .update({
        ...profile.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating patient profile: $e');
      rethrow;
    }
  }

  Future<List<PatientProfile>> searchPatients(String query) async {
    try {
      // Search by first name, last name, or email
      final firstNameQuery = await _firestore
          .collection('patient_profiles')
          .where('firstName', isGreaterThanOrEqualTo: query)
          .where('firstName', isLessThan: '${query}z')
          .get();

      final lastNameQuery = await _firestore
          .collection('patient_profiles')
          .where('lastName', isGreaterThanOrEqualTo: query)
          .where('lastName', isLessThan: '${query}z')
          .get();

      final Set<String> seenIds = {};
      final List<PatientProfile> results = [];

      for (final doc in [...firstNameQuery.docs, ...lastNameQuery.docs]) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          results.add(PatientProfile.fromMap({...doc.data(), 'id': doc.id}));
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error searching patients: $e');
      rethrow;
    }
  }

  // Medical History Management
  Future<String> addMedicalHistory(MedicalHistory history) async {
    try {
      final docRef = await _firestore
          .collection('medical_history')
          .add(history.toMap());
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding medical history: $e');
      rethrow;
    }
  }

  Future<List<MedicalHistory>> getPatientMedicalHistory(String patientId) async {
    try {
      final query = await _firestore
          .collection('medical_history')
          .where('patientId', isEqualTo: patientId)
          .orderBy('date', descending: true)
          .get();

      return query.docs
          .map((doc) => MedicalHistory.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting medical history: $e');
      rethrow;
    }
  }

  Future<void> updateMedicalHistory(MedicalHistory history) async {
    try {
      await _firestore
          .collection('medical_history')
          .doc(history.id)
          .update(history.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating medical history: $e');
      rethrow;
    }
  }

  Future<void> deleteMedicalHistory(String historyId) async {
    try {
      await _firestore
          .collection('medical_history')
          .doc(historyId)
          .delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting medical history: $e');
      rethrow;
    }
  }

  // Allergy Management
  Future<String> addAllergy(Allergy allergy) async {
    try {
      final docRef = await _firestore
          .collection('allergies')
          .add(allergy.toMap());
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding allergy: $e');
      rethrow;
    }
  }

  Future<List<Allergy>> getPatientAllergies(String patientId) async {
    try {
      final query = await _firestore
          .collection('allergies')
          .where('patientId', isEqualTo: patientId)
          .where('isActive', isEqualTo: true)
          .orderBy('severity', descending: true)
          .get();

      return query.docs
          .map((doc) => Allergy.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting allergies: $e');
      rethrow;
    }
  }

  Future<void> updateAllergy(Allergy allergy) async {
    try {
      await _firestore
          .collection('allergies')
          .doc(allergy.id)
          .update({
        ...allergy.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating allergy: $e');
      rethrow;
    }
  }

  Future<void> deactivateAllergy(String allergyId) async {
    try {
      await _firestore
          .collection('allergies')
          .doc(allergyId)
          .update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error deactivating allergy: $e');
      rethrow;
    }
  }

  // Vital Signs Management
  Future<String> addVitalSigns(VitalSigns vitals) async {
    try {
      final docRef = await _firestore
          .collection('vital_signs')
          .add(vitals.toMap());
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding vital signs: $e');
      rethrow;
    }
  }

  Future<List<VitalSigns>> getPatientVitalSigns(String patientId, {int? limit}) async {
    try {
      Query query = _firestore
          .collection('vital_signs')
          .where('patientId', isEqualTo: patientId)
          .orderBy('recordedAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final result = await query.get();
      return result.docs
          .map((doc) => VitalSigns.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting vital signs: $e');
      rethrow;
    }
  }

  Future<VitalSigns?> getLatestVitalSigns(String patientId) async {
    try {
      final vitals = await getPatientVitalSigns(patientId, limit: 1);
      return vitals.isNotEmpty ? vitals.first : null;
    } catch (e) {
      debugPrint('Error getting latest vital signs: $e');
      rethrow;
    }
  }

  Future<void> updateVitalSigns(VitalSigns vitals) async {
    try {
      await _firestore
          .collection('vital_signs')
          .doc(vitals.id)
          .update(vitals.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating vital signs: $e');
      rethrow;
    }
  }

  // Diagnosis Management
  Future<String> addDiagnosis(Diagnosis diagnosis) async {
    try {
      final docRef = await _firestore
          .collection('diagnoses')
          .add(diagnosis.toMap());
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding diagnosis: $e');
      rethrow;
    }
  }

  Future<List<Diagnosis>> getPatientDiagnoses(String patientId) async {
    try {
      final query = await _firestore
          .collection('diagnoses')
          .where('patientId', isEqualTo: patientId)
          .orderBy('diagnosedDate', descending: true)
          .get();

      return query.docs
          .map((doc) => Diagnosis.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting diagnoses: $e');
      rethrow;
    }
  }

  Future<List<Diagnosis>> getActiveDiagnoses(String patientId) async {
    try {
      final query = await _firestore
          .collection('diagnoses')
          .where('patientId', isEqualTo: patientId)
          .where('status', whereIn: ['active', 'chronic'])
          .orderBy('diagnosedDate', descending: true)
          .get();

      return query.docs
          .map((doc) => Diagnosis.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting active diagnoses: $e');
      rethrow;
    }
  }

  Future<void> updateDiagnosis(Diagnosis diagnosis) async {
    try {
      await _firestore
          .collection('diagnoses')
          .doc(diagnosis.id)
          .update({
        ...diagnosis.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating diagnosis: $e');
      rethrow;
    }
  }

  Future<void> resolveDiagnosis(String diagnosisId, DateTime resolvedDate) async {
    try {
      await _firestore
          .collection('diagnoses')
          .doc(diagnosisId)
          .update({
        'status': 'resolved',
        'resolvedDate': Timestamp.fromDate(resolvedDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error resolving diagnosis: $e');
      rethrow;
    }
  }

  // Medication Management
  Future<String> addMedication(Medication medication) async {
    try {
      final docRef = await _firestore
          .collection('medications')
          .add(medication.toMap());
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding medication: $e');
      rethrow;
    }
  }

  Future<List<Medication>> getPatientMedications(String patientId) async {
    try {
      final query = await _firestore
          .collection('medications')
          .where('patientId', isEqualTo: patientId)
          .orderBy('startDate', descending: true)
          .get();

      return query.docs
          .map((doc) => Medication.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting medications: $e');
      rethrow;
    }
  }

  Future<List<Medication>> getActiveMedications(String patientId) async {
    try {
      final query = await _firestore
          .collection('medications')
          .where('patientId', isEqualTo: patientId)
          .where('status', isEqualTo: 'active')
          .orderBy('startDate', descending: true)
          .get();

      return query.docs
          .map((doc) => Medication.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting active medications: $e');
      rethrow;
    }
  }

  Future<void> updateMedication(Medication medication) async {
    try {
      await _firestore
          .collection('medications')
          .doc(medication.id)
          .update({
        ...medication.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating medication: $e');
      rethrow;
    }
  }

  Future<void> discontinueMedication(String medicationId, DateTime endDate) async {
    try {
      await _firestore
          .collection('medications')
          .doc(medicationId)
          .update({
        'status': 'discontinued',
        'endDate': Timestamp.fromDate(endDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error discontinuing medication: $e');
      rethrow;
    }
  }

  // Comprehensive Patient Summary
  Future<Map<String, dynamic>> getPatientSummary(String patientId) async {
    try {
      final profile = await getPatientProfile(patientId);
      final allergies = await getPatientAllergies(patientId);
      final activeDiagnoses = await getActiveDiagnoses(patientId);
      final activeMedications = await getActiveMedications(patientId);
      final latestVitals = await getLatestVitalSigns(patientId);
      final recentHistory = await getPatientMedicalHistory(patientId);

      return {
        'profile': profile,
        'allergies': allergies,
        'activeDiagnoses': activeDiagnoses,
        'activeMedications': activeMedications,
        'latestVitals': latestVitals,
        'recentHistory': recentHistory.take(5).toList(),
      };
    } catch (e) {
      debugPrint('Error getting patient summary: $e');
      rethrow;
    }
  }

  // Health Analytics
  Future<Map<String, dynamic>> getHealthAnalytics(String patientId) async {
    try {
      final vitals = await getPatientVitalSigns(patientId, limit: 30);
      final medications = await getPatientMedications(patientId);
      final diagnoses = await getPatientDiagnoses(patientId);

      // Calculate trends and statistics
      final analytics = {
        'vitalsTrends': _calculateVitalsTrends(vitals),
        'medicationCompliance': _calculateMedicationCompliance(medications),
        'diagnosisHistory': _analyzeDiagnosisHistory(diagnoses),
        'riskFactors': _identifyRiskFactors(vitals, diagnoses, medications),
      };

      return analytics;
    } catch (e) {
      debugPrint('Error getting health analytics: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _calculateVitalsTrends(List<VitalSigns> vitals) {
    if (vitals.isEmpty) return {};

    final trends = <String, dynamic>{};
    
    // Blood pressure trend
    final bpReadings = vitals
        .where((v) => v.systolicBP != null && v.diastolicBP != null)
        .toList();
    if (bpReadings.isNotEmpty) {
      trends['bloodPressure'] = {
        'latest': '${bpReadings.first.systolicBP!.toInt()}/${bpReadings.first.diastolicBP!.toInt()}',
        'average': {
          'systolic': bpReadings.map((v) => v.systolicBP!).reduce((a, b) => a + b) / bpReadings.length,
          'diastolic': bpReadings.map((v) => v.diastolicBP!).reduce((a, b) => a + b) / bpReadings.length,
        },
        'trend': bpReadings.length > 1 ? 
            (bpReadings.first.systolicBP! > bpReadings.last.systolicBP! ? 'decreasing' : 'increasing') : 'stable',
      };
    }

    // Weight trend
    final weightReadings = vitals.where((v) => v.weight != null).toList();
    if (weightReadings.isNotEmpty) {
      trends['weight'] = {
        'latest': weightReadings.first.weight,
        'average': weightReadings.map((v) => v.weight!).reduce((a, b) => a + b) / weightReadings.length,
        'trend': weightReadings.length > 1 ?
            (weightReadings.first.weight! > weightReadings.last.weight! ? 'increasing' : 'decreasing') : 'stable',
      };
    }

    return trends;
  }

  Map<String, dynamic> _calculateMedicationCompliance(List<Medication> medications) {
    final activeMeds = medications.where((m) => m.isActive).length;
    final totalMeds = medications.length;
    
    return {
      'activeMedications': activeMeds,
      'totalMedications': totalMeds,
      'complianceRate': totalMeds > 0 ? (activeMeds / totalMeds) * 100 : 0,
    };
  }

  Map<String, dynamic> _analyzeDiagnosisHistory(List<Diagnosis> diagnoses) {
    final activeCount = diagnoses.where((d) => d.isActive).length;
    final resolvedCount = diagnoses.where((d) => d.status == DiagnosisStatus.resolved).length;
    final chronicCount = diagnoses.where((d) => d.status == DiagnosisStatus.chronic).length;

    return {
      'total': diagnoses.length,
      'active': activeCount,
      'resolved': resolvedCount,
      'chronic': chronicCount,
    };
  }

  List<String> _identifyRiskFactors(
    List<VitalSigns> vitals,
    List<Diagnosis> diagnoses,
    List<Medication> medications,
  ) {
    final riskFactors = <String>[];

    // Check latest vitals for risk factors
    if (vitals.isNotEmpty) {
      final latest = vitals.first;
      
      if (latest.systolicBP != null && latest.systolicBP! > 140) {
        riskFactors.add('High Blood Pressure');
      }
      
      if (latest.bmi != null && latest.bmi! > 30) {
        riskFactors.add('Obesity');
      }
      
      if (latest.bloodSugar != null && latest.bloodSugar! > 126) {
        riskFactors.add('High Blood Sugar');
      }
    }

    // Check for chronic conditions
    final chronicConditions = diagnoses
        .where((d) => d.status == DiagnosisStatus.chronic)
        .map((d) => d.condition)
        .toList();
    
    if (chronicConditions.contains('Diabetes')) {
      riskFactors.add('Diabetes');
    }
    
    if (chronicConditions.contains('Hypertension')) {
      riskFactors.add('Hypertension');
    }

    return riskFactors;
  }

  // Data Export
  Future<Map<String, dynamic>> exportPatientData(String patientId) async {
    try {
      final summary = await getPatientSummary(patientId);
      final analytics = await getHealthAnalytics(patientId);
      
      return {
        'exportDate': DateTime.now().toIso8601String(),
        'patientId': patientId,
        'summary': summary,
        'analytics': analytics,
      };
    } catch (e) {
      debugPrint('Error exporting patient data: $e');
      rethrow;
    }
  }
}

