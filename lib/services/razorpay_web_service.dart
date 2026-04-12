// ============================================================
//  RazorpayWebService – Flutter Web Razorpay Payment
//  Uses JS interop to call the checkout.js bridge in index.html
// ============================================================
// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:flutter/foundation.dart';

// Web-only imports
// ignore: uri_does_not_exist
import 'dart:js' as js; // ignore: deprecated_member_use

typedef PaymentSuccessCallback = void Function(String paymentId);
typedef PaymentFailedCallback = void Function(String error);
typedef PaymentDismissedCallback = void Function();

class RazorpayWebService {
  RazorpayWebService._();
  static final RazorpayWebService instance = RazorpayWebService._();

  PaymentSuccessCallback? _onSuccess;
  PaymentFailedCallback? _onFailed;
  PaymentDismissedCallback? _onDismiss;

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
    if (!kIsWeb) return;

    _onSuccess = onSuccess;
    _onFailed = onFailed;
    _onDismiss = onDismiss;

    // Register callbacks on window object so JS can call them
    js.context['razorpaySuccess'] = js.allowInterop((String paymentId) {
      _onSuccess?.call(paymentId);
    });

    js.context['razorpayFailed'] = js.allowInterop((String error) {
      _onFailed?.call(error);
    });

    js.context['razorpayDismiss'] = js.allowInterop(() {
      _onDismiss?.call();
    });

    // Call the bridge function defined in index.html
    js.context.callMethod('openRazorpay', [
      keyId,
      amount,
      currency,
      name,
      description,
      email ?? '',
      phone ?? '',
      orderId ?? '',
    ]);
  }
}
