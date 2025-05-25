import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../models/lab_model.dart';
import '../screens/lab_confirmation_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medic_model.dart';
import '../screens/test_confirmation_screen.dart';
import 'dart:math';

class ReserveTestScreen extends StatefulWidget {
  const ReserveTestScreen({super.key});

  @override
  State<ReserveTestScreen> createState() => _ReserveTestScreenState();
}

class _ReserveTestScreenState extends State<ReserveTestScreen> {
  final _formKey = GlobalKey<FormState>();
  List<String> _selectedTestTypes = ['Blood Test'];
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  bool _isHomeVisit = true;
  Lab? _selectedLab;
  TimeOfDay _homeVisitTime = TimeOfDay.now();
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _availableTests = [
    {
      'id': 'blood',
      'name': 'Blood Test',
      'icon': FontAwesomeIcons.droplet,
      'description': 'Complete blood count and other blood tests',
    },
    {
      'id': 'mri',
      'name': 'MRI Scan',
      'icon': FontAwesomeIcons.magnet,
      'description': 'Magnetic Resonance Imaging scan',
    },
    {
      'id': 'xray',
      'name': 'X-Ray',
      'icon': FontAwesomeIcons.xRay,
      'description': 'X-Ray imaging for bones and chest',
    },
    {
      'id': 'ct',
      'name': 'CT Scan',
      'icon': FontAwesomeIcons.brain,
      'description': 'Computed Tomography scan',
    },
    {
      'id': 'ultrasound',
      'name': 'Ultrasound',
      'icon': FontAwesomeIcons.waveSquare,
      'description': 'Ultrasound imaging',
    },
    {
      'id': 'ecg',
      'name': 'ECG',
      'icon': FontAwesomeIcons.heartPulse,
      'description': 'Electrocardiogram test',
    },
  ];

