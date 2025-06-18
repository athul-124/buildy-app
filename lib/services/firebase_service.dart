import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';
import '../models/expert_model.dart';
import 'cache_service.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cacheService = CacheService();
  
  Future<List<Service>> getPopularServices({int limit = 5}) async {
    const cacheKey = 'popular_services';
    
    // Try to get from cache first
    final cached = _cacheService.get<List<Service>>(cacheKey);
    if (cached != null) {
      return cached;
    }
    
    try {
      final snapshot = await _firestore
          .collection('services')
          .orderBy('popularity', descending: true)
          .limit(limit)
          .get();
      
      final services = snapshot.docs
          .map((doc) => Service.fromMap(doc.data(), doc.id))
          .toList();
      
      // Cache the result
      _cacheService.set(cacheKey, services);
      
      return services;
    } catch (e) {
      debugPrint('Error fetching services: $e');
      return [];
    }
  }

  Future<List<Expert>> getExperts({int limit = 5, DocumentSnapshot? lastDoc}) async {
    try {
      Query query = _firestore
          .collection('experts')
          .orderBy('rating', descending: true)
          .limit(limit);
      
      // Add pagination if lastDoc is provided
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }
      
      final snapshot = await query.get();
      
      final experts = <Expert>[];
      
      for (var doc in snapshot.docs) {
        final expert = Expert.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        expert.reference = doc.reference;
        experts.add(expert);
      }
      
      return experts;
    } catch (e) {
      debugPrint('Error fetching experts: $e');
      return [];
    }
  }
  
  // Add other methods as needed
}
