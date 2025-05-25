import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import 'medic_dashboard_screen.dart';
import 'doctor_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'login_screen.dart';

class RoleBasedHome extends StatefulWidget {
  const RoleBasedHome({super.key});

  @override
  State<RoleBasedHome> createState() => _RoleBasedHomeState();
}

class _RoleBasedHomeState extends State<RoleBasedHome> {
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _userRole = null;
        });
        return;
      }

      // Get user role from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        setState(() {
          _isLoading = false;
          _userRole = null;
        });
        return;
      }

      final role = userDoc.data()?['role'] as String?;
      print('User role: $role'); // Debug print

      setState(() {
        _userRole = role;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking user role: $e');
      setState(() {
        _isLoading = false;
        _userRole = null;
      });
    }
  }

  Widget _getDashboardForRole() {
    print('Getting dashboard for role: $_userRole'); // Debug print
    
    switch (_userRole?.toLowerCase()) {
      case 'medic':
        return const MedicDashboardScreen();
      case 'doctor':
        return const DoctorDashboardScreen();
      case 'admin':
        return const AdminDashboardScreen();
      default:
        return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_userRole == null) {
      return const LoginScreen();
    }

    return _getDashboardForRole();
  }
} 