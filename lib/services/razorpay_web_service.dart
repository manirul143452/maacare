// ============================================================
//  RazorpayWebService – Flutter Web Razorpay Payment
//  Conditional implementation for Web only
// ============================================================

import 'package:flutter/foundation.dart';
import 'razorpay_web_service_stub.dart' if (dart.library.js) 'razorpay_web_service_web.dart' as web_impl;

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

    if (onSuccess != null && onFailed != null && onDismiss != null) {
      web_impl.setRazorpayCallbacks(onSuccess, onFailed, onDismiss);
    }

    web_impl.openRazorpayWebImpl(
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
}
