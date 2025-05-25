import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../services/ambulance_service.dart';

class AmbulanceConfirmationScreen extends StatefulWidget {
  final String fullName;
  final String phoneNumber;
  final String address;
  final String description;
  final Position userPosition;

  const AmbulanceConfirmationScreen({
    super.key,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.description,
    required this.userPosition,
  });

  @override
  State<AmbulanceConfirmationScreen> createState() => _AmbulanceConfirmationScreenState();
}

class _AmbulanceConfirmationScreenState extends State<AmbulanceConfirmationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AmbulanceService _ambulanceService = AmbulanceService();
  
  bool _isSubmitting = false;
  bool _isRequestSubmitted = false;
  String _error = '';
  String _userPhoneNumber = '';
  
  // Map-related variables
  MapController? _mapController; // Make nullable to prevent late initialization errors
  latlong.LatLng? _ambulancePosition;
  List<Polyline> _polylines = [];
  
  // Timer and countdown
  Timer? _ambulanceTimer;
  Timer? _countdownTimer;
  int _secondsLeft = 600; // 10 minutes
  
  // Medic info
  Map<String, dynamic>? _medicInfo;
  
  // Custom ambulance marker widget
  Widget _buildAmbulanceMarker() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(4),
      child: Image.asset(
        'assets/images/ambulance.png',
        width: 32,
        height: 32,
      ),
    );
  }
  
  @override
  void initState() {
    super.initState();
    print('DEBUG: AmbulanceConfirmationScreen initialized');
    print('DEBUG: User position: ${widget.userPosition.latitude}, ${widget.userPosition.longitude}');
    
    // Initialize map controller
    _mapController = MapController();
    
    // Initialize phone number - use widget phone number or fetch from database
    _initializePhoneNumber();
    
    // If request is already submitted but timers aren't running, restart them
    if (_isRequestSubmitted) {
      print('DEBUG: Request already submitted in initState, ensuring timers are running');
      
      // Use a short delay to allow the widget to fully build before starting animations
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          if (_ambulancePosition == null) {
            print('DEBUG: Generating ambulance position in initState');
            _generateRandomAmbulancePosition();
          }
          
          print('DEBUG: Starting timers from initState');
          _startAmbulanceAnimation();
          _startCountdownTimer();
        }
      });
    }
  }
  
  Future<void> _initializePhoneNumber() async {
    // Use provided phone number if available, otherwise fetch from user profile
    if (widget.phoneNumber.isNotEmpty) {
      setState(() {
        _userPhoneNumber = widget.phoneNumber;
      });
      print('DEBUG: Using provided phone number: ${widget.phoneNumber}');
    } else {
      print('DEBUG: Phone number not provided, fetching from user profile');
      await _fetchUserPhoneNumber();
    }
  }
  
  Future<void> _fetchUserPhoneNumber() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('DEBUG: No current user to fetch phone number from');
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        final phoneNumber = userData['phone'] ?? userData['phoneNumber'] ?? '';
        setState(() {
          _userPhoneNumber = phoneNumber;
        });
        print('DEBUG: Fetched phone number from database: $phoneNumber');
      } else {
        print('DEBUG: User document not found');
        setState(() {
          _userPhoneNumber = 'Not available';
        });
      }
    } catch (e) {
      print('DEBUG: Error fetching phone number: $e');
      setState(() {
        _userPhoneNumber = 'Not available';
      });
    }
  }
  
  @override
  void dispose() {
    print('DEBUG: Disposing AmbulanceConfirmationScreen');
    _ambulanceTimer?.cancel();
    _countdownTimer?.cancel();
    // No need to dispose _mapController as it's handled internally
    super.dispose();
  }
  
  void _generateRandomAmbulancePosition() {
    print('DEBUG: Generating random ambulance position');
    // Generate random position in Cairo (approximately 10km away from user)
    final random = math.Random();
    final latOffset = (random.nextDouble() - 0.5) * 0.09; // ~10km range
    final lngOffset = (random.nextDouble() - 0.5) * 0.09; // ~10km range
    
    _ambulancePosition = latlong.LatLng(
      widget.userPosition.latitude + latOffset,
      widget.userPosition.longitude + lngOffset,
    );
    print('DEBUG: Ambulance position generated at: ${_ambulancePosition!.latitude}, ${_ambulancePosition!.longitude}');
    
    _updatePolyline();
  }
  
  void _updatePolyline() {
    if (_ambulancePosition == null) {
      print('DEBUG: Cannot update polyline - ambulance position is null');
      return;
    }
    
    print('DEBUG: Updating polyline');
    try {
      setState(() {
        _polylines = [
          Polyline(
            points: [
              _ambulancePosition!,
              latlong.LatLng(widget.userPosition.latitude, widget.userPosition.longitude),
            ],
            color: Colors.red,
            strokeWidth: 3.0,
            isDotted: true,
          ),
        ];
      });
      
      // Only try to center map if controller exists and is ready
      if (_mapController != null) {
        try {
          if (_mapController!.camera.center != null) {
            _centerMapToShowBothPositions();
          } else {
            print('DEBUG: Map controller exists but camera is not ready yet');
          }
        } catch (e) {
          print('DEBUG: Error checking map controller status: $e');
        }
      } else {
        print('DEBUG: Map controller is null, skipping map centering');
      }
    } catch (e) {
      print('DEBUG: Error updating polyline: $e');
    }
  }
  
  void _centerMapToShowBothPositions() {
    print('DEBUG: Attempting to center map');
    
    // Double-check all required conditions
    if (_ambulancePosition == null) {
      print('DEBUG: Cannot center map - ambulance position is null');
      return;
    }
    
    if (_mapController == null) {
      print('DEBUG: Cannot center map - map controller is null');
      return;
    }
    
    if (_mapController!.camera.center == null) {
      print('DEBUG: Cannot center map - map controller camera center is null');
      return;
    }
    
    try {
      // Calculate center point between user and ambulance
      final centerLat = (widget.userPosition.latitude + _ambulancePosition!.latitude) / 2;
      final centerLng = (widget.userPosition.longitude + _ambulancePosition!.longitude) / 2;
      
      // Calculate appropriate zoom level
      final latDiff = (widget.userPosition.latitude - _ambulancePosition!.latitude).abs();
      final lngDiff = (widget.userPosition.longitude - _ambulancePosition!.longitude).abs();
      final maxDiff = math.max(latDiff, lngDiff) * 111; // rough conversion to km
      
      double zoom = 14.0;
      if (maxDiff > 5) zoom = 12.0;
      if (maxDiff > 10) zoom = 11.0;
      if (maxDiff > 20) zoom = 10.0;
      
      print('DEBUG: Moving map to center at $centerLat, $centerLng with zoom $zoom');
      try {
        _mapController!.move(latlong.LatLng(centerLat, centerLng), zoom);
        print('DEBUG: Map centered successfully');
      } catch (e) {
        print('DEBUG: Error moving map: $e');
      }
    } catch (e) {
      print('DEBUG: Error calculating map center: $e');
    }
  }
  
  void _startAmbulanceAnimation() {
    print('DEBUG: Starting ambulance animation');
    
    // Generate initial ambulance position if not set
    if (_ambulancePosition == null) {
      print('DEBUG: No ambulance position in _startAmbulanceAnimation, generating now');
      _generateRandomAmbulancePosition();
    }
    
    // Cancel existing timer if any
    if (_ambulanceTimer != null) {
      print('DEBUG: Cancelling existing ambulance timer');
      _ambulanceTimer?.cancel();
    }
    
    // Start animation timer - update every 1 second
    print('DEBUG: Creating new ambulance timer');
    _ambulanceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      print('DEBUG: Ambulance timer tick');
      
      // Check if widget is still mounted and ambulance position is valid
      if (!mounted || _ambulancePosition == null) {
        print('DEBUG: Widget not mounted or ambulance position null, cancelling timer');
        timer.cancel();
        return;
      }
      
      final userLatLng = latlong.LatLng(widget.userPosition.latitude, widget.userPosition.longitude);
      
      // Move ambulance 1% closer to user's position
      final newLat = _ambulancePosition!.latitude + (userLatLng.latitude - _ambulancePosition!.latitude) * 0.01;
      final newLng = _ambulancePosition!.longitude + (userLatLng.longitude - _ambulancePosition!.longitude) * 0.01;
      
      // Check if ambulance has arrived (very close to user)
      final distance = _calculateDistance(_ambulancePosition!, userLatLng);
      if (distance < 0.0001) { // Very close (about 10 meters)
        print('DEBUG: Ambulance arrived at destination, cancelling timers');
        timer.cancel();
        _countdownTimer?.cancel();
        setState(() {
          _secondsLeft = 0;
        });
        return;
      }
      
      try {
        // Use setState safely in case the widget is unmounted
        if (mounted) {
          setState(() {
            _ambulancePosition = latlong.LatLng(newLat, newLng);
            if (_mapController != null) {
              _updatePolyline();
            } else {
              print('DEBUG: Map controller is null, skipping polyline update');
            }
          });
        }
      } catch (e) {
        print('DEBUG: Error updating ambulance position: $e');
        timer.cancel();
      }
    });
  }
  
  // Calculate approximate distance between two points
  double _calculateDistance(latlong.LatLng point1, latlong.LatLng point2) {
    return math.sqrt(
      math.pow(point1.latitude - point2.latitude, 2) + 
      math.pow(point1.longitude - point2.longitude, 2)
    );
  }
  
  void _startCountdownTimer() {
    print('DEBUG: Starting countdown timer');
    
    if (_countdownTimer != null) {
      print('DEBUG: Cancelling existing countdown timer');
      _countdownTimer?.cancel();
    }
    
    print('DEBUG: Creating new countdown timer, seconds left: $_secondsLeft');
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      print('DEBUG: Countdown timer tick, seconds left: $_secondsLeft');
      if (!mounted) {
        print('DEBUG: Widget not mounted, cancelling countdown timer');
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          print('DEBUG: Countdown reached zero, cancelling timer');
          timer.cancel();
        }
      });
    });
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  Future<void> _fetchRandomMedic() async {
    print('DEBUG: Fetching random medic information');
    try {
      // Get medics from users collection with role 'medic'
      final medicsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'medic')
          .limit(5)
          .get();
      
      print('DEBUG: Fetched ${medicsSnapshot.docs.length} medics from Firestore');
      
      if (medicsSnapshot.docs.isNotEmpty) {
        // Pick a random medic from the results
        final random = math.Random();
        final randomIndex = random.nextInt(medicsSnapshot.docs.length);
        final medicDoc = medicsSnapshot.docs[randomIndex];
        final medicData = medicDoc.data();
        
        setState(() {
          _medicInfo = {
            'id': medicDoc.id, // This is the medic's user ID
            'name': medicData['name'] ?? medicData['firstName'] + ' ' + (medicData['lastName'] ?? '') ?? 'Unknown Medic',
            'phone': medicData['phone'] ?? medicData['phoneNumber'] ?? '+201012345678',
            'experience': medicData['experience'] ?? '5+ years',
          };
        });
        print('DEBUG: Selected medic: ${_medicInfo!['name']} with ID: ${_medicInfo!['id']}');
      } else {
        // If no medics in collection, use mock data
        print('DEBUG: No medics found, using mock data');
        setState(() {
          _medicInfo = {
            'id': 'mock-medic-1',
            'name': 'Dr. Ahmed Mohamed',
            'phone': '+201012345678',
            'experience': '5+ years',
          };
        });
      }
    } catch (e) {
      print('DEBUG: Error fetching medic: $e');
      // Fall back to mock data
      setState(() {
        _medicInfo = {
          'id': 'mock-medic-1',
          'name': 'Dr. Ahmed Mohamed',
          'phone': '+201012345678',
          'experience': '5+ years',
        };
      });
    }
  }

  Future<void> _submitRequest() async {
    print('DEBUG: Submitting ambulance request');
    final User? currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      print('DEBUG: User not logged in');
      setState(() {
        _error = 'Please log in to request an ambulance';
      });
      return;
    }

    try {
      setState(() {
        _isSubmitting = true;
        _error = '';
      });

      // Fetch a random medic first
      print('DEBUG: Fetching random medic information');
      await _fetchRandomMedic();
      print('DEBUG: Medic information fetched successfully');

      print('DEBUG: Calling ambulance service');
      try {
        await _ambulanceService.submitAmbulanceRequest(
          fullName: widget.fullName,
          phoneNumber: _userPhoneNumber.isNotEmpty ? _userPhoneNumber : widget.phoneNumber,
          address: widget.address,
          description: widget.description,
          medicId: _medicInfo?['id'] ?? '',
          medicName: _medicInfo?['name'] ?? 'Unknown Medic',
          latitude: widget.userPosition.latitude,
          longitude: widget.userPosition.longitude,
          userId: currentUser.uid,
        );
        print('DEBUG: Ambulance request submitted successfully');
      } catch (e) {
        print('DEBUG: Error in ambulance service: $e');
        throw e; // Rethrow to be caught by outer try-catch
      }
      
      // Just update the state to switch to tracking view
      // DO NOT access map controller or start animations here
      setState(() {
        print('DEBUG: Setting isRequestSubmitted to true');
        _isSubmitting = false;
        _isRequestSubmitted = true;
        
        // Generate initial ambulance position without updating the map
        print('DEBUG: Pre-generating ambulance position without map updates');
        // Generate random position in Cairo (approximately 10km away from user)
        final random = math.Random();
        final latOffset = (random.nextDouble() - 0.5) * 0.09; // ~10km range
        final lngOffset = (random.nextDouble() - 0.5) * 0.09; // ~10km range
        
        _ambulancePosition = latlong.LatLng(
          widget.userPosition.latitude + latOffset,
          widget.userPosition.longitude + lngOffset,
        );
        
        // Don't update polyline or call any map controller methods here
      });
      
      // Leave the rest to be handled in the onMapReady callback
      // which will be triggered when the map is built and ready

      print('DEBUG: Request process completed successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ambulance request submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('DEBUG: Error in submit request: $e');
      setState(() {
        _isSubmitting = false;
        _error = 'Failed to submit request. Please try again.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelRequest() async {
    print('DEBUG: Canceling request');
    final bool confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text('Are you sure you want to cancel the ambulance request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm && mounted) {
      print('DEBUG: Request cancellation confirmed');
      // Stop timers
      _ambulanceTimer?.cancel();
      _countdownTimer?.cancel();
      
      Navigator.pop(context);
    } else {
      print('DEBUG: Request cancellation declined');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building AmbulanceConfirmationScreen UI, isRequestSubmitted: $_isRequestSubmitted, secondsLeft: $_secondsLeft, ambulancePosition: ${_ambulancePosition?.toString()}');
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Ambulance Request',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Error message
          if (_error.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(16),
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
            
          // Main content
          Expanded(
            child: _isRequestSubmitted 
                ? _buildTrackingView() 
                : _buildConfirmationView(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrackingView() {
    print('DEBUG: Building tracking view');
    return Column(
      children: [
        // Map showing user and ambulance
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: latlong.LatLng(
                widget.userPosition.latitude,
                widget.userPosition.longitude,
              ),
              initialZoom: 14,
              onMapReady: () {
                // Initialize the ambulance position and start animation when map is ready
                print('DEBUG: Map is ready');
                
                try {
                  // Update polylines if ambulance position is already set
                  if (_ambulancePosition != null) {
                    print('DEBUG: Ambulance position exists in onMapReady: ${_ambulancePosition!.latitude}, ${_ambulancePosition!.longitude}');
                    // We can safely update polylines now since the map is ready
                    _updatePolyline();
                  } else {
                    print('DEBUG: Ambulance position is null in onMapReady, generating position');
                    _generateRandomAmbulancePosition();
                  }
                  
                  // Always start these regardless of ambulance position
                  print('DEBUG: Starting timers from onMapReady');
                  _startAmbulanceAnimation();
                  _startCountdownTimer();
                  
                  // Clear any error messages that might be showing
                  if (_error.isNotEmpty) {
                    setState(() {
                      _error = '';
                    });
                  }
                } catch (e) {
                  print('DEBUG: Error in onMapReady: $e');
                  // Don't set error message here to avoid UI loop
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.saree3anapp',
              ),
              PolylineLayer(polylines: _polylines),
              MarkerLayer(
                markers: [
                  // User marker
                  Marker(
                    point: latlong.LatLng(
                      widget.userPosition.latitude,
                      widget.userPosition.longitude,
                    ),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                  // Ambulance marker
                  if (_ambulancePosition != null)
                    Marker(
                      point: _ambulancePosition!,
                      width: 40,
                      height: 40,
                      child: _buildAmbulanceMarker(),
                    ),
                ],
              ),
            ],
          ),
        ),
        
        // Ambulance ETA and driver info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ETA section
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.blue),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimated Time of Arrival',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDuration(_secondsLeft),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Progress indicator
              LinearProgressIndicator(
                value: 1 - (_secondsLeft / 600), // 10 minutes total
                backgroundColor: Colors.grey[200],
                color: Colors.blue,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Driver info section
              const Text(
                'Medical Professional Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Medic details
              if (_medicInfo != null) ...[
                _buildInfoRow(Icons.person, 'Name', _medicInfo!['name'] ?? 'Unknown'),
                _buildInfoRow(Icons.phone, 'Phone', _medicInfo!['phone'] ?? 'N/A'),
                _buildInfoRow(Icons.timer, 'Experience', _medicInfo!['experience'] ?? 'N/A'),
              ] else ...[
                const Center(
                  child: CircularProgressIndicator(),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cancelRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Cancel Request',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationView() {
    print('DEBUG: Building confirmation view');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Request details card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Request Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Name', widget.fullName),
                  _buildDetailRow('Phone', _userPhoneNumber.isNotEmpty ? _userPhoneNumber : 'Loading...'),
                  _buildDetailRow('Address', widget.address),
                  if (widget.description.isNotEmpty)
                    _buildDetailRow('Notes', widget.description),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Map
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: latlong.LatLng(
                    widget.userPosition.latitude,
                    widget.userPosition.longitude,
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
                          widget.userPosition.latitude,
                          widget.userPosition.longitude,
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

          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 60,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'Confirm',
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
} 