import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ServiceModel {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String routeName;

  const ServiceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.routeName,
  });

  static List<ServiceModel> get services => [
    const ServiceModel(
      id: 'ambulance',
      title: 'Request Ambulance',
      description: 'Emergency ambulance service with GPS tracking and real-time status updates.',
      icon: FontAwesomeIcons.truckMedical,
      routeName: '/ambulance',
    ),
    const ServiceModel(
      id: 'doctor',
      title: 'Home Doctor Visit',
      description: 'Book a doctor to visit your home for medical consultation and treatment.',
      icon: FontAwesomeIcons.userDoctor,
      routeName: '/doctor',
    ),
    const ServiceModel(
      id: 'lab',
      title: 'Lab Tests',
      description: 'Schedule laboratory tests with home sample collection and online reports.',
      icon: FontAwesomeIcons.vial,
      routeName: '/lab-tests',
    ),
    const ServiceModel(
      id: 'education',
      title: 'Medical Education',
      description: 'Access educational videos on health, first aid, and medical topics.',
      icon: FontAwesomeIcons.video,
      routeName: '/education',
    ),
  ];
}

class TestimonialModel {
  final String name;
  final String testimonial;
  final String? avatarUrl;
  final double rating;

  const TestimonialModel({
    required this.name,
    required this.testimonial,
    this.avatarUrl,
    required this.rating,
  });

  static List<TestimonialModel> get testimonials => [
    const TestimonialModel(
      name: 'Ahmad Hassan',
      testimonial: 'The ambulance service was incredibly fast. They arrived within 10 minutes of my request during an emergency.',
      rating: 5.0,
    ),
    const TestimonialModel(
      name: 'Sarah Johnson',
      testimonial: 'I regularly use the home doctor service for my elderly father. The doctors are professional and thorough in their examinations.',
      rating: 4.5,
    ),
    const TestimonialModel(
      name: 'Mohammed Ali',
      testimonial: 'The lab test service is very convenient. They collect samples from home and I get reports digitally. Saved me a lot of time!',
      rating: 5.0,
    ),
    const TestimonialModel(
      name: 'Emily Wang',
      testimonial: 'Educational videos are excellent resources. I learned how to perform CPR correctly through one of their tutorials.',
      rating: 4.0,
    ),
  ];
} 