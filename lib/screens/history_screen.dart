import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';
import '../widgets/custom_app_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  final HistoryService _historyService = HistoryService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'History',
        showBackButton: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Doctor Visits'),
                Tab(text: 'Test Reservations'),
                Tab(text: 'Ambulance Requests'),
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
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryList(_historyService.getDoctorVisits(), _buildDoctorVisitItem),
          _buildHistoryList(_historyService.getTestReservations(), _buildTestReservationItem),
          _buildHistoryList(_historyService.getAmbulanceRequests(), _buildAmbulanceRequestItem),
        ],
      ),
    );
  }

  Widget _buildHistoryList(Stream<QuerySnapshot> stream, Widget Function(DocumentSnapshot) itemBuilder) {
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
              'No history found',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: itemBuilder(doc),
              ),
            ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.1, end: 0);
          },
        );
      },
    );
  }

  Widget _buildDoctorVisitItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
    final appointmentTime = data['appointmentTime'] as String;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dr. ${data['doctorName'] ?? 'Unknown'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data['doctorSpecialty'] ?? 'General Medicine',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today,
              'Date',
              '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}',
            ),
            const SizedBox(height: 4),
            _buildInfoRow(
              Icons.access_time,
              'Time',
              appointmentTime,
            ),
            if (data['symptoms']?.isNotEmpty ?? false) ...[
              const SizedBox(height: 4),
              _buildInfoRow(
                Icons.medical_information,
                'Symptoms',
                data['symptoms'],
              ),
            ],
            const SizedBox(height: 4),
            _buildInfoRow(
              Icons.location_on,
              'Address',
              data['address'] ?? 'Not specified',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestReservationItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final appointmentDate = data['preferredDate'] != null 
        ? (data['preferredDate'] as Timestamp).toDate()
        : DateTime.now();
    final appointmentTime = data['preferredTime'] as String? ?? 'Not specified';
    
    // Get test types list and join them
    String testTypes = 'Unknown Test';
    if (data['testTypes'] != null) {
      if (data['testTypes'] is List) {
        testTypes = (data['testTypes'] as List).join(', ');
      } else if (data['testTypes'] is String) {
        testTypes = data['testTypes'] as String;
      }
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['labName'] ?? 'Home Visit',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              testTypes,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today,
              'Date',
              '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}',
            ),
            const SizedBox(height: 4),
            _buildInfoRow(
              Icons.access_time,
              'Time',
              appointmentTime,
            ),
            const SizedBox(height: 4),
            _buildInfoRow(
              Icons.location_on,
              'Address',
              data['address'] ?? 'Not specified',
            ),
            if (data['isHomeVisit'] == true) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Home Visit',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmbulanceRequestItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Ambulance',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          Icons.local_hospital,
          'Type',
          data['emergencyType'] ?? 'General Emergency',
        ),
        const SizedBox(height: 4),
        _buildInfoRow(
          Icons.calendar_today, 
          'Date',
          data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate().toString().split('.')[0]
              : 'Not specified',
        ),
        const SizedBox(height: 4),
        _buildInfoRow(
          Icons.location_on,
          'Address',
          data['address'] ?? 'Not specified',
        ),
        if (data['description'] != null && data['description'].toString().isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildInfoRow(
            Icons.description,
            'Notes',
            data['description'],
          ),
        ],
        if (data['medicName'] != null && data['medicName'].toString().isNotEmpty) ...[
          const SizedBox(height: 8),
          Divider(),
          const SizedBox(height: 8),
          Text(
            'Medical Professional',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          _buildInfoRow(
            Icons.person,
            'Name',
            data['medicName'],
          ),
        ],
      ],
    );
  }
} 