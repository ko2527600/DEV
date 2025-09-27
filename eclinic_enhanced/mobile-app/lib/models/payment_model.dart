import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
  partiallyRefunded,
}

enum PaymentMethod {
  creditCard,
  debitCard,
  paypal,
  applePay,
  googlePay,
  bankTransfer,
  cash,
  insurance,
}

enum PaymentType {
  consultation,
  prescription,
  labTest,
  procedure,
  subscription,
  copay,
  deductible,
  other,
}

enum RefundStatus {
  none,
  requested,
  processing,
  completed,
  denied,
}

class Payment {
  final String id;
  final String patientId;
  final String patientName;
  final String? doctorId;
  final String? doctorName;
  final String? appointmentId;
  final String? prescriptionId;
  final PaymentType type;
  final PaymentMethod method;
  final PaymentStatus status;
  final double amount;
  final double? taxAmount;
  final double? discountAmount;
  final double totalAmount;
  final String currency;
  final String? description;
  final String? invoiceNumber;
  final String? transactionId;
  final String? stripePaymentIntentId;
  final String? paypalOrderId;
  final Map<String, dynamic>? paymentMethodDetails;
  final Map<String, dynamic>? billingAddress;
  final Map<String, dynamic>? insuranceInfo;
  final DateTime createdAt;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final String? failureReason;
  final List<String> receiptUrls;
  final RefundStatus refundStatus;
  final double? refundedAmount;
  final DateTime? refundedAt;
  final String? refundReason;
  final Map<String, dynamic>? metadata;

  Payment({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.doctorId,
    this.doctorName,
    this.appointmentId,
    this.prescriptionId,
    required this.type,
    required this.method,
    required this.status,
    required this.amount,
    this.taxAmount,
    this.discountAmount,
    required this.totalAmount,
    this.currency = 'USD',
    this.description,
    this.invoiceNumber,
    this.transactionId,
    this.stripePaymentIntentId,
    this.paypalOrderId,
    this.paymentMethodDetails,
    this.billingAddress,
    this.insuranceInfo,
    required this.createdAt,
    this.processedAt,
    this.completedAt,
    this.failureReason,
    this.receiptUrls = const [],
    this.refundStatus = RefundStatus.none,
    this.refundedAmount,
    this.refundedAt,
    this.refundReason,
    this.metadata,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorId: map['doctorId'],
      doctorName: map['doctorName'],
      appointmentId: map['appointmentId'],
      prescriptionId: map['prescriptionId'],
      type: PaymentType.values.firstWhere(
        (e) => e.toString() == 'PaymentType.${map['type']}',
        orElse: () => PaymentType.other,
      ),
      method: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${map['method']}',
        orElse: () => PaymentMethod.creditCard,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${map['status']}',
        orElse: () => PaymentStatus.pending,
      ),
      amount: map['amount']?.toDouble() ?? 0.0,
      taxAmount: map['taxAmount']?.toDouble(),
      discountAmount: map['discountAmount']?.toDouble(),
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'USD',
      description: map['description'],
      invoiceNumber: map['invoiceNumber'],
      transactionId: map['transactionId'],
      stripePaymentIntentId: map['stripePaymentIntentId'],
      paypalOrderId: map['paypalOrderId'],
      paymentMethodDetails: map['paymentMethodDetails'],
      billingAddress: map['billingAddress'],
      insuranceInfo: map['insuranceInfo'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      processedAt: map['processedAt'] != null ? (map['processedAt'] as Timestamp).toDate() : null,
      completedAt: map['completedAt'] != null ? (map['completedAt'] as Timestamp).toDate() : null,
      failureReason: map['failureReason'],
      receiptUrls: List<String>.from(map['receiptUrls'] ?? []),
      refundStatus: RefundStatus.values.firstWhere(
        (e) => e.toString() == 'RefundStatus.${map['refundStatus']}',
        orElse: () => RefundStatus.none,
      ),
      refundedAmount: map['refundedAmount']?.toDouble(),
      refundedAt: map['refundedAt'] != null ? (map['refundedAt'] as Timestamp).toDate() : null,
      refundReason: map['refundReason'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'appointmentId': appointmentId,
      'prescriptionId': prescriptionId,
      'type': type.toString().split('.').last,
      'method': method.toString().split('.').last,
      'status': status.toString().split('.').last,
      'amount': amount,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'currency': currency,
      'description': description,
      'invoiceNumber': invoiceNumber,
      'transactionId': transactionId,
      'stripePaymentIntentId': stripePaymentIntentId,
      'paypalOrderId': paypalOrderId,
      'paymentMethodDetails': paymentMethodDetails,
      'billingAddress': billingAddress,
      'insuranceInfo': insuranceInfo,
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'failureReason': failureReason,
      'receiptUrls': receiptUrls,
      'refundStatus': refundStatus.toString().split('.').last,
      'refundedAmount': refundedAmount,
      'refundedAt': refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
      'refundReason': refundReason,
      'metadata': metadata,
    };
  }

  String get statusDisplayText {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.partiallyRefunded:
        return 'Partially Refunded';
    }
  }

