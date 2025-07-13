import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../models/service_model.dart';
import '../models/expert_model.dart';

class BookingService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<BookingModel> _userBookings = [];
  bool _isLoading = false;
  String? _error;
  
  List<BookingModel> get userBookings => _userBookings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Create a new booking
  Future<String?> createBooking({
    required String serviceId,
    required String expertId,
    required DateTime scheduledAt,
    required String address,
    String? notes,
    double? estimatedAmount,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final bookingId = _firestore.collection('bookings').doc().id;
      
      final booking = BookingModel(
        id: bookingId,
        userId: user.uid,
        expertId: expertId,
        serviceId: serviceId,
        status: 'pending',
        scheduledAt: scheduledAt,
        paymentStatus: 'pending',
        amount: estimatedAmount,
        notes: notes,
        address: address,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _firestore.collection('bookings').doc(bookingId).set(booking.toMap());
      
      // Add to local list
      _userBookings.add(booking);
      
      _isLoading = false;
      notifyListeners();
      
      return bookingId;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error creating booking: $e');
      return null;
    }
  }
  
  // Get user's bookings
  Future<void> fetchUserBookings() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();
      
      _userBookings = snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data()))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error fetching user bookings: $e');
    }
  }
  
  // Update booking status
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Update local booking
      final index = _userBookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _userBookings[index] = _userBookings[index].copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error updating booking status: $e');
      return false;
    }
  }
  
  // Update payment status
  Future<bool> updatePaymentStatus(String bookingId, String paymentStatus) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'paymentStatus': paymentStatus,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Update local booking
      final index = _userBookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _userBookings[index] = _userBookings[index].copyWith(
          paymentStatus: paymentStatus,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error updating payment status: $e');
      return false;
    }
  }
  
  // Cancel booking
  Future<bool> cancelBooking(String bookingId) async {
    return await updateBookingStatus(bookingId, 'cancelled');
  }
  
  // Get available time slots for a specific date and expert
  Future<List<String>> getAvailableTimeSlots(String expertId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final existingBookings = await _firestore
          .collection('bookings')
          .where('expertId', isEqualTo: expertId)
          .where('scheduledAt', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .where('scheduledAt', isLessThan: endOfDay.millisecondsSinceEpoch)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();
      
      // Generate all possible time slots (9 AM to 6 PM)
      final allSlots = <String>[];
      for (int hour = 9; hour < 18; hour++) {
        allSlots.add('${hour.toString().padLeft(2, '0')}:00');
        allSlots.add('${hour.toString().padLeft(2, '0')}:30');
      }
      
      // Remove booked slots
      final bookedTimes = existingBookings.docs.map((doc) {
        final booking = BookingModel.fromMap(doc.data());
        final time = booking.scheduledAt;
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }).toList();
      
      return allSlots.where((slot) => !bookedTimes.contains(slot)).toList();
    } catch (e) {
      debugPrint('Error getting available time slots: $e');
      return [];
    }
  }
  
  // Get booking details with service and expert information
  Future<Map<String, dynamic>?> getBookingDetails(String bookingId) async {
    try {
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      
      if (!bookingDoc.exists) return null;
      
      final booking = BookingModel.fromMap(bookingDoc.data()!);
      
      // Fetch service details
      final serviceDoc = await _firestore.collection('services').doc(booking.serviceId).get();
      Service? service;
      if (serviceDoc.exists) {
        service = Service.fromMap(serviceDoc.data()!, serviceDoc.id);
      }
      
      // Fetch expert details
      final expertDoc = await _firestore.collection('experts').doc(booking.expertId).get();
      Expert? expert;
      if (expertDoc.exists) {
        expert = Expert.fromMap(expertDoc.data()!, expertDoc.id);
      }
      
      return {
        'booking': booking,
        'service': service,
        'expert': expert,
      };
    } catch (e) {
      debugPrint('Error getting booking details: $e');
      return null;
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}