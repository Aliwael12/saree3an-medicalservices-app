import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_theme.dart';
import '../services/doctor_service.dart';
import '../widgets/custom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../widgets/statistics_card.dart';
import '../models/doctor_model.dart';
import '../widgets/appointment_card.dart';
import '../widgets/stat_card.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final DoctorService _doctorService = DoctorService();
  bool _isLoading = true;
  Doctor? _doctor;
  List<Map<String, dynamic>> _appointments = [];
  int _totalAppointments = 0;
  int _pendingAppointments = 0;
  int _completedAppointments = 0;
  int _todayAppointments = 0;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
    _loadStatistics();
  }

  Future<void> _loadDoctorData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doctor = await _doctorService.getDoctorByUserId(user.uid);
      if (doctor != null) {
        setState(() {
          _doctor = doctor;
        });
      }

      print('Loading doctor data for user ID: ${user.uid}');
      print('Doctor data loaded: ${doctor?.name}');
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading doctor data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final appointments = await _getAppointmentsWithPatientNames();
      setState(() {
        _appointments = appointments;
        _updateStatistics(appointments);
      });
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  void _updateStatistics(List<Map<String, dynamic>> appointments) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _totalAppointments = appointments.length;
    _pendingAppointments = appointments.where((a) => a['status'] == 'pending').length;
    _completedAppointments = appointments.where((a) => a['status'] == 'completed').length;
    _todayAppointments = appointments.where((a) {
      if (a['appointmentDate'] == null) return false;
      final appointmentDate = (a['appointmentDate'] as Timestamp).toDate();
      final appointmentDay = DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
      );
      return appointmentDay.isAtSameMomentAs(today);
    }).length;
    
    print('Statistics updated: Total=$_totalAppointments, Pending=$_pendingAppointments, Completed=$_completedAppointments, Today=$_todayAppointments');
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await _doctorService.updateAppointmentStatus(
        docId: appointmentId,
        status: status,
      );
      
      // Force UI to refresh with updated data
      _refreshAppointments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating appointment: $e')),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  // Modified to load appointments and fetch patient names for each
  Future<List<Map<String, dynamic>>> _getAppointmentsWithPatientNames() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in');
      return [];
    }
    
    try {
      print('Fetching appointments for doctor ID: ${user.uid}');
      final snapshot = await FirebaseFirestore.instance
        .collection('doctorVisits')
        .where('doctorId', isEqualTo: user.uid)
        .orderBy('appointmentDate', descending: true)
        .get();
        
      final appointments = <Map<String, dynamic>>[];
      
      // Process each appointment
      for (final doc in snapshot.docs) {
        final appointment = {
          'id': doc.id,
          ...doc.data(),
        };
        
        // Try to get patient name if not already present
        String? patientName = _extractFieldValue(appointment, 'userName');
        if (patientName == null && appointment.containsKey('userId')) {
          final userId = appointment['userId'];
          if (userId != null) {
            final name = await _fetchUserNameFromId(userId.toString());
            if (name != null && name.isNotEmpty) {
              appointment['userName'] = name;
              patientName = name;
              print('Added patient name from user ID for appointment ${doc.id}: $name');
            }
          }
        }
        
        // If still no name, check other fields
        if (patientName == null) {
          final possibleNameFields = [
            'user_name',
            'patientName',
            'patient_name',
            'name',
            'fullName',
            'full_name'
          ];
          
          for (final field in possibleNameFields) {
            if (appointment.containsKey(field) && appointment[field] != null) {
              appointment['userName'] = appointment[field];
              patientName = appointment[field].toString();
              print('Added patient name from $field for appointment ${doc.id}: $patientName');
              break;
            }
          }
        }
        
        // Use default name if still not found
        if (patientName == null) {
          appointment['userName'] = 'Patient';
          print('Using default name for appointment ${doc.id}');
        }
        
        appointments.add(appointment);
      }
      
      print('Fetched ${appointments.length} appointments with patient names');
      return appointments;
    } catch (e) {
      print('Error fetching appointments: $e');
      return [];
    }
  }

  // Original method for backward compatibility
  Stream<QuerySnapshot> _getAppointmentsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in');
      return Stream.empty();
    }

    print('Setting up appointments stream for doctor ID: ${user.uid}');
    return FirebaseFirestore.instance
        .collection('doctorVisits')
        .where('doctorId', isEqualTo: user.uid)
        .orderBy('appointmentDate', descending: true)
        .snapshots();
  }

  // Add a key to force rebuild
  final _futureBuilderKey = GlobalKey();
  
  // Method to force refresh appointments
  void _refreshAppointments() {
    setState(() {
      // This will rebuild the entire screen, including the FutureBuilder
    });
    // Also refresh statistics
    _loadStatistics();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_doctor == null) {
      return const Scaffold(
        body: Center(
          child: Text('No doctor data found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, Dr. ${_doctor!.name}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.2,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              children: [
                StatisticsCard(
                  title: 'Total Appointments',
                  value: _totalAppointments.toString(),
                  icon: Icons.calendar_today,
                  color: Colors.blue,
                ),
                StatisticsCard(
                  title: 'Completed',
                  value: _completedAppointments.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                StatisticsCard(
                  title: 'Pending',
                  value: _pendingAppointments.toString(),
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
                StatisticsCard(
                  title: 'Today',
                  value: _todayAppointments.toString(),
                  icon: Icons.today,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointment Distribution',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: _completedAppointments.toDouble(),
                              title: 'Completed',
                              color: Colors.green,
                              radius: 50,
                            ),
                            PieChartSectionData(
                              value: _pendingAppointments.toDouble(),
                              title: 'Pending',
                              color: Colors.orange,
                              radius: 50,
                            ),
                          ],
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Statistics',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Today\'s Appointments',
                            value: _todayAppointments.toString(),
                            icon: Icons.today,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Appointments',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              key: _futureBuilderKey,
              future: _appointments.isNotEmpty ? Future.value(_appointments) : _getAppointmentsWithPatientNames(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Error in appointments future: ${snapshot.error}');
                  return Center(
                    child: Text('Error loading appointments: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting && _appointments.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No appointments found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                final appointments = snapshot.data!;
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    final date = (appointment['appointmentDate'] ?? appointment['date']) as Timestamp;
                    final formattedDate = DateFormat('MMM dd, yyyy').format(date.toDate());
                    final formattedTime = DateFormat('hh:mm a').format(date.toDate());

                    // Get patient name from the appointment data
                    final patientName = appointment['userName'] ?? 'Patient';
                    print('Displaying patient name for appointment ${appointment['id']}: $patientName');
                    
                    // Extract coordinates with better error handling
                    double? latitude;
                    double? longitude;
                    String? address;
                    
                    try {
                      // Try standard location fields
                      var latValue = appointment['latitude'];
                      var lngValue = appointment['longitude'];
                      address = appointment['address']?.toString();
                      
                      // Check if address field actually contains coordinates
                      if (address != null && latitude == null && longitude == null) {
                        final parts = address.split(',');
                        if (parts.length == 2) {
                          // Try to parse coordinates from the address field
                          final lat = double.tryParse(parts[0].trim());
                          final lng = double.tryParse(parts[1].trim());
                          
                          if (lat != null && lng != null) {
                            print('Found coordinates in address field: $lat, $lng');
                            latitude = lat;
                            longitude = lng;
                            // Set a generic address since we're using the address field for coordinates
                            address = 'Click to open location';
                          }
                        }
                      }
                      
                      // Parse latitude and longitude
                      if (latValue != null && lngValue != null) {
                        if (latValue is double) {
                          latitude = latValue;
                        } else if (latValue is num) {
                          latitude = latValue.toDouble();
                        } else if (latValue is String) {
                          latitude = double.tryParse(latValue);
                        }
                        
                        if (lngValue is double) {
                          longitude = lngValue;
                        } else if (lngValue is num) {
                          longitude = lngValue.toDouble();
                        } else if (lngValue is String) {
                          longitude = double.tryParse(lngValue);
                        }
                      }
                    } catch (e) {
                      print('Error parsing coordinates: $e');
                    }
                    
                    // Ensure we have a fallback address
                    if (address == null || address.trim().isEmpty) {
                      address = 'Location not available';
                    }
                    
                    return AppointmentCard(
                      patientName: patientName,
                      date: formattedDate,
                      time: formattedTime,
                      status: appointment['status'] ?? 'pending',
                      onComplete: () => _updateAppointmentStatus(appointment['id'], 'completed'),
                      latitude: latitude,
                      longitude: longitude,
                      address: address,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to extract values from potentially nested fields
  String? _extractFieldValue(Map<String, dynamic> data, String fieldPath) {
    final parts = fieldPath.split('.');
    dynamic value = data;
    
    for (final part in parts) {
      if (value is Map && value.containsKey(part)) {
        value = value[part];
      } else {
        return null;
      }
    }
    
    return value?.toString();
  }
  
  // Helper method to fetch user name from Firestore using the user ID
  Future<String?> _fetchUserNameFromId(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final userData = doc.data()!;
        if (userData.containsKey('name')) {
          return userData['name']?.toString();
        } else if (userData.containsKey('fullName')) {
          return userData['fullName']?.toString();
        } else if (userData.containsKey('displayName')) {
          return userData['displayName']?.toString();
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user name from ID: $e');
      return null;
    }
  }
} 