  String _getDayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
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
        _selectedTime = null; // Reset selected time when date changes
      });
    }
  }

  void _selectTime(String time) {
    setState(() {
      _selectedTime = time;
    });
  }

  void _toggleVisitType(bool value) {
    setState(() {
      _isHomeVisit = value;
      if (_isHomeVisit) {
        // Only allow Blood Test
        _selectedTestTypes = ['Blood Test'];
      } else {
        // If current selection is not available, pick the first available test
        if (_selectedTestTypes.isEmpty || !_availableTests.any((t) => t['name'] == _selectedTestTypes.first)) {
          _selectedTestTypes = [_availableTests.first['name']];
        }
      }
    });
  }

  void _selectLab(Lab lab) {
    setState(() {
      _selectedLab = lab;
      _selectedTime = null; // Reset selected time when lab changes
    });
    Navigator.pop(context);
  }

  void _toggleTestSelection(String testName) {
    setState(() {
      if (_isHomeVisit && testName != 'Blood Test') {
        return; // Don't allow selection of non-blood tests for home visits
      }
      
      // Simply set the selected test to the new test
      _selectedTestTypes = [testName];
    });
  }

  Widget _buildTestSelection() {
    final availableTests = _isHomeVisit
        ? _availableTests.where((test) => test['name'] == 'Blood Test').toList()
        : _availableTests;

    if (_selectedTestTypes.isEmpty) {
      _selectedTestTypes = ['Blood Test'];
    }
    if (!availableTests.any((test) => test['name'] == _selectedTestTypes[0])) {
      _selectedTestTypes = [availableTests[0]['name']];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Test Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        // Multi-select dropdown implementation
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      title: const Text('Select Test Type'),
                      content: SingleChildScrollView(
                        child: ListBody(
                          children: availableTests.map((test) {
                            return RadioListTile<String>(
                              title: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: FaIcon(
                                      test['icon'],
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          test['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          test['description'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              value: test['name'],
                              groupValue: _selectedTestTypes.isNotEmpty ? _selectedTestTypes[0] : null,
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedTestTypes = [value];
                                  });
                                  
                                  // Update parent state
                                  this.setState(() {});
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Done'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  }
                );
              },
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
              color: Colors.blue.withOpacity(0.05),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      FaIcon(
                        _availableTests.firstWhere((test) => test['name'] == _selectedTestTypes[0])['icon'],
                        size: 18,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedTestTypes[0],
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Icon(
                    Icons.arrow_drop_down,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        if (_isHomeVisit)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Only Blood Test is available for home visits',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLabImage(String imageUrl) {
    return Image.asset(
      imageUrl,
      width: 50,
      height: 50,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.white,
        child: const Icon(Icons.error, color: Colors.grey),
      ),
    );
  }

  void _showLabsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select a Lab',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: Lab.topEgyptianLabs.length,
                    itemBuilder: (context, index) {
                      final lab = Lab.topEgyptianLabs[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildLabImage(lab.imageUrl),
                        ),
                        title: Text(
                          lab.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.orange,
                            ),
                            Text(' ${lab.rating}'),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Home Visit Available',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _selectLab(lab),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTimeSlotSelector() {
    if (_selectedLab == null) return const SizedBox.shrink();

    final dayName = _getDayName(_selectedDate);
    final availableSlots = _selectedLab!.availableTimeSlots[dayName] ?? [];

    if (availableSlots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No available time slots for this day',
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Available Time Slots',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableSlots.map((time) {
            final isSelected = _selectedTime == time;
            return InkWell(
              onTap: () => _selectTime(time),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.blue,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectHomeVisitTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _homeVisitTime,
    );
    if (picked != null && picked != _homeVisitTime) {
      setState(() {
        _homeVisitTime = picked;
      });
    }
  }

  Widget _buildHomeVisitFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Home Visit Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _selectHomeVisitTime(context),
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
                    _homeVisitTime.format(context),
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
          onTap: _getCurrentLocation,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
              color: Colors.blue.withOpacity(0.05),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentPosition != null
                            ? 'Location Selected'
                            : 'Get Current Location',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      if (_currentPosition != null)
                        Text(
                          'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Long: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isLoadingLocation)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.blue,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<Medic> _getRandomMedic() async {
    try {
      print('Fetching medics from users collection...');
      
      // Get users with role 'medic' from the users collection
      final usersWithMedicRoleSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'medic')
          .get();
      
      print('Found ${usersWithMedicRoleSnapshot.size} users with medic role');
      
      if (usersWithMedicRoleSnapshot.docs.isEmpty) {
        throw Exception('No medics available at the moment');
      }
      
      // Create list for users with medic role
      final userMedics = usersWithMedicRoleSnapshot.docs.map((doc) {
        final data = doc.data();
        String fullName;
        
        // Try different name fields in order of preference
        if (data['fullName'] != null && data['fullName'].toString().isNotEmpty) {
          fullName = data['fullName'];
        } else if (data['fname'] != null || data['lname'] != null) {
          fullName = '${data['fname'] ?? ''} ${data['lname'] ?? ''}'.trim();
        } else if (data['name'] != null && data['name'].toString().isNotEmpty) {
          fullName = data['name'];
        } else {
          fullName = 'Dr. ${doc.id.substring(0, 6)}'; // Fallback name
        }
        
        print('Processing user medic: $fullName (${doc.id})');
        return Medic(
          id: doc.id,
          name: fullName,
          experience: data['experience'] is int ? data['experience'] : 5,
          userId: doc.id,
        );
      }).toList();
      
      // Return a random medic from the list
      userMedics.shuffle();
      final selectedMedic = userMedics.first;
      print('Selected medic: ${selectedMedic.name} (${selectedMedic.id})');
      return selectedMedic;
      
    } catch (e) {
      print('Error getting random medic: $e');
      throw Exception('Failed to assign a medic. Please try again later.');
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        setState(() {
          _isLoading = true;
        });

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not logged in');
        }

        if (_isHomeVisit) {
          // Handle home visit
          final serviceName = 'Home Blood Test Service';
          
          // Create appointment data for home visit
          final appointmentData = {
            'userId': user.uid,
            'userName': user.displayName ?? 'Unknown',
            'userEmail': user.email,
            'serviceName': serviceName,
            'preferredDate': Timestamp.fromDate(_selectedDate),
            'preferredTime': _homeVisitTime.format(context),
            'testTypes': _selectedTestTypes,
            'status': 'pending',
            'isHomeVisit': true,
            'address': _currentPosition != null 
                ? '${_currentPosition!.latitude}, ${_currentPosition!.longitude}'
                : 'Location not available',
            'createdAt': FieldValue.serverTimestamp(),
          };
          
          // Save to testReservations collection
          final docRef = await FirebaseFirestore.instance
              .collection('testReservations')
              .add(appointmentData);
          
          // Navigate to confirmation screen
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TestConfirmationScreen(
                  testType: _selectedTestTypes.join(', '),
                  date: _selectedDate,
                  time: _homeVisitTime.format(context),
                  medicName: serviceName,
                  address: _currentPosition != null 
                      ? '${_currentPosition!.latitude}, ${_currentPosition!.longitude}'
                      : 'Location not available',
                ),
              ),
            );
          }
        } else {
          // Handle lab visit
          if (_selectedLab == null || _selectedTime == null) {
            throw Exception('Please select a lab and time slot');
          }

          // Create appointment data for lab visit
          final appointmentData = {
            'labId': _selectedLab!.id,
            'labName': _selectedLab!.name,
            'userId': user.uid,
            'userName': user.displayName ?? 'Unknown',
            'userEmail': user.email,
            'preferredDate': Timestamp.fromDate(_selectedDate),
            'preferredTime': _selectedTime,
            'testTypes': _selectedTestTypes,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          };
          
          // Save to testReservations collection
          final docRef = await FirebaseFirestore.instance
              .collection('testReservations')
              .add(appointmentData);
          
          // Navigate to confirmation screen
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TestConfirmationScreen(
                  testType: _selectedTestTypes.join(', '),
                  date: _selectedDate,
                  time: _selectedTime!,
                  medicName: _selectedLab!.name,
                  address: _selectedLab!.address,
                ),
              ),
            );
          }
        }
      } catch (e) {
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
        title: 'Reserve Test',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        'Test Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTestSelection(),
                      const SizedBox(height: 16),
                      const Text(
                        'Test Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _toggleVisitType(true),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _isHomeVisit ? Colors.blue : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isHomeVisit ? Colors.blue : Colors.grey,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.houseMedical,
                                      color: _isHomeVisit ? Colors.white : Colors.black87,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Home Visit',
                                      style: TextStyle(
                                        color: _isHomeVisit ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _toggleVisitType(false),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: !_isHomeVisit ? Colors.blue : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: !_isHomeVisit ? Colors.blue : Colors.grey,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.hospital,
                                      color: !_isHomeVisit ? Colors.white : Colors.black87,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Lab Visit',
                                      style: TextStyle(
                                        color: !_isHomeVisit ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_isHomeVisit)
                        _buildHomeVisitFields()
                      else ...[
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _showLabsBottomSheet,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.blue.withOpacity(0.05),
                            ),
                            child: Row(
                              children: [
                                if (_selectedLab != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      _selectedLab!.imageUrl,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.white,
                                        child: const Icon(Icons.error, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedLab!.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          _selectedLab!.address,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  const Icon(
                                    Icons.business,
                                    color: Colors.blue,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Select a Lab',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                        'Schedule',
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
                      if (!_isHomeVisit) ...[
                        const SizedBox(height: 16),
                        _buildTimeSlotSelector(),
                      ],
                    ],
                  ),
                ),
              ),
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
                    'Confirm Reservation',
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
} 