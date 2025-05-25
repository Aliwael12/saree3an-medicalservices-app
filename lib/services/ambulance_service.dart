import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AmbulanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> submitAmbulanceRequest({
    required String fullName,
    required String phoneNumber,
    required String address,
    required String description,
    String? emergencyType,
    String? medicId,
    String? medicName,
    double? latitude,
    double? longitude,
    String? userId,
  }) async {
    print('DEBUG: AmbulanceService - submitAmbulanceRequest called');
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('DEBUG: AmbulanceService - User not authenticated');
        throw Exception('User not authenticated');
      }
      
      print('DEBUG: AmbulanceService - Creating request document');
      print('DEBUG: AmbulanceService - Request details: Name=$fullName, Phone=$phoneNumber, Address=$address, Medic=$medicName');
      
      final requestData = {
        'userId': userId ?? user.uid,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'address': address,
        'description': description,
        'emergencyType': emergencyType ?? 'General Emergency',
        'status': 'pending',
        'medicId': medicId ?? '',
        'medicName': medicName ?? '',
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      try {
        final docRef = await _firestore.collection('ambulanceRequests').add(requestData);
        print('DEBUG: AmbulanceService - Request added successfully with ID: ${docRef.id}');
      } catch (firestoreError) {
        print('DEBUG: AmbulanceService - Firestore error: $firestoreError');
        throw Exception('Failed to write to Firestore: $firestoreError');
      }
    } catch (e) {
      print('DEBUG: AmbulanceService - Exception: $e');
      throw Exception('Failed to submit ambulance request: $e');
    }
  }

  Stream<QuerySnapshot> getUserAmbulanceRequests() {
    print('DEBUG: AmbulanceService - getUserAmbulanceRequests called');
    final user = _auth.currentUser;
    if (user == null) {
      print('DEBUG: AmbulanceService - User not authenticated for requests stream');
      throw Exception('User not authenticated');
    }

    print('DEBUG: AmbulanceService - Creating requests stream for user ${user.uid}');
    return _firestore
        .collection('ambulanceRequests')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
} 