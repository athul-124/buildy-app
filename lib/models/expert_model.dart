import 'package:cloud_firestore/cloud_firestore.dart';

class Expert {
  final String id;
  final String name;
  final String imageUrl;
  final String profession;
  final double rating;
  final int completedJobs;
  final List<String> skills;
  final bool isAvailable;
  DocumentReference? reference;

  Expert({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.profession,
    required this.rating,
    required this.completedJobs,
    required this.skills,
    required this.isAvailable,
    this.reference,
  });

  factory Expert.fromMap(Map<String, dynamic> map, String id) {
    return Expert(
      id: id,
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      profession: map['profession'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      completedJobs: map['completedJobs'] ?? 0,
      skills: List<String>.from(map['skills'] ?? []),
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'profession': profession,
      'rating': rating,
      'completedJobs': completedJobs,
      'skills': skills,
      'isAvailable': isAvailable,
    };
  }
}
