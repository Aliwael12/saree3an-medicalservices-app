import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/home_screen.dart';
import '../screens/services_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/about_us_screen.dart';
import '../screens/contact_us_screen.dart';
import '../screens/faq_screen.dart';
import '../theme/app_theme.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;
  StreamSubscription<User?>? _authSubscription;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ServicesScreen(),
    const AuthScreen(), // This will be replaced based on auth state
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _checkAuthState() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (!mounted) return;
      
      setState(() {
        _screens[2] = user != null ? const UserProfileScreen() : const AuthScreen();
      });
    });
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      // Show more options
      _showMoreOptions();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blue),
              title: const Text('About Us'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/about-us');
              },
            ),
            ListTile(
              leading: const Icon(Icons.question_answer, color: Colors.blue),
              title: const Text('FAQ'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/faq');
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_support, color: Colors.blue),
              title: const Text('Contact Us'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/contact-us');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
        currentIndex: _selectedIndex > 2 ? 3 : _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
} 