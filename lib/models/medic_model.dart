class Medic {
  final String id;
  final String name;
  final int experience;
  final String userId;

  Medic({
    required this.id,
    required this.name,
    required this.experience,
    required this.userId,
  });

  factory Medic.fromMap(Map<String, dynamic> map) {
    return Medic(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      experience: map['experience'] ?? 0,
      userId: map['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'experience': experience,
      'userId': userId,
    };
  }
} 