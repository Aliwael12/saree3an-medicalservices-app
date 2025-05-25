import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';

import '../constants/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/animated_button.dart';
import '../theme/app_theme.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  final _formKey = GlobalKey<FormState>();

  final List<Map<String, dynamic>> _specialties = [
    {
      'name': 'General Physician',
      'icon': FontAwesomeIcons.userDoctor,
      'description': 'For general health concerns, fever, cough, or flu.',
    },
    {
      'name': 'Pediatrician',
      'icon': FontAwesomeIcons.childReaching,
      'description': "Specializes in children's health from infancy to adolescence.",
    },
    {
      'name': 'Cardiologist',
      'icon': FontAwesomeIcons.heartPulse,
      'description': 'Heart-related issues, chest pain, or high blood pressure.',
    },
    {
      'name': 'Dermatologist',
      'icon': FontAwesomeIcons.allergies,
      'description': 'Skin conditions, allergies, or rashes.',
    },
    {
      'name': 'Orthopedic',
      'icon': FontAwesomeIcons.personWalking,
      'description': 'Bone and joint issues, fractures, or sprains.',
    },
  ];

  final List<String> _timeSlots = [
    '09:00 AM - 11:00 AM',
    '11:00 AM - 01:00 PM',
    '02:00 PM - 04:00 PM',
    '04:00 PM - 06:00 PM',
    '06:00 PM - 08:00 PM',
  ];

  int _selectedSpecialtyIndex = 0;
  String _selectedDate = '';
  String _selectedTimeSlot = '';
  bool _isBooking = false;
  bool _isBooked = false;

  @override
  void initState() {
    super.initState();
    // Set default selected date to tomorrow's date
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _selectedDate = '${tomorrow.day}/${tomorrow.month}/${tomorrow.year}';
    _selectedTimeSlot = _timeSlots[0];
  }

  void _bookDoctor() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isBooking = true;
      });

      // Simulate booking process
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isBooking = false;
          _isBooked = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const CustomAppBar(
        title: 'Home Doctor Visit',
      ),
      body: _isBooked ? _buildBookingConfirmation() : _buildBookingForm(),
    );
  }

  Widget _buildBookingForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Select a Specialty'),
            const SizedBox(height: 16),
            _buildSpecialtySelector(),
            const SizedBox(height: 24),
            _buildSectionTitle('Patient Information'),
            const SizedBox(height: 16),
            _buildPatientForm(),
            const SizedBox(height: 24),
            _buildSectionTitle('Select Date and Time'),
            const SizedBox(height: 16),
            _buildDateTimePicker(),
            const SizedBox(height: 24),
            _buildSpecialInstructions(),
            const SizedBox(height: 24),
            AnimatedButton(
              text: 'Book Doctor Visit',
              icon: FontAwesomeIcons.calendarPlus,
              onPressed: _bookDoctor,
              isLoading: _isBooking,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildSpecialtySelector() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _specialties.length,
        itemBuilder: (context, index) {
          final specialty = _specialties[index];
          final isSelected = index == _selectedSpecialtyIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSpecialtyIndex = index;
              });
            },
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    specialty['icon'],
                    size: 32,
                    color: isSelected ? AppTheme.white : AppTheme.primary,
                  ).animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  ).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1000.ms),
                  const SizedBox(height: 12),
                  Text(
                    specialty['name'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.white : AppTheme.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      specialty['description'],
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? AppTheme.white.withOpacity(0.8) : AppTheme.textLight,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (100 * index).ms, duration: 300.ms),
          );
        },
      ),
    );
  }

  Widget _buildPatientForm() {
    return Column(
      children: [
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Patient Name',
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the patient name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Age',
            prefixIcon: Icon(Icons.cake),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter patient age';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Address',
            prefixIcon: Icon(Icons.location_on),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );

            if (pickedDate != null) {
              setState(() {
                _selectedDate = '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppTheme.primary),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textLight,
                      ),
                    ),
                    Text(
                      _selectedDate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Select Time Slot',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _timeSlots.map((timeSlot) {
            final isSelected = timeSlot == _selectedTimeSlot;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTimeSlot = timeSlot;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.textLight.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  timeSlot,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.white : AppTheme.textDark,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpecialInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Special Instructions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: const InputDecoration(
            hintText: 'Any special notes or requirements?',
            prefixIcon: Icon(Icons.notes),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildBookingConfirmation() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network(
              'https://assets10.lottiefiles.com/packages/lf20_jbrw3hcz.json',
              height: 200,
              repeat: true,
              animate: true,
            ),
            const SizedBox(height: 24),
            const Text(
              'Booking Confirmed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ).animate().fadeIn(duration: 600.ms).shimmer(),
            const SizedBox(height: 16),
            Text(
              'Your doctor visit has been scheduled for $_selectedDate, $_selectedTimeSlot.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 24),
            _buildConfirmationDetails(),
            const SizedBox(height: 32),
            AnimatedButton(
              text: 'Return to Home',
              icon: Icons.home,
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationDetails() {
    final specialty = _specialties[_selectedSpecialtyIndex];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildConfirmationRow(
            icon: FontAwesomeIcons.userDoctor,
            title: 'Specialty',
            value: specialty['name'],
          ),
          const Divider(height: 24),
          _buildConfirmationRow(
            icon: Icons.calendar_today,
            title: 'Date',
            value: _selectedDate,
          ),
          const Divider(height: 24),
          _buildConfirmationRow(
            icon: Icons.access_time,
            title: 'Time',
            value: _selectedTimeSlot,
          ),
          const Divider(height: 24),
          _buildConfirmationRow(
            icon: Icons.confirmation_number,
            title: 'Booking ID',
            value: 'DOC-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildConfirmationRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textLight,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
} 