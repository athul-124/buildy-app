import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';
import '../models/expert_model.dart';
import 'cache_service.dart';
import 'mock_data_service.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cacheService = CacheService();
  
  // Cache duration in minutes
  static const int _cacheExpiryMinutes = 15;
  
  Future<List<Service>> getPopularServices({int limit = 5}) async {
    const cacheKey = 'popular_services';
    const cacheTimeKey = 'popular_services_time';
    
    // Check if cache is still valid
    final cacheTime = _cacheService.get<String>(cacheTimeKey);
    final now = DateTime.now();
    
    if (cacheTime != null) {
      final cachedDateTime = DateTime.parse(cacheTime);
      if (now.difference(cachedDateTime).inMinutes < _cacheExpiryMinutes) {
        final cached = _cacheService.get<List<dynamic>>(cacheKey);
        if (cached != null) {
          try {
            return cached.map((item) => Service.fromMap(
              Map<String, dynamic>.from(item['data']), 
              item['id']
            )).toList();
          } catch (e) {
            debugPrint('Error parsing cached services: $e');
          }
        }
      }
    }
    
    try {
      // Use source: Source.serverAndCache for better performance
      final snapshot = await _firestore
          .collection('services')
          .orderBy('popularity', descending: true)
          .limit(limit)
          .get(const GetOptions(source: Source.serverAndCache));
      
      final services = snapshot.docs
          .map((doc) => Service.fromMap(doc.data(), doc.id))
          .toList();
      
      // Cache the result with timestamp
      final cacheData = services.map((service) => {
        'id': service.id,
        'data': service.toMap(),
      }).toList();
      
      await _cacheService.set(cacheKey, cacheData);
      await _cacheService.set(cacheTimeKey, now.toIso8601String());
      
      return services;
    } catch (e) {
      debugPrint('Error fetching services: $e');
      
      // Try to return cached data even if expired
      final cached = _cacheService.get<List<dynamic>>(cacheKey);
      if (cached != null) {
        try {
          return cached.map((item) => Service.fromMap(
            Map<String, dynamic>.from(item['data']), 
            item['id']
          )).toList();
        } catch (e) {
          debugPrint('Error parsing fallback cached services: $e');
        }
      }
      
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
      
      // Use server and cache for better performance
      final snapshot = await query.get(const GetOptions(source: Source.serverAndCache));
      
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
  
  // Combined method to fetch both services and experts in parallel
  Future<({List<Service> services, List<Expert> experts})> getHomeData() async {
    try {
      // First try to fetch from Firebase
      final results = await Future.wait([
        getPopularServices(limit: 5),
        getExperts(limit: 5),
      ]);
      
      final services = results[0] as List<Service>;
      final experts = results[1] as List<Expert>;
      
      // If we got data from Firebase, return it
      if (services.isNotEmpty || experts.isNotEmpty) {
        return (services: services, experts: experts);
      }
      
      // If no data from Firebase, fallback to mock data
      debugPrint('No data from Firebase, using mock data');
      return await MockDataService.getHomeData();
    } catch (e) {
      debugPrint('Error fetching home data from Firebase: $e');
      debugPrint('Falling back to mock data');
      
      // Fallback to mock data if Firebase fails
      try {
        return await MockDataService.getHomeData();
      } catch (mockError) {
        debugPrint('Error fetching mock data: $mockError');
        return (services: <Service>[], experts: <Expert>[]);
      }
    }
  }
  
  // Method to check if Firebase is available
  Future<bool> isFirebaseAvailable() async {
    try {
      await _firestore.collection('test').limit(1).get();
      return true;
    } catch (e) {
      debugPrint('Firebase not available: $e');
      return false;
    }
  }
  
  // Add other methods as needed
}
