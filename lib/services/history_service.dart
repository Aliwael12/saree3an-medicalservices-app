import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Get doctor visits
  Stream<QuerySnapshot> getDoctorVisits() {
    return _firestore
        .collection('doctorVisits')
        .where('userId', isEqualTo: _userId)
        .orderBy('appointmentDate', descending: true)
        .snapshots();
  }

  // Get test reservations
  Stream<QuerySnapshot> getTestReservations() {
    return _firestore
        .collection('testReservations')
        .where('userId', isEqualTo: _userId)
        .orderBy('preferredDate', descending: true)
        .snapshots();
  }

  // Get ambulance requests
  Stream<QuerySnapshot> getAmbulanceRequests() {
    return _firestore
        .collection('ambulanceRequests')
        .where('userId', isEqualTo: _userId)
        .snapshots();
  }
} 