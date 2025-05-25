import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getUserAppointments() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: user.uid)
        .orderBy('appointmentDate', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserTestReservations() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('test_reservations')
        .where('userId', isEqualTo: user.uid)
        .orderBy('reservationDate', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserAmbulanceRequests() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('ambulance_requests')
        .where('userId', isEqualTo: user.uid)
        .orderBy('requestDate', descending: true)
        .snapshots();
  }
} 