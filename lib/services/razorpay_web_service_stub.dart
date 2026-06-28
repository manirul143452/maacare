// Stub for native platforms
void openRazorpayWebImpl({
  required String keyId,
  required int amount,
  required String currency,
  required String name,
  required String description,
  required String email,
  required String phone,
  required String orderId,
}) {}

void setRazorpayCallbacks(Function(String) onSuccess, Function(String) onFailed, Function() onDismiss) {}
