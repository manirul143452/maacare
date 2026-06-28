// ignore_for_file: avoid_web_libraries_in_flutter
// ignore_for_file: deprecated_member_use
import 'dart:js' as js;

void openRazorpayWebImpl({
  required String keyId,
  required int amount,
  required String currency,
  required String name,
  required String description,
  required String email,
  required String phone,
  required String orderId,
}) {
  js.context.callMethod('openRazorpay', [
    keyId, amount, currency, name, description, email, phone, orderId
  ]);
}

void setRazorpayCallbacks(Function(String) onSuccess, Function(String) onFailed, Function() onDismiss) {
  js.context['razorpaySuccess'] = js.allowInterop((paymentId) => onSuccess(paymentId));
  js.context['razorpayFailed'] = js.allowInterop((error) => onFailed(error));
  js.context['razorpayDismiss'] = js.allowInterop(() => onDismiss());
}
