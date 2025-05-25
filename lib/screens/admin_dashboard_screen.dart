import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_theme.dart';
import '../services/admin_service.dart';
import '../widgets/custom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../widgets/statistics_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;
  int _currentTabIndex = 0;
  double _doctorRating = 0.0;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  
  // Statistics data
  Map<String, dynamic> _ambulanceStats = {
    'total': 0,
    'pending': 0,
    'completed': 0,
    'cancelled': 0,
    'today': 0,
  };
  
  Map<String, dynamic> _testStats = {
    'total': 0,
    'homeVisits': 0,
    'labVisits': 0,
    'pending': 0,
    'completed': 0,
    'today': 0,
  };
  
  Map<String, dynamic> _userStats = {
    'total': 0,
    'patients': 0,
    'medics': 0,
    'doctors': 0,
    'newToday': 0,
  };
  
  Map<String, dynamic> _doctorStats = {
    'total': 0,
    'pending': 0,
    'completed': 0,
    'today': 0,
  };

  // Controllers
  final _carNumberController = TextEditingController();
  final _carModelController = TextEditingController();
  String? _carStatus;

  // Doctor form controllers
  final _doctorNameController = TextEditingController();
  final _doctorEmailController = TextEditingController();
  final _doctorPhoneController = TextEditingController();
  final _doctorGraduatedFromController = TextEditingController();
  final _doctorSpecialtyController = TextEditingController();
  final _doctorYearsOfExperienceController = TextEditingController();
  String? _doctorStatus;

  // Medic form controllers
  final _medicNameController = TextEditingController();
  final _medicEmailController = TextEditingController();
  final _medicPhoneController = TextEditingController();
  final _medicGraduatedFromController = TextEditingController();
  final _medicYearsOfExperienceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _carNumberController.dispose();
    _carModelController.dispose();
    _doctorNameController.dispose();
    _doctorEmailController.dispose();
    _doctorPhoneController.dispose();
    _doctorGraduatedFromController.dispose();
    _doctorSpecialtyController.dispose();
    _doctorYearsOfExperienceController.dispose();
    _medicNameController.dispose();
    _medicEmailController.dispose();
    _medicPhoneController.dispose();
    _medicGraduatedFromController.dispose();
    _medicYearsOfExperienceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Get dashboard statistics from the admin service
      final statistics = await _adminService.getDashboardStatistics();
      
      setState(() {
        _ambulanceStats = statistics['ambulanceStats'];
        _testStats = statistics['testStats'];
        _userStats = statistics['userStats'];
        _doctorStats = statistics['doctorStats'];
        _isLoading = false;
      });
      
      print("Statistics updated: Ambulance(${_ambulanceStats['total']}), Tests(${_testStats['total']}), Users(${_userStats['total']}), Doctor Visits(${_doctorStats['total']})");
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Admin Dashboard',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Statistics'),
                Tab(text: 'Ambulance Requests'),
                Tab(text: 'Doctor Visits'),
                Tab(text: 'Test Reservations'),
                Tab(text: 'Add Resources'),
              ],
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
              isScrollable: true,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              bottom: true,
              maintainBottomViewPadding: true,
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStatisticsTab(),
                    _buildRequestsList(_adminService.getAllAmbulanceRequests(), _buildAmbulanceRequestItem),
                    _buildRequestsList(_adminService.getAllDoctorVisits(), _buildDoctorVisitItem),
                    _buildRequestsList(_adminService.getAllTestReservations(), _buildTestReservationItem),
                    _buildAddResourcesTab(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRequestsList(Stream<QuerySnapshot> stream, Widget Function(DocumentSnapshot) itemBuilder) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No requests found',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        return Container(
          height: MediaQuery.of(context).size.height,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            physics: const BouncingScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              return itemBuilder(doc)
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideX(begin: 0.1, end: 0);
            },
          ),
        );
      },
    );
  }

  Widget _buildAmbulanceRequestItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Emergency: ${data['emergencyType'] ?? 'Not specified'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Patient', data['fullName']),
            _buildInfoRow('Phone', data['phoneNumber']),
            _buildInfoRow('Location', '${data['latitude'] ?? 'Unknown'}, ${data['longitude'] ?? 'Unknown'}'),
            _buildInfoRow('Created', data['createdAt'])
          
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorVisitItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Patient: ${data['userName'] ?? data['patientName'] ?? 'Not specified'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Email', data['userEmail'] ?? data['patientEmail']),
            _buildInfoRow('Phone', data['userPhone'] ?? data['patientPhone']),
            _buildInfoRow('Preferred Date', data['preferredDate'] ?? data['appointmentDate']),
            _buildInfoRow('Preferred Time', data['preferredTime'] ?? data['appointmentTime']),
            _buildInfoRow('Address', data['address']),
            _buildInfoRow('Created', data['createdAt']),
          ],
        ),
      ),
    );
  }

  Widget _buildTestReservationItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Print document data for debugging
    print('Test reservation data: ${data.toString()}');
    
    // Determine location type
    String locationType = 'Home Visit';
    if (data['isHomeVisit'] != null) {
      locationType = data['isHomeVisit'] == true ? 'Home Visit' : 'Lab Visit';
    } else if (data['locationType'] != null && data['locationType'].toString().isNotEmpty) {
      locationType = data['locationType'];
    }
    
    // Determine laboratory name
    String laboratory = 'Home Visit';
    if (locationType != 'Home Visit') {
      laboratory = data['labName'] ?? data['laboratory'] ?? data['lab'] ?? 'Not specified';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Test Type: ${data['testType'] ?? data['testName'] ?? 'Not specified'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Patient', data['patientName'] ?? data['userName'] ?? 'Not specified'),
            _buildInfoRow('Email', data['patientEmail'] ?? data['userEmail'] ?? data['email'] ?? 'Not specified'),
            _buildInfoRow('Phone', data['patientPhone'] ?? data['userPhone'] ?? data['phoneNumber'] ?? data['phone'] ?? 'Not specified'),
            _buildInfoRow('Date', data['appointmentDate'] ?? data['preferredDate'] ?? data['date'] ?? data['reservationDate'] ?? 'Not specified'),
            _buildInfoRow('Time', data['appointmentTime'] ?? data['preferredTime'] ?? data['time'] ?? data['reservationTime'] ?? 'Not specified'),
            _buildInfoRow('Laboratory', laboratory),
            _buildInfoRow('Address', data['address'] ?? 'Not specified'),
            _buildInfoRow('Created', data['createdAt']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    String displayValue = 'Not specified';
    
    if (value != null) {
      if (value is Timestamp) {
        displayValue = DateFormat('MMM dd, yyyy hh:mm a').format(value.toDate());
      } else if (value is String && (value.contains('-') || value.contains('/') || value.contains(':'))) {
        // Try to parse string dates if they contain date separators
        try {
          // Attempt to parse the date string
          final date = DateTime.parse(value);
          displayValue = DateFormat('MMM dd, yyyy hh:mm a').format(date);
        } catch (e) {
          // If parsing fails, just use the string value
          displayValue = value;
        }
      } else {
        displayValue = value.toString();
      }
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status ?? 'pending',
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(String collection, String docId, String? currentStatus) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (currentStatus == 'pending')
          TextButton(
            onPressed: () => _updateStatus(collection, docId, 'approved'),
            child: const Text('Approve'),
          ),
        if (currentStatus == 'pending')
          TextButton(
            onPressed: () => _updateStatus(collection, docId, 'rejected'),
            child: const Text('Reject'),
          ),
        if (currentStatus == 'approved')
          TextButton(
            onPressed: () => _updateStatus(collection, docId, 'completed'),
            child: const Text('Mark Completed'),
          ),
      ],
    );
  }

  Widget _buildAddResourcesTab() {
    return Container(
      height: MediaQuery.of(context).size.height,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddResourceCard(
              'Add Doctor',
              [
                _buildTextField('Name', _doctorNameController),
                _buildTextField('Email', _doctorEmailController, keyboardType: TextInputType.emailAddress),
                _buildTextField('Phone', _doctorPhoneController, keyboardType: TextInputType.phone),
                _buildTextField('Graduated From', _doctorGraduatedFromController),
                _buildTextField('Specialty', _doctorSpecialtyController),
                _buildTextField('Years of Experience', _doctorYearsOfExperienceController, keyboardType: TextInputType.number),
                _buildDropdown('Status', ['available', 'busy', 'offline'], _doctorStatus, (value) {
                  setState(() => _doctorStatus = value);
                }),
              ],
              _addDoctor,
            ),
            const SizedBox(height: 16),
            _buildAddResourceCard(
              'Add Medic',
              [
                _buildTextField('Name', _medicNameController),
                _buildTextField('Email', _medicEmailController, keyboardType: TextInputType.emailAddress),
                _buildTextField('Phone', _medicPhoneController, keyboardType: TextInputType.phone),
                _buildTextField('Graduated From', _medicGraduatedFromController),
                _buildTextField('Years of Experience', _medicYearsOfExperienceController, keyboardType: TextInputType.number),
              ],
              _addMedic,
            ),
            const SizedBox(height: 16),
            _buildAddResourceCard(
              'Add Ambulance Car',
              [
                _buildTextField('Car Number', _carNumberController),
                _buildTextField('Model', _carModelController),
                _buildDropdown('Status', ['available', 'in-use', 'maintenance'], _carStatus, (value) {
                  setState(() => _carStatus = value);
                }),
              ],
              _addAmbulanceCar,
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildAddResourceCard(
    String title,
    List<Widget> children,
    VoidCallback onAdd,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildStarRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rating',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _doctorRating = (index + 1).toDouble();
                });
              },
              child: Icon(
                index < _doctorRating ? Icons.star : Icons.star_border,
                color: Colors.blue,
                size: 40,
              ).animate().scale(
                duration: 200.ms,
                curve: Curves.easeOut,
              ),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _updateStatus(String collection, String docId, String status) async {
    try {
      await _adminService.updateRequestStatus(
        collection: collection,
        docId: docId,
        status: status,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to $status'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addAmbulanceCar() async {
    if (_carNumberController.text.isEmpty || 
        _carModelController.text.isEmpty || 
        _carStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _adminService.addAmbulanceCar(
        carNumber: _carNumberController.text,
        model: _carModelController.text,
        status: _carStatus!,
      );

      // Clear form
      _carNumberController.clear();
      _carModelController.clear();
      setState(() => _carStatus = null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ambulance car added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding ambulance car: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addDoctor() async {
    if (_doctorNameController.text.isEmpty ||
        _doctorEmailController.text.isEmpty ||
        _doctorPhoneController.text.isEmpty ||
        _doctorGraduatedFromController.text.isEmpty ||
        _doctorSpecialtyController.text.isEmpty ||
        _doctorYearsOfExperienceController.text.isEmpty ||
        _doctorStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _adminService.addDoctor(
        name: _doctorNameController.text,
        email: _doctorEmailController.text,
        phone: _doctorPhoneController.text,
        graduatedFrom: _doctorGraduatedFromController.text,
        specialty: _doctorSpecialtyController.text,
        yearsOfExpertise: int.parse(_doctorYearsOfExperienceController.text),
        status: _doctorStatus!,
        rating: 0.0, // Initial rating
      );

      // Clear form
      _doctorNameController.clear();
      _doctorEmailController.clear();
      _doctorPhoneController.clear();
      _doctorGraduatedFromController.clear();
      _doctorSpecialtyController.clear();
      _doctorYearsOfExperienceController.clear();
      setState(() => _doctorStatus = null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding doctor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addMedic() async {
    if (_medicNameController.text.isEmpty ||
        _medicEmailController.text.isEmpty ||
        _medicPhoneController.text.isEmpty ||
        _medicGraduatedFromController.text.isEmpty ||
        _medicYearsOfExperienceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _adminService.addMedic(
        name: _medicNameController.text,
        email: _medicEmailController.text,
        phone: _medicPhoneController.text,
        graduatedFrom: _medicGraduatedFromController.text,
        yearsOfExperience: int.parse(_medicYearsOfExperienceController.text),
      );

      // Clear form
      _medicNameController.clear();
      _medicEmailController.clear();
      _medicPhoneController.clear();
      _medicGraduatedFromController.clear();
      _medicYearsOfExperienceController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medic added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding medic: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatisticsTab() {
    return Container(
      height: MediaQuery.of(context).size.height,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
              child: Text(
                'Dashboard Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildUserStatistics(),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildRequestStatistics(),
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width > 400 ? 2 : 1;
            final childAspectRatio = width > 400 ? 1.8 : 2.5;
                
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
              children: [
                StatisticsCard(
                  title: 'Total Users',
                  value: _userStats['total'].toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                StatisticsCard(
                  title: 'Patients',
                  value: _userStats['patients'].toString(),
                  icon: Icons.person,
                  color: Colors.green,
                ),
                StatisticsCard(
                  title: 'Medics',
                  value: _userStats['medics'].toString(),
                  icon: Icons.medical_services,
                  color: Colors.blue,
                ),
                StatisticsCard(
                  title: 'Doctors',
                  value: _userStats['doctors'].toString(),
                  icon: Icons.local_hospital,
                  color: Colors.purple,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRequestStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Request Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width > 400 ? 2 : 1;
            final childAspectRatio = width > 400 ? 1.8 : 2.5;
                
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
              children: [
                StatisticsCard(
                  title: 'Ambulance Requests',
                  value: _ambulanceStats['total'].toString(),
                  icon: Icons.emergency,
                  color: Colors.red,
                ),
                StatisticsCard(
                  title: 'Doctor Visits',
                  value: _doctorStats['total'].toString(),
                  icon: Icons.medical_services,
                  color: Colors.purple,
                ),
                StatisticsCard(
                  title: 'Home Test Visits',
                  value: _testStats['homeVisits'].toString(),
                  icon: Icons.home,
                  color: Colors.teal,
                ),
                StatisticsCard(
                  title: 'Lab Test Visits',
                  value: _testStats['labVisits'].toString(),
                  icon: Icons.science,
                  color: Colors.orange,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
} 