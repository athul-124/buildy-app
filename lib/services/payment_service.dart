import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/booking_model.dart';
import '../models/user_model.dart';

class PaymentService extends ChangeNotifier {
  final Razorpay _razorpay = Razorpay();
  
  bool _isProcessing = false;
  String? _error;
  String? _successPaymentId;
  
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  String? get successPaymentId => _successPaymentId;
  
  PaymentService() {
    _initializeRazorpay();
  }
  
  void _initializeRazorpay() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }
  
  Future<void> initiatePayment({
    required double amount,
    required String orderId,
    required UserModel user,
    required String description,
  }) async {
    try {
      _isProcessing = true;
      _error = null;
      _successPaymentId = null;
      notifyListeners();
      
      // Get Razorpay key from environment
      final keyId = dotenv.env['RAZORPAY_KEY_ID'];
      if (keyId == null || keyId.isEmpty) {
        throw Exception('Razorpay Key ID not configured');
      }
      
      // Convert amount to paise (Razorpay accepts amount in smallest currency unit)
      final amountInPaise = (amount * 100).round();
      
      var options = {
        'key': keyId,
        'amount': amountInPaise,
        'currency': 'INR',
        'name': 'Buildly Services',
        'description': description,
        'order_id': orderId,
        'timeout': 300, // 5 minutes
        'prefill': {
          'contact': user.phone ?? '',
          'email': user.email,
          'name': user.name,
        },
        'theme': {
          'color': '#6366F1', // Your app's primary color
        },
        'notes': {
          'booking_id': orderId,
          'user_id': user.id,
        },
        'retry': {
          'enabled': true,
          'max_count': 3,
        },
        'send_sms_hash': true,
        'remember_customer': false,
        'readonly': {
          'contact': false,
          'email': false,
        },
        'hidden': {
          'contact': false,
          'email': false,
        },
        'modal': {
          'backdropclose': false,
          'escape': false,
          'handleback': false,
          'confirm_close': true,
          'ondismiss': () {
            _handlePaymentDismiss();
          },
        },
      };
      
      _razorpay.open(options);
    } catch (e) {
      _isProcessing = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error initiating payment: $e');
    }
  }
  
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _isProcessing = false;
    _successPaymentId = response.paymentId;
    _error = null;
    notifyListeners();
    
    debugPrint('Payment successful: ${response.paymentId}');
    debugPrint('Order ID: ${response.orderId}');
    debugPrint('Signature: ${response.signature}');
  }
  
  void _handlePaymentError(PaymentFailureResponse response) {
    _isProcessing = false;
    _error = _getErrorMessage(response.code, response.message);
    _successPaymentId = null;
    notifyListeners();
    
    debugPrint('Payment failed: ${response.code} - ${response.message}');
  }
  
  void _handleExternalWallet(ExternalWalletResponse response) {
    _isProcessing = false;
    _error = 'Payment attempted via external wallet: ${response.walletName}';
    notifyListeners();
    
    debugPrint('External wallet selected: ${response.walletName}');
  }
  
  void _handlePaymentDismiss() {
    _isProcessing = false;
    _error = 'Payment cancelled by user';
    notifyListeners();
    
    debugPrint('Payment modal dismissed');
  }
  
  String _getErrorMessage(int? code, String? message) {
    switch (code) {
      case Razorpay.NETWORK_ERROR:
        return 'Network error. Please check your internet connection and try again.';
      case Razorpay.INVALID_CREDENTIALS:
        return 'Payment configuration error. Please contact support.';
      case Razorpay.PAYMENT_CANCELLED:
        return 'Payment was cancelled by user.';
      case Razorpay.TLS_ERROR:
        return 'Security error. Please update your app and try again.';
      case Razorpay.INCOMPATIBLE_PLUGIN:
        return 'App compatibility issue. Please update the app.';
      case Razorpay.UNKNOWN_ERROR:
        return 'An unknown error occurred. Please try again.';
      default:
        return message ?? 'Payment failed. Please try again.';
    }
  }
  
  // Method to create a test order ID (in production, this should come from your backend)
  String generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'order_${timestamp}_${(1000 + (9999 - 1000) * (timestamp % 1000) / 1000).round()}';
  }
  
  // Method to verify payment (in production, this should be done on your backend)
  Future<bool> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      // In a real app, you would send these details to your backend for verification
      // For now, we'll assume payment is valid if we have all required fields
      if (paymentId.isNotEmpty && orderId.isNotEmpty && signature.isNotEmpty) {
        debugPrint('Payment verification successful (mock)');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Payment verification failed: $e');
      return false;
    }
  }
  
  // Method to get payment details (mock implementation)
  Future<Map<String, dynamic>?> getPaymentDetails(String paymentId) async {
    try {
      // In a real app, you would fetch payment details from Razorpay API via your backend
      return {
        'id': paymentId,
        'amount': 50000, // Amount in paise
        'currency': 'INR',
        'status': 'captured',
        'method': 'card',
        'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
    } catch (e) {
      debugPrint('Error fetching payment details: $e');
      return null;
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  void reset() {
    _isProcessing = false;
    _error = null;
    _successPaymentId = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}

// Payment result class
class PaymentResult {
  final bool isSuccess;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? error;
  
  PaymentResult({
    required this.isSuccess,
    this.paymentId,
    this.orderId,
    this.signature,
    this.error,
  });
  
  factory PaymentResult.success({
    required String paymentId,
    required String orderId,
    required String signature,
  }) {
    return PaymentResult(
      isSuccess: true,
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
    );
  }
  
  factory PaymentResult.failure(String error) {
    return PaymentResult(
      isSuccess: false,
      error: error,
    );
  }
}

// Test card numbers for development
class TestCards {
  static const String successCard = '4111111111111111';
  static const String failureCard = '4000000000000002';
  static const String authenticationCard = '4000000000000051';
  
  static const Map<String, String> testCards = {
    'Success': successCard,
    'Failure': failureCard,
    'Authentication Required': authenticationCard,
  };
  
  static const Map<String, dynamic> testCardDetails = {
    'cvv': '123',
    'expiry_month': '12',
    'expiry_year': '2025',
    'name': 'Test User',
  };
}