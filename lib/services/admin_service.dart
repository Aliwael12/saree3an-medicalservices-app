import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if current user is admin
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.exists && doc.data()?['role'] == 'admin';
  }

  // Get all ambulance requests
  Stream<QuerySnapshot> getAllAmbulanceRequests() {
    return _firestore
        .collection('ambulanceRequests')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get all doctor visits
  Stream<QuerySnapshot> getAllDoctorVisits() {
    return _firestore
        .collection('doctorVisits')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get all test reservations
  Stream<QuerySnapshot> getAllTestReservations() {
    return _firestore
        .collection('testReservations')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Add new ambulance car
  Future<void> addAmbulanceCar({
    required String carNumber,
    required String model,
    required String status,
  }) async {
    await _firestore.collection('ambulanceCars').add({
      'carNumber': carNumber,
      'model': model,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Add new ambulance driver
  Future<void> addAmbulanceDriver({
    required String name,
    required String phone,
    required String licenseNumber,
    required String status,
  }) async {
    await _firestore.collection('ambulanceDrivers').add({
      'name': name,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Add new doctor
  Future<void> addDoctor({
    required String name,
    required String specialty,
    required String phone,
    required String email,
    required String status,
    required int yearsOfExpertise,
    required String graduatedFrom,
    required double rating,
  }) async {
    await _firestore.collection('doctors').add({
      'name': name,
      'specialty': specialty,
      'phone': phone,
      'email': email,
      'status': status,
      'yearsOfExpertise': yearsOfExpertise,
      'graduatedFrom': graduatedFrom,
      'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Add new medic
  Future<void> addMedic({
    required String name,
    required String phone,
    required String email,
    required String graduatedFrom,
    required int yearsOfExperience,
  }) async {
    await _firestore.collection('medics').add({
      'name': name,
      'phone': phone,
      'email': email,
      'graduatedFrom': graduatedFrom,
      'yearsOfExperience': yearsOfExperience,
      'role': 'medic',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update request status
  Future<void> updateRequestStatus({
    required String collection,
    required String docId,
    required String status,
  }) async {
    await _firestore.collection(collection).doc(docId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStatistics() async {
    try {
      print('Fetching dashboard statistics...');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Get ambulance requests counts
      final ambulanceSnapshot = await _firestore.collection('ambulanceRequests').get();
      final ambulanceRequests = ambulanceSnapshot.docs.map((doc) => doc.data()).toList();
      print('Fetched ${ambulanceRequests.length} ambulance requests');
      
      // Get test reservations counts
      final testSnapshot = await _firestore.collection('testReservations').get();
      final testReservations = testSnapshot.docs.map((doc) => doc.data()).toList();
      print('Fetched ${testReservations.length} test reservations');
      
      // Get users counts
      final userSnapshot = await _firestore.collection('users').get();
      final users = userSnapshot.docs.map((doc) => doc.data()).toList();
      print('Fetched ${users.length} users');
      
      // Get doctor visits counts
      final doctorVisitsSnapshot = await _firestore.collection('doctorVisits').get();
      final doctorVisits = doctorVisitsSnapshot.docs.map((doc) => doc.data()).toList();
      print('Fetched ${doctorVisits.length} doctor visits');
      
      // Calculate ambulance statistics safely
      int pendingAmbulance = 0;
      int completedAmbulance = 0;
      int cancelledAmbulance = 0;
      int todayAmbulance = 0;
      
      for (var request in ambulanceRequests) {
        final status = request['status'] as String?;
        if (status == 'pending') pendingAmbulance++;
        if (status == 'completed') completedAmbulance++;
        if (status == 'cancelled') cancelledAmbulance++;
        
        try {
          final createdAt = request['createdAt'] as Timestamp?;
          if (createdAt != null) {
            final date = createdAt.toDate();
            if (date.year == today.year && date.month == today.month && date.day == today.day) {
              todayAmbulance++;
            }
          }
        } catch (e) {
          print('Error parsing ambulance date: $e');
        }
      }
      
      // Calculate test statistics safely
      int homeVisits = 0;
      int labVisits = 0;
      int pendingTests = 0;
      int completedTests = 0;
      int todayTests = 0;
      
      for (var test in testReservations) {
        final labName = test['labName'] as String?;
        final status = test['status'] as String?;
        
        if (labName == 'Home Visit Service') homeVisits++;
        if (labName != 'Home Visit Service') labVisits++;
        if (status == 'pending') pendingTests++;
        if (status == 'completed') completedTests++;
        
        try {
          final testDate = test['date'] as Timestamp?;
          if (testDate != null) {
            final date = testDate.toDate();
            if (date.year == today.year && date.month == today.month && date.day == today.day) {
              todayTests++;
            }
          }
        } catch (e) {
          print('Error parsing test date: $e');
        }
      }
      
      // Calculate user statistics safely
      int patients = 0;
      int medics = 0;
      int doctors = 0;
      int newToday = 0;
      
      for (var user in users) {
        final role = user['role'] as String?;
        if (role == 'patient') patients++;
        if (role == 'medic') medics++;
        if (role == 'doctor') doctors++;
        
        try {
          final createdAt = user['createdAt'] as Timestamp?;
          if (createdAt != null) {
            final date = createdAt.toDate();
            if (date.year == today.year && date.month == today.month && date.day == today.day) {
              newToday++;
            }
          }
        } catch (e) {
          print('Error parsing user date: $e');
        }
      }
      
      // Calculate doctor visit statistics safely
      int pendingVisits = 0;
      int completedVisits = 0;
      int todayVisits = 0;
      
      for (var visit in doctorVisits) {
        final status = visit['status'] as String?;
        if (status == 'pending') pendingVisits++;
        if (status == 'completed') completedVisits++;
        
        try {
          final visitDate = visit['preferredDate'] as Timestamp?;
          if (visitDate != null) {
            final date = visitDate.toDate();
            if (date.year == today.year && date.month == today.month && date.day == today.day) {
              todayVisits++;
            }
          }
        } catch (e) {
          print('Error parsing doctor visit date: $e');
        }
      }
      
      // Build statistics maps with safe values
      final ambulanceStats = {
        'total': ambulanceRequests.length,
        'pending': pendingAmbulance,
        'completed': completedAmbulance,
        'cancelled': cancelledAmbulance,
        'today': todayAmbulance,
      };
      
      final testStats = {
        'total': testReservations.length,
        'homeVisits': homeVisits,
        'labVisits': labVisits,
        'pending': pendingTests,
        'completed': completedTests,
        'today': todayTests,
      };
      
      final userStats = {
        'total': users.length,
        'patients': patients,
        'medics': medics,
        'doctors': doctors,
        'newToday': newToday,
      };
      
      final doctorStats = {
        'total': doctorVisits.length,
        'pending': pendingVisits,
        'completed': completedVisits,
        'today': todayVisits,
      };
      
      print('Statistics calculated: Ambulance(${ambulanceStats['total']}), Tests(${testStats['total']}), Users(${userStats['total']}), Doctor Visits(${doctorStats['total']})');
      
      return {
        'ambulanceStats': ambulanceStats,
        'testStats': testStats,
        'userStats': userStats,
        'doctorStats': doctorStats,
      };
    } catch (e) {
      print('Error getting dashboard statistics: $e');
      return {
        'ambulanceStats': {'total': 0, 'pending': 0, 'completed': 0, 'cancelled': 0, 'today': 0},
        'testStats': {'total': 0, 'homeVisits': 0, 'labVisits': 0, 'pending': 0, 'completed': 0, 'today': 0},
        'userStats': {'total': 0, 'patients': 0, 'medics': 0, 'doctors': 0, 'newToday': 0},
        'doctorStats': {'total': 0, 'pending': 0, 'completed': 0, 'today': 0},
      };
    }
  }
} 