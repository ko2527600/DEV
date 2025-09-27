import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_service.dart';
import '../../services/appointment_service.dart';
import '../../utils/app_theme.dart';

class SmartBookingScreen extends StatefulWidget {
  const SmartBookingScreen({super.key});

  @override
  State<SmartBookingScreen> createState() => _SmartBookingScreenState();
}

class _SmartBookingScreenState extends State<SmartBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _ageController = TextEditingController();
  
  String _selectedUrgency = 'medium';
  bool _isAnalyzing = false;
  Map<String, dynamic>? _triageResult;
  List<Map<String, dynamic>> _recommendations = [];

  @override
  void dispose() {
    _symptomsController.dispose();
    _medicalHistoryController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _performTriage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isAnalyzing = true;
      _triageResult = null;
      _recommendations = [];
    });

    try {
      final aiService = context.read<AIService>();
      
      // Perform triage analysis
      final triageResult = await aiService.triageAppointment(
        symptoms: _symptomsController.text.trim(),
        urgency: _selectedUrgency,
        patientAge: int.parse(_ageController.text),
        medicalHistory: _medicalHistoryController.text.trim(),
      );

      // Get appointment recommendations
      final recommendations = await aiService.getAppointmentRecommendations(
        symptoms: _symptomsController.text.trim(),
        urgency: _selectedUrgency,
      );

      setState(() {
        _triageResult = triageResult;
        _recommendations = recommendations;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error performing triage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _bookAppointment(String specialization, String urgency) async {
    try {
      final appointmentService = context.read<AppointmentService>();
      
      // Create appointment with triage information
      final appointment = Appointment(
        id: '',
        patientId: 'current_user_id', // Replace with actual user ID
        doctorId: '', // Will be assigned based on specialization
        doctorName: 'To be assigned',
        specialization: specialization,
        appointmentDate: DateTime.now().add(const Duration(days: 1)),
        timeSlot: '09:00 AM',
        status: 'pending',
        symptoms: _symptomsController.text.trim(),
        urgency: urgency,
        triageData: _triageResult,
      );

      await appointmentService.createAppointment(appointment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Appointment Booking'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.psychology,
                        size: 48,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'AI-Powered Appointment Triage',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Our AI will analyze your symptoms and recommend the best specialist and urgency level for your appointment.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Symptoms Input
              Text(
                'Describe Your Symptoms',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _symptomsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Please describe your symptoms, pain level, and any concerns in detail',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe your symptoms';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Patient Information
              Text(
                'Patient Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final age = int.tryParse(value);
                        if (age == null || age < 1 || age > 120) {
                          return 'Invalid age';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedUrgency,
                      decoration: const InputDecoration(
                        labelText: 'How urgent do you feel this is?',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low - Can wait')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium - Soon')),
                        DropdownMenuItem(value: 'high', child: Text('High - Urgent')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedUrgency = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Medical History
              TextFormField(
                controller: _medicalHistoryController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Relevant Medical History (Optional)',
                  hintText: 'Any relevant medical conditions, medications, or previous treatments',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Analyze Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isAnalyzing ? null : _performTriage,
                  child: _isAnalyzing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Analyzing...'),
                          ],
                        )
                      : const Text('Analyze & Get Recommendations'),
                ),
              ),
              const SizedBox(height: 24),

              // Triage Results
              if (_triageResult != null) _buildTriageResults(),

              // Recommendations
              if (_recommendations.isNotEmpty) _buildRecommendations(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTriageResults() {
    final result = _triageResult!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.analytics,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Triage Assessment',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Priority Level
            _buildResultRow(
              'Priority Level',
              result['priority'] ?? 'Unknown',
              _getPriorityColor(result['priority']),
              Icons.priority_high,
            ),
            const SizedBox(height: 12),

            // Recommended Timeframe
            _buildResultRow(
              'Recommended Timeframe',
              result['recommendedTimeframe'] ?? 'Unknown',
              Colors.blue,
              Icons.schedule,
            ),
            const SizedBox(height: 12),

            // Suggested Specialist
            _buildResultRow(
              'Suggested Specialist',
              result['suggestedSpecialist'] ?? 'General Practice',
              Colors.green,
              Icons.medical_services,
            ),
            const SizedBox(height: 12),

            // Urgency Score
            Row(
              children: [
                const Icon(Icons.score, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Urgency Score: ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(result['urgencyScore']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${result['urgencyScore']}/5',
                    style: TextStyle(
                      color: _getScoreColor(result['urgencyScore']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            if (result['notes'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result['notes'],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.recommend,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recommended Appointments',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ..._recommendations.map((recommendation) => 
              _buildRecommendationCard(recommendation)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                recommendation['specialization'] ?? 'General Practice',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getUrgencyColor(recommendation['urgency']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  recommendation['urgency']?.toUpperCase() ?? 'MEDIUM',
                  style: TextStyle(
                    color: _getUrgencyColor(recommendation['urgency']),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation['reason'] ?? 'Recommended based on symptoms',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Recommended timeframe: ${recommendation['recommendedTimeframe'] ?? 'within 1 week'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _bookAppointment(
                recommendation['specialization'] ?? 'General Practice',
                recommendation['urgency'] ?? 'medium',
              ),
              child: Text('Book ${recommendation['specialization']} Appointment'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'priority':
        return Colors.orange;
      case 'routine':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getUrgencyColor(String? urgency) {
    switch (urgency?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
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
}

