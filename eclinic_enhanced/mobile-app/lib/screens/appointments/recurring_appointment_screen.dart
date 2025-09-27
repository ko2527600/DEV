import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/recurring_appointment_service.dart';
import '../../utils/app_theme.dart';
import '../../models/recurring_appointment_model.dart';
import 'create_recurring_appointment_screen.dart';

class RecurringAppointmentScreen extends StatefulWidget {
  const RecurringAppointmentScreen({super.key});

  @override
  State<RecurringAppointmentScreen> createState() => _RecurringAppointmentScreenState();
}

class _RecurringAppointmentScreenState extends State<RecurringAppointmentScreen> {
  List<RecurringAppointment> _recurringAppointments = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadRecurringAppointments();
  }

  Future<void> _loadRecurringAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recurringService = context.read<RecurringAppointmentService>();
      final appointments = await recurringService.getPatientRecurringAppointments('current_user_id');
      
      setState(() {
        _recurringAppointments = appointments;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading recurring appointments: $e'),
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

  List<RecurringAppointment> get _filteredAppointments {
    switch (_selectedFilter) {
      case 'active':
        return _recurringAppointments.where((ra) => ra.status == 'active').toList();
      case 'paused':
        return _recurringAppointments.where((ra) => ra.status == 'paused').toList();
      case 'completed':
        return _recurringAppointments.where((ra) => ra.status == 'completed').toList();
      case 'cancelled':
        return _recurringAppointments.where((ra) => ra.status == 'cancelled').toList();
      default:
        return _recurringAppointments;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Appointments'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecurringAppointments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          _buildStatisticsCard(),
          
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateRecurring(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final stats = {
      'total': _recurringAppointments.length,
      'active': _recurringAppointments.where((ra) => ra.status == 'active').length,
      'paused': _recurringAppointments.where((ra) => ra.status == 'paused').length,
      'completed': _recurringAppointments.where((ra) => ra.status == 'completed').length,
    };

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatItem('Total', stats['total']!, Colors.blue)),
                  Expanded(child: _buildStatItem('Active', stats['active']!, Colors.green)),
                  Expanded(child: _buildStatItem('Paused', stats['paused']!, Colors.orange)),
                  Expanded(child: _buildStatItem('Completed', stats['completed']!, Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
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
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'active', 'label': 'Active'},
      {'key': 'paused', 'label': 'Paused'},
      {'key': 'completed', 'label': 'Completed'},
      {'key': 'cancelled', 'label': 'Cancelled'},
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredAppointments.length,
      itemBuilder: (context, index) {
        return _buildRecurringAppointmentCard(_filteredAppointments[index]);
      },
    );
  }

  Widget _buildRecurringAppointmentCard(RecurringAppointment appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        appointment.specialization,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointment.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(appointment.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Recurrence Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.repeat, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Recurring Pattern',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Pattern: ${appointment.getRecurrenceDescription()}'),
                  Text('Time: ${appointment.timeSlot}'),
                  Text('End: ${appointment.getEndDescription()}'),
                  if (appointment.generatedCount > 0)
                    Text('Generated: ${appointment.generatedCount} appointments'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                if (appointment.status == 'active') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pauseAppointment(appointment),
                      icon: const Icon(Icons.pause, size: 16),
                      label: const Text('Pause'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (appointment.status == 'paused') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _resumeAppointment(appointment),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Resume'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewUpcomingAppointments(appointment),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('View Upcoming'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showOptionsMenu(appointment),
                    icon: const Icon(Icons.more_horiz, size: 16),
                    label: const Text('Options'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.repeat_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No recurring appointments',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up recurring appointments for regular check-ups',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateRecurring(),
            icon: const Icon(Icons.add),
            label: const Text('Create Recurring Appointment'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _navigateToCreateRecurring() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateRecurringAppointmentScreen(),
      ),
    ).then((_) => _loadRecurringAppointments());
  }

  Future<void> _pauseAppointment(RecurringAppointment appointment) async {
    final reason = await _showReasonDialog('Pause Appointment', 'Why are you pausing this recurring appointment?');
    if (reason != null) {
      try {
        final recurringService = context.read<RecurringAppointmentService>();
        await recurringService.pauseRecurringAppointment(appointment.id, reason);
        _loadRecurringAppointments();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recurring appointment paused'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error pausing appointment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _resumeAppointment(RecurringAppointment appointment) async {
    try {
      final recurringService = context.read<RecurringAppointmentService>();
      await recurringService.resumeRecurringAppointment(appointment.id);
      _loadRecurringAppointments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recurring appointment resumed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resuming appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewUpcomingAppointments(RecurringAppointment appointment) {
    // Navigate to upcoming appointments view
    // This would show the individual appointments generated from this recurring appointment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upcoming appointments view coming soon')),
    );
  }

  void _showOptionsMenu(RecurringAppointment appointment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Modify Pattern'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.skip_next),
              title: const Text('Skip Next Appointment'),
              onTap: () {
                Navigator.pop(context);
                // Skip next occurrence
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Cancel Recurring Appointment'),
              onTap: () {
                Navigator.pop(context);
                _cancelAppointment(appointment);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelAppointment(RecurringAppointment appointment) async {
    final reason = await _showReasonDialog('Cancel Appointment', 'Why are you cancelling this recurring appointment?');
    if (reason != null) {
      try {
        final recurringService = context.read<RecurringAppointmentService>();
        await recurringService.cancelRecurringAppointment(appointment.id, reason);
        _loadRecurringAppointments();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recurring appointment cancelled'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling appointment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<String?> _showReasonDialog(String title, String message) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
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
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

