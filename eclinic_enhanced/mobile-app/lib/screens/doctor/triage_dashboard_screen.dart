import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/appointment_service.dart';
import '../../utils/app_theme.dart';
import '../../models/appointment_model.dart';

class TriageDashboardScreen extends StatefulWidget {
  const TriageDashboardScreen({super.key});

  @override
  State<TriageDashboardScreen> createState() => _TriageDashboardScreenState();
}

class _TriageDashboardScreenState extends State<TriageDashboardScreen> {
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appointmentService = context.read<AppointmentService>();
      final appointments = await appointmentService.getDoctorAppointments('current_doctor_id');
      
      setState(() {
        _appointments = appointments;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading appointments: $e'),
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

  List<Appointment> get _filteredAppointments {
    switch (_selectedFilter) {
      case 'urgent':
        return _appointments.where((apt) => apt.urgency == 'high' || apt.urgency == 'urgent').toList();
      case 'priority':
        return _appointments.where((apt) => apt.urgency == 'medium' || apt.urgency == 'priority').toList();
      case 'routine':
        return _appointments.where((apt) => apt.urgency == 'low' || apt.urgency == 'routine').toList();
      case 'pending':
        return _appointments.where((apt) => apt.status == 'pending').toList();
      default:
        return _appointments;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Triage Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Cards
          _buildStatisticsSection(),
          
          // Filter Tabs
          _buildFilterTabs(),
          
          // Appointments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAppointments.isEmpty
                    ? _buildEmptyState()
                    : _buildAppointmentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final urgentCount = _appointments.where((apt) => apt.urgency == 'high' || apt.urgency == 'urgent').length;
    final priorityCount = _appointments.where((apt) => apt.urgency == 'medium' || apt.urgency == 'priority').length;
    final routineCount = _appointments.where((apt) => apt.urgency == 'low' || apt.urgency == 'routine').length;
    final pendingCount = _appointments.where((apt) => apt.status == 'pending').length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Urgent', urgentCount, Colors.red)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Priority', priorityCount, Colors.orange)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Routine', routineCount, Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Pending', pendingCount, Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'urgent', 'label': 'Urgent'},
      {'key': 'priority', 'label': 'Priority'},
      {'key': 'routine', 'label': 'Routine'},
      {'key': 'pending', 'label': 'Pending'},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['key'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter['key']!;
                });
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppointmentsList() {
    final sortedAppointments = List<Appointment>.from(_filteredAppointments);
    
    // Sort by urgency score (highest first)
    sortedAppointments.sort((a, b) {
      final aScore = _getUrgencyScore(a.urgency);
      final bScore = _getUrgencyScore(b.urgency);
      return bScore.compareTo(aScore);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedAppointments.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(sortedAppointments[index]);
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with patient info and urgency
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient ID: ${appointment.patientId}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        appointment.specialization ?? 'General Practice',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getUrgencyColor(appointment.urgency).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        appointment.urgency?.toUpperCase() ?? 'MEDIUM',
                        style: TextStyle(
                          color: _getUrgencyColor(appointment.urgency),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (appointment.triageData != null && appointment.triageData!['urgencyScore'] != null)
                      Row(
                        children: [
                          Icon(
                            Icons.score,
                            size: 16,
                            color: _getScoreColor(appointment.triageData!['urgencyScore']),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${appointment.triageData!['urgencyScore']}/5',
                            style: TextStyle(
                              color: _getScoreColor(appointment.triageData!['urgencyScore']),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Symptoms
            if (appointment.symptoms != null) ...[
              Text(
                'Symptoms:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                appointment.symptoms!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
            ],

            // Triage Information
            if (appointment.triageData != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Triage Assessment:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (appointment.triageData!['priority'] != null)
                      _buildTriageRow('Priority', appointment.triageData!['priority']),
                    if (appointment.triageData!['recommendedTimeframe'] != null)
                      _buildTriageRow('Timeframe', appointment.triageData!['recommendedTimeframe']),
                    if (appointment.triageData!['suggestedSpecialist'] != null)
                      _buildTriageRow('Specialist', appointment.triageData!['suggestedSpecialist']),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptAppointment(appointment),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewDetails(appointment),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rescheduleAppointment(appointment),
                    icon: const Icon(Icons.schedule, size: 16),
                    label: const Text('Reschedule'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTriageRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No appointments found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Appointments will appear here when patients book them',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _acceptAppointment(Appointment appointment) async {
    try {
      final appointmentService = context.read<AppointmentService>();
      await appointmentService.updateAppointmentStatus(appointment.id, 'confirmed');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment accepted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewDetails(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appointment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Patient ID', appointment.patientId),
              _buildDetailRow('Specialization', appointment.specialization ?? 'General Practice'),
              _buildDetailRow('Urgency', appointment.urgency ?? 'Medium'),
              _buildDetailRow('Status', appointment.status),
              if (appointment.symptoms != null)
                _buildDetailRow('Symptoms', appointment.symptoms!),
              if (appointment.triageData != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Triage Data:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...appointment.triageData!.entries.map((entry) =>
                  _buildDetailRow(entry.key, entry.value.toString())
                ).toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _rescheduleAppointment(Appointment appointment) {
    // Implement reschedule functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reschedule functionality coming soon'),
      ),
    );
  }

  Color _getUrgencyColor(String? urgency) {
    switch (urgency?.toLowerCase()) {
      case 'high':
      case 'urgent':
        return Colors.red;
      case 'medium':
      case 'priority':
        return Colors.orange;
      case 'low':
      case 'routine':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getScoreColor(int? score) {
    if (score == null) return Colors.grey;
    if (score >= 4) return Colors.red;
    if (score >= 3) return Colors.orange;
    return Colors.green;
  }

  int _getUrgencyScore(String? urgency) {
    switch (urgency?.toLowerCase()) {
      case 'high':
      case 'urgent':
        return 5;
      case 'medium':
      case 'priority':
        return 3;
      case 'low':
      case 'routine':
        return 1;
      default:
        return 2;
    }
  }
}

