import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/availability_service.dart';
import '../../services/appointment_service.dart';
import '../../utils/app_theme.dart';
import '../../models/appointment_model.dart';

class AdvancedBookingScreen extends StatefulWidget {
  final String? preferredSpecialization;
  final String? urgency;

  const AdvancedBookingScreen({
    super.key,
    this.preferredSpecialization,
    this.urgency,
  });

  @override
  State<AdvancedBookingScreen> createState() => _AdvancedBookingScreenState();
}

class _AdvancedBookingScreenState extends State<AdvancedBookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedDoctorId;
  String? _selectedTimeSlot;
  List<Map<String, dynamic>> _availableDoctors = [];
  List<String> _availableTimeSlots = [];
  bool _isLoading = false;
  String _selectedSpecialization = 'General Practice';

  final List<String> _specializations = [
    'General Practice',
    'Cardiology',
    'Dermatology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'Psychiatry',
    'Radiology',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSpecialization = widget.preferredSpecialization ?? 'General Practice';
    _loadAvailableDoctors();
  }

  Future<void> _loadAvailableDoctors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final availabilityService = context.read<AvailabilityService>();
      final doctors = await availabilityService.getAvailableDoctors(
        _selectedSpecialization,
        _selectedDate,
      );

      setState(() {
        _availableDoctors = doctors;
        _selectedDoctorId = null;
        _selectedTimeSlot = null;
        _availableTimeSlots = [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading doctors: $e'),
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

  Future<void> _loadTimeSlots(String doctorId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final availabilityService = context.read<AvailabilityService>();
      final timeSlots = await availabilityService.getAvailableTimeSlots(
        doctorId,
        _selectedDate,
      );

      setState(() {
        _availableTimeSlots = timeSlots;
        _selectedTimeSlot = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading time slots: $e'),
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

  Future<void> _bookAppointment() async {
    if (_selectedDoctorId == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a doctor and time slot'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final appointmentService = context.read<AppointmentService>();
      final selectedDoctor = _availableDoctors.firstWhere(
        (doctor) => doctor['id'] == _selectedDoctorId,
      );

      final appointment = Appointment(
        id: '',
        patientId: 'current_user_id', // Replace with actual user ID
        doctorId: _selectedDoctorId!,
        doctorName: selectedDoctor['name'],
        specialization: _selectedSpecialization,
        appointmentDate: _selectedDate,
        timeSlot: _selectedTimeSlot!,
        status: 'pending',
        urgency: widget.urgency ?? 'medium',
      );

      await appointmentService.createAppointment(appointment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
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
        title: const Text('Book Appointment'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Specialization Selection
                  _buildSpecializationSection(),
                  const SizedBox(height: 24),

                  // Calendar
                  _buildCalendarSection(),
                  const SizedBox(height: 24),

                  // Available Doctors
                  _buildDoctorsSection(),
                  const SizedBox(height: 24),

                  // Time Slots
                  if (_selectedDoctorId != null) _buildTimeSlotsSection(),
                ],
              ),
            ),
          ),

          // Book Button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedDoctorId != null && _selectedTimeSlot != null
                    ? _bookAppointment
                    : null,
                child: const Text('Book Appointment'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Specialization',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedSpecialization,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _specializations.map((specialization) =>
                DropdownMenuItem(
                  value: specialization,
                  child: Text(specialization),
                )
              ).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSpecialization = value;
                    _selectedDoctorId = null;
                    _selectedTimeSlot = null;
                  });
                  _loadAvailableDoctors();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Date',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TableCalendar<Event>(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _selectedDate,
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              onDaySelected: (selectedDay, focusedDay) {
                if (!selectedDay.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
                  setState(() {
                    _selectedDate = selectedDay;
                    _selectedDoctorId = null;
                    _selectedTimeSlot = null;
                  });
                  _loadAvailableDoctors();
                }
              },
              enabledDayPredicate: (day) {
                return !day.isBefore(DateTime.now().subtract(const Duration(days: 1)));
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                disabledDecoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Doctors',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_availableDoctors.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No doctors available for the selected date and specialization',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _availableDoctors.map((doctor) =>
                  _buildDoctorCard(doctor)
                ).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final isSelected = _selectedDoctorId == doctor['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDoctorId = doctor['id'];
          });
          _loadTimeSlots(doctor['id']);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  doctor['name'][0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor['name'],
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      doctor['specialization'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${doctor['rating']?.toStringAsFixed(1) ?? '0.0'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${doctor['availableSlots']?.length ?? 0} slots',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Time Slots',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_availableTimeSlots.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No available time slots for this doctor on the selected date',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTimeSlots.map((timeSlot) =>
                  _buildTimeSlotChip(timeSlot)
                ).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotChip(String timeSlot) {
    final isSelected = _selectedTimeSlot == timeSlot;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTimeSlot = timeSlot;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          timeSlot,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class Event {
  final String title;
  Event(this.title);
}

