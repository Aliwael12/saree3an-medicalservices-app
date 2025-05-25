import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import 'ambulance_screen.dart';
import 'doctor_visit_screen.dart';
import 'reserve_test_screen.dart';
import 'educational_videos_screen.dart';
import 'about_us_screen.dart';
import 'contact_us_screen.dart';
import 'faq_screen.dart';

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Services',
        showBackButton: true,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _ServiceCard(
            icon: FontAwesomeIcons.ambulance,
            title: 'Request Ambulance',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AmbulanceScreen()),
              );
            },
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
          _ServiceCard(
            icon: FontAwesomeIcons.vial,
            title: 'Reserve Test',
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReserveTestScreen()),
              );
            },
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: -0.2, end: 0),
          _ServiceCard(
            icon: FontAwesomeIcons.userDoctor,
            title: 'Doctor Visit',
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DoctorVisitScreen()),
              );
            },
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: -0.2, end: 0),
          _ServiceCard(
            icon: FontAwesomeIcons.video,
            title: 'Educational Videos',
            color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EducationalVideosScreen()),
              );
            },
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(begin: -0.2, end: 0),
          _ServiceCard(
            icon: FontAwesomeIcons.info,
            title: 'About Us',
            color: Colors.indigo,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutUsScreen()),
              );
            },
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideX(begin: -0.2, end: 0),
          _ServiceCard(
            icon: FontAwesomeIcons.question,
            title: 'FAQ',
            color: Colors.amber,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FAQScreen()),
              );
            },
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideX(begin: -0.2, end: 0),
          _ServiceCard(
            icon: FontAwesomeIcons.envelope,
            title: 'Contact Us',
            color: Colors.blue.withOpacity(0.7),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactUsScreen()),
              );
            },
          ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideX(begin: -0.2, end: 0),
        ],
      ),
    );
  }
} 