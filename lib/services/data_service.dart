import 'package:flutter/foundation.dart';
import 'dart:convert';

class DataService {
  // Parse JSON in background isolate
  Future<List<T>> parseJsonList<T>(
    String responseBody,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    return compute(_parseJsonList<T>, {
      'data': responseBody,
      'fromMap': fromMap,
    });
  }
}

// Top-level function for compute
List<T> _parseJsonList<T>(Map<String, dynamic> params) {
  final data = params['data'] as String;
  final fromMap = params['fromMap'] as T Function(Map<String, dynamic>);
  
  final parsed = (jsonDecode(data) as List).cast<Map<String, dynamic>>();
  return parsed.map<T>((json) => fromMap(json)).toList();
}