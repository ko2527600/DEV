import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';

class PaymentService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Payment Management
  Future<String> createPayment(Payment payment) async {
    try {
      final docRef = await _firestore
          .collection('payments')
          .add(payment.toMap());
      
      // Create invoice if needed
      if (payment.type == PaymentType.consultation || payment.type == PaymentType.procedure) {
        await _createInvoice(docRef.id, payment);
      }
      
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating payment: $e');
      rethrow;
    }
  }

  Future<Payment?> getPayment(String paymentId) async {
    try {
      final doc = await _firestore
          .collection('payments')
          .doc(paymentId)
          .get();

      if (doc.exists) {
        return Payment.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      debugPrint('Error getting payment: $e');
      rethrow;
    }
  }

  Future<List<Payment>> getPatientPayments(String patientId) async {
    try {
      final query = await _firestore
          .collection('payments')
          .where('patientId', isEqualTo: patientId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => Payment.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting patient payments: $e');
      rethrow;
    }
  }

  Future<List<Payment>> getDoctorPayments(String doctorId) async {
    try {
      final query = await _firestore
          .collection('payments')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => Payment.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting doctor payments: $e');
      rethrow;
    }
  }

  Future<void> updatePaymentStatus(String paymentId, PaymentStatus status, {String? failureReason}) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == PaymentStatus.processing) {
        updateData['processedAt'] = FieldValue.serverTimestamp();
      } else if (status == PaymentStatus.completed) {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      } else if (status == PaymentStatus.failed && failureReason != null) {
        updateData['failureReason'] = failureReason;
      }

      await _firestore
          .collection('payments')
          .doc(paymentId)
          .update(updateData);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      rethrow;
    }
  }

  // Stripe Integration
  Future<Map<String, dynamic>> createStripePaymentIntent(Payment payment) async {
    try {
      // This would typically call a Firebase Function that creates a Stripe Payment Intent
      // For now, we'll return mock data
      final paymentIntentData = {
        'id': 'pi_mock_${DateTime.now().millisecondsSinceEpoch}',
        'client_secret': 'pi_mock_secret_${DateTime.now().millisecondsSinceEpoch}',
        'amount': (payment.totalAmount * 100).round(), // Stripe uses cents
        'currency': payment.currency.toLowerCase(),
        'status': 'requires_payment_method',
      };

      // Update payment with Stripe Payment Intent ID
      await _firestore
          .collection('payments')
          .doc(payment.id)
          .update({
        'stripePaymentIntentId': paymentIntentData['id'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return paymentIntentData;
    } catch (e) {
      debugPrint('Error creating Stripe payment intent: $e');
      rethrow;
    }
  }

  Future<bool> confirmStripePayment(String paymentId, String paymentMethodId) async {
    try {
      // This would typically call a Firebase Function that confirms the Stripe payment
      // For now, we'll simulate success
      await updatePaymentStatus(paymentId, PaymentStatus.processing);
      
      // Simulate processing delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Update to completed
      await updatePaymentStatus(paymentId, PaymentStatus.completed);
      
      return true;
    } catch (e) {
      debugPrint('Error confirming Stripe payment: $e');
      await updatePaymentStatus(paymentId, PaymentStatus.failed, failureReason: e.toString());
      return false;
    }
  }

  // PayPal Integration
  Future<Map<String, dynamic>> createPayPalOrder(Payment payment) async {
    try {
      // This would typically call a Firebase Function that creates a PayPal order
      final orderData = {
        'id': 'PAYPAL_ORDER_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'CREATED',
        'amount': payment.totalAmount,
        'currency': payment.currency,
        'approval_url': 'https://www.sandbox.paypal.com/checkoutnow?token=mock_token',
      };

      // Update payment with PayPal Order ID
      await _firestore
          .collection('payments')
          .doc(payment.id)
          .update({
        'paypalOrderId': orderData['id'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return orderData;
    } catch (e) {
      debugPrint('Error creating PayPal order: $e');
      rethrow;
    }
  }

  Future<bool> capturePayPalPayment(String paymentId, String orderId) async {
    try {
      // This would typically call a Firebase Function that captures the PayPal payment
      await updatePaymentStatus(paymentId, PaymentStatus.processing);
      
      // Simulate processing
      await Future.delayed(const Duration(seconds: 2));
      
      await updatePaymentStatus(paymentId, PaymentStatus.completed);
      return true;
    } catch (e) {
      debugPrint('Error capturing PayPal payment: $e');
      await updatePaymentStatus(paymentId, PaymentStatus.failed, failureReason: e.toString());
      return false;
    }
  }

  // Payment Methods Management
  Future<String> addPaymentMethod(PaymentMethod paymentMethod) async {
    try {
      // If this is set as default, unset other default methods
      if (paymentMethod.isDefault) {
        await _unsetDefaultPaymentMethods(paymentMethod.patientId);
      }

      final docRef = await _firestore
          .collection('payment_methods')
          .add(paymentMethod.toMap());
      
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding payment method: $e');
      rethrow;
    }
  }

  Future<List<PaymentMethod>> getPatientPaymentMethods(String patientId) async {
    try {
      final query = await _firestore
          .collection('payment_methods')
          .where('patientId', isEqualTo: patientId)
          .where('isActive', isEqualTo: true)
          .orderBy('isDefault', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => PaymentMethod.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting payment methods: $e');
      rethrow;
    }
  }

  Future<void> setDefaultPaymentMethod(String paymentMethodId, String patientId) async {
    try {
      // Unset all other default methods
      await _unsetDefaultPaymentMethods(patientId);
      
      // Set this one as default
      await _firestore
          .collection('payment_methods')
          .doc(paymentMethodId)
          .update({
        'isDefault': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting default payment method: $e');
      rethrow;
    }
  }

  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      await _firestore
          .collection('payment_methods')
          .doc(paymentMethodId)
          .update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting payment method: $e');
      rethrow;
    }
  }

  Future<void> _unsetDefaultPaymentMethods(String patientId) async {
    final query = await _firestore
        .collection('payment_methods')
        .where('patientId', isEqualTo: patientId)
        .where('isDefault', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {
        'isDefault': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // Refund Management
  Future<String> requestRefund(String paymentId, double amount, String reason) async {
    try {
      final refundData = {
        'paymentId': paymentId,
        'amount': amount,
        'reason': reason,
        'status': 'requested',
        'requestedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('refund_requests')
          .add(refundData);

      // Update payment refund status
      await _firestore
          .collection('payments')
          .doc(paymentId)
          .update({
        'refundStatus': RefundStatus.requested.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error requesting refund: $e');
      rethrow;
    }
  }

  Future<void> processRefund(String paymentId, double amount) async {
    try {
      // This would typically call a payment processor API to process the refund
      // For now, we'll simulate the process
      
      await _firestore
          .collection('payments')
          .doc(paymentId)
          .update({
        'refundStatus': RefundStatus.processing.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Simulate processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Complete the refund
      await _firestore
          .collection('payments')
          .doc(paymentId)
          .update({
        'refundStatus': RefundStatus.completed.toString().split('.').last,
        'refundedAmount': amount,
        'refundedAt': FieldValue.serverTimestamp(),
        'status': amount >= (await getPayment(paymentId))!.totalAmount 
            ? PaymentStatus.refunded.toString().split('.').last
            : PaymentStatus.partiallyRefunded.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error processing refund: $e');
      rethrow;
    }
  }

  // Invoice Management
  Future<String> _createInvoice(String paymentId, Payment payment) async {
    try {
      final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';
      
      final items = <InvoiceItem>[
        InvoiceItem(
          description: payment.description ?? payment.typeDisplayText,
          quantity: 1,
          unitPrice: payment.amount,
          totalPrice: payment.amount,
        ),
      ];

      final invoice = Invoice(
        id: '',
        paymentId: paymentId,
        patientId: payment.patientId,
        patientName: payment.patientName,
        doctorId: payment.doctorId,
        doctorName: payment.doctorName,
        invoiceNumber: invoiceNumber,
        issueDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 30)),
        items: items,
        subtotal: payment.amount,
        taxAmount: payment.taxAmount,
        discountAmount: payment.discountAmount,
        totalAmount: payment.totalAmount,
        currency: payment.currency,
        status: 'sent',
        billingAddress: payment.billingAddress,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('invoices')
          .add(invoice.toMap());

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating invoice: $e');
      rethrow;
    }
  }

  Future<List<Invoice>> getPatientInvoices(String patientId) async {
    try {
      final query = await _firestore
          .collection('invoices')
          .where('patientId', isEqualTo: patientId)
          .orderBy('issueDate', descending: true)
          .get();

      return query.docs
          .map((doc) => Invoice.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting patient invoices: $e');
      rethrow;
    }
  }

  Future<Invoice?> getInvoice(String invoiceId) async {
    try {
      final doc = await _firestore
          .collection('invoices')
          .doc(invoiceId)
          .get();

      if (doc.exists) {
        return Invoice.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      debugPrint('Error getting invoice: $e');
      rethrow;
    }
  }

  // Insurance Claims
  Future<String> submitInsuranceClaim(InsuranceClaim claim) async {
    try {
      final docRef = await _firestore
          .collection('insurance_claims')
          .add(claim.toMap());
      
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error submitting insurance claim: $e');
      rethrow;
    }
  }

  Future<List<InsuranceClaim>> getPatientInsuranceClaims(String patientId) async {
    try {
      final query = await _firestore
          .collection('insurance_claims')
          .where('patientId', isEqualTo: patientId)
          .orderBy('submittedDate', descending: true)
          .get();

      return query.docs
          .map((doc) => InsuranceClaim.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting insurance claims: $e');
      rethrow;
    }
  }

  // Payment Analytics
  Future<Map<String, dynamic>> getPaymentAnalytics(String patientId) async {
    try {
      final payments = await getPatientPayments(patientId);
      
      final totalPayments = payments.length;
      final completedPayments = payments.where((p) => p.isCompleted).length;
      final pendingPayments = payments.where((p) => p.isPending).length;
      final failedPayments = payments.where((p) => p.isFailed).length;
      
      final totalAmount = payments.fold<double>(0.0, (sum, payment) => sum + payment.totalAmount);
      final completedAmount = payments
          .where((p) => p.isCompleted)
          .fold<double>(0.0, (sum, payment) => sum + payment.totalAmount);
      
      // Payment methods breakdown
      final methodCounts = <String, int>{};
      for (final payment in payments) {
        final method = payment.methodDisplayText;
        methodCounts[method] = (methodCounts[method] ?? 0) + 1;
      }

      // Payment types breakdown
      final typeCounts = <String, int>{};
      for (final payment in payments) {
        final type = payment.typeDisplayText;
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }

      // Monthly spending
      final monthlySpending = <String, double>{};
      for (final payment in payments.where((p) => p.isCompleted)) {
        final monthKey = '${payment.completedAt!.year}-${payment.completedAt!.month.toString().padLeft(2, '0')}';
        monthlySpending[monthKey] = (monthlySpending[monthKey] ?? 0.0) + payment.totalAmount;
      }

      return {
        'totalPayments': totalPayments,
        'completedPayments': completedPayments,
        'pendingPayments': pendingPayments,
        'failedPayments': failedPayments,
        'totalAmount': totalAmount,
        'completedAmount': completedAmount,
        'averagePayment': completedPayments > 0 ? completedAmount / completedPayments : 0.0,
        'successRate': totalPayments > 0 ? (completedPayments / totalPayments) * 100 : 0.0,
        'paymentMethods': methodCounts,
        'paymentTypes': typeCounts,
        'monthlySpending': monthlySpending,
      };
    } catch (e) {
      debugPrint('Error getting payment analytics: $e');
      rethrow;
    }
  }

  // Search and Filter
  Future<List<Payment>> searchPayments(String patientId, String query) async {
    try {
      final payments = await getPatientPayments(patientId);
      
      return payments.where((payment) {
        return payment.description?.toLowerCase().contains(query.toLowerCase()) == true ||
               payment.typeDisplayText.toLowerCase().contains(query.toLowerCase()) ||
               payment.methodDisplayText.toLowerCase().contains(query.toLowerCase()) ||
               payment.invoiceNumber?.toLowerCase().contains(query.toLowerCase()) == true;
      }).toList();
    } catch (e) {
      debugPrint('Error searching payments: $e');
      rethrow;
    }
  }

  Future<List<Payment>> filterPayments(
    String patientId, {
    PaymentStatus? status,
    PaymentType? type,
    PaymentMethod? method,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('payments')
          .where('patientId', isEqualTo: patientId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.toString().split('.').last);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }

      if (method != null) {
        query = query.where('method', isEqualTo: method.toString().split('.').last);
      }

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final result = await query.orderBy('createdAt', descending: true).get();
      return result.docs
          .map((doc) => Payment.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error filtering payments: $e');
      rethrow;
    }
  }

  // Export Data
  Future<Map<String, dynamic>> exportPaymentData(String patientId) async {
    try {
      final payments = await getPatientPayments(patientId);
      final invoices = await getPatientInvoices(patientId);
      final claims = await getPatientInsuranceClaims(patientId);
      final analytics = await getPaymentAnalytics(patientId);

      return {
        'exportDate': DateTime.now().toIso8601String(),
        'patientId': patientId,
        'payments': payments.map((p) => p.toMap()).toList(),
        'invoices': invoices.map((i) => i.toMap()).toList(),
        'insuranceClaims': claims.map((c) => c.toMap()).toList(),
        'analytics': analytics,
      };
    } catch (e) {
      debugPrint('Error exporting payment data: $e');
      rethrow;
    }
  }

  // Subscription Management
  Future<String> createSubscription(String patientId, String planId, double amount) async {
    try {
      final subscriptionData = {
        'patientId': patientId,
        'planId': planId,
        'amount': amount,
        'status': 'active',
        'startDate': FieldValue.serverTimestamp(),
        'nextBillingDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('subscriptions')
          .add(subscriptionData);
      
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating subscription: $e');
      rethrow;
    }
  }

  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      await _firestore
          .collection('subscriptions')
          .doc(subscriptionId)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error cancelling subscription: $e');
      rethrow;
    }
  }

  // Billing Address Management
  Future<void> updateBillingAddress(String patientId, Map<String, dynamic> address) async {
    try {
      await _firestore
          .collection('billing_addresses')
          .doc(patientId)
          .set({
        'patientId': patientId,
        'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating billing address: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getBillingAddress(String patientId) async {
    try {
      final doc = await _firestore
          .collection('billing_addresses')
          .doc(patientId)
          .get();

      if (doc.exists) {
        return doc.data()?['address'];
      }
      return null;
    } catch (e) {
      debugPrint('Error getting billing address: $e');
      rethrow;
    }
  }
}

