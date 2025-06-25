import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  SharedPreferences? _prefs;
  final Map<String, dynamic> _memoryCache = {};
  
  factory CacheService() {
    return _instance;
  }
  
  CacheService._internal() {
    _initPrefs();
  }
  
  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  T? get<T>(String key) {
    // First check memory cache
    if (_memoryCache.containsKey(key)) {
      final cached = _memoryCache[key];
      try {
        return cached as T?;
      } catch (e) {
        debugPrint('Error casting cached data: $e');
        _memoryCache.remove(key);
      }
    }
    
    // Then check persistent storage if available
    if (_prefs != null) {
      final jsonString = _prefs!.getString(key);
      if (jsonString != null) {
        try {
          // For simple types, just return the value
          if (T == String) {
            final result = jsonString as T;
            _memoryCache[key] = result; // Cache in memory
            return result;
          } else if (T == int) {
            final result = int.parse(jsonString) as T;
            _memoryCache[key] = result;
            return result;
          } else if (T == double) {
            final result = double.parse(jsonString) as T;
            _memoryCache[key] = result;
            return result;
          } else if (T == bool) {
            final result = (jsonString == 'true') as T;
            _memoryCache[key] = result;
            return result;
          }
          
          // For complex types, decode JSON
          final decoded = json.decode(jsonString);
          _memoryCache[key] = decoded; // Cache in memory
          return decoded as T;
        } catch (e) {
          debugPrint('Error parsing cached data for key $key: $e');
          // Remove corrupted cache entry
          _prefs!.remove(key);
          return null;
        }
      }
    }
    
    return null;
  }
  
  Future<void> set<T>(String key, T value) async {
    // Store in memory cache
    _memoryCache[key] = value;
    
    // Store in persistent storage if available
    if (_prefs != null) {
      String valueToStore;
      
      if (value is String || value is int || value is double || value is bool) {
        valueToStore = value.toString();
      } else {
        valueToStore = json.encode(value);
      }
      
      await _prefs!.setString(key, valueToStore);
    }
  }
  
  Future<void> remove(String key) async {
    // Remove from memory cache
    _memoryCache.remove(key);
    
    // Remove from persistent storage if available
    if (_prefs != null) {
      await _prefs!.remove(key);
    }
  }
  
  Future<void> clear() async {
    // Clear memory cache
    _memoryCache.clear();
    
    // Clear persistent storage if available
    if (_prefs != null) {
      await _prefs!.clear();
    }
  }
}

