import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../models/doctor_model.dart';
import '../services/doctor_service.dart';
import '../services/doctor_appointment_service.dart';
import '../widgets/custom_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorConfirmationScreen extends StatefulWidget {
  final Doctor doctor;
  final DateTime appointmentDate;
  final TimeOfDay appointmentTime;
  final String symptoms;
  final String address;

  const DoctorConfirmationScreen({
    super.key,
    required this.doctor,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.symptoms,
    required this.address,
  });

  @override
  State<DoctorConfirmationScreen> createState() => _DoctorConfirmationScreenState();
}

class _DoctorConfirmationScreenState extends State<DoctorConfirmationScreen> {
  bool _isSaving = false;
  bool _hasInitialized = false;
  final DoctorAppointmentService _appointmentService = DoctorAppointmentService();
  String? _appointmentTime;
  Map<String, dynamic>? _doctorUserData;

  // Check authentication and user status
  Future<bool> _verifyAuthentication() async {
    try {
      print('Verifying authentication...');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Error: User is not authenticated');
        return false;
      }
      
      print('Current user: ${user.uid}, Email: ${user.email}');
      
      // Check if user token is valid
      try {
        final idToken = await user.getIdToken();
        if (idToken != null && idToken.isNotEmpty) {
          print('User token is valid: ${idToken.substring(0, math.min(10, idToken.length))}...');
        } else {
          print('Retrieved ID token is null or empty');
        }
      } catch (e) {
        print('Failed to get ID token: $e');
        return false;
      }
      
      // Try to get the user from Firestore to verify database access
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
            
        if (!userDoc.exists) {
          print('User document does not exist in Firestore!');
          return false;
        }
        
        print('User document exists: ${userDoc.data()}');
        return true;
      } catch (e) {
        print('Failed to access user document: $e');
        return false;
      }
    } catch (e) {
      print('Authentication verification failed: $e');
      return false;
    }
  }
  
  @override
  void initState() {
    super.initState();
    _loadDoctorUserData();
    // Store the formatted time in initState to avoid context dependency
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _appointmentTime = widget.appointmentTime.format(context);
        });
      }
    });
  }

  Future<void> _loadDoctorUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.doctor.id)
          .get();
      
      if (userDoc.exists) {
        setState(() {
          _doctorUserData = userDoc.data();
        });
      }
    } catch (e) {
      print('Error loading doctor user data: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      _verifyAuthentication().then((isAuthenticated) {
        if (!isAuthenticated && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication error. Please sign in again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  Future<void> _saveAppointment() async {
    if (!mounted) {
      print('Widget is not mounted, cancelling save operation');
      return;
    }
    
    try {
      if (mounted) {
        setState(() {
          _isSaving = true;
        });
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Error: User not authenticated');
        throw Exception('User not authenticated');
      }

      print('Saving appointment for user: ${user.uid}');
      print('Doctor ID: ${widget.doctor.id}');
      print('Appointment Date: ${widget.appointmentDate}');

      // Create appointment data
      final appointmentData = {
        'userId': user.uid,
        'doctorId': widget.doctor.id,
        'doctorName': widget.doctor.name,
        'doctorSpecialty': widget.doctor.specialty,
        'appointmentDate': widget.appointmentDate,
        'appointmentTime': _appointmentTime,
        'symptoms': widget.symptoms,
        'address': widget.address,
        'consultationFee': widget.doctor.consultationFee,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await _appointmentService.saveAppointment(appointmentData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving appointment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving appointment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Appointment Confirmed',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 36,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Appointment Booked Successfully!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your appointment has been confirmed. A confirmation has been sent to your email.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0),
              const SizedBox(height: 24),
              _buildDoctorCard().animate().fadeIn(duration: 800.ms),
              const SizedBox(height: 24),
              _buildAppointmentDetailsCard(context).animate().fadeIn(delay: 200.ms, duration: 800.ms),
              const SizedBox(height: 24),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Return to Home',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 800.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard() {
    return Card(
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
              'Doctor Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _doctorUserData?['name'] ?? 
                        _doctorUserData?['fullName'] ?? 
                        '${_doctorUserData?['fname'] ?? ''} ${_doctorUserData?['lname'] ?? ''}'.trim() ?? 
                        widget.doctor.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.doctor.specialty,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_doctorUserData?['phone'] != null) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 16,
                              color: Colors.black87,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _doctorUserData!['phone'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        children: [
                          const Icon(
                            Icons.school,
                            size: 16,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.doctor.education,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildRatingStars(widget.doctor.rating),
                const SizedBox(width: 8),
                Text(
                  widget.doctor.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  '/5 (${widget.doctor.reviews} reviews)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageChip(String language) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Text(
        language,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildAppointmentDetailsCard(BuildContext context) {
    return Card(
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.calendar_today,
              'Date',
              '${widget.appointmentDate.day}/${widget.appointmentDate.month}/${widget.appointmentDate.year}',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.access_time,
              'Time',
              widget.appointmentTime.format(context),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.location_on,
              'Address',
              widget.address,
            ),
            if (widget.symptoms.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.medical_information,
                'Symptoms',
                widget.symptoms,
              ),
            ],
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.monetization_on,
              'Consultation Fee',
              'EGP ${widget.doctor.consultationFee.toStringAsFixed(0)}',
              valueColor: Colors.blue,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                // Extract coordinates from address string
                if (widget.address.contains(',')) {
                  final coords = widget.address.split(',');
                  if (coords.length == 2) {
                    final lat = coords[0].trim();
                    final lng = coords[1].trim();
                    final url = 'https://www.google.com/maps?q=$lat,$lng';
                    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  }
                }
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.map,
                    size: 18,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'View Location on Map',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.blue,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.orange, size: 18);
        } else if (index == rating.floor() && rating % 1 > 0) {
          return const Icon(Icons.star_half, color: Colors.orange, size: 18);
        } else {
          return const Icon(Icons.star_border, color: Colors.orange, size: 18);
        }
      }),
    );
  }
} 