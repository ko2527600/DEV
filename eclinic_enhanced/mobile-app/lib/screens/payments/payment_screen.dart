import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/payment_service.dart';
import '../../utils/app_theme.dart';
import '../../models/payment_model.dart';

class PaymentScreen extends StatefulWidget {
  final String patientId;
  final bool isDoctorView;

  const PaymentScreen({
    super.key,
    required this.patientId,
    this.isDoctorView = false,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Payment> _payments = [];
  List<Invoice> _invoices = [];
  List<PaymentMethod> _paymentMethods = [];
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.isDoctorView ? 5 : 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final paymentService = context.read<PaymentService>();
      
      final payments = await paymentService.getPatientPayments(widget.patientId);
      final invoices = await paymentService.getPatientInvoices(widget.patientId);
      final paymentMethods = await paymentService.getPatientPaymentMethods(widget.patientId);
      final analytics = await paymentService.getPaymentAnalytics(widget.patientId);

      setState(() {
        _payments = payments;
        _invoices = invoices;
        _paymentMethods = paymentMethods;
        _analytics = analytics;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading payment data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDoctorView ? 'Patient Payments' : 'Payments & Billing'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              _showSearchDialog();
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              _exportData();
            },
            icon: const Icon(Icons.download),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            const Tab(text: 'Payments'),
            const Tab(text: 'Invoices'),
            const Tab(text: 'Methods'),
            if (widget.isDoctorView) const Tab(text: 'Analytics'),
            const Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPaymentsTab(),
                _buildInvoicesTab(),
                _buildPaymentMethodsTab(),
                if (widget.isDoctorView) _buildAnalyticsTab(),
                _buildHistoryTab(),
              ],
            ),
      floatingActionButton: !widget.isDoctorView
          ? FloatingActionButton(
              onPressed: () {
                _showAddPaymentMethodDialog();
              },
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildPaymentsTab() {
    final recentPayments = _payments.take(10).toList();
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            if (_analytics != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Paid',
                      '\$${_analytics!['completedAmount'].toStringAsFixed(2)}',
                      Icons.payment,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Pending',
                      '${_analytics!['pendingPayments']}',
                      Icons.pending,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Recent Payments
            const Text(
              'Recent Payments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            if (recentPayments.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.payment, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No Payments Found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ...recentPayments.map((payment) => _buildPaymentCard(payment)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.description ?? payment.typeDisplayText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        payment.formattedTotalAmount,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getPaymentStatusColor(payment.status),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPaymentStatusChip(payment.status),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildDetailRow(Icons.payment, 'Method', payment.methodDisplayText),
            _buildDetailRow(Icons.calendar_today, 'Date', 
                '${payment.createdAt.day}/${payment.createdAt.month}/${payment.createdAt.year}'),
            
            if (payment.doctorName != null)
              _buildDetailRow(Icons.person, 'Doctor', payment.doctorName!),
            
            if (payment.invoiceNumber != null)
              _buildDetailRow(Icons.receipt, 'Invoice', payment.invoiceNumber!),

            if (payment.failureReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Failure reason: ${payment.failureReason}',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showPaymentDetails(payment);
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                  ),
                ),
                
                if (payment.canRefund && !widget.isDoctorView) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _requestRefund(payment);
                      },
                      icon: const Icon(Icons.undo, size: 16),
                      label: const Text('Request Refund'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _invoices.length,
        itemBuilder: (context, index) {
          final invoice = _invoices[index];
          return _buildInvoiceCard(invoice);
        },
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          Icons.receipt_long,
          color: invoice.isPaid ? Colors.green : Colors.orange,
        ),
        title: Text('Invoice ${invoice.invoiceNumber}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ${invoice.formattedTotalAmount}'),
            Text('Date: ${invoice.issueDate.day}/${invoice.issueDate.month}/${invoice.issueDate.year}'),
            Text('Status: ${invoice.status.toUpperCase()}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Text('View Invoice'),
            ),
            const PopupMenuItem(
              value: 'download',
              child: Text('Download PDF'),
            ),
            if (!invoice.isPaid)
              const PopupMenuItem(
                value: 'pay',
                child: Text('Pay Now'),
              ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'view':
                _showInvoiceDetails(invoice);
                break;
              case 'download':
                _downloadInvoice(invoice);
                break;
              case 'pay':
                _payInvoice(invoice);
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _paymentMethods.length,
        itemBuilder: (context, index) {
          final method = _paymentMethods[index];
          return _buildPaymentMethodCard(method);
        },
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          _getPaymentMethodIcon(method.type),
          color: method.isDefault ? AppTheme.primaryColor : Colors.grey,
        ),
        title: Text(method.displayText),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (method.expiryMonth != null && method.expiryYear != null)
              Text('Expires: ${method.expiryMonth}/${method.expiryYear}'),
            if (method.isDefault)
              const Text(
                'Default Payment Method',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (method.isExpired)
              const Text(
                'EXPIRED',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            if (!method.isDefault)
              const PopupMenuItem(
                value: 'default',
                child: Text('Set as Default'),
              ),
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'default':
                _setDefaultPaymentMethod(method);
                break;
              case 'edit':
                _editPaymentMethod(method);
                break;
              case 'delete':
                _deletePaymentMethod(method);
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_analytics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overview Stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total',
                          '${_analytics!['totalPayments']}',
                          Icons.payment,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Completed',
                          '${_analytics!['completedPayments']}',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Pending',
                          '${_analytics!['pendingPayments']}',
                          Icons.pending,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Failed',
                          '${_analytics!['failedPayments']}',
                          Icons.error,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Revenue Stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Revenue Analytics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '\$${_analytics!['completedAmount'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Text('Total Revenue'),
                        const SizedBox(height: 16),
                        Text(
                          '\$${_analytics!['averagePayment'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const Text('Average Payment'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Payment Methods Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Methods',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...(_analytics!['paymentMethods'] as Map<String, int>)
                      .entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key),
                                Text('${entry.value} payments'),
                              ],
                            ),
                          ))
                      ,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _payments.length,
        itemBuilder: (context, index) {
          final payment = _payments[index];
          return _buildPaymentCard(payment);
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusChip(PaymentStatus status) {
    final color = _getPaymentStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toString().split('.').last.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.pending:
      case PaymentStatus.processing:
        return Colors.orange;
      case PaymentStatus.failed:
      case PaymentStatus.cancelled:
        return Colors.red;
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return Colors.blue;
    }
  }

  IconData _getPaymentMethodIcon(String type) {
    switch (type.toLowerCase()) {
      case 'card':
        return Icons.credit_card;
      case 'paypal':
        return Icons.account_balance_wallet;
      case 'bank_account':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Payments'),
        content: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: const InputDecoration(
            hintText: 'Enter payment description or invoice number',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(Icons.payment, 'Amount', payment.formattedTotalAmount),
              _buildDetailRow(Icons.credit_card, 'Method', payment.methodDisplayText),
              _buildDetailRow(Icons.info, 'Type', payment.typeDisplayText),
              _buildDetailRow(Icons.info, 'Status', payment.statusDisplayText),
              if (payment.description != null)
                _buildDetailRow(Icons.description, 'Description', payment.description!),
              if (payment.transactionId != null)
                _buildDetailRow(Icons.confirmation_number, 'Transaction ID', payment.transactionId!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showInvoiceDetails(Invoice invoice) {
    // Show invoice details dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invoice details would be shown here')),
    );
  }

  void _downloadInvoice(Invoice invoice) {
    // Download invoice as PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invoice download would start here')),
    );
  }

  void _payInvoice(Invoice invoice) {
    // Navigate to payment screen for invoice
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment screen for invoice would open here')),
    );
  }

  void _showAddPaymentMethodDialog() {
    // Show add payment method dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add payment method dialog would open here')),
    );
  }

  void _setDefaultPaymentMethod(PaymentMethod method) async {
    try {
      final paymentService = context.read<PaymentService>();
      await paymentService.setDefaultPaymentMethod(method.id, method.patientId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default payment method updated'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating default payment method: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editPaymentMethod(PaymentMethod method) {
    // Navigate to edit payment method screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit payment method screen would open here')),
    );
  }

  void _deletePaymentMethod(PaymentMethod method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: const Text('Are you sure you want to delete this payment method?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final paymentService = context.read<PaymentService>();
        await paymentService.deletePaymentMethod(method.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment method deleted'),
            backgroundColor: Colors.green,
          ),
        );
        
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting payment method: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _requestRefund(Payment payment) {
    showDialog(
      context: context,
      builder: (context) {
        String reason = '';
        return AlertDialog(
          title: const Text('Request Refund'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Refund amount: ${payment.formattedTotalAmount}'),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => reason = value,
                decoration: const InputDecoration(
                  hintText: 'Enter reason for refund',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final paymentService = context.read<PaymentService>();
                  await paymentService.requestRefund(payment.id, payment.totalAmount, reason);
                  
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refund request submitted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error requesting refund: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Request Refund'),
            ),
          ],
        );
      },
    );
  }

  void _exportData() async {
    try {
      final paymentService = context.read<PaymentService>();
      final exportData = await paymentService.exportPaymentData(widget.patientId);
      
      // In a real app, this would save to file or share
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment data exported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

