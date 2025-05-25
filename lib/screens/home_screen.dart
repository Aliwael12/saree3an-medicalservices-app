import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../constants/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/service_card.dart';
import '../widgets/testimonial_card.dart';
import '../widgets/chatbot_widget.dart';
import '../models/service_model.dart';
import 'ambulance_screen.dart';
import 'reserve_test_screen.dart';
import 'doctor_visit_screen.dart';
import 'educational_videos_screen.dart';
import 'about_us_screen.dart';
import 'contact_us_screen.dart';
import 'faq_screen.dart';
import 'services_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),
    const ServicesScreen(),
    const ProfileScreen(),
    const HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        if (_scrollController.offset >= 300) {
          _showBackToTopButton = true;
        } else {
          _showBackToTopButton = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Sareean Medical',
        showBackButton: false,
      ),
      body: Stack(
        children: [
          _screens[_currentIndex],
          const ChatbotWidget(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
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
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
      floatingActionButton: _showBackToTopButton
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.arrow_upward),
            ).animate().scale(duration: 300.ms)
          : null,
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroBanner(context),
          const SizedBox(height: 24),
          _buildAboutSection(context),
          const SizedBox(height: 24),
          _buildServicesSection(context),
          const SizedBox(height: 24),
          _buildTestimonialsSection(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue,
            Colors.blue.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.1,
              child: FaIcon(
                FontAwesomeIcons.heartPulse,
                color: Colors.white,
                size: 150,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/gradlogo.png',
                  width: 180,
                  height: 175,
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                Transform.translate(
                  offset: const Offset(0, -15),
                  child: Text(
                    'Your Health, Our Priority',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 0.9,
                        ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3, end: 0),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Medical services at your fingertips',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.2,
                        ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms, duration: 800.ms),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('About Us'),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Our Vision',
            content: 'To be the leading provider of digital healthcare solutions, making quality medical services accessible to everyone.',
            icon: FontAwesomeIcons.eye,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Our Mission',
            content: 'Delivering fast, reliable, and professional medical services through innovative technology to ensure better health outcomes for all.',
            icon: FontAwesomeIcons.bullseye,
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Our Services'),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/services');
                },
                child: Row(
                  children: const [
                    Text('View All'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              ServiceCard(
                icon: FontAwesomeIcons.ambulance,
                title: 'Request Ambulance',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AmbulanceScreen()),
                  );
                },
              ),
              ServiceCard(
                icon: FontAwesomeIcons.vial,
                title: 'Reserve Test',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReserveTestScreen()),
                  );
                },
              ),
              ServiceCard(
                icon: FontAwesomeIcons.userDoctor,
                title: 'Doctor Visit',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DoctorVisitScreen()),
                  );
                },
              ),
              ServiceCard(
                icon: FontAwesomeIcons.video,
                title: 'Educational Videos',
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EducationalVideosScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestimonialsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildSectionTitle('Testimonials'),
        ),
        const SizedBox(height: 16),
        CarouselSlider(
          options: CarouselOptions(
            height: 220,
            enableInfiniteScroll: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: true,
            scrollDirection: Axis.horizontal,
          ),
          items: TestimonialModel.testimonials.map((testimonial) {
            return Builder(
              builder: (BuildContext context) {
                return TestimonialCard(
                  name: testimonial.name,
                  testimonial: testimonial.testimonial,
                  avatarUrl: testimonial.avatarUrl,
                  rating: testimonial.rating,
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    ).animate().fadeIn(duration: 600.ms).shimmer(delay: 200.ms);
  }

  Widget _buildInfoCard({
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
        padding: const EdgeInsets.all(16.0),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.05, end: 0);
  }
} 