// ============================================================
//  PaymentService – Secure Razorpay Integration
//  ✅ Server-side order creation (amount cannot be tampered)
//  ✅ Server-side payment verification + premium grant
//  ✅ Works on both Mobile (razorpay_flutter) and Web
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'auth_service.dart';

class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? error;
  PaymentResult.success({this.paymentId, this.orderId})
      : success = true,
        error = null;
  PaymentResult.failure(this.error)
      : success = false,
        paymentId = null,
        orderId = null;
}

class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  // ── Razorpay valid plans (must match server-side VALID_PLANS) ──
  static const Map<String, int> subscriptionPlans = {
    'monthly': 19900,  // ₹199 in paise
    'yearly': 149900,  // ₹1499 in paise
  };

  Map<String, String> get _authHeaders {
    final token = AuthService.instance.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Step 1: Create order on server (amount enforced server-side) ──────────
  /// Creates a Razorpay order via Railway backend.
  /// [plan] must be 'monthly' or 'yearly' for subscriptions.
  /// [amountPaise] is used for doctor consultation fees (doctor_id provided).
  Future<Map<String, dynamic>?> createOrder({
    String? plan,
    int? amountPaise,
    String? currency = 'INR',
  }) async {
    try {
      final body = <String, dynamic>{
        'action': 'create_order',
        'currency': currency,
      };
      if (plan != null) body['plan'] = plan;
      if (amountPaise != null) body['amount'] = amountPaise;

      final response = await http.post(
        Uri.parse('${AppConstants.backendUrl}/functions/razorpay'),
        headers: _authHeaders,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[Payment] Order created: ${data['id']}');
        return data; // { id, amount, currency, ... }
      } else {
        debugPrint('[Payment] Order creation failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[Payment] createOrder error: $e');
      return null;
    }
  }

  // ── Step 2: Verify payment on server (grants premium / confirms booking) ──
  /// Verifies a completed Razorpay payment server-side.
  /// Server re-validates the HMAC signature and grants premium if valid.
  Future<PaymentResult> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    String? plan,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.backendUrl}/functions/razorpay'),
        headers: _authHeaders,
        body: jsonEncode({
          'action': 'verify_payment',
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
          if (plan != null) 'plan': plan,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        debugPrint('[Payment] ✅ Verified: $razorpayPaymentId');
        return PaymentResult.success(
          paymentId: razorpayPaymentId,
          orderId: razorpayOrderId,
        );
      } else {
        return PaymentResult.failure(data['message'] ?? 'Payment verification failed');
      }
    } catch (e) {
      debugPrint('[Payment] verifyPayment error: $e');
      return PaymentResult.failure('Could not verify payment. Please contact support.');
    }
  }

  // ── Razorpay checkout options builder ─────────────────────────────────────
  /// Builds the options map for razorpay_flutter (mobile).
  Map<String, dynamic> buildCheckoutOptions({
    required String orderId,
    required int amountPaise,
    required String description,
    String? userEmail,
    String? userPhone,
    String? currency = 'INR',
  }) {
    return {
      'key': AppConstants.razorpayKey,        // ✅ Public key ID only
      'order_id': orderId,                     // ✅ Server-generated order ID
      'amount': amountPaise,
      'currency': currency,
      'name': 'MaaCare Health',
      'description': description,
      'prefill': {
        'email': userEmail ?? '',
        'contact': userPhone ?? '',
      },
      'theme': {'color': '#E91E8C'},
    };
  }
}
