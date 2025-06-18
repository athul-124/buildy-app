import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final double rating;
  final int popularity;
  final String category;
  final bool isAvailable;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.popularity,
    required this.category,
    required this.isAvailable,
  });

  factory Service.fromMap(Map<String, dynamic> map, String id) {
    return Service(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      rating: (map['rating'] ?? 0).toDouble(),
      popularity: map['popularity'] ?? 0,
      category: map['category'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'rating': rating,
      'popularity': popularity,
      'category': category,
      'isAvailable': isAvailable,
    };
  }
}
