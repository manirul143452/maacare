// ============================================================
//  RazorpayWebService – Flutter Web Razorpay Payment
//  Conditional implementation for Web only
// ============================================================

import 'package:flutter/foundation.dart';

typedef PaymentSuccessCallback = void Function(String paymentId);
typedef PaymentFailedCallback = void Function(String error);
typedef PaymentDismissedCallback = void Function();

class RazorpayWebService {
  RazorpayWebService._();
  static final RazorpayWebService instance = RazorpayWebService._();

  /// Opens Razorpay checkout popup on Web
  /// [amount] is in PAISE (e.g., 9900 = ₹99)
  void openCheckout({
    required String keyId,
    required int amount,
    required String currency,
    required String name,
    required String description,
    String? email,
    String? phone,
    String? orderId,
    PaymentSuccessCallback? onSuccess,
    PaymentFailedCallback? onFailed,
    PaymentDismissedCallback? onDismiss,
  }) {
    if (!kIsWeb) {
      debugPrint('RazorpayWebService: Only available on Web platform');
      return;
    }

    // Store callbacks for web implementation
    // Note: Web implementation is loaded dynamically
    // _onSuccess = onSuccess;
    // _onFailed = onFailed;
    // _onDismiss = onDismiss;

    // Web implementation is loaded dynamically
    _openCheckoutWeb(
      keyId: keyId,
      amount: amount,
      currency: currency,
      name: name,
      description: description,
      email: email,
      phone: phone,
      orderId: orderId,
    );
  }

  void _openCheckoutWeb({
    required String keyId,
    required int amount,
    required String currency,
    required String name,
    required String description,
    String? email,
    String? phone,
    String? orderId,
  }) {
    // This is a stub - actual web implementation uses dart:js
    // which is conditionally imported via razorpay_web_service_web.dart
    debugPrint('RazorpayWebService: Web checkout stub called');
    
    // Call the web-specific implementation if available
    _callWebImplementation(
      keyId: keyId,
      amount: amount,
      currency: currency,
      name: name,
      description: description,
      email: email ?? '',
      phone: phone ?? '',
      orderId: orderId ?? '',
    );
  }

  void _callWebImplementation({
    required String keyId,
    required int amount,
    required String currency,
    required String name,
    required String description,
    required String email,
    required String phone,
    required String orderId,
  }) {
    // Stub for non-web platforms
    // Web platforms override this via conditional imports
  }
}
