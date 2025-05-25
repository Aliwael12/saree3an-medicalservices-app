import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final List<FAQItem> _faqs = [
    FAQItem(
      question: 'How do I request an ambulance?',
      answer: 'To request an ambulance, go to the Services tab and select "Request Ambulance". Fill in your details and location, and our team will dispatch the nearest available ambulance to your location.',
    ),
    FAQItem(
      question: 'How long does it take for an ambulance to arrive?',
      answer: 'Our average response time is 10-15 minutes in urban areas. However, this may vary depending on traffic conditions and your location.',
    ),
    FAQItem(
      question: 'What services can I book through the app?',
      answer: 'You can book ambulance services, doctor visits, lab tests, and access educational medical videos through our app.',
    ),
    FAQItem(
      question: 'How do I pay for services?',
      answer: 'We accept various payment methods including cash, credit cards, and mobile payment services. Payment details will be provided when you book a service.',
    ),
    FAQItem(
      question: 'Is my personal information secure?',
      answer: 'Yes, we take data security seriously. All your personal and medical information is encrypted and stored securely in compliance with healthcare data protection regulations.',
    ),
    FAQItem(
      question: 'Can I cancel a service booking?',
      answer: 'Yes, you can cancel most service bookings through the app. However, cancellation policies may vary depending on the service type and timing.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            ..._faqs.asMap().entries.map((entry) {
              final index = entry.key;
              final faq = entry.value;
              return _buildFAQCard(faq, index);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard(FAQItem faq, int index) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: FaIcon(
          FontAwesomeIcons.circleQuestion,
          color: Colors.blue,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              faq.answer,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).slideX(begin: -0.2, end: 0);
  }
} 