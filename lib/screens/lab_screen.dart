import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/animated_button.dart';
import '../models/lab_model.dart';
import '../services/firebase_service.dart';
import 'lab_confirmation_screen.dart';

class LabScreen extends StatefulWidget {
  const LabScreen({super.key});

  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final List<Map<String, dynamic>> _labTests = [
    {
      'id': 'cbc',
      'name': 'Complete Blood Count (CBC)',
      'description': 'Measures different components and features of your blood.',
      'price': 25.99,
      'icon': FontAwesomeIcons.droplet,
      'selected': false,
    },
    {
      'id': 'glucose',
      'name': 'Blood Glucose Test',
      'description': 'Measures the amount of glucose in your blood.',
      'price': 15.99,
      'icon': FontAwesomeIcons.vial,
      'selected': false,
    },
    {
      'id': 'lipid',
      'name': 'Lipid Panel',
      'description': 'Measures fats and fatty substances in your blood.',
      'price': 30.99,
      'icon': FontAwesomeIcons.flask,
      'selected': false,
    },
    {
      'id': 'liver',
      'name': 'Liver Function Test',
      'description': 'Measures proteins, enzymes, and bilirubin in your blood.',
      'price': 35.99,
      'icon': FontAwesomeIcons.lungs,
      'selected': false,
    },
    {
      'id': 'kidney',
      'name': 'Kidney Function Test',
      'icon': FontAwesomeIcons.kidneys,
      'description': 'Tests to evaluate kidney function and health.',
      'price': 28.99,
      'selected': false,
    },
    {
      'id': 'thyroid',
      'name': 'Thyroid Function Test',
      'description': 'Checks the function of your thyroid gland.',
      'price': 42.99,
      'icon': FontAwesomeIcons.heartPulse,
      'selected': false,
    },
    {
      'id': 'vitamin',
      'name': 'Vitamin D Test',
      'description': 'Measures the level of vitamin D in your blood.',
      'price': 22.99,
      'icon': FontAwesomeIcons.sun,
      'selected': false,
    },
    {
      'id': 'mri',
      'name': 'MRI Scan',
      'description': 'Magnetic Resonance Imaging scan for detailed body imaging.',
      'price': 299.99,
      'icon': FontAwesomeIcons.magnet,
      'selected': false,
    },
    {
      'id': 'xray',
      'name': 'X-Ray',
      'description': 'X-Ray imaging for bones and chest examination.',
      'price': 49.99,
      'icon': FontAwesomeIcons.xRay,
      'selected': false,
    },
    {
      'id': 'ct',
      'name': 'CT Scan',
      'description': 'Computed Tomography scan for detailed cross-sectional imaging.',
      'price': 199.99,
      'icon': FontAwesomeIcons.brain,
      'selected': false,
    },
    {
      'id': 'ultrasound',
      'name': 'Ultrasound',
      'description': 'Ultrasound imaging for soft tissue examination.',
      'price': 89.99,
      'icon': FontAwesomeIcons.waveSquare,
      'selected': false,
    },
    {
      'id': 'ecg',
      'name': 'ECG',
      'description': 'Electrocardiogram test for heart function analysis.',
      'price': 39.99,
      'icon': FontAwesomeIcons.heartPulse,
      'selected': false,
    },
  ];

  bool _homeCollection = true;
  String _selectedDate = '';
  String _selectedTime = '09:00 AM';
  bool _isProcessing = false;
  bool _isConfirmed = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set default selected date to tomorrow's date
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _selectedDate = '${tomorrow.day}/${tomorrow.month}/${tomorrow.year}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    double total = 0;
    for (var test in _labTests) {
      if (test['selected']) {
        total += test['price'] as double;
      }
    }
    // Add home collection fee if selected
    if (_homeCollection) {
      total += 10.00;
    }
    return total;
  }

  int get _selectedTestsCount {
    return _labTests.where((test) => test['selected']).length;
  }

  void _toggleTestSelection(int index) {
    setState(() {
      final test = _labTests[index];
      final isBloodTest = test['id'] == 'cbc' || 
                         test['id'] == 'glucose' || 
                         test['id'] == 'lipid' || 
                         test['id'] == 'liver' || 
                         test['id'] == 'kidney' || 
                         test['id'] == 'thyroid' || 
                         test['id'] == 'vitamin';
      
      if (_homeCollection && !isBloodTest) {
        return; // Don't allow selection of non-blood tests for home collection
      }
      
      test['selected'] = !test['selected'];
    });
  }

  void _toggleHomeCollection(bool value) {
    setState(() {
      _homeCollection = value;
      // Deselect non-blood tests when switching to home collection
      if (_homeCollection) {
        for (var test in _labTests) {
          final isBloodTest = test['id'] == 'cbc' || 
                            test['id'] == 'glucose' || 
                            test['id'] == 'lipid' || 
                            test['id'] == 'liver' || 
                            test['id'] == 'kidney' || 
                            test['id'] == 'thyroid' || 
                            test['id'] == 'vitamin';
          if (!isBloodTest) {
            test['selected'] = false;
          }
        }
      }
    });
  }

  Future<void> _submitReservation() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        setState(() {
          _isProcessing = true;
        });

        await FirebaseService.reserveLabTest(
          patientName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          selectedTests: _labTests.where((test) => test['selected']).map((e) => e['id']).toList(),
          totalAmount: _totalAmount,
          isHomeCollection: _homeCollection,
          selectedDate: DateTime.parse(_selectedDate),
          selectedTime: _selectedTime,
          address: _homeCollection ? _addressController.text.trim() : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lab test reservation submitted successfully!'),
              backgroundColor: AppTheme.success,
            ),
          );
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit reservation: ${e.toString()}'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  Future<void> _launchMap() async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=123+Medical+Center+Downtown',
    );
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch map'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _launchCall() async {
    final Uri url = Uri.parse('tel:+1234567890');
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch call'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const CustomAppBar(
        title: 'Lab Tests',
      ),
      body: _buildTestSelectionScreen(),
    );
  }

  Widget _buildTestSelectionScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('Collection Type'),
            const SizedBox(height: 16),
            _buildCollectionOptions(),
            const SizedBox(height: 24),
            _buildSectionTitle('Available Tests'),
            const SizedBox(height: 16),
            if (_homeCollection)
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Only blood tests are available for home collection',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            _buildLabTestList(),
            const SizedBox(height: 24),
            _buildSectionTitle('Patient Information'),
            const SizedBox(height: 16),
            _buildPatientForm(),
            const SizedBox(height: 24),
            _buildPriceSummary(),
            const SizedBox(height: 24),
            AnimatedButton(
              text: 'Confirm Reservation',
              icon: Icons.check_circle,
              onPressed: _submitReservation,
              isLoading: _isProcessing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const FaIcon(
              FontAwesomeIcons.flask,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lab Tests at Home',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Select tests, schedule a time, and our phlebotomist will collect your sample at your doorstep.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          height: 24,
          width: 4,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildLabTestList() {
    // Filter tests based on collection type
    final visibleTests = _homeCollection
        ? _labTests.where((test) {
            final isBloodTest = test['id'] == 'cbc' ||
                test['id'] == 'glucose' ||
                test['id'] == 'lipid' ||
                test['id'] == 'liver' ||
                test['id'] == 'kidney' ||
                test['id'] == 'thyroid' ||
                test['id'] == 'vitamin';
            return isBloodTest;
          }).toList()
        : _labTests;

    // Make sure at least one test is selected
    if (!_labTests.any((test) => test['selected'])) {
      // Select first available test by default
      if (visibleTests.isNotEmpty) {
        visibleTests[0]['selected'] = true;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Test',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        SizedBox(height: 16),
        
        // Simple, reliable dropdown for test selection
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text("Select a test"),
              value: _labTests.firstWhere((test) => test['selected'], orElse: () => visibleTests[0])['id'],
              items: visibleTests.map((test) {
                return DropdownMenuItem<String>(
                  value: test['id'],
                  child: Row(
                    children: [
                      FaIcon(
                        test['icon'],
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              test['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(
                              '\$${test['price'].toString()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    // Deselect all tests
                    for (var test in _labTests) {
                      test['selected'] = false;
                    }
                    // Select the chosen test
                    final selectedTest = _labTests.firstWhere((test) => test['id'] == newValue);
                    selectedTest['selected'] = true;
                  });
                }
              },
            ),
          ),
        ),
        
        // Show selected test details
        SizedBox(height: 16),
        if (_labTests.any((test) => test['selected']))
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Test',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    FaIcon(
                      _labTests.firstWhere((test) => test['selected'])['icon'],
                      color: AppTheme.primary,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _labTests.firstWhere((test) => test['selected'])['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _labTests.firstWhere((test) => test['selected'])['description'],
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${_labTests.firstWhere((test) => test['selected'])['price'].toString()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCollectionOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Home Sample Collection',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          subtitle: const Text(
            'Our phlebotomist will visit your home to collect the sample',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textLight,
            ),
          ),
          value: _homeCollection,
          activeColor: AppTheme.primary,
          onChanged: _toggleHomeCollection,
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Available Tests'),
        const SizedBox(height: 16),
        if (_homeCollection)
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Only blood tests are available for home collection',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        _buildLabTestList(),
        const SizedBox(height: 24),
        if (_homeCollection) ...[
          const Text(
            'Select Date and Time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );

                    if (pickedDate != null) {
                      setState(() {
                        _selectedDate =
                            '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppTheme.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDate,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );

                    if (pickedTime != null) {
                      setState(() {
                        _selectedTime = pickedTime.format(context);
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: AppTheme.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _selectedTime,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              prefixIcon: Icon(Icons.location_on),
            ),
            validator: (value) {
              if (_homeCollection && (value == null || value.isEmpty)) {
                return 'Please enter your address for home collection';
              }
              return null;
            },
          ),
        ],
        if (!_homeCollection)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Visit Our Lab',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You can visit our diagnostic center at:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '123 Medical Center, Downtown\nCity, Country\nWorking Hours: 8:00 AM - 8:00 PM',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _launchMap,
                        icon: const Icon(Icons.map),
                        label: const Text('View on Map'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _launchCall,
                        icon: const Icon(Icons.call),
                        label: const Text('Call Center'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPatientForm() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person),
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
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            _selectedTestsCount,
            (index) {
              final test = _labTests.where((t) => t['selected']).toList()[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      test['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      '\$${test['price']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_homeCollection) ...[
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Home Collection Fee',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  '\$10.00',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ],
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              Text(
                '\$${_totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
} 