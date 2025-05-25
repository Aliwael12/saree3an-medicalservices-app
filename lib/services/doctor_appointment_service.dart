import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorAppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createAppointment({
    required Map<String, dynamic> doctorData,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String address,
    required String symptoms,
    required double consultationFee,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      print('DoctorAppointmentService: Creating appointment with doctor data: $doctorData');
      print('DoctorAppointmentService: User ID: ${user.uid}');
      print('DoctorAppointmentService: Appointment Date: $appointmentDate');
      print('DoctorAppointmentService: Appointment Time: $appointmentTime');

      // Check if doctorId is valid - if using mock data, set a placeholder ID
      String doctorId = doctorData['id'] ?? 'mock-doctor-id';
      
      final appointmentData = {
        'userId': user.uid,
        'doctorId': doctorId,
        'doctorName': doctorData['name'],
        'doctorSpecialty': doctorData['specialty'],
        'appointmentDate': Timestamp.fromDate(appointmentDate),
        'appointmentTime': appointmentTime,
        'address': address,
        'symptoms': symptoms,
        'consultationFee': consultationFee,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      print('DoctorAppointmentService: Appointment data: $appointmentData');
      print('DoctorAppointmentService: Attempting to save to doctorVisits collection...');
      
      // Implement retry mechanism
      int maxRetries = 3;
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          print('DoctorAppointmentService: Attempt $attempt of $maxRetries');
          
          // Direct Firestore access test
          print('DoctorAppointmentService: Testing direct Firestore access...');
          final testData = {
            'test': 'DoctorAppointmentService test',
            'timestamp': FieldValue.serverTimestamp(),
          };
          
          final testDocRef = await _firestore.collection('firestoreTestDAS').add(testData);
          print('DoctorAppointmentService: Test document created with ID: ${testDocRef.id}');
          await testDocRef.delete();
          print('DoctorAppointmentService: Test document deleted successfully.');
          
          // Now try to save the actual appointment
          final docRef = await _firestore.collection('doctorVisits').add(appointmentData);
          print('DoctorAppointmentService: Successfully saved! Document ID: ${docRef.id}');
          
          // Verify document was actually created
          final docSnapshot = await docRef.get();
          if (!docSnapshot.exists) {
            print('DoctorAppointmentService: ERROR - Document not found after creation!');
            if (attempt == maxRetries) {
              throw Exception('Document was not created successfully after $maxRetries attempts');
            }
            // Wait before retrying
            await Future.delayed(Duration(seconds: 1));
            continue;
          }
          
          print('DoctorAppointmentService: Document verified with data: ${docSnapshot.data()}');
          return docRef.id;
        } catch (firestoreError) {
          print('DoctorAppointmentService: Firestore error in attempt $attempt: $firestoreError');
          if (attempt == maxRetries) {
            throw Exception('Firestore error after $maxRetries attempts: $firestoreError');
          }
          // Wait before retrying
          await Future.delayed(Duration(seconds: 1));
        }
      }
      
      // Should never reach here, but just in case
      throw Exception('Failed to create appointment after multiple attempts');
    } catch (e) {
      print('DoctorAppointmentService: Failed to create appointment: $e');
      throw Exception('Failed to create appointment: $e');
    }
  }

  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await _firestore.collection('doctorVisits').doc(appointmentId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    }
  }

  Stream<QuerySnapshot> getUserAppointments() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('doctorVisits')
        .where('userId', isEqualTo: user.uid)
        .orderBy('appointmentDate', descending: true)
        .snapshots();
  }

  Future<String> saveAppointment(Map<String, dynamic> appointmentData) async {
    try {
      print('DoctorAppointmentService: Saving appointment with data: $appointmentData');
      
      // Convert DateTime to Timestamp for Firestore
      if (appointmentData['appointmentDate'] is DateTime) {
        appointmentData['appointmentDate'] = Timestamp.fromDate(appointmentData['appointmentDate']);
      }

      final docRef = await _firestore.collection('doctorVisits').add(appointmentData);
      print('DoctorAppointmentService: Successfully saved! Document ID: ${docRef.id}');
      
      // Verify document creation
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        print('DoctorAppointmentService: ERROR - Document not found after creation!');
        throw Exception('Document was not created successfully');
      }
      
      print('DoctorAppointmentService: Document verified with data: ${docSnapshot.data()}');
      return docRef.id;
    } catch (e) {
      print('DoctorAppointmentService: Failed to save appointment: $e');
      throw Exception('Failed to save appointment: $e');
    }
  }
} 