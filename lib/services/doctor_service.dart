import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/doctor_model.dart';
import 'dart:math';

class DoctorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all appointments for the current doctor
  Stream<QuerySnapshot> getDoctorAppointments() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('Error: User not authenticated');
      throw Exception('User not authenticated');
    }

    print('Fetching appointments for doctor: ${currentUser.uid}');
    
    return _firestore
        .collection('doctorVisits')
        .where('doctorId', isEqualTo: currentUser.uid)
        .snapshots()
        .handleError((error) {
          print('Error fetching appointments: $error');
          throw error;
        });
  }

  // Update appointment status
  Future<void> updateAppointmentStatus({
    required String docId,
    required String status,
  }) async {
    try {
      print('Updating appointment $docId to status: $status');
      
      // First verify the appointment exists
      final appointmentDoc = await _firestore.collection('doctorVisits').doc(docId).get();
      if (!appointmentDoc.exists) {
        print('Error: Appointment $docId not found');
        throw Exception('Appointment not found');
      }
      
      print('Current appointment data: ${appointmentDoc.data()}');
      
      // Update the appointment
      await _firestore.collection('doctorVisits').doc(docId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('Successfully updated appointment $docId to status: $status');
      
      // Verify the update
      final updatedDoc = await _firestore.collection('doctorVisits').doc(docId).get();
      print('Updated appointment data: ${updatedDoc.data()}');
    } catch (e) {
      print('Error updating appointment status: $e');
      throw Exception('Failed to update appointment status: $e');
    }
  }

  // Check if current user is a doctor
  Future<bool> isDoctor() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    final isDoctor = userDoc.exists && userDoc.data()?['role'] == 'doctor';
    print('User ${currentUser.uid} is doctor: $isDoctor');
    return isDoctor;
  }

  // Get all doctors
  Stream<List<Doctor>> getDoctors() {
    return Stream.fromFuture(Future(() async {
      try {
        print('Fetching doctors from users collection...');
        
        // Get users with the role 'doctor' from the users collection
        final usersWithDoctorRoleSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'doctor')
            .get();
        
        print('Found ${usersWithDoctorRoleSnapshot.size} users with doctor role');
        
        // Create list for users with doctor role
        final userDoctors = usersWithDoctorRoleSnapshot.docs.map((doc) {
          final data = doc.data();
          final fullName = data['fullName'] ?? 
                          '${data['fname'] ?? ''} ${data['lname'] ?? ''}' ?? 
                          data['name'] ?? 
                          'Dr. Unknown';
          
          print('Processing user doctor: $fullName (${doc.id})');
          print('Doctor data: $data');
          
          return Doctor(
            id: doc.id,
            name: fullName,
            specialty: data['specialty'] ?? 'General Medicine',
            imageUrl: data['profilePicture'] ?? 'https://randomuser.me/api/portraits/men/${Random().nextInt(50)}.jpg',
            rating: (data['rating'] ?? 4.5 + Random().nextDouble() * 0.5).toDouble(),
            reviews: data['reviews'] ?? Random().nextInt(100) + 20,
            experience: data['experience'] is String ? data['experience'] : '${Random().nextInt(15) + 5} years',
            education: data['education'] ?? 'Medical School',
            languages: List<String>.from(data['languages'] ?? ['Arabic', 'English']),
            isAvailable: data['isAvailable'] ?? true,
            consultationFee: (data['consultationFee'] ?? 200.0 + Random().nextInt(200)).toDouble(),
          );
        }).toList();
        
        if (userDoctors.isEmpty) {
          print('No doctors found in users collection');
          throw Exception('No doctors available');
        }
        
        userDoctors.shuffle();
        print('Returning ${userDoctors.length} doctors from users collection');
        return userDoctors;
      } catch (error) {
        print('Error fetching doctors: $error');
        throw error;
      }
    }));
  }

  Future<Doctor?> getDoctorByUserId(String userId) async {
    try {
      // First try to get the doctor from the doctors collection
      final snapshot = await _firestore
          .collection('doctors')
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No doctor record found in doctors collection, checking users collection');
        // If no doctor record found, try to get user data from users collection
        final userDoc = await _firestore
            .collection('users')
            .doc(userId)
            .get();
            
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData['role'] == 'doctor') {
            print('Found doctor user data, creating doctor record');
            
            // Create a new doctor record
            final doctorData = {
              'userId': userId,
              'name': userData['name'] ?? userData['fullName'] ?? 'Dr. Unknown',
              'specialty': userData['specialty'] ?? 'General Medicine',
              'imageUrl': userData['profilePicture'] ?? 'https://randomuser.me/api/portraits/men/1.jpg',
              'rating': 0.0,
              'reviews': 0,
              'experience': userData['experience'] ?? '0 years',
              'education': userData['education'] ?? 'Not specified',
              'languages': userData['languages'] ?? ['Arabic'],
              'isAvailable': true,
              'consultationFee': 200.0,
              'createdAt': FieldValue.serverTimestamp(),
            };
            
            final docRef = await _firestore.collection('doctors').add(doctorData);
            print('Created new doctor record with ID: ${docRef.id}');
            
            return Doctor(
              id: docRef.id,
              name: doctorData['name'],
              specialty: doctorData['specialty'],
              imageUrl: doctorData['imageUrl'],
              rating: doctorData['rating'],
              reviews: doctorData['reviews'],
              experience: doctorData['experience'],
              education: doctorData['education'],
              languages: List<String>.from(doctorData['languages']),
              isAvailable: doctorData['isAvailable'],
              consultationFee: doctorData['consultationFee'],
            );
          }
        }
        return null;
      }

      final doc = snapshot.docs.first;
      final data = doc.data();
      return Doctor(
        id: doc.id,
        name: data['name'] ?? 'Unknown Doctor',
        specialty: data['specialty'] ?? 'General Medicine',
        imageUrl: data['imageUrl'] ?? 'https://randomuser.me/api/portraits/men/1.jpg',
        rating: (data['rating'] ?? 3.0).toDouble(),
        reviews: data['reviews'] ?? 0,
        experience: data['experience'] ?? '0 years',
        education: data['education'] ?? 'Not specified',
        languages: List<String>.from(data['languages'] ?? ['Arabic']),
        isAvailable: data['isAvailable'] ?? true,
        consultationFee: (data['consultationFee'] ?? 200.0).toDouble(),
      );
    } catch (e) {
      print('Error getting doctor by user ID: $e');
      return null;
    }
  }
} 