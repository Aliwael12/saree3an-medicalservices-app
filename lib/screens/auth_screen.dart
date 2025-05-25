import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_theme.dart';
import '../services/firebase_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_details.dart';
import 'medic_dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  String? _selectedBloodType;
  bool _isSignUp = false;
  bool _isLoading = false;

  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userDetails = await FirebaseService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      print('Sign in successful. User role: ${userDetails.role}'); // Debug log

      if (mounted) {
        switch (userDetails.role) {
          case 'admin':
            print('Navigating to admin dashboard'); // Debug log
            Navigator.pushReplacementNamed(context, '/admin');
            break;
          case 'doctor':
            print('Navigating to doctor dashboard'); // Debug log
            Navigator.pushReplacementNamed(context, '/doctor');
            break;
          case 'medic':
            print('Navigating to medic dashboard'); // Debug log
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MedicDashboardScreen()),
            );
            break;
          default:
            print('Navigating to home screen'); // Debug log
            Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      // Check if the user is already authenticated despite the error
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // User is logged in despite the error, try to get their role
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
          
          if (userDoc.exists && mounted) {
            final data = userDoc.data();
            final role = data?['role'] as String? ?? 'patient';
            
            // Print the role to verify it's correct
            print('Retrieved user role from Firestore after sign-in error: $role');
            
            // Navigate based on role
            switch (role) {
              case 'admin':
                Navigator.pushReplacementNamed(context, '/admin');
                break;
              case 'doctor':
                Navigator.pushReplacementNamed(context, '/doctor');
                break;
              case 'medic':
                print('Navigating to medic dashboard');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MedicDashboardScreen()),
                );
                break;
              default:
                Navigator.pushReplacementNamed(context, '/home');
            }
            return; // Don't show error if we successfully redirected
          }
        } catch (_) {
          // If we can't get the role, continue to show the error
        }
      }
      
      // Show error message if we couldn't redirect
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      print('Starting signup process...');
      
      // First, let's create the user and get userDetails
      final userDetails = await FirebaseService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
        phone: _phoneController.text,
        nationalId: '', // Not required anymore
        gender: 'not specified', // Not required anymore
        bloodType: _selectedBloodType ?? 'not specified',
        medicalHistory: _medicalHistoryController.text,
        address: _addressController.text,
      );

      // Debug output to verify user details
      print('Sign up successful. User details: ${userDetails.toMap()}');
      print('User role: ${userDetails.role}');

      // Verify the user document exists in Firestore
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          // Double check if the user document exists and has proper data
          final docSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
              
          if (!docSnapshot.exists) {
            // User document doesn't exist, create it directly here as a fallback
            print('Creating user document for ${currentUser.uid} as fallback');
            
            final userData = {
              'uid': currentUser.uid,
              'mail': _emailController.text,
              'email': _emailController.text,
              'name': _nameController.text,
              'fname': _nameController.text.split(' ').first,
              'lname': _nameController.text.split(' ').length > 1 
                  ? _nameController.text.split(' ').sublist(1).join(' ') : '',
              'phone': _phoneController.text,
              'bloodType': _selectedBloodType ?? 'not specified',
              'bloodtype': _selectedBloodType ?? 'not specified',
              'medicalHistory': _medicalHistoryController.text,
              'history': _medicalHistoryController.text,
              'gender': 'not specified',
              'address': _addressController.text,
              'role': 'patient',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            };
            
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .set(userData);
                
            print('User document created successfully as fallback');
          } else {
            // Document exists, but let's verify it's in the correct format (not a List)
            final data = docSnapshot.data();
            if (data is List) {
              // Document is in wrong format, overwrite it
              print('User document exists but in wrong format. Fixing...');
              
              final userData = {
                'uid': currentUser.uid,
                'mail': _emailController.text,
                'email': _emailController.text,
                'name': _nameController.text,
                'fname': _nameController.text.split(' ').first,
                'lname': _nameController.text.split(' ').length > 1 
                    ? _nameController.text.split(' ').sublist(1).join(' ') : '',
                'phone': _phoneController.text,
                'bloodType': _selectedBloodType ?? 'not specified',
                'bloodtype': _selectedBloodType ?? 'not specified',
                'medicalHistory': _medicalHistoryController.text,
                'history': _medicalHistoryController.text,
                'gender': 'not specified',
                'address': _addressController.text,
                'role': 'patient',
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              };
              
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .set(userData);
                  
              print('User document fixed successfully');
            } else {
              print('User document exists in correct format. No fix needed.');
            }
          }
        } catch (docError) {
          print('Error verifying/creating user document: $docError');
          // Continue with navigation even if this check fails
        }
      }

      if (mounted) {
        // Navigate to the home screen
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print('Sign up error: $e');
      
      // Even if we had an error, check if the user was created in Firebase Auth
      // This is crucial for handling the list/pigeon error case
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && mounted) {
        // User is created in Auth, which means signup technically succeeded
        // The error is likely just with parsing the user data
        print('User created in auth but error occurred: ${currentUser.uid}');
        
        try {
          // Create a basic user document in Firestore
          final basicUserData = {
            'uid': currentUser.uid,
            'mail': _emailController.text,
            'email': _emailController.text,
            'name': _nameController.text,
            'fname': _nameController.text.split(' ').first,
            'lname': _nameController.text.split(' ').length > 1 
                ? _nameController.text.split(' ').sublist(1).join(' ') : '',
            'phone': _phoneController.text,
            'bloodType': _selectedBloodType ?? 'not specified',
            'bloodtype': _selectedBloodType ?? 'not specified',
            'medicalHistory': _medicalHistoryController.text,
            'history': _medicalHistoryController.text,
            'gender': 'not specified',
            'address': _addressController.text,
            'role': 'patient',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };
          
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .set(basicUserData);
              
          print('Basic user document created successfully after error');
        } catch (docError) {
          print('Error creating backup user document: $docError');
          // Continue with navigation even if this fails
        }
        
        // Navigate to home screen regardless of document creation
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Authentication',
        showBackButton: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          MediaQuery.of(context).padding.bottom - 
                          kToolbarHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blue.withOpacity(0.1),
                                    Colors.blue.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.user,
                                    color: Colors.blue,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isSignUp ? 'Create Account' : 'Welcome Back',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _isSignUp
                                              ? 'Fill in your details to create an account'
                                              : 'Sign in to access your account',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54.withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.1, end: 0),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.blue),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.blue),
                                ),
                                prefixIcon: const Icon(Icons.email, color: Colors.blue),
                                filled: true,
                                fillColor: Colors.blue.withOpacity(0.05),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.blue),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.blue),
                                ),
                                prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                                filled: true,
                                fillColor: Colors.blue.withOpacity(0.05),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            if (_isSignUp) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.blue),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.blue),
                                  ),
                                  prefixIcon: const Icon(Icons.person, color: Colors.blue),
                                  filled: true,
                                  fillColor: Colors.blue.withOpacity(0.05),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.blue),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.blue),
                                  ),
                                  prefixIcon: const Icon(Icons.phone, color: Colors.blue),
                                  filled: true,
                                  fillColor: Colors.blue.withOpacity(0.05),
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedBloodType,
                                decoration: InputDecoration(
                                  labelText: 'Blood Type',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.blue),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.blue),
                                  ),
                                  prefixIcon: const Icon(Icons.bloodtype, color: Colors.blue),
                                  filled: true,
                                  fillColor: Colors.blue.withOpacity(0.05),
                                ),
                                items: _bloodTypes.map((String bloodType) {
                                  return DropdownMenuItem<String>(
                                    value: bloodType,
                                    child: Text(bloodType),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedBloodType = newValue;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select your blood type';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _addressController,
                                decoration: InputDecoration(
                                  labelText: 'Address',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.blue),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.blue),
                                  ),
                                  prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
                                  filled: true,
                                  fillColor: Colors.blue.withOpacity(0.05),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _medicalHistoryController,
                                decoration: InputDecoration(
                                  labelText: 'Medical History',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.blue),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.blue),
                                  ),
                                  prefixIcon: const Icon(Icons.medical_services, color: Colors.blue),
                                  filled: true,
                                  fillColor: Colors.blue.withOpacity(0.05),
                                ),
                                maxLines: 3,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your medical history';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _isSignUp = !_isSignUp;
                                        });
                                      },
                                      child: Text(
                                        _isSignUp ? 'Already have an account? Sign In' : 'Don\'t have an account? Sign Up',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _isSignUp ? _signUp : _handleSignIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    ),
                                    child: Text(
                                      _isSignUp ? 'Sign Up' : 'Sign In',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
} 