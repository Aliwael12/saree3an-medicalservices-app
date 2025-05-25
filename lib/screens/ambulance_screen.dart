import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/custom_app_bar.dart';
import '../constants/app_theme.dart';
import '../services/ambulance_service.dart';
import 'ambulance_confirmation_screen.dart';

class AmbulanceScreen extends StatefulWidget {
  const AmbulanceScreen({super.key});

  @override
  State<AmbulanceScreen> createState() => _AmbulanceScreenState();
}

class _AmbulanceScreenState extends State<AmbulanceScreen> {
  final AmbulanceService _ambulanceService = AmbulanceService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Position? _location;
  bool _isGettingLocation = false;
  String _error = '';
  bool _isSubmitting = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    print('DEBUG: AmbulanceScreen initialized');
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    print('DEBUG: Getting current location');
    setState(() {
      _isGettingLocation = true;
      _error = '';
    });

    try {
      // Check location permission
      print('DEBUG: Checking location permission');
      LocationPermission permission = await Geolocator.checkPermission();
      print('DEBUG: Current permission status: $permission');
      
      if (permission == LocationPermission.denied) {
        print('DEBUG: Permission denied, requesting permission');
        permission = await Geolocator.requestPermission();
        print('DEBUG: New permission status: $permission');
        
        if (permission == LocationPermission.denied) {
          print('DEBUG: Permission still denied after request');
          setState(() {
            _error = 'Location permission denied';
            _isGettingLocation = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('DEBUG: Permission denied forever');
        setState(() {
          _error = 'Location permission permanently denied. Please enable it in settings.';
          _isGettingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied. Please enable it in settings.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get current position
      print('DEBUG: Getting position');
      final position = await Geolocator.getCurrentPosition();
      print('DEBUG: Position received: ${position.latitude}, ${position.longitude}');
      
      setState(() {
        _location = position;
        _isGettingLocation = false;
      });
      
      print('DEBUG: Location captured successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location captured successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('DEBUG: Error getting location: $e');
      setState(() {
        _error = 'Failed to get location. Please try again.';
        _isGettingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleConfirm() async {
    print('DEBUG: Handling confirmation button press');
    final User? currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      print('DEBUG: User not logged in');
      setState(() {
        _error = 'Please log in to request an ambulance';
      });
      return;
    }

    if (_location == null) {
      print('DEBUG: Location not available');
      setState(() {
        _error = 'Please get your location first';
      });
      return;
    }

    try {
      print('DEBUG: Starting request submission');
      setState(() {
        _isSubmitting = true;
        _error = '';
      });

      // Get user data from database
      print('DEBUG: Fetching user data');
      DocumentSnapshot? userDoc;
      try {
        userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        print('DEBUG: User document exists: ${userDoc.exists}');
      } catch (e) {
        print('DEBUG: Error fetching user data: $e');
      }
      
      final userData = userDoc != null && userDoc.exists ? userDoc.data() as Map<String, dynamic>? : null;
      print('DEBUG: User data retrieved: ${userData != null ? 'Yes' : 'No'}');

      final formattedLocation = 'Current location (${_location!.latitude.toStringAsFixed(4)}, ${_location!.longitude.toStringAsFixed(4)})';
      
      print('DEBUG: Preparing to navigate to confirmation screen');
      final fullName = userData?['name'] ?? currentUser.displayName ?? 'Unknown';
      final phoneNumber = userData?['phoneNumber'] ?? '';
      
      print('DEBUG: Navigation data ready - Name: $fullName, Phone: $phoneNumber, Address: $formattedLocation');
      
      // We're no longer setting state here to avoid rebuilding before navigation
      print('DEBUG: About to push to navigation stack');
      try {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AmbulanceConfirmationScreen(
              fullName: fullName,
              phoneNumber: phoneNumber,
              address: formattedLocation,
              description: 'Emergency ambulance request from current location',
              userPosition: _location!,
            ),
          ),
        ).then((_) {
          // This runs when we return from the confirmation screen
          print('DEBUG: Returned from confirmation screen');
          if (mounted) {
            setState(() {
              _isSubmitting = false;
            });
          }
        });
        print('DEBUG: Navigation pushed successfully');
      } catch (e) {
        print('DEBUG: Error during navigation: $e');
        throw Exception('Navigation failed: $e');
      }
    } catch (e) {
      print('DEBUG: Error in confirmation flow: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to submit request. Please try again.';
          _isSubmitting = false;
        });
      }
      print('Error creating ambulance request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building AmbulanceScreen UI');
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Ambulance Request',
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              
              // Header
              const Center(
                child: Text(
                  'Request An Ambulance Now!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Center(
                child: Text(
                  'Click the button below to share your location and request emergency medical assistance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Error message
              if (_error.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade400),
                  ),
                  child: Text(
                    _error,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Location button or map with details
              _location == null
                  ? Center(
                      child: ElevatedButton.icon(
                        onPressed: _isGettingLocation ? null : _getCurrentLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: _isGettingLocation
                            ? Container(
                                width: 24,
                                height: 24,
                                padding: const EdgeInsets.all(2.0),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Icon(Icons.location_on),
                        label: Text(
                          _isGettingLocation ? 'Getting Location...' : 'Share My Location',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // Map
                        SizedBox(
                          height: 300,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: latlong.LatLng(
                                  _location!.latitude,
                                  _location!.longitude,
                                ),
                                initialZoom: 15,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.saree3anapp',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: latlong.LatLng(
                                        _location!.latitude,
                                        _location!.longitude,
                                      ),
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Confirm button
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                          ),
                          child: _isSubmitting 
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                'Confirm Location & Request Ambulance',
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