  String get typeDisplayText {
    switch (type) {
      case PaymentType.consultation:
        return 'Consultation';
      case PaymentType.prescription:
        return 'Prescription';
      case PaymentType.labTest:
        return 'Lab Test';
      case PaymentType.procedure:
        return 'Procedure';
      case PaymentType.subscription:
        return 'Subscription';
      case PaymentType.copay:
        return 'Co-pay';
      case PaymentType.deductible:
        return 'Deductible';
      case PaymentType.other:
        return 'Other';
    }
  }

  String get methodDisplayText {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.googlePay:
        return 'Google Pay';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.insurance:
        return 'Insurance';
    }
  }

  String get refundStatusDisplayText {
    switch (refundStatus) {
      case RefundStatus.none:
        return 'No Refund';
      case RefundStatus.requested:
        return 'Refund Requested';
      case RefundStatus.processing:
        return 'Processing Refund';
      case RefundStatus.completed:
        return 'Refunded';
      case RefundStatus.denied:
        return 'Refund Denied';
    }
  }

  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';
  String get formattedTotalAmount => '\$${totalAmount.toStringAsFixed(2)}';
  String get formattedRefundedAmount => refundedAmount != null ? '\$${refundedAmount!.toStringAsFixed(2)}' : '\$0.00';

  bool get isCompleted => status == PaymentStatus.completed;
  bool get isPending => status == PaymentStatus.pending || status == PaymentStatus.processing;
  bool get isFailed => status == PaymentStatus.failed || status == PaymentStatus.cancelled;
  bool get canRefund => isCompleted && refundStatus == RefundStatus.none;
}

class PaymentMethod {
  final String id;
  final String patientId;
  final String type; // card, paypal, bank_account
  final String? last4;
  final String? brand; // visa, mastercard, amex
  final String? expiryMonth;
  final String? expiryYear;
  final String? holderName;
  final Map<String, dynamic>? billingAddress;
  final bool isDefault;
  final bool isActive;
  final String? stripePaymentMethodId;
  final String? paypalEmail;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentMethod({
    required this.id,
    required this.patientId,
    required this.type,
    this.last4,
    this.brand,
    this.expiryMonth,
    this.expiryYear,
    this.holderName,
    this.billingAddress,
    this.isDefault = false,
    this.isActive = true,
    this.stripePaymentMethodId,
    this.paypalEmail,
    required this.createdAt,
    this.updatedAt,
  });

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      type: map['type'] ?? '',
      last4: map['last4'],
      brand: map['brand'],
      expiryMonth: map['expiryMonth'],
      expiryYear: map['expiryYear'],
      holderName: map['holderName'],
      billingAddress: map['billingAddress'],
      isDefault: map['isDefault'] ?? false,
      isActive: map['isActive'] ?? true,
      stripePaymentMethodId: map['stripePaymentMethodId'],
      paypalEmail: map['paypalEmail'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'type': type,
      'last4': last4,
      'brand': brand,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'holderName': holderName,
      'billingAddress': billingAddress,
      'isDefault': isDefault,
      'isActive': isActive,
      'stripePaymentMethodId': stripePaymentMethodId,
      'paypalEmail': paypalEmail,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get displayText {
    if (type == 'card') {
      return '${brand?.toUpperCase() ?? 'Card'} •••• ${last4 ?? '****'}';
    } else if (type == 'paypal') {
      return 'PayPal ${paypalEmail ?? ''}';
    } else if (type == 'bank_account') {
      return 'Bank Account •••• ${last4 ?? '****'}';
    }
    return type.toUpperCase();
  }

  bool get isExpired {
    if (expiryMonth == null || expiryYear == null) return false;
    final now = DateTime.now();
    final expiry = DateTime(int.parse(expiryYear!), int.parse(expiryMonth!));
    return expiry.isBefore(now);
  }
}

class Invoice {
  final String id;
  final String paymentId;
  final String patientId;
  final String patientName;
  final String? doctorId;
  final String? doctorName;
  final String invoiceNumber;
  final DateTime issueDate;
  final DateTime? dueDate;
  final List<InvoiceItem> items;
  final double subtotal;
  final double? taxAmount;
  final double? discountAmount;
  final double totalAmount;
  final String currency;
  final String status; // draft, sent, paid, overdue, cancelled
  final String? notes;
  final Map<String, dynamic>? billingAddress;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Invoice({
    required this.id,
    required this.paymentId,
    required this.patientId,
    required this.patientName,
    this.doctorId,
    this.doctorName,
    required this.invoiceNumber,
    required this.issueDate,
    this.dueDate,
    required this.items,
    required this.subtotal,
    this.taxAmount,
    this.discountAmount,
    required this.totalAmount,
    this.currency = 'USD',
    this.status = 'draft',
    this.notes,
    this.billingAddress,
    required this.createdAt,
    this.updatedAt,
  });

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] ?? '',
      paymentId: map['paymentId'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorId: map['doctorId'],
      doctorName: map['doctorName'],
      invoiceNumber: map['invoiceNumber'] ?? '',
      issueDate: (map['issueDate'] as Timestamp).toDate(),
      dueDate: map['dueDate'] != null ? (map['dueDate'] as Timestamp).toDate() : null,
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => InvoiceItem.fromMap(item))
          .toList() ?? [],
      subtotal: map['subtotal']?.toDouble() ?? 0.0,
      taxAmount: map['taxAmount']?.toDouble(),
      discountAmount: map['discountAmount']?.toDouble(),
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'USD',
      status: map['status'] ?? 'draft',
      notes: map['notes'],
      billingAddress: map['billingAddress'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paymentId': paymentId,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'invoiceNumber': invoiceNumber,
      'issueDate': Timestamp.fromDate(issueDate),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'currency': currency,
      'status': status,
      'notes': notes,
      'billingAddress': billingAddress,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(2)}';
  String get formattedTotalAmount => '\$${totalAmount.toStringAsFixed(2)}';
  String get formattedTaxAmount => taxAmount != null ? '\$${taxAmount!.toStringAsFixed(2)}' : '\$0.00';
  String get formattedDiscountAmount => discountAmount != null ? '\$${discountAmount!.toStringAsFixed(2)}' : '\$0.00';

  bool get isPaid => status == 'paid';
  bool get isOverdue => status == 'overdue' || (dueDate != null && dueDate!.isBefore(DateTime.now()) && !isPaid);
}

class InvoiceItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: map['unitPrice']?.toDouble() ?? 0.0,
      totalPrice: map['totalPrice']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  String get formattedUnitPrice => '\$${unitPrice.toStringAsFixed(2)}';
  String get formattedTotalPrice => '\$${totalPrice.toStringAsFixed(2)}';
}

class InsuranceClaim {
  final String id;
  final String paymentId;
  final String patientId;
  final String insuranceProvider;
  final String policyNumber;
  final String claimNumber;
  final String status; // submitted, processing, approved, denied, paid
  final double claimedAmount;
  final double? approvedAmount;
  final double? paidAmount;
  final DateTime submittedDate;
  final DateTime? processedDate;
  final String? denialReason;
  final List<String> documentUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;

  InsuranceClaim({
    required this.id,
    required this.paymentId,
    required this.patientId,
    required this.insuranceProvider,
    required this.policyNumber,
    required this.claimNumber,
    this.status = 'submitted',
    required this.claimedAmount,
    this.approvedAmount,
    this.paidAmount,
    required this.submittedDate,
    this.processedDate,
    this.denialReason,
    this.documentUrls = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory InsuranceClaim.fromMap(Map<String, dynamic> map) {
    return InsuranceClaim(
      id: map['id'] ?? '',
      paymentId: map['paymentId'] ?? '',
      patientId: map['patientId'] ?? '',
      insuranceProvider: map['insuranceProvider'] ?? '',
      policyNumber: map['policyNumber'] ?? '',
      claimNumber: map['claimNumber'] ?? '',
      status: map['status'] ?? 'submitted',
      claimedAmount: map['claimedAmount']?.toDouble() ?? 0.0,
      approvedAmount: map['approvedAmount']?.toDouble(),
      paidAmount: map['paidAmount']?.toDouble(),
      submittedDate: (map['submittedDate'] as Timestamp).toDate(),
      processedDate: map['processedDate'] != null ? (map['processedDate'] as Timestamp).toDate() : null,
      denialReason: map['denialReason'],
      documentUrls: List<String>.from(map['documentUrls'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paymentId': paymentId,
      'patientId': patientId,
      'insuranceProvider': insuranceProvider,
      'policyNumber': policyNumber,
      'claimNumber': claimNumber,
      'status': status,
      'claimedAmount': claimedAmount,
      'approvedAmount': approvedAmount,
      'paidAmount': paidAmount,
      'submittedDate': Timestamp.fromDate(submittedDate),
      'processedDate': processedDate != null ? Timestamp.fromDate(processedDate!) : null,
      'denialReason': denialReason,
      'documentUrls': documentUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get formattedClaimedAmount => '\$${claimedAmount.toStringAsFixed(2)}';
  String get formattedApprovedAmount => approvedAmount != null ? '\$${approvedAmount!.toStringAsFixed(2)}' : 'N/A';
  String get formattedPaidAmount => paidAmount != null ? '\$${paidAmount!.toStringAsFixed(2)}' : 'N/A';

  bool get isApproved => status == 'approved' || status == 'paid';
  bool get isDenied => status == 'denied';
  bool get isPaid => status == 'paid';
}

