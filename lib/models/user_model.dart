import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? imageUrl;
  final String role;
  final DateTime createdAt;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.imageUrl,
    required this.role,
    required this.createdAt,
    this.preferences,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      imageUrl: map['imageUrl'],
      role: map['role'] ?? 'customer',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preferences: map['preferences'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'imageUrl': imageUrl,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'preferences': preferences,
    };
  }
}
