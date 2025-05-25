import 'dart:math';

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String imageUrl;
  final double rating;
  final int reviews;
  final String experience;
  final String education;
  final List<String> languages;
  final bool isAvailable;
  final double consultationFee;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.experience,
    required this.education,
    required this.languages,
    required this.isAvailable,
    required this.consultationFee,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviews': reviews,
      'experience': experience,
      'education': education,
      'languages': languages,
      'isAvailable': isAvailable,
      'consultationFee': consultationFee,
    };
  }

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as String,
      name: json['name'] as String,
      specialty: json['specialty'] as String,
      imageUrl: json['imageUrl'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviews: json['reviews'] as int,
      experience: json['experience'] as String,
      education: json['education'] as String,
      languages: List<String>.from(json['languages'] as List),
      isAvailable: json['isAvailable'] as bool,
      consultationFee: (json['consultationFee'] as num).toDouble(),
    );
  }

  static List<String> specialties = [
    'General Medicine',
    'Cardiology',
    'Dermatology',
    'Pediatrics',
    'Orthopedics',
    'Neurology',
    'Gynecology',
    'Ophthalmology',
    'ENT',
    'Psychiatry',
  ];

  static final random = Random();

  static Doctor getRandomDoctor(String specialty) {
    // Get a doctor based on specialty
    return getDoctors().firstWhere(
      (doc) => doc.specialty == specialty,
      orElse: () => getDoctors().first,
    );
  }

  static List<Doctor> getDoctors() {
    return [
      Doctor(
        id: '1',
        name: 'Dr. Ahmed Hassan',
        imageUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
        specialty: 'Cardiology',
        rating: 4.9,
        reviews: 100,
        experience: '15 years',
        education: 'Cairo University Medical School',
        languages: ['Arabic', 'English'],
        isAvailable: true,
        consultationFee: 350,
      ),
      Doctor(
        id: '2',
        name: 'Dr. Fatima Ali',
        imageUrl: 'https://randomuser.me/api/portraits/women/2.jpg',
        specialty: 'Dermatology',
        rating: 4.8,
        reviews: 80,
        experience: '12 years',
        education: 'Ain Shams University',
        languages: ['Arabic', 'French'],
        isAvailable: true,
        consultationFee: 300,
      ),
      Doctor(
        id: '3',
        name: 'Dr. Mohamed Ibrahim',
        imageUrl: 'https://randomuser.me/api/portraits/men/3.jpg',
        specialty: 'General Medicine',
        rating: 4.7,
        reviews: 150,
        experience: '20 years',
        education: 'Alexandria University',
        languages: ['Arabic', 'German'],
        isAvailable: true,
        consultationFee: 250,
      ),
      Doctor(
        id: '4',
        name: 'Dr. Sara Khaled',
        imageUrl: 'https://randomuser.me/api/portraits/women/4.jpg',
        specialty: 'Pediatrics',
        rating: 4.6,
        reviews: 50,
        experience: '8 years',
        education: 'Cairo University',
        languages: ['Arabic', 'Spanish'],
        isAvailable: true,
        consultationFee: 275,
      ),
      Doctor(
        id: '5',
        name: 'Dr. Omar Abdel Rahman',
        imageUrl: 'https://randomuser.me/api/portraits/men/5.jpg',
        specialty: 'Orthopedics',
        rating: 4.9,
        reviews: 120,
        experience: '18 years',
        education: 'Mansoura University',
        languages: ['Arabic', 'Italian'],
        isAvailable: true,
        consultationFee: 400,
      ),
      Doctor(
        id: '6',
        name: 'Dr. Nadia Mahmoud',
        imageUrl: 'https://randomuser.me/api/portraits/women/6.jpg',
        specialty: 'Neurology',
        rating: 4.7,
        reviews: 90,
        experience: '14 years',
        education: 'Ain Shams University',
        languages: ['Arabic', 'Russian'],
        isAvailable: true,
        consultationFee: 350,
      ),
      Doctor(
        id: '7',
        name: 'Dr. Tarek Fouad',
        imageUrl: 'https://randomuser.me/api/portraits/men/7.jpg',
        specialty: 'ENT',
        rating: 4.5,
        reviews: 70,
        experience: '10 years',
        education: 'Cairo University',
        languages: ['Arabic', 'Turkish'],
        isAvailable: true,
        consultationFee: 300,
      ),
      Doctor(
        id: '8',
        name: 'Dr. Laila Hamdy',
        imageUrl: 'https://randomuser.me/api/portraits/women/8.jpg',
        specialty: 'Gynecology',
        rating: 4.8,
        reviews: 100,
        experience: '16 years',
        education: 'Alexandria University',
        languages: ['Arabic', 'Japanese'],
        isAvailable: true,
        consultationFee: 325,
      ),
      Doctor(
        id: '9',
        name: 'Dr. Hesham Galal',
        imageUrl: 'https://randomuser.me/api/portraits/men/9.jpg',
        specialty: 'Ophthalmology',
        rating: 4.9,
        reviews: 150,
        experience: '22 years',
        education: 'Assiut University',
        languages: ['Arabic', 'Chinese'],
        isAvailable: true,
        consultationFee: 375,
      ),
      Doctor(
        id: '10',
        name: 'Dr. Amira Saleh',
        imageUrl: 'https://randomuser.me/api/portraits/women/10.jpg',
        specialty: 'Psychiatry',
        rating: 4.6,
        reviews: 80,
        experience: '13 years',
        education: 'Cairo University',
        languages: ['Arabic', 'Portuguese'],
        isAvailable: true,
        consultationFee: 300,
      ),
    ];
  }
} 