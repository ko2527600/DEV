import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prescription_model.dart';

class PrescriptionService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Prescription Management
  Future<String> createPrescription(Prescription prescription) async {
    try {
      // Check for drug interactions before creating
      await _checkDrugInteractions(prescription.patientId, prescription.medicationName);
      
      final docRef = await _firestore
          .collection('prescriptions')
          .add(prescription.toMap());
      
      // Create medication adherence tracking
      await _initializeMedicationAdherence(docRef.id, prescription);
      
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating prescription: $e');
      rethrow;
    }
  }

  Future<Prescription?> getPrescription(String prescriptionId) async {
    try {
      final doc = await _firestore
          .collection('prescriptions')
          .doc(prescriptionId)
          .get();

      if (doc.exists) {
        return Prescription.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      debugPrint('Error getting prescription: $e');
      rethrow;
    }
  }

  Future<List<Prescription>> getPatientPrescriptions(String patientId) async {
    try {
      final query = await _firestore
          .collection('prescriptions')
          .where('patientId', isEqualTo: patientId)
          .orderBy('prescribedDate', descending: true)
          .get();

      return query.docs
          .map((doc) => Prescription.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting patient prescriptions: $e');
      rethrow;
    }
  }

  Future<List<Prescription>> getActivePrescriptions(String patientId) async {
    try {
      final query = await _firestore
          .collection('prescriptions')
          .where('patientId', isEqualTo: patientId)
          .where('status', isEqualTo: 'active')
          .orderBy('prescribedDate', descending: true)
          .get();

      return query.docs
          .map((doc) => Prescription.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting active prescriptions: $e');
      rethrow;
    }
  }

  Future<List<Prescription>> getDoctorPrescriptions(String doctorId) async {
    try {
      final query = await _firestore
          .collection('prescriptions')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('prescribedDate', descending: true)
          .get();

      return query.docs
          .map((doc) => Prescription.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting doctor prescriptions: $e');
      rethrow;
    }
  }

  Future<void> updatePrescription(Prescription prescription) async {
    try {
      await _firestore
          .collection('prescriptions')
          .doc(prescription.id)
          .update({
        ...prescription.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating prescription: $e');
      rethrow;
    }
  }

  Future<void> cancelPrescription(String prescriptionId, String reason) async {
    try {
      await _firestore
          .collection('prescriptions')
          .doc(prescriptionId)
          .update({
        'status': 'cancelled',
        'notes': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error cancelling prescription: $e');
      rethrow;
    }
  }

  Future<void> completePrescription(String prescriptionId) async {
    try {
      await _firestore
          .collection('prescriptions')
          .doc(prescriptionId)
          .update({
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing prescription: $e');
      rethrow;
    }
  }

  // Refill Management
  Future<String> requestRefill(RefillRequest refillRequest) async {
    try {
      // Check if prescription is eligible for refill
      final prescription = await getPrescription(refillRequest.prescriptionId);
      if (prescription == null || !prescription.canRefill) {
        throw Exception('Prescription is not eligible for refill');
      }

      final docRef = await _firestore
          .collection('refill_requests')
          .add(refillRequest.toMap());
      
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error requesting refill: $e');
      rethrow;
    }
  }

  Future<List<RefillRequest>> getPatientRefillRequests(String patientId) async {
    try {
      final query = await _firestore
          .collection('refill_requests')
          .where('patientId', isEqualTo: patientId)
          .orderBy('requestedDate', descending: true)
          .get();

      return query.docs
          .map((doc) => RefillRequest.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting refill requests: $e');
      rethrow;
    }
  }

  Future<List<RefillRequest>> getDoctorRefillRequests(String doctorId) async {
    try {
      final query = await _firestore
          .collection('refill_requests')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'requested')
          .orderBy('requestedDate', descending: true)
          .get();

      return query.docs
          .map((doc) => RefillRequest.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting doctor refill requests: $e');
      rethrow;
    }
  }

  Future<void> approveRefill(String refillRequestId, String prescriptionId) async {
    try {
      // Update refill request
      await _firestore
          .collection('refill_requests')
          .doc(refillRequestId)
          .update({
        'status': 'approved',
        'approvedDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Decrease refills remaining on prescription
      await _firestore
          .collection('prescriptions')
          .doc(prescriptionId)
          .update({
        'refillsRemaining': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error approving refill: $e');
      rethrow;
    }
  }

  Future<void> denyRefill(String refillRequestId, String reason) async {
    try {
      await _firestore
          .collection('refill_requests')
          .doc(refillRequestId)
          .update({
        'status': 'denied',
        'deniedDate': FieldValue.serverTimestamp(),
        'denialReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error denying refill: $e');
      rethrow;
    }
  }

  // Pharmacy Management
  Future<String> addPharmacy(Pharmacy pharmacy) async {
    try {
      final docRef = await _firestore
          .collection('pharmacies')
          .add(pharmacy.toMap());
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding pharmacy: $e');
      rethrow;
    }
  }

  Future<List<Pharmacy>> getPharmacies() async {
    try {
      final query = await _firestore
          .collection('pharmacies')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return query.docs
          .map((doc) => Pharmacy.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting pharmacies: $e');
      rethrow;
    }
  }

  Future<List<Pharmacy>> searchPharmacies(String query) async {
    try {
      final nameQuery = await _firestore
          .collection('pharmacies')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .where('isActive', isEqualTo: true)
          .get();

      return nameQuery.docs
          .map((doc) => Pharmacy.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error searching pharmacies: $e');
      rethrow;
    }
  }

  // Drug Interaction Checking
  Future<List<DrugInteraction>> checkDrugInteractions(String patientId, String newMedication) async {
    try {
      // Get patient's current medications
      final activePrescriptions = await getActivePrescriptions(patientId);
      final currentMedications = activePrescriptions.map((p) => p.medicationName).toList();

      final interactions = <DrugInteraction>[];

      // Check interactions with each current medication
      for (final medication in currentMedications) {
        final interactionQuery = await _firestore
            .collection('drug_interactions')
            .where('drug1', isEqualTo: medication)
            .where('drug2', isEqualTo: newMedication)
            .get();

        interactions.addAll(
          interactionQuery.docs.map((doc) => DrugInteraction.fromMap({...doc.data(), 'id': doc.id}))
        );

        // Check reverse combination
        final reverseQuery = await _firestore
            .collection('drug_interactions')
            .where('drug1', isEqualTo: newMedication)
            .where('drug2', isEqualTo: medication)
            .get();

        interactions.addAll(
          reverseQuery.docs.map((doc) => DrugInteraction.fromMap({...doc.data(), 'id': doc.id}))
        );
      }

      return interactions;
    } catch (e) {
      debugPrint('Error checking drug interactions: $e');
      rethrow;
    }
  }

  Future<void> _checkDrugInteractions(String patientId, String medication) async {
    final interactions = await checkDrugInteractions(patientId, medication);
    
    // Check for major interactions
    final majorInteractions = interactions.where((i) => i.severity == 'major').toList();
    if (majorInteractions.isNotEmpty) {
      debugPrint('Warning: Major drug interactions detected for $medication');
      // In a real app, this might throw an exception or require confirmation
    }
  }

  // Medication Adherence
  Future<void> recordMedicationTaken(String prescriptionId, String patientId, DateTime date, {String? notes}) async {
    try {
      final adherence = MedicationAdherence(
        id: '',
        prescriptionId: prescriptionId,
        patientId: patientId,
        date: date,
        taken: true,
        takenTime: DateTime.now(),
        notes: notes,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('medication_adherence')
          .add(adherence.toMap());
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error recording medication taken: $e');
      rethrow;
    }
  }

  Future<void> recordMedicationMissed(String prescriptionId, String patientId, DateTime date, {String? notes}) async {
    try {
      final adherence = MedicationAdherence(
        id: '',
        prescriptionId: prescriptionId,
        patientId: patientId,
        date: date,
        taken: false,
        notes: notes,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('medication_adherence')
          .add(adherence.toMap());
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error recording medication missed: $e');
      rethrow;
    }
  }

  Future<List<MedicationAdherence>> getMedicationAdherence(String prescriptionId, {int? days}) async {
    try {
      Query query = _firestore
          .collection('medication_adherence')
          .where('prescriptionId', isEqualTo: prescriptionId)
          .orderBy('date', descending: true);

      if (days != null) {
        final startDate = DateTime.now().subtract(Duration(days: days));
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      final result = await query.get();
      return result.docs
          .map((doc) => MedicationAdherence.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting medication adherence: $e');
      rethrow;
    }
  }

  Future<double> calculateAdherenceRate(String prescriptionId, int days) async {
    try {
      final adherenceRecords = await getMedicationAdherence(prescriptionId, days: days);
      
      if (adherenceRecords.isEmpty) return 0.0;
      
      final takenCount = adherenceRecords.where((record) => record.taken).length;
      return (takenCount / adherenceRecords.length) * 100;
    } catch (e) {
      debugPrint('Error calculating adherence rate: $e');
      return 0.0;
    }
  }

  Future<void> _initializeMedicationAdherence(String prescriptionId, Prescription prescription) async {
    // This would typically set up a schedule for medication adherence tracking
    // For now, we'll just create a placeholder
    debugPrint('Initialized medication adherence tracking for prescription: $prescriptionId');
  }

  // Prescription Analytics
  Future<Map<String, dynamic>> getPrescriptionAnalytics(String patientId) async {
    try {
      final prescriptions = await getPatientPrescriptions(patientId);
      
      final analytics = {
        'totalPrescriptions': prescriptions.length,
        'activePrescriptions': prescriptions.where((p) => p.isActive).length,
        'completedPrescriptions': prescriptions.where((p) => p.status == PrescriptionStatus.completed).length,
        'cancelledPrescriptions': prescriptions.where((p) => p.status == PrescriptionStatus.cancelled).length,
        'expiredPrescriptions': prescriptions.where((p) => p.isExpired).length,
        'prescriptionsWithRefills': prescriptions.where((p) => p.canRefill).length,
        'controlledSubstances': prescriptions.where((p) => p.isControlledSubstance).length,
        'averageAdherenceRate': await _calculateAverageAdherence(patientId),
        'commonMedications': _getCommonMedications(prescriptions),
        'prescribingDoctors': _getPrescribingDoctors(prescriptions),
      };

      return analytics;
    } catch (e) {
      debugPrint('Error getting prescription analytics: $e');
      rethrow;
    }
  }

  Future<double> _calculateAverageAdherence(String patientId) async {
    try {
      final activePrescriptions = await getActivePrescriptions(patientId);
      if (activePrescriptions.isEmpty) return 0.0;

      double totalAdherence = 0.0;
      int count = 0;

      for (final prescription in activePrescriptions) {
        final adherenceRate = await calculateAdherenceRate(prescription.id, 30);
        totalAdherence += adherenceRate;
        count++;
      }

      return count > 0 ? totalAdherence / count : 0.0;
    } catch (e) {
      debugPrint('Error calculating average adherence: $e');
      return 0.0;
    }
  }

  Map<String, int> _getCommonMedications(List<Prescription> prescriptions) {
    final medicationCounts = <String, int>{};
    
    for (final prescription in prescriptions) {
      medicationCounts[prescription.medicationName] = 
          (medicationCounts[prescription.medicationName] ?? 0) + 1;
    }

    // Sort by count and return top 5
    final sortedEntries = medicationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries.take(5));
  }

  Map<String, int> _getPrescribingDoctors(List<Prescription> prescriptions) {
    final doctorCounts = <String, int>{};
    
    for (final prescription in prescriptions) {
      doctorCounts[prescription.doctorName] = 
          (doctorCounts[prescription.doctorName] ?? 0) + 1;
    }

    return doctorCounts;
  }

  // Search and Filter
  Future<List<Prescription>> searchPrescriptions(String patientId, String query) async {
    try {
      final prescriptions = await getPatientPrescriptions(patientId);
      
      return prescriptions.where((prescription) {
        return prescription.medicationName.toLowerCase().contains(query.toLowerCase()) ||
               prescription.doctorName.toLowerCase().contains(query.toLowerCase()) ||
               (prescription.indication?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
    } catch (e) {
      debugPrint('Error searching prescriptions: $e');
      rethrow;
    }
  }

  Future<List<Prescription>> filterPrescriptions(
    String patientId, {
    PrescriptionStatus? status,
    String? doctorId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('prescriptions')
          .where('patientId', isEqualTo: patientId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.toString().split('.').last);
      }

      if (doctorId != null) {
        query = query.where('doctorId', isEqualTo: doctorId);
      }

      if (startDate != null) {
        query = query.where('prescribedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('prescribedDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final result = await query.orderBy('prescribedDate', descending: true).get();
      return result.docs
          .map((doc) => Prescription.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error filtering prescriptions: $e');
      rethrow;
    }
  }

  // Export Data
  Future<Map<String, dynamic>> exportPrescriptionData(String patientId) async {
    try {
      final prescriptions = await getPatientPrescriptions(patientId);
      final refillRequests = await getPatientRefillRequests(patientId);
      final analytics = await getPrescriptionAnalytics(patientId);

      return {
        'exportDate': DateTime.now().toIso8601String(),
        'patientId': patientId,
        'prescriptions': prescriptions.map((p) => p.toMap()).toList(),
        'refillRequests': refillRequests.map((r) => r.toMap()).toList(),
        'analytics': analytics,
      };
    } catch (e) {
      debugPrint('Error exporting prescription data: $e');
      rethrow;
    }
  }
}

