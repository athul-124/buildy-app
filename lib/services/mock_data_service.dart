import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../models/expert_model.dart';

class MockDataService {
  static const Duration _mockDelay = Duration(milliseconds: 800);

  static Future<List<Service>> getPopularServices({int limit = 5}) async {
    await Future.delayed(_mockDelay);
    
    final services = [
      Service(
        id: '1',
        name: 'Electrical Repair',
        description: 'Professional electrical services for your home',
        imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300&h=200&fit=crop',
        price: 150.0,
        rating: 4.8,
        popularity: 95,
        category: 'Electrical',
        isAvailable: true,
      ),
      Service(
        id: '2',
        name: 'Plumbing Services',
        description: 'Expert plumbing solutions',
        imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=300&h=200&fit=crop',
        price: 120.0,
        rating: 4.7,
        popularity: 88,
        category: 'Plumbing',
        isAvailable: true,
      ),
      Service(
        id: '3',
        name: 'Carpentry Work',
        description: 'Custom carpentry and woodwork',
        imageUrl: 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=300&h=200&fit=crop',
        price: 200.0,
        rating: 4.9,
        popularity: 82,
        category: 'Carpentry',
        isAvailable: true,
      ),
      Service(
        id: '4',
        name: 'House Cleaning',
        description: 'Professional home cleaning services',
        imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=300&h=200&fit=crop',
        price: 80.0,
        rating: 4.6,
        popularity: 90,
        category: 'Cleaning',
        isAvailable: true,
      ),
      Service(
        id: '5',
        name: 'AC Repair',
        description: 'Air conditioning repair and maintenance',
        imageUrl: 'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=300&h=200&fit=crop',
        price: 180.0,
        rating: 4.5,
        popularity: 76,
        category: 'HVAC',
        isAvailable: true,
      ),
    ];
    
    return services.take(limit).toList();
  }

  static Future<List<Expert>> getExperts({int limit = 5}) async {
    await Future.delayed(_mockDelay);
    
    final experts = [
      Expert(
        id: '1',
        name: 'John Smith',
        imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        profession: 'Master Electrician',
        rating: 4.9,
        completedJobs: 127,
        skills: ['Wiring', 'Circuit Repair', 'Installation'],
        isAvailable: true,
      ),
      Expert(
        id: '2',
        name: 'Sarah Johnson',
        imageUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b634?w=150&h=150&fit=crop&crop=face',
        profession: 'Licensed Plumber',
        rating: 4.8,
        completedJobs: 89,
        skills: ['Pipe Repair', 'Installation', 'Emergency'],
        isAvailable: false,
      ),
      Expert(
        id: '3',
        name: 'Mike Wilson',
        imageUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
        profession: 'Professional Carpenter',
        rating: 4.9,
        completedJobs: 156,
        skills: ['Custom Furniture', 'Renovation', 'Repair'],
        isAvailable: true,
      ),
      Expert(
        id: '4',
        name: 'Emily Davis',
        imageUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
        profession: 'Cleaning Specialist',
        rating: 4.7,
        completedJobs: 203,
        skills: ['Deep Cleaning', 'Eco-friendly', 'Organization'],
        isAvailable: true,
      ),
      Expert(
        id: '5',
        name: 'David Brown',
        imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face',
        profession: 'HVAC Technician',
        rating: 4.6,
        completedJobs: 98,
        skills: ['AC Repair', 'Installation', 'Maintenance'],
        isAvailable: true,
      ),
    ];
    
    return experts.take(limit).toList();
  }

  static Future<({List<Service> services, List<Expert> experts})> getHomeData() async {
    try {
      final results = await Future.wait([
        getPopularServices(limit: 5),
        getExperts(limit: 5),
      ]);
      
      return (
        services: results[0] as List<Service>,
        experts: results[1] as List<Expert>,
      );
    } catch (e) {
      debugPrint('Error fetching mock home data: $e');
      return (services: <Service>[], experts: <Expert>[]);
    }
  }
}