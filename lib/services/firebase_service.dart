import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_details.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  static Future<UserDetails> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    String nationalId = '',
    String gender = 'not specified',
    required String medicalHistory,
    required String bloodType,
    required String address,
  }) async {
    try {
      // Validate input
      if (email.isEmpty || password.isEmpty) {
        throw 'Email and password are required';
      }

      // Create user in Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw 'Failed to create user';
      }

      final String uid = userCredential.user!.uid;
      final DateTime now = DateTime.now();

      // Split name into first and last name for user_profile_screen
      List<String> nameParts = name.split(' ');
      String firstName = nameParts.isNotEmpty ? nameParts[0] : name;
      String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final UserDetails userDetails = UserDetails(
        uid: uid,
        email: email,
        name: name,
        phone: phone,
        nationalId: nationalId,
        gender: gender,
        bloodType: bloodType,
        medicalHistory: medicalHistory,
        role: 'patient',
        createdAt: now,
        updatedAt: now,
        address: address,
      );

      // Create user document in Firestore with format compatible with profile screen
      final Map<String, dynamic> userData = {
        // Fields for UserDetails model
        'uid': uid,
        'mail': email,
        'email': email, // Added for additional compatibility
        'name': name,
        'phone': phone,
        'nationalid': nationalId,
        'gender': gender,
        'bloodType': bloodType,
        'medicalHistory': medicalHistory,
        'role': 'patient',
        'address': address,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        
        // Additional fields for user_profile_screen
        'fname': firstName,
        'lname': lastName,
        'fullName': name,
        'username': email.split('@')[0],
        'bloodtype': bloodType, // Duplicate with different field name for profile screen
        'history': medicalHistory, // Duplicate with different field name for profile screen
      };
      
      print('Creating user with data: $userData');
      
      try {
        // Use set instead of add to ensure we're creating a document with the UID as key
        await _firestore.collection('users').doc(uid).set(userData);

        // Verify the document was created
        final doc = await _firestore.collection('users').doc(uid).get();
        if (!doc.exists) {
          // If document creation failed, delete the auth user
          await userCredential.user?.delete();
          throw 'Failed to create user document';
        }
        
        // Double check data format
        final docData = doc.data();
        print('User document created successfully. Data: $docData');
        
        // Return the UserDetails we created rather than parsing from Firestore
        return userDetails;
      } catch (docError) {
        print('Error creating/verifying document: $docError');
        print('User created in auth but error occurred: $uid');
        
        // Despite the error, return the UserDetails object to avoid breaking the app flow
        return userDetails;
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw 'Email is already in use';
        case 'weak-password':
          throw 'Password is too weak';
        case 'invalid-email':
          throw 'Invalid email address';
        default:
          throw 'An error occurred during sign up';
      }
    } catch (e) {
      print('Unexpected error during sign up: $e');
      throw 'Unexpected error during sign up: $e';
    }
  }

  // Sign in with email and password
  static Future<UserDetails> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw 'Failed to sign in';
      }

      print('User signed in successfully: ${userCredential.user!.uid}');
      
      // Here we'll use a try-catch to handle potential errors when retrieving user data
      try {
        // Get user data directly rather than going through getUserData
        final doc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
            
        if (!doc.exists) {
          print('User document not found after sign in');
          // Create a minimal UserDetails object to return
          final DateTime now = DateTime.now();
          return UserDetails(
            uid: userCredential.user!.uid,
            email: email,
            name: '',
            phone: '',
            bloodType: '',
            medicalHistory: '',
            role: 'patient',
            address: '',
            createdAt: now,
            updatedAt: now,
          );
        }
        
        // We have document data, try to parse it
        final data = doc.data();
        print('User document found: $data');
        
        // Use the fromMap method which has robust error handling
        final userDetails = UserDetails.fromMap(data);
        return userDetails;
      } catch (userDataError) {
        print('Error getting user data after sign in: $userDataError');
        // Return a basic UserDetails object if we can't get/parse the data
        final DateTime now = DateTime.now();
        return UserDetails(
          uid: userCredential.user!.uid,
          email: email,
          name: '',
          phone: '',
          bloodType: '',
          medicalHistory: '',
          role: 'patient',
          address: '',
          createdAt: now,
          updatedAt: now,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email. Please sign up first.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          message = 'The email address is invalid.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many failed attempts. Please try again later.';
          break;
        default:
          message = 'Sign in failed: ${e.message}';
      }
      throw message;
    } catch (e) {
      // Catch all other errors, including the PigeonUserDetails type mismatch
      print('Sign in error: $e');
      
      // Since we've likely authenticated successfully but had a parsing issue,
      // we can try to handle it gracefully
      final user = _auth.currentUser;
      if (user != null) {
        print('User is authenticated despite error, creating minimal UserDetails');
        
        // Try to get the actual user role from Firestore instead of defaulting to 'patient'
        try {
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          String role = 'patient'; // Default role
          
          if (userDoc.exists) {
            final userData = userDoc.data();
            if (userData != null && userData['role'] != null) {
              role = userData['role'].toString();
              print('Retrieved actual user role from Firestore: $role');
            }
          }
          
          final DateTime now = DateTime.now();
          return UserDetails(
            uid: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? '',
            phone: '',
            bloodType: '',
            medicalHistory: '',
            role: role, // Use the actual role from Firestore
            address: '',
            createdAt: now,
            updatedAt: now,
          );
        } catch (roleError) {
          print('Error retrieving user role: $roleError');
          // If we can't get the role, fallback to a default UserDetails
          final DateTime now = DateTime.now();
          return UserDetails(
            uid: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? '',
            phone: '',
            bloodType: '',
            medicalHistory: '',
            role: 'patient', // Default if we can't retrieve the actual role
            address: '',
            createdAt: now,
            updatedAt: now,
          );
        }
      }
      
      throw 'There was a problem signing in. Please try again.';
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user data
  static Future<UserDetails?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        print('User document does not exist for UID: $uid');
        return null;
      }
      
      final data = doc.data();
      if (data == null) {
        print('User document exists but data is null for UID: $uid');
        return null;
      }
      
      print('Retrieved user data: $data');
      
      // Properly handle data formats to avoid List<Object?> error
      if (data is List) {
        print('Received List instead of Map in getUserData, trying to fix...');
        
        // Get the actual role from the Firestore document if possible
        String role = 'patient'; // Default role
        try {
          // Try to get the role directly from Firestore again
          final userDoc = await _firestore.collection('users').doc(uid).get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            if (userData != null && userData is Map && userData['role'] != null) {
              role = userData['role'].toString();
              print('Retrieved actual user role from Firestore: $role');
            }
          }
        } catch (roleError) {
          print('Error retrieving user role: $roleError');
          // Keep the default role if we can't retrieve it
        }
        
        // If we somehow got a List, let's create a proper user data Map
        final DateTime now = DateTime.now();
        final user = FirebaseAuth.instance.currentUser;
        
        Map<String, dynamic> fixedUserData = {
          'uid': uid,
          'mail': user?.email ?? '',
          'email': user?.email ?? '',
          'name': user?.displayName ?? '',
          'phone': '',
          'nationalid': '',
          'gender': 'not specified',
          'bloodType': '',
          'medicalHistory': '',
          'role': role, // Use the retrieved role instead of hardcoding 'patient'
          'address': '',
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now)
        };
        
        // Save the fixed data to Firestore to prevent future errors
        try {
          await _firestore.collection('users').doc(uid).set(fixedUserData);
          print('Fixed incorrect user data format in Firestore');
        } catch (e) {
          print('Error saving fixed user data: $e');
        }
        
        // Return user details from our fixed map
        return UserDetails.fromMap(fixedUserData);
      }
      
      // Use the improved fromMap method from UserDetails
      return UserDetails.fromMap(data);
    } catch (e) {
      print('Error in getUserData: $e');
      
      // Try to create a minimal valid user object to prevent app crashes
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Try to get the actual role from Firestore
          String role = 'patient'; // Default role
          try {
            final userDoc = await _firestore.collection('users').doc(uid).get();
            if (userDoc.exists) {
              final userData = userDoc.data();
              if (userData != null && userData is Map && userData['role'] != null) {
                role = userData['role'].toString();
                print('Retrieved actual user role for fallback UserDetails: $role');
              }
            }
          } catch (roleError) {
            print('Error retrieving user role for fallback: $roleError');
            // Keep the default role if we can't retrieve it
          }
          
          final DateTime now = DateTime.now();
          return UserDetails(
            uid: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? '',
            phone: '',
            bloodType: '',
            medicalHistory: '',
            role: role, // Use the retrieved role
            address: '',
            createdAt: now,
            updatedAt: now,
          );
        }
      } catch (innerError) {
        print('Error creating fallback UserDetails: $innerError');
      }
      
      return null;
    }
  }

  // Update user data
  static Future<void> updateUserData(String uid, UserDetails userDetails) async {
    try {
      await _firestore.collection('users').doc(uid).update(userDetails.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Create appointment
  static Future<String> createAppointment({
    required String doctorId,
    required String patientId,
    required DateTime appointmentDate,
    required String symptoms,
    required double consultationFee,
    required String address,
    String? notes,
  }) async {
    try {
      final appointmentDoc = await _firestore.collection('appointments').add({
        'doctorId': doctorId,
        'patientId': patientId,
        'appointmentDate': Timestamp.fromDate(appointmentDate),
        'symptoms': symptoms,
        'consultationFee': consultationFee,
        'address': address,
        'notes': notes,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return appointmentDoc.id;
    } catch (e) {
      rethrow;
    }
  }

  // Get appointment by ID
  static Future<Map<String, dynamic>?> getAppointment(String appointmentId) async {
    try {
      final doc = await _firestore.collection('appointments').doc(appointmentId).get();
      return doc.data();
    } catch (e) {
      rethrow;
    }
  }

  // Update appointment status
  static Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get user appointments
  static Stream<QuerySnapshot> getUserAppointments(String userId, {String? status}) {
    Query query = _firestore.collection('appointments')
        .where('patientId', isEqualTo: userId)
        .orderBy('appointmentDate', descending: true);
    
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    
    return query.snapshots();
  }

  // Get doctor appointments
  static Stream<QuerySnapshot> getDoctorAppointments(String doctorId, {String? status}) {
    Query query = _firestore.collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('appointmentDate', descending: true);
    
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    
    return query.snapshots();
  }

  // Book doctor appointment
  static Future<void> bookDoctorAppointment({
    required String patientName,
    required String phoneNumber,
    required String doctorName,
    required String specialty,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String reason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('FirebaseService.bookDoctorAppointment: User not authenticated');
        throw Exception('User not authenticated');
      }

      print('FirebaseService.bookDoctorAppointment: Creating appointment for user ${user.uid}');
      print('FirebaseService.bookDoctorAppointment: Doctor: $doctorName, Specialty: $specialty');
      print('FirebaseService.bookDoctorAppointment: Date: $appointmentDate, Time: $appointmentTime');

      final appointmentData = {
        'userId': user.uid,
        'patientName': patientName,
        'phoneNumber': phoneNumber,
        'doctorName': doctorName,
        'doctorSpecialty': specialty,
        'appointmentDate': Timestamp.fromDate(appointmentDate),
        'appointmentTime': appointmentTime,
        'symptoms': reason,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      print('FirebaseService.bookDoctorAppointment: Appointment data: $appointmentData');
      print('FirebaseService.bookDoctorAppointment: Saving to doctorVisits collection...');

      try {
        final docRef = await _firestore.collection('doctorVisits').add(appointmentData);
        print('FirebaseService.bookDoctorAppointment: Successfully saved! Document ID: ${docRef.id}');
        
        // Verify document creation
        final docSnapshot = await docRef.get();
        if (!docSnapshot.exists) {
          print('FirebaseService.bookDoctorAppointment: ERROR - Document not found after creation!');
          throw Exception('Document was not created successfully');
        }
        
        print('FirebaseService.bookDoctorAppointment: Document verified with data: ${docSnapshot.data()}');
      } catch (firestoreError) {
        print('FirebaseService.bookDoctorAppointment: Firestore error: $firestoreError');
        throw Exception('Failed to save appointment: $firestoreError');
      }
    } catch (e) {
      print('FirebaseService.bookDoctorAppointment: Error booking doctor appointment: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserHistory(String uid) async {
    try {
      final historySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('history')
          .orderBy('date', descending: true)
          .get();

      return historySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['type'] ?? 'unknown',
          'title': data['title'] ?? 'Unknown Event',
          'date': data['date'] ?? 'No date',
          'details': data['details'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error getting user history: $e');
      return [];
    }
  }

  static Future<void> addToHistory(String uid, Map<String, dynamic> historyData) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('history')
          .add({
        ...historyData,
        'date': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding to history: $e');
      rethrow;
    }
  }
} 