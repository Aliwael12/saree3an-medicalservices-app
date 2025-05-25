import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../models/doctor_model.dart';
import '../services/doctor_service.dart';
import 'doctor_confirmation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class DoctorVisitScreen extends StatefulWidget {
  const DoctorVisitScreen({super.key});

  @override
  State<DoctorVisitScreen> createState() => _DoctorVisitScreenState();
}

class _DoctorVisitScreenState extends State<DoctorVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  bool _isLoadingLocation = false;
  final DoctorService _doctorService = DoctorService();
  bool _isLoading = false;
  Position? _currentPosition;
  Doctor? _selectedDoctor;

  @override
  void dispose() {
    _addressController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _addressController.text = '${position.latitude}, ${position.longitude}';
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Doctor> _getRandomDoctor() async {
    try {
      print('Fetching doctors from users collection...');
      
      // Get users with the role 'doctor' from the users collection
      final doctorsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();
      
      print('Found ${doctorsSnapshot.size} doctors in users collection');
      
      if (doctorsSnapshot.docs.isEmpty) {
        print('No doctors found in the database');
        throw Exception('No doctors available');
      }
      
      // Get a random doctor from the list
      final randomIndex = Random().nextInt(doctorsSnapshot.docs.length);
      final doctorDoc = doctorsSnapshot.docs[randomIndex];
      final doctorData = doctorDoc.data();
      
      // Get the doctor's name, ensuring we have a valid name
      final doctorName = doctorData['name'] ?? 
                        doctorData['fullName'] ?? 
                        '${doctorData['fname'] ?? ''} ${doctorData['lname'] ?? ''}'.trim() ?? 
                        'Dr. Unknown';
      
      if (doctorName.isEmpty) {
        throw Exception('Doctor name is empty');
      }
      
      print('Selected doctor data:');
      print('ID: ${doctorDoc.id}');
      print('Name: $doctorName');
      print('Data: $doctorData');
      
      return Doctor(
        id: doctorDoc.id,
        name: doctorName,
        specialty: doctorData['specialty'] ?? 'General Medicine',
        imageUrl: doctorData['profilePicture'] ?? 'https://randomuser.me/api/portraits/men/${Random().nextInt(50)}.jpg',
        rating: (doctorData['rating'] ?? 4.5 + Random().nextDouble() * 0.5).toDouble(),
        reviews: doctorData['reviews'] ?? Random().nextInt(100) + 20,
        experience: doctorData['experience'] is String ? doctorData['experience'] : '${Random().nextInt(15) + 5} years',
        education: doctorData['education'] ?? 'Medical School',
        languages: List<String>.from(doctorData['languages'] ?? ['Arabic', 'English']),
        isAvailable: doctorData['isAvailable'] ?? true,
        consultationFee: (doctorData['consultationFee'] ?? 200.0 + Random().nextInt(200)).toDouble(),
      );
    } catch (e) {
      print('Error getting random doctor: $e');
      rethrow;
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isLoading = true;
        });
        
        final doctor = await _getRandomDoctor();
        print('Got doctor: ${doctor.name} with ID: ${doctor.id}');
        
        if (doctor.id.isEmpty || doctor.name.isEmpty) {
          throw Exception('Invalid doctor data - missing ID or name');
        }

        // Get current user
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not authenticated');
        }

        // Get the doctor's user ID from the users collection
        final doctorDoc = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'doctor')
            .get();

        if (doctorDoc.docs.isEmpty) {
          throw Exception('No doctors found in users collection');
        }

        print('Selected doctor name: ${doctor.name}');
        print('Available doctors in users collection:');
        for (var doc in doctorDoc.docs) {
          final data = doc.data();
          print('Doctor: ${data['name'] ?? data['fullName']} (ID: ${doc.id})');
        }

        // Find the doctor by matching their name
        final matchingDoctor = doctorDoc.docs.firstWhere(
          (doc) {
            final data = doc.data();
            final docName = data['name'] ?? data['fullName'] ?? '';
            print('Comparing: "$docName" with "${doctor.name}"');
            return docName == doctor.name; // Exact match since we're using the same name
          },
          orElse: () => throw Exception('Could not find matching doctor user record'),
        );

        final doctorUserId = matchingDoctor.id;
        print('Found doctor user record with ID: $doctorUserId');

        // Ensure we have coordinates
        if (_currentPosition == null) {
          throw Exception('Location coordinates are required');
        }

        // Fetch patient data from users collection
        final patientDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        final patientData = patientDoc.data();
        final patientName = patientData?['name'] ?? 
                          patientData?['fullName'] ?? 
                          '${patientData?['fname'] ?? ''} ${patientData?['lname'] ?? ''}'.trim() ?? 
                          'Unknown Patient';

        // Create appointment data
        final appointmentData = {
          'doctorId': doctorUserId, // Use the doctor's user ID
          'doctorName': doctor.name,
          'doctorSpecialty': doctor.specialty,
          'userId': user.uid,
          'userName': patientName, // Use the fetched patient name
          'userEmail': user.email,
          'appointmentDate': Timestamp.fromDate(_selectedDate),
          'appointmentTime': _selectedTime.format(context),
          'symptoms': _symptomsController.text.trim(),
          'address': _addressController.text.trim(),
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        };

        print('Saving appointment with doctor ID: $doctorUserId');

        // Save to doctorVisits collection
        final docRef = await FirebaseFirestore.instance
            .collection('doctorVisits')
            .add(appointmentData);
        
        // Navigate to confirmation screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorConfirmationScreen(
                doctor: doctor,
                appointmentDate: _selectedDate,
                appointmentTime: _selectedTime,
                symptoms: _symptomsController.text.trim(),
                address: _addressController.text.trim(),
              ),
            ),
          );
        }
      } catch (e) {
        print('Error in _submitForm: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Doctor Visit',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.withOpacity(0.1),
                      Colors.blue.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Provide your details to schedule a home visit. A doctor will be assigned to you.',
                        style: TextStyle(
                          color: Colors.black87.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Appointment Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.blue.withOpacity(0.05),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.blue,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.blue,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _selectTime(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.blue.withOpacity(0.05),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.blue,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedTime.format(context),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.blue,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                          prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isLoadingLocation ? Icons.hourglass_empty : Icons.my_location,
                              color: Colors.blue,
                            ),
                            onPressed: _isLoadingLocation ? null : _getLocation,
                          ),
                          filled: true,
                          fillColor: Colors.blue.withOpacity(0.05),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _symptomsController,
                        decoration: InputDecoration(
                          labelText: 'Symptoms (Optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                          prefixIcon: const Icon(Icons.medical_information, color: Colors.blue),
                          filled: true,
                          fillColor: Colors.blue.withOpacity(0.05),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.1, end: 0),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Book Appointment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
} 