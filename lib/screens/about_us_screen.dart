import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_theme.dart';
import '../widgets/custom_app_bar.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'About Us',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Our Story',
              content: 'Sareean Medical was founded with a vision to revolutionize healthcare accessibility in Egypt. We believe that quality medical services should be available to everyone, anytime, anywhere.',
              icon: FontAwesomeIcons.book,
            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Our Mission',
              content: 'To provide fast, reliable, and professional medical services through innovative technology, ensuring better health outcomes for all Egyptians.',
              icon: FontAwesomeIcons.bullseye,
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: -0.2, end: 0),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Our Vision',
              content: 'To be the leading digital healthcare platform in Egypt, connecting patients with quality medical services at their fingertips.',
              icon: FontAwesomeIcons.eye,
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: -0.2, end: 0),
            const SizedBox(height: 24),
            _buildTeamSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  icon,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Our Team',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            _buildTeamMember(
              name: 'Khadija Samir',
              role: 'Medical Director',
              icon: FontAwesomeIcons.userDoctor,
            ),
            _buildTeamMember(
              name: 'Menna Marwan',
              role: 'Operations Manager',
              icon: FontAwesomeIcons.briefcase,
            ),
            _buildTeamMember(
              name: 'Salma Mowafak',
              role: 'Technical Lead',
              icon: FontAwesomeIcons.code,
            ),
            _buildTeamMember(
              name: 'Sanaria Aloussi',
              role: 'Customer Support',
              icon: FontAwesomeIcons.headset,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamMember({
    required String name,
    required String role,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: FaIcon(
                    icon,
                    size: 28,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              role,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(delay: 200.ms);
  }
} 