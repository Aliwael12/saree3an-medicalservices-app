import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/doctor_dashboard_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/medic_dashboard_screen.dart';
import 'services/admin_service.dart';
import 'services/doctor_service.dart';
import 'constants/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    
    // Configure Firestore settings for better reliability
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    print('Firebase initialized successfully!');
    
    // Test Firebase connectivity
    try {
      final auth = FirebaseAuth.instance;
      print('Firebase Auth initialized: ${auth.app.name}');
      
      final firestore = FirebaseFirestore.instance;
      print('Firestore initialized: ${firestore.app.name}');
      
      // Test Firestore connectivity with a harmless operation
      await firestore.collection('_connectivity_test').doc('test').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Connectivity test',
      });
      print('Firestore write test successful!');
      
      // Clean up test document
      await firestore.collection('_connectivity_test').doc('test').delete();
      print('Firestore delete test successful!');
    } catch (testError) {
      print('Firebase connectivity test failed: $testError');
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
    // Still proceed with the app, but some features might not work
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sareean App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
        '/doctor': (context) => const DoctorDashboardScreen(),
        '/medic': (context) => const MedicDashboardScreen(),
      },
    );
  }
}
