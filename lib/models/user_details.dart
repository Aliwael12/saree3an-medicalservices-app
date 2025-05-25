import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetails {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String nationalId;
  final String gender;
  final String bloodType;
  final String medicalHistory;
  final String role;
  final String address;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserDetails({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    this.nationalId = '',
    this.gender = 'not specified',
    required this.bloodType,
    required this.medicalHistory,
    required this.role,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserDetails.fromMap(dynamic rawData) {
    // For debugging
    print('UserDetails.fromMap received data type: ${rawData.runtimeType}');
    print('UserDetails.fromMap received data: $rawData');
    
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    // Create default empty map in case we can't properly convert the data
    Map<String, dynamic> processedMap = {
      'uid': '',
      'mail': '',
      'name': '',
      'phone': '',
      'nationalid': '',
      'gender': 'not specified',
      'bloodType': '',
      'medicalHistory': '',
      'role': 'patient',
      'address': '',
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };
    
    try {
      // Handle case where data might be a List
      if (rawData is List) {
        print('Received List in UserDetails.fromMap, trying to convert...');
        if (rawData.isNotEmpty) {
          // Try to get the first item in the list
          var firstItem = rawData[0];
          
          // If first item is a Map, use it
          if (firstItem is Map<String, dynamic>) {
            processedMap = firstItem;
          } 
          // If first item is not a Map but can be converted to string
          else if (firstItem != null) {
            print('First item in list is not a Map, but: ${firstItem.runtimeType}');
            // Try to parse any available data
            processedMap['uid'] = rawData.toString();
          }
        }
      } 
      // If data is already a Map, use it directly
      else if (rawData is Map<String, dynamic>) {
        processedMap = rawData;
      }
      // Special handling for PigeonUserDetails or other native objects
      else if (rawData != null) {
        // Try to extract fields using reflection or dynamic method
        try {
          // This part is tricky - try to adapt based on the actual object type
          if (rawData.toString().contains('Pigeon')) {
            print('Attempting to handle PigeonUserDetails object');
            // Try to extract values from the pigeon object using common property names
            // Note: This approach depends on the structure of your Pigeon-generated class
            
            // We'll try both direct property access and method calls
            // Direct property access
            try {
              if (rawData.uid != null) processedMap['uid'] = rawData.uid.toString();
              if (rawData.email != null) processedMap['mail'] = rawData.email.toString();
              if (rawData.name != null) processedMap['name'] = rawData.name.toString();
              if (rawData.phone != null) processedMap['phone'] = rawData.phone.toString();
              if (rawData.nationalId != null) processedMap['nationalid'] = rawData.nationalId.toString();
              if (rawData.gender != null) processedMap['gender'] = rawData.gender.toString();
              if (rawData.bloodType != null) processedMap['bloodType'] = rawData.bloodType.toString();
              if (rawData.medicalHistory != null) processedMap['medicalHistory'] = rawData.medicalHistory.toString();
              if (rawData.role != null) processedMap['role'] = rawData.role.toString();
              if (rawData.address != null) processedMap['address'] = rawData.address.toString();
            } catch (e) {
              print('Error accessing Pigeon properties directly: $e');
            }
            
            // Method calls (e.g. getUid(), getEmail(), etc.)
            try {
              // This is just an example - adjust based on your actual Pigeon class methods
              final methods = ['getUid', 'getEmail', 'getName', 'getPhone', 'getNationalId', 
                              'getGender', 'getBloodType', 'getMedicalHistory', 'getRole', 'getAddress'];
              final keys = ['uid', 'mail', 'name', 'phone', 'nationalid', 
                          'gender', 'bloodType', 'medicalHistory', 'role', 'address'];
                          
              for (int i = 0; i < methods.length; i++) {
                try {
                  final method = methods[i];
                  final key = keys[i];
                  // Try to dynamically call the method
                  final value = rawData.callMethod(method, []);
                  if (value != null) {
                    processedMap[key] = value.toString();
                  }
                } catch (methodError) {
                  // Just continue if a particular method doesn't exist
                }
              }
            } catch (e) {
              print('Error calling Pigeon methods: $e');
            }
          }
        } catch (e) {
          print('Error extracting from non-map object: $e');
        }
      }
    } catch (e) {
      print('Error in UserDetails.fromMap: $e');
      // Use the default empty map we created earlier
    }
    
    // Create UserDetails with whatever data we could extract or defaults
    return UserDetails(
      uid: processedMap['uid']?.toString() ?? '',
      email: processedMap['mail']?.toString() ?? '',
      name: processedMap['name']?.toString() ?? '',
      phone: processedMap['phone']?.toString() ?? '',
      nationalId: processedMap['nationalid']?.toString() ?? '',
      gender: processedMap['gender']?.toString() ?? 'not specified',
      bloodType: processedMap['bloodType']?.toString() ?? '',
      medicalHistory: processedMap['medicalHistory']?.toString() ?? '',
      role: processedMap['role']?.toString() ?? 'patient',
      address: processedMap['address']?.toString() ?? '',
      createdAt: parseTimestamp(processedMap['createdAt']),
      updatedAt: parseTimestamp(processedMap['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'mail': email,
      'name': name,
      'phone': phone,
      'nationalid': nationalId,
      'gender': gender,
      'bloodType': bloodType,
      'medicalHistory': medicalHistory,
      'role': role,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
} 