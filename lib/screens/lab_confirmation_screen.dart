import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/animated_button.dart';
import '../widgets/custom_app_bar.dart';
import '../models/lab_model.dart';

class LabConfirmationScreen extends StatefulWidget {
  final Lab lab;
  final List<String> testTypes;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String address;
  final bool isHomeVisit;

  const LabConfirmationScreen({
    super.key,
    required this.lab,
    required this.testTypes,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.address,
    required this.isHomeVisit,
  });

  @override
  State<LabConfirmationScreen> createState() => _LabConfirmationScreenState();
}

class _LabConfirmationScreenState extends State<LabConfirmationScreen> {
  bool _isSaving = false;
  Map<String, dynamic>? _phlebotomist;

  @override
  void initState() {
    super.initState();
    if (widget.isHomeVisit) {
      _loadRandomPhlebotomist();
    }
    _saveReservation();
  }

  Future<void> _loadRandomPhlebotomist() async {
    try {
      // Instead of fetching a doctor from database, use generic service information
      setState(() {
        _phlebotomist = {
          'id': 'home-service',
          'name': 'Medical Test Service',
          'rating': 5.0,
          'reviews': 120,
          'phone': '+1234567890',
          'specialization': 'Home Testing',
        };
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading service information: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveReservation() async {
    try {
      setState(() {
        _isSaving = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final reservationData = {
        'userId': user.uid,
        'labId': widget.lab.id,
        'labName': widget.lab.name,
        'testTypes': widget.testTypes,
        'preferredDate': Timestamp.fromDate(widget.appointmentDate),
        'preferredTime': widget.appointmentTime,
        'address': widget.address,
        'isHomeVisit': widget.isHomeVisit,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('testReservations')
          .add(reservationData);

      // Add to user's history
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .add({
        'type': 'test_reservation',
        'title': '${widget.testTypes.join(", ")} at ${widget.lab.name}',
        'date': FieldValue.serverTimestamp(),
        'details': {
          'labName': widget.lab.name,
          'testTypes': widget.testTypes,
          'preferredDate': Timestamp.fromDate(widget.appointmentDate),
          'preferredTime': widget.appointmentTime,
          'isHomeVisit': widget.isHomeVisit,
        },
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving reservation: ${e.toString()}'),
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

  Future<void> _launchMap() async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.lab.address)}',
    );
    if (!await launchUrl(url)) {
      throw Exception('Could not launch map');
    }
  }

  Future<void> _launchCall() async {
    if (widget.isHomeVisit && _phlebotomist != null) {
      final Uri url = Uri.parse('tel:${_phlebotomist!['phone']}');
      if (!await launchUrl(url)) {
        throw Exception('Could not launch call');
      }
    } else {
      final Uri url = Uri.parse('tel:${widget.lab.phone}');
      if (!await launchUrl(url)) {
        throw Exception('Could not launch call');
      }
    }
  }

  Future<void> _launchMessage() async {
    if (widget.isHomeVisit && _phlebotomist != null) {
      final Uri url = Uri.parse('sms:${_phlebotomist!['phone']}');
      if (!await launchUrl(url)) {
        throw Exception('Could not launch message');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Confirmation',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Success Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            // Heading
            Text(
              widget.isHomeVisit ? 'Test Scheduled Successfully!' : 'Lab Visit Scheduled!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              widget.isHomeVisit
                  ? 'Our medical service will visit your address on ${widget.appointmentDate.day}/${widget.appointmentDate.month}/${widget.appointmentDate.year} at ${widget.appointmentTime} to collect your sample.'
                  : 'Please visit ${widget.lab.name} on ${widget.appointmentDate.day}/${widget.appointmentDate.month}/${widget.appointmentDate.year} at ${widget.appointmentTime}.',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Lab/Phlebotomist Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isHomeVisit ? 'Service Details' : 'Lab Details',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(height: 24),
                  if (widget.isHomeVisit && _phlebotomist != null) ...[
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _phlebotomist!['photoUrl'] != null
                                ? Image.network(
                                    _phlebotomist!['photoUrl'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.blue.withOpacity(0.1),
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.blue,
                                          size: 30,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.blue.withOpacity(0.1),
                                    child: const Icon(
                                      Icons.medical_information,
                                      color: Colors.blue,
                                      size: 30,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _phlebotomist!['name'] ?? 'Medical Professional',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _phlebotomist!['specialization'] ?? 'Medical Professional',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              widget.lab.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.blue.withOpacity(0.1),
                                  child: const Icon(
                                    Icons.local_hospital,
                                    color: Colors.blue,
                                    size: 30,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.lab.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.lab.address,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _launchCall,
                          icon: const Icon(Icons.call),
                          label: const Text('Call'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.isHomeVisit ? _launchMessage : _launchCall,
                          icon: const Icon(Icons.message),
                          label: Text(widget.isHomeVisit ? 'Message' : 'Call Lab'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Test Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Test Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.vial,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.testTypes.join(", "),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              widget.isHomeVisit ? 'Home Collection' : 'Lab Visit',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
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
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Appointment Date',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.appointmentDate.day}/${widget.appointmentDate.month}/${widget.appointmentDate.year}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Appointment Time',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.appointmentTime,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (widget.isHomeVisit) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Collection Address',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.address,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            AnimatedButton(
              text: 'Done',
              icon: Icons.check_circle,
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
          ],
        ),
      ),
    );
  }
} 