import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ehr_service.dart';
import '../../utils/app_theme.dart';
import '../../models/ehr_model.dart';

class PatientProfileScreen extends StatefulWidget {
  final String patientId;
  final bool isEditable;

  const PatientProfileScreen({
    super.key,
    required this.patientId,
    this.isEditable = false,
  });

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PatientProfile? _patient;
  Map<String, dynamic>? _patientSummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadPatientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ehrService = context.read<EHRService>();
      final patient = await ehrService.getPatientProfile(widget.patientId);
      final summary = await ehrService.getPatientSummary(widget.patientId);

      setState(() {
        _patient = patient;
        _patientSummary = summary;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading patient data: $e'),
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Patient Profile'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_patient == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Patient Profile'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Patient not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_patient!.fullName),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (widget.isEditable)
            IconButton(
              onPressed: () {
                // Navigate to edit profile
              },
              icon: const Icon(Icons.edit),
            ),
          IconButton(
            onPressed: () {
              // Export patient data
              _exportPatientData();
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
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Vitals'),
            Tab(text: 'Allergies'),
            Tab(text: 'Diagnoses'),
            Tab(text: 'Medications'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildVitalsTab(),
          _buildAllergiesTab(),
          _buildDiagnosesTab(),
          _buildMedicationsTab(),
          _buildHistoryTab(),
        ],
      ),
      floatingActionButton: widget.isEditable
          ? FloatingActionButton(
              onPressed: () {
                _showAddDataDialog();
              },
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Basic Info
          _buildPatientInfoCard(),
          const SizedBox(height: 16),

          // Quick Stats
          _buildQuickStatsCard(),
          const SizedBox(height: 16),

          // Recent Activity
          _buildRecentActivityCard(),
          const SizedBox(height: 16),

          // Risk Factors
          _buildRiskFactorsCard(),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    _patient!.firstName[0] + _patient!.lastName[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _patient!.fullName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_patient!.age} years old • ${_patient!.genderDisplayText}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Blood Type: ${_patient!.bloodTypeDisplayText}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Contact Information
            _buildInfoRow(Icons.phone, 'Phone', _patient!.phoneNumber ?? 'Not provided'),
            _buildInfoRow(Icons.email, 'Email', _patient!.email ?? 'Not provided'),
            if (_patient!.address != null)
              _buildInfoRow(Icons.location_on, 'Address', _patient!.address!.fullAddress),
            
            // Insurance Information
            if (_patient!.insuranceProvider != null)
              _buildInfoRow(Icons.medical_services, 'Insurance', _patient!.insuranceProvider!),
            
            // Emergency Contact
            if (_patient!.emergencyContact != null) ...[
              const SizedBox(height: 8),
              Text(
                'Emergency Contact',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              _buildInfoRow(Icons.person, 'Name', _patient!.emergencyContact!.name),
              _buildInfoRow(Icons.family_restroom, 'Relationship', _patient!.emergencyContact!.relationship),
              _buildInfoRow(Icons.phone, 'Phone', _patient!.emergencyContact!.phoneNumber),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCard() {
    final allergies = _patientSummary?['allergies'] as List<Allergy>? ?? [];
    final activeDiagnoses = _patientSummary?['activeDiagnoses'] as List<Diagnosis>? ?? [];
    final activeMedications = _patientSummary?['activeMedications'] as List<Medication>? ?? [];
    final latestVitals = _patientSummary?['latestVitals'] as VitalSigns?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Allergies',
                    allergies.length.toString(),
                    Icons.warning,
                    allergies.isNotEmpty ? Colors.orange : Colors.grey,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Active Diagnoses',
                    activeDiagnoses.length.toString(),
                    Icons.medical_information,
                    activeDiagnoses.isNotEmpty ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Medications',
                    activeMedications.length.toString(),
                    Icons.medication,
                    activeMedications.isNotEmpty ? Colors.blue : Colors.grey,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Last Vitals',
                    latestVitals != null 
                        ? '${DateTime.now().difference(latestVitals.recordedAt).inDays}d ago'
                        : 'None',
                    Icons.favorite,
                    latestVitals != null ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
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

  Widget _buildRecentActivityCard() {
    final recentHistory = _patientSummary?['recentHistory'] as List<MedicalHistory>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (recentHistory.isEmpty)
              const Text('No recent activity')
            else
              ...recentHistory.take(3).map((history) => _buildActivityItem(history)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(MedicalHistory history) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${history.date.day}/${history.date.month}/${history.date.year}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskFactorsCard() {
    // This would typically come from health analytics
    final riskFactors = ['High Blood Pressure', 'Diabetes Risk'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Risk Factors',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (riskFactors.isEmpty)
              const Text('No identified risk factors')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: riskFactors.map((factor) => Chip(
                  label: Text(factor),
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  labelStyle: const TextStyle(color: Colors.orange),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsTab() {
    final latestVitals = _patientSummary?['latestVitals'] as VitalSigns?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (latestVitals != null) ...[
            _buildVitalsCard(latestVitals),
            const SizedBox(height: 16),
          ],
          _buildVitalsHistoryCard(),
        ],
      ),
    );
  }

  Widget _buildVitalsCard(VitalSigns vitals) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Latest Vital Signs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${vitals.recordedAt.day}/${vitals.recordedAt.month}/${vitals.recordedAt.year}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (vitals.bloodPressure != null)
              _buildVitalRow('Blood Pressure', '${vitals.bloodPressure} mmHg', Icons.favorite),
            if (vitals.heartRate != null)
              _buildVitalRow('Heart Rate', '${vitals.heartRate!.toInt()} bpm', Icons.monitor_heart),
            if (vitals.temperature != null)
              _buildVitalRow('Temperature', '${vitals.temperature!.toStringAsFixed(1)}°F', Icons.thermostat),
            if (vitals.weight != null)
              _buildVitalRow('Weight', '${vitals.weight!.toStringAsFixed(1)} kg', Icons.scale),
            if (vitals.height != null)
              _buildVitalRow('Height', '${vitals.height!.toStringAsFixed(1)} cm', Icons.height),
            if (vitals.oxygenSaturation != null)
              _buildVitalRow('Oxygen Saturation', '${vitals.oxygenSaturation!.toInt()}%', Icons.air),
            if (vitals.bmi != null)
              _buildVitalRow('BMI', '${vitals.bmi!.toStringAsFixed(1)} (${vitals.bmiCategory})', Icons.calculate),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vitals History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Vitals chart would be displayed here'),
            // TODO: Implement vitals chart
          ],
        ),
      ),
    );
  }

  Widget _buildAllergiesTab() {
    final allergies = _patientSummary?['allergies'] as List<Allergy>? ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allergies.length,
      itemBuilder: (context, index) {
        final allergy = allergies[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              Icons.warning,
              color: _getAllergySeverityColor(allergy.severity),
            ),
            title: Text(allergy.allergen),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${allergy.typeDisplayText} • ${allergy.severityDisplayText}'),
                if (allergy.reaction != null)
                  Text('Reaction: ${allergy.reaction}'),
              ],
            ),
            trailing: widget.isEditable
                ? IconButton(
                    onPressed: () {
                      // Edit allergy
                    },
                    icon: const Icon(Icons.edit),
                  )
                : null,
          ),
        );
      },
    );
  }

  Color _getAllergySeverityColor(AllergySeverity severity) {
    switch (severity) {
      case AllergySeverity.mild:
        return Colors.green;
      case AllergySeverity.moderate:
        return Colors.orange;
      case AllergySeverity.severe:
        return Colors.red;
      case AllergySeverity.lifeThreatening:
        return Colors.red[900]!;
    }
  }

  Widget _buildDiagnosesTab() {
    final diagnoses = _patientSummary?['activeDiagnoses'] as List<Diagnosis>? ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: diagnoses.length,
      itemBuilder: (context, index) {
        final diagnosis = diagnoses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              Icons.medical_information,
              color: _getDiagnosisStatusColor(diagnosis.status),
            ),
            title: Text(diagnosis.condition),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${diagnosis.statusDisplayText} • ${diagnosis.diagnosedDate.day}/${diagnosis.diagnosedDate.month}/${diagnosis.diagnosedDate.year}'),
                if (diagnosis.diagnosedBy != null)
                  Text('Diagnosed by: ${diagnosis.diagnosedBy}'),
              ],
            ),
            trailing: widget.isEditable
                ? IconButton(
                    onPressed: () {
                      // Edit diagnosis
                    },
                    icon: const Icon(Icons.edit),
                  )
                : null,
          ),
        );
      },
    );
  }

  Color _getDiagnosisStatusColor(DiagnosisStatus status) {
    switch (status) {
      case DiagnosisStatus.active:
        return Colors.red;
      case DiagnosisStatus.chronic:
        return Colors.orange;
      case DiagnosisStatus.resolved:
        return Colors.green;
      case DiagnosisStatus.suspected:
        return Colors.blue;
      case DiagnosisStatus.ruled_out:
        return Colors.grey;
    }
  }

  Widget _buildMedicationsTab() {
    final medications = _patientSummary?['activeMedications'] as List<Medication>? ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: medications.length,
      itemBuilder: (context, index) {
        final medication = medications[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(
              Icons.medication,
              color: AppTheme.primaryColor,
            ),
            title: Text(medication.displayName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${medication.dosage} • ${medication.frequency}'),
                Text('Route: ${medication.route}'),
                if (medication.prescribedBy != null)
                  Text('Prescribed by: ${medication.prescribedBy}'),
              ],
            ),
            trailing: widget.isEditable
                ? IconButton(
                    onPressed: () {
                      // Edit medication
                    },
                    icon: const Icon(Icons.edit),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    final history = _patientSummary?['recentHistory'] as List<MedicalHistory>? ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(
              Icons.history,
              color: AppTheme.primaryColor,
            ),
            title: Text(item.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description),
                Text('${item.date.day}/${item.date.month}/${item.date.year}'),
                if (item.doctorName != null)
                  Text('By: ${item.doctorName}'),
              ],
            ),
            trailing: widget.isEditable
                ? IconButton(
                    onPressed: () {
                      // Edit history item
                    },
                    icon: const Icon(Icons.edit),
                  )
                : null,
          ),
        );
      },
    );
  }

  void _showAddDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medical Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Add Vital Signs'),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to add vitals
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning),
              title: const Text('Add Allergy'),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to add allergy
              },
            ),
            ListTile(
              leading: const Icon(Icons.medical_information),
              title: const Text('Add Diagnosis'),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to add diagnosis
              },
            ),
            ListTile(
              leading: const Icon(Icons.medication),
              title: const Text('Add Medication'),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to add medication
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportPatientData() async {
    try {
      final ehrService = context.read<EHRService>();
      final exportData = await ehrService.exportPatientData(widget.patientId);
      
      // In a real app, this would save to file or share
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient data exported successfully'),
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

