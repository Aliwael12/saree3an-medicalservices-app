import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'admin_dashboard_screen.dart';
import 'doctor_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3)); // Show splash screen for 3 seconds

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!mounted) return;

    if (!userDoc.exists) {
      Navigator.pushReplacementNamed(context, '/auth');
      return;
    }

    final userData = userDoc.data()!;
    if (userData['role'] == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin');
    } else if (userData['role'] == 'doctor') {
      Navigator.pushReplacementNamed(context, '/doctor');
    } else if (userData['role'] == 'medic') {
      Navigator.pushReplacementNamed(context, '/medic');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(delay: 200.ms, duration: 600.ms)
                .then()
                .shake(duration: 400.ms),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
                .animate()
                .fadeIn(delay: 800.ms, duration: 600.ms)
                .scale(delay: 800.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
} 