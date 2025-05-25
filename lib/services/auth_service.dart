import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user role
  Future<String?> getUserRole() async {
    if (currentUser == null) return null;
    
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      return userDoc.data()?['role'] as String?;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Check if user has access to a specific role
  Future<bool> hasRoleAccess(List<String> allowedRoles) async {
    final userRole = await getUserRole();
    return userRole != null && allowedRoles.contains(userRole);
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user role
      final userRole = await getUserRole();
      if (userRole == null) {
        throw Exception('User role not found');
      }

      return userCredential;
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
} 