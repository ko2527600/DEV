import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/prescription_service.dart';
import '../../utils/app_theme.dart';
import '../../models/prescription_model.dart';

class PrescriptionManagementScreen extends StatefulWidget {
  final String patientId;
  final bool isDoctorView;

  const PrescriptionManagementScreen({
    super.key,
    required this.patientId,
    this.isDoctorView = false,
  });

  @override
  State<PrescriptionManagementScreen> createState() => _PrescriptionManagementScreenState();
}

class _PrescriptionManagementScreenState extends State<PrescriptionManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Prescription> _prescriptions = [];
  List<RefillRequest> _refillRequests = [];
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.isDoctorView ? 4 : 3, vsync: this);
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
      final prescriptionService = context.read<PrescriptionService>();
      
      final prescriptions = await prescriptionService.getPatientPrescriptions(widget.patientId);
      final refillRequests = await prescriptionService.getPatientRefillRequests(widget.patientId);
      final analytics = await prescriptionService.getPrescriptionAnalytics(widget.patientId);

      setState(() {
        _prescriptions = prescriptions;
        _refillRequests = refillRequests;
        _analytics = analytics;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading prescription data: $e'),
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
        title: Text(widget.isDoctorView ? 'Patient Prescriptions' : 'My Prescriptions'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              _showSearchDialog();
            },
            icon: const Icon(Icons.search),
          ),
          if (widget.isDoctorView)
            IconButton(
              onPressed: () {
                _showCreatePrescriptionDialog();
              },
              icon: const Icon(Icons.add),
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
            const Tab(text: 'Active'),
            const Tab(text: 'All'),
            const Tab(text: 'Refills'),
            if (widget.isDoctorView) const Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActivePrescriptionsTab(),
                _buildAllPrescriptionsTab(),
                _buildRefillsTab(),
                if (widget.isDoctorView) _buildAnalyticsTab(),
              ],
            ),
      floatingActionButton: widget.isDoctorView
          ? FloatingActionButton(
              onPressed: () {
                _showCreatePrescriptionDialog();
              },
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildActivePrescriptionsTab() {
    final activePrescriptions = _prescriptions.where((p) => p.isActive).toList();
    
    if (activePrescriptions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Active Prescriptions',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activePrescriptions.length,
        itemBuilder: (context, index) {
          final prescription = activePrescriptions[index];
          return _buildPrescriptionCard(prescription);
        },
      ),
    );
  }

  Widget _buildAllPrescriptionsTab() {
    final filteredPrescriptions = _searchQuery.isEmpty
        ? _prescriptions
        : _prescriptions.where((p) =>
            p.medicationName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.doctorName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredPrescriptions.length,
        itemBuilder: (context, index) {
          final prescription = filteredPrescriptions[index];
          return _buildPrescriptionCard(prescription);
        },
      ),
    );
  }

  Widget _buildPrescriptionCard(Prescription prescription) {
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
                        prescription.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        prescription.fullDosageInfo,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(prescription.status),
              ],
            ),
            const SizedBox(height: 12),
            
            // Prescription Details
            _buildDetailRow(Icons.person, 'Doctor', prescription.doctorName),
            _buildDetailRow(Icons.schedule, 'Frequency', prescription.frequency),
            _buildDetailRow(Icons.calendar_today, 'Prescribed', 
                '${prescription.prescribedDate.day}/${prescription.prescribedDate.month}/${prescription.prescribedDate.year}'),
            
            if (prescription.indication != null)
              _buildDetailRow(Icons.info, 'For', prescription.indication!),
            
            if (prescription.refillsRemaining != null)
              _buildDetailRow(Icons.refresh, 'Refills', '${prescription.refillsRemaining} remaining'),
            
            if (prescription.instructions != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        prescription.instructions!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Warnings
            if (prescription.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Warnings:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...prescription.warnings.map((warning) => Text(
                      '• $warning',
                      style: const TextStyle(fontSize: 12),
                    )),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              children: [
                if (prescription.canRefill && !widget.isDoctorView)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _requestRefill(prescription);
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Request Refill'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                
                if (prescription.canRefill && !widget.isDoctorView)
                  const SizedBox(width: 8),
                
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showPrescriptionDetails(prescription);
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                  ),
                ),
                
                if (widget.isDoctorView) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _editPrescription(prescription);
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
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

  Widget _buildStatusChip(PrescriptionStatus status) {
    Color color;
    switch (status) {
      case PrescriptionStatus.active:
        color = Colors.green;
        break;
      case PrescriptionStatus.pending:
        color = Colors.orange;
        break;
      case PrescriptionStatus.completed:
        color = Colors.blue;
        break;
      case PrescriptionStatus.cancelled:
        color = Colors.red;
        break;
      case PrescriptionStatus.expired:
        color = Colors.grey;
        break;
    }

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

  Widget _buildRefillsTab() {
    if (_refillRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Refill Requests',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _refillRequests.length,
      itemBuilder: (context, index) {
        final refill = _refillRequests[index];
        return _buildRefillCard(refill);
      },
    );
  }

  Widget _buildRefillCard(RefillRequest refill) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          Icons.refresh,
          color: _getRefillStatusColor(refill.status),
        ),
        title: Text(refill.medicationName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Requested: ${refill.requestedDate.day}/${refill.requestedDate.month}/${refill.requestedDate.year}'),
            Text('Status: ${refill.statusDisplayText}'),
            if (refill.denialReason != null)
              Text('Reason: ${refill.denialReason}', style: const TextStyle(color: Colors.red)),
          ],
        ),
        trailing: widget.isDoctorView && refill.status == RefillStatus.requested
            ? PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'approve',
                    child: Text('Approve'),
                  ),
                  const PopupMenuItem(
                    value: 'deny',
                    child: Text('Deny'),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'approve') {
                    _approveRefill(refill);
                  } else if (value == 'deny') {
                    _denyRefill(refill);
                  }
                },
              )
            : null,
      ),
    );
  }

  Color _getRefillStatusColor(RefillStatus status) {
    switch (status) {
      case RefillStatus.available:
        return Colors.green;
      case RefillStatus.requested:
        return Colors.orange;
      case RefillStatus.approved:
        return Colors.blue;
      case RefillStatus.denied:
        return Colors.red;
      case RefillStatus.noRefillsLeft:
        return Colors.grey;
    }
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
                    'Prescription Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total',
                          _analytics!['totalPrescriptions'].toString(),
                          Icons.medication,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Active',
                          _analytics!['activePrescriptions'].toString(),
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
                          'Completed',
                          _analytics!['completedPrescriptions'].toString(),
                          Icons.done_all,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Cancelled',
                          _analytics!['cancelledPrescriptions'].toString(),
                          Icons.cancel,
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
          
          // Adherence Rate
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Medication Adherence',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '${_analytics!['averageAdherenceRate'].toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Text('Average Adherence Rate'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Common Medications
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Most Prescribed Medications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...(_analytics!['commonMedications'] as Map<String, int>)
                      .entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key),
                                Text('${entry.value} times'),
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

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Prescriptions'),
        content: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: const InputDecoration(
            hintText: 'Enter medication or doctor name',
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

  void _showCreatePrescriptionDialog() {
    // Navigate to create prescription screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create prescription feature would open here')),
    );
  }

  void _showPrescriptionDetails(Prescription prescription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(prescription.displayName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(Icons.person, 'Doctor', prescription.doctorName),
              _buildDetailRow(Icons.medication, 'Dosage', prescription.fullDosageInfo),
              _buildDetailRow(Icons.schedule, 'Frequency', prescription.frequency),
              _buildDetailRow(Icons.numbers, 'Quantity', prescription.quantity.toString()),
              if (prescription.instructions != null)
                _buildDetailRow(Icons.info, 'Instructions', prescription.instructions!),
              if (prescription.indication != null)
                _buildDetailRow(Icons.medical_services, 'Indication', prescription.indication!),
              if (prescription.pharmacyName != null)
                _buildDetailRow(Icons.local_pharmacy, 'Pharmacy', prescription.pharmacyName!),
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

  void _editPrescription(Prescription prescription) {
    // Navigate to edit prescription screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit prescription feature would open here')),
    );
  }

  void _requestRefill(Prescription prescription) async {
    try {
      final prescriptionService = context.read<PrescriptionService>();
      
      final refillRequest = RefillRequest(
        id: '',
        prescriptionId: prescription.id,
        patientId: prescription.patientId,
        patientName: prescription.patientName,
        doctorId: prescription.doctorId,
        doctorName: prescription.doctorName,
        medicationName: prescription.medicationName,
        status: RefillStatus.requested,
        requestedDate: DateTime.now(),
        pharmacyId: prescription.pharmacyId,
        pharmacyName: prescription.pharmacyName,
        createdAt: DateTime.now(),
      );

      await prescriptionService.requestRefill(refillRequest);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refill request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error requesting refill: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _approveRefill(RefillRequest refill) async {
    try {
      final prescriptionService = context.read<PrescriptionService>();
      await prescriptionService.approveRefill(refill.id, refill.prescriptionId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refill approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving refill: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _denyRefill(RefillRequest refill) {
    showDialog(
      context: context,
      builder: (context) {
        String reason = '';
        return AlertDialog(
          title: const Text('Deny Refill Request'),
          content: TextField(
            onChanged: (value) => reason = value,
            decoration: const InputDecoration(
              hintText: 'Enter reason for denial',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final prescriptionService = context.read<PrescriptionService>();
                  await prescriptionService.denyRefill(refill.id, reason);
                  
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refill denied'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error denying refill: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Deny'),
            ),
          ],
        );
      },
    );
  }

  void _exportData() async {
    try {
      final prescriptionService = context.read<PrescriptionService>();
      final exportData = await prescriptionService.exportPrescriptionData(widget.patientId);
      
      // In a real app, this would save to file or share
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription data exported successfully'),
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

