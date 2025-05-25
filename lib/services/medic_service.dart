import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medic_model.dart';

class MedicService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Medic?> getMedicByUserId(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('medics')
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      return Medic.fromMap(doc.data()..['id'] = doc.id);
    } catch (e) {
      print('Error getting medic by user ID: $e');
      return null;
    }
  }

  Future<List<Medic>> getMedics() async {
    try {
      final snapshot = await _firestore.collection('medics').get();
      return snapshot.docs
          .map((doc) => Medic.fromMap(doc.data()..['id'] = doc.id))
          .toList();
    } catch (e) {
      print('Error getting medics: $e');
      return [];
    }
  }
} 