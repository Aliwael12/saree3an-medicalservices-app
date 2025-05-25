import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/statistics_card.dart';
import '../models/medic_model.dart';
import '../services/medic_service.dart';
import 'test_confirmation_screen.dart';

class MedicDashboardScreen extends StatefulWidget {
  const MedicDashboardScreen({super.key});

  @override
  State<MedicDashboardScreen> createState() => _MedicDashboardScreenState();
}

class _MedicDashboardScreenState extends State<MedicDashboardScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final MedicService _medicService = MedicService();
  bool _isLoading = true;
  Medic? _medic;
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoadingAppointments = false; // Flag to prevent recursion
  Map<String, dynamic> _statistics = {
    'totalVisits': 0,
    'completedVisits': 0,
    'pendingVisits': 0,
    'todayVisits': 0,
  };

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMedicData();
  }

  Future<void> _loadMedicData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Loading medic data for user ID: ${user.uid}');
        // Try to get existing medic record
        final medic = await _medicService.getMedicByUserId(user.uid);
        
        if (medic != null) {
          print('Found existing medic record: ${medic.id}');
          setState(() {
            _medic = medic;
            _isLoading = false;
          });
          _loadAppointments();
        } else {
          print('No medic record found, creating one from user data');
          // No medic record found, try to create one from user data
          try {
            // Get user data from users collection
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
                
            if (userDoc.exists) {
              final userData = userDoc.data();
              if (userData != null) {
                print('User data found: $userData');
                
                // Create a new medic record in the medics collection
                final medicData = {
                  'name': userData['name'] ?? 'Unknown Medic',
                  'experience': 0, // Default experience
                  'userId': user.uid,
                  'createdAt': FieldValue.serverTimestamp(),
                };
                
                print('Creating new medic record with data: $medicData');
                final docRef = await FirebaseFirestore.instance
                    .collection('medics')
                    .add(medicData);
                    
                // Get the newly created medic with its ID
                final newMedic = Medic(
                  id: docRef.id,
                  name: medicData['name'] as String,
                  experience: medicData['experience'] as int,
                  userId: user.uid,
                );
                
                print('Created new medic record with ID: ${newMedic.id}');
                setState(() {
                  _medic = newMedic;
                  _isLoading = false;
                });
                _loadAppointments();
              } else {
                print('User document exists but data is null');
                setState(() {
                  _isLoading = false;
                });
              }
            } else {
              print('User document does not exist');
              setState(() {
                _isLoading = false;
              });
            }
          } catch (createError) {
            print('Error creating medic record: $createError');
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        print('No user is currently signed in');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _loadMedicData: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading medic data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _loadAppointments() {
    // Prevent recursion by checking if we're already loading
    if (_medic != null && !_isLoadingAppointments) {
      _isLoadingAppointments = true;
      print('Loading appointments for medic ID: ${_medic!.id} and user ID: ${_medic!.userId}');
      
      // Create a list to store all appointments
      List<Map<String, dynamic>> allAppointments = [];
      
      // Fetch ambulance requests assigned to this medic by medicId
      FirebaseFirestore.instance
          .collection('ambulanceRequests')
          .where('medicId', isEqualTo: _medic!.userId)
          .orderBy('createdAt', descending: true)
          .get()
          .then((snapshot) async {
            
        print('Found ${snapshot.docs.length} ambulance requests assigned to this medic');
            
        // Process each document
        final appointmentsList = await Future.wait(snapshot.docs.map((doc) async {
          final data = doc.data();
          print('Ambulance request data: $data'); // Debug print
          
          // Fetch user data if userId exists
          String? patientName = 'Unknown Patient';
          if (data['userId'] != null) {
            try {
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(data['userId'])
                  .get();
              
              if (userDoc.exists && userDoc.data() != null) {
                patientName = userDoc.data()!['name'] ?? data['fullName'] ?? 'Unknown Patient';
              }
            } catch (e) {
              print('Error fetching user data: $e');
            }
          } else if (data['fullName'] != null) {
            patientName = data['fullName'];
          }
          
          return {
            'id': doc.id,
            ...data,
            'patientName': patientName,
            'appointmentType': 'ambulance',
          };
        }));
        
        setState(() {
          _appointments = appointmentsList;
          print('Total appointments loaded: ${_appointments.length}');
          
          // Update statistics
          _statistics = {
            'totalVisits': _appointments.length,
            'completedVisits': _appointments.where((a) => a['status'] == 'completed').length,
            'pendingVisits': _appointments.where((a) => a['status'] == 'pending').length,
            'todayVisits': _appointments.where((a) {
              final createdAt = a['createdAt'] as Timestamp?;
              if (createdAt == null) return false;
              
              final now = DateTime.now();
              final date = createdAt.toDate();
              return date.year == now.year && 
                     date.month == now.month && 
                     date.day == now.day;
            }).length,
          };
          
          _isLoadingAppointments = false; // Reset the flag when done
        });
      }).catchError((error) {
        print('Error loading appointments: $error');
        setState(() {
          _isLoadingAppointments = false;
        });
      });
      
      // Set up a listener to watch for new ambulance requests
      FirebaseFirestore.instance
          .collection('ambulanceRequests')
          .where('medicId', isEqualTo: _medic!.userId)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
        // Reload appointments after a delay to avoid hammering the database
        Future.delayed(const Duration(seconds: 5), () {
          if (!_isLoadingAppointments) {
            _loadAppointments();
          }
        });
      });
    }
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String status) async {
    try {
      print('Updating appointment $appointmentId to status: $status');
      
      // Update in ambulanceRequests collection
      await FirebaseFirestore.instance
          .collection('ambulanceRequests')
          .doc(appointmentId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp()
          });
      print('Updated status in ambulanceRequests collection');
      
      // Reload appointments to refresh the list
      _loadAppointments();
      
    } catch (e) {
      print('Error updating appointment status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

    if (_medic == null) {
      return const Scaffold(
        body: Center(
          child: Text('No medic data found'),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _handleLogout,
                tooltip: 'Logout',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Welcome, ${_medic!.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blue.shade700,
                      Colors.blue.shade500,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Icon(
                        Icons.medical_services,
                        size: 50,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                        title: 'Total Requests',
                        value: _statistics['totalVisits'].toString(),
                        icon: Icons.emergency,
                        color: Colors.blue,
                      ),
                      StatisticsCard(
                        title: 'Completed',
                        value: _statistics['completedVisits'].toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      StatisticsCard(
                        title: 'Pending',
                        value: _statistics['pendingVisits'].toString(),
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                      ),
                      StatisticsCard(
                        title: 'Today',
                        value: _statistics['todayVisits'].toString(),
                        icon: Icons.today,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Visit Distribution',
                    style: TextStyle(
                      fontSize: 20,
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
                            value: _statistics['completedVisits'].toDouble(),
                            title: 'Completed',
                            color: Colors.green,
                            radius: 50,
                          ),
                          PieChartSectionData(
                            value: _statistics['pendingVisits'].toDouble(),
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
                  const SizedBox(height: 24),
                  const Text(
                    'Recent Requests',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (_appointments.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No appointments found',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final appointment = _appointments[index];
                  print('Processing appointment: ${appointment}'); // Debug print
                  
                  // Format date and time
                  String dateText = 'Date: Not specified';
                  String timeText = 'Time: Not specified';
                  
                  // Handle date with all possible fields
                  if (appointment['appointmentDate'] != null) {
                    final date = appointment['appointmentDate'] is Timestamp 
                        ? (appointment['appointmentDate'] as Timestamp).toDate()
                        : (appointment['appointmentDate'] is DateTime 
                            ? appointment['appointmentDate'] 
                            : null);
                            
                    if (date != null) {
                      dateText = 'Date: ${DateFormat('MMM dd, yyyy').format(date)}';
                    }
                  } else if (appointment['date'] != null) {
                    dateText = 'Date: ${appointment['date']}';
                  } else if (appointment['preferredDate'] != null) {
                    final preferredDate = appointment['preferredDate'] is Timestamp 
                        ? (appointment['preferredDate'] as Timestamp).toDate()
                        : (appointment['preferredDate'] is DateTime 
                            ? appointment['preferredDate'] 
                            : null);
                            
                    if (preferredDate != null) {
                      dateText = 'Preferred Date: ${DateFormat('MMM dd, yyyy').format(preferredDate)}';
                    }
                  }
                  
                  // Handle time with all possible fields
                  if (appointment['appointmentTime'] != null) {
                    timeText = 'Time: ${appointment['appointmentTime']}';
                  } else if (appointment['time'] != null) {
                    timeText = 'Time: ${appointment['time']}';
                  } else if (appointment['preferredTime'] != null) {
                    timeText = 'Preferred Time: ${appointment['preferredTime']}';
                  }
                  
                  // Get location coordinates directly from the appointment fields
                  final latitude = appointment['latitude']?.toDouble();
                  final longitude = appointment['longitude']?.toDouble();
                  
                  print('Raw location data from Firebase - lat: $latitude, lng: $longitude'); // Debug print

                  Future<void> _launchMapsUrl() async {
                    if (latitude != null && longitude != null) {
                      // Format coordinates to ensure they're valid numbers
                      final formattedLat = latitude.toStringAsFixed(6);
                      final formattedLng = longitude.toStringAsFixed(6);
                      
                      // Create Google Maps URL with the formatted coordinates
                      final url = 'https://www.google.com/maps?q=$formattedLat,$formattedLng';
                      print('Generated Google Maps URL: $url'); // Debug print
                      
                      try {
                        final uri = Uri.parse(url);
                        print('Attempting to launch maps with coordinates: $formattedLat, $formattedLng'); // Debug print
                        
                        if (await canLaunchUrl(uri)) {
                          print('Launching maps...'); // Debug print
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          print('Cannot launch maps URL'); // Debug print
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open maps. Please make sure you have a maps application installed.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        print('Error launching maps: $e'); // Debug print
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error opening maps: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } else {
                      print('Missing coordinates - lat: $latitude, lng: $longitude'); // Debug print
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Location coordinates not available'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.emergency,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ambulance Request',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Patient: ${appointment['patientName']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 8),
                          if (appointment['emergencyType'] != null)
                            Row(
                              children: [
                                Icon(Icons.crisis_alert, size: 16, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Emergency: ${appointment['emergencyType']}',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  appointment['createdAt'] != null
                                      ? 'Request: ${DateFormat('MMM dd, yyyy - hh:mm a').format((appointment['createdAt'] as Timestamp).toDate())}'
                                      : 'Recent request',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (appointment['description'] != null && appointment['description'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.description, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Notes: ${appointment['description']}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          InkWell(
                            onTap: _launchMapsUrl,
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    latitude != null && longitude != null
                                        ? 'Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}'
                                        : 'Location not available',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: latitude != null && longitude != null
                                          ? Colors.blue.shade700
                                          : Colors.grey,
                                      decoration: latitude != null && longitude != null
                                          ? TextDecoration.underline
                                          : TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  _updateAppointmentStatus(appointment['id'], 'completed');
                                },
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Complete'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _appointments.length,
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 