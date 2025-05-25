import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class TestConfirmationScreen extends StatefulWidget {
  final String testType;
  final DateTime date;
  final String time;
  final String medicName;
  final String address;

  const TestConfirmationScreen({
    super.key,
    required this.testType,
    required this.date,
    required this.time,
    required this.medicName,
    required this.address,
  });

  @override
  State<TestConfirmationScreen> createState() => _TestConfirmationScreenState();
}

class _TestConfirmationScreenState extends State<TestConfirmationScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _doctorInfo;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchRandomDoctor();
  }

  Future<void> _fetchRandomDoctor() async {
    try {
      // Query for users with role 'doctor'
      final doctorsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .limit(10)
          .get();

      if (doctorsQuery.docs.isNotEmpty) {
        // Pick a random doctor from the results
        final random = Random();
        final randomIndex = random.nextInt(doctorsQuery.docs.length);
        final doctorDoc = doctorsQuery.docs[randomIndex];
        final doctorData = doctorDoc.data();

        // Create a doctor info object with available fields
        setState(() {
          _doctorInfo = {
            'id': doctorDoc.id,
            'name': doctorData['name'] ?? 
                    '${doctorData['firstName'] ?? ''} ${doctorData['lastName'] ?? ''}' ?? 
                    'Dr. Ahmed Mohamed',
            'specialty': doctorData['specialty'] ?? 'General Medicine',
            'phone': doctorData['phone'] ?? doctorData['phoneNumber'] ?? '+201234567890',
            'email': doctorData['email'] ?? 'doctor@example.com',
            'experience': doctorData['experience'] ?? '5+ years',
          };
          _isLoading = false;
        });
      } else {
        // Fallback to default data if no doctors found
        setState(() {
          _doctorInfo = {
            'id': 'default-doctor-1',
            'name': 'Dr. Ahmed Mohamed',
            'specialty': 'Laboratory Medicine',
            'phone': '+201234567890',
            'email': 'doctor@example.com',
            'experience': '5+ years',
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching doctor: $e');
      // Fallback to default data
      setState(() {
        _doctorInfo = {
          'id': 'default-doctor-1',
          'name': 'Dr. Ahmed Mohamed',
          'specialty': 'Laboratory Medicine',
          'phone': '+201234567890',
          'email': 'doctor@example.com',
          'experience': '5+ years',
        };
        _isLoading = false;
      });
    }
  }

  void _launchPhone() async {
    // Use the doctor's phone number if available
    final phoneNumber = _doctorInfo?['phone'] ?? '+201234567890';
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(phoneUri);
  }

  void _launchEmail() async {
    // Use the doctor's email if available
    final email = _doctorInfo?['email'] ?? 'support@sareean.com';
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Regarding my test appointment&body=Hello, I have a question about my test appointment on ${DateFormat('dd/MM/yyyy').format(widget.date)} at ${widget.time}.',
    );
    await launchUrl(emailUri);
  }

  void _launchMap(BuildContext context) async {
    try {
      // Extract coordinates if available
      if (widget.address.contains(',')) {
        final coords = widget.address.split(',');
        if (coords.length == 2) {
          final lat = coords[0].trim();
          final lng = coords[1].trim();
          final Uri mapUri = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
          await launchUrl(mapUri, mode: LaunchMode.externalApplication);
          return;
        }
      }

      // Fallback to address search
      final encodedAddress = Uri.encodeComponent(widget.address);
      final Uri mapUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$encodedAddress');
      await launchUrl(mapUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open maps: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Test Confirmation'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Success indicator
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 80,
                        ),
                      ),
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 24),
                  
                  // Confirmation message
                  Center(
                    child: Text(
                      'Test Reservation Confirmed!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 8),
                  
                  Center(
                    child: Text(
                      'Your test has been scheduled successfully',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Confirmation card
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.medical_services, 'Test Type', widget.testType),
                          _buildDetailRow(Icons.calendar_today, 'Date', DateFormat('EEEE, MMM d, yyyy').format(widget.date)),
                          _buildDetailRow(Icons.access_time, 'Time', widget.time),
                          _buildDetailRow(Icons.person, 'Doctor', _doctorInfo?['name'] ?? 'Dr. Ahmed Mohamed'),
                          _buildDetailRow(Icons.medical_information, 'Specialty', _doctorInfo?['specialty'] ?? 'Laboratory Medicine'),
                          _buildDetailRow(Icons.star, 'Experience', _doctorInfo?['experience'] ?? '5+ years'),
                          _buildDetailRow(Icons.location_on, 'Address', widget.address, isLocation: true, onTap: () => _launchMap(context)),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.1, end: 0),
                  const SizedBox(height: 24),
                  
                  // Contact card
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
                            'Need Help?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildContactButton(
                                icon: FontAwesomeIcons.phone,
                                label: 'Call Doctor',
                                color: Colors.green,
                                onTap: _launchPhone,
                              ),
                              _buildContactButton(
                                icon: FontAwesomeIcons.envelope,
                                label: 'Email Doctor',
                                color: Colors.blue,
                                onTap: _launchEmail,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 24),
                  
                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Important Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Please be available at the specified address at least 15 minutes before the appointment time.',
                          style: TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '• The doctor will bring all necessary equipment for your test.',
                          style: TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '• You will receive the test results within 24-48 hours via email.',
                          style: TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '• Payment can be made to the doctor at the time of the test.',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 1000.ms),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isLocation = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: isLocation ? onTap : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blue, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isLocation ? Colors.blue : Colors.black87,
                    ),
                  ),
                  if (isLocation)
                    const Text(
                      'Tap to open in maps',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
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

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: FaIcon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 