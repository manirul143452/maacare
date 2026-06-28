// ============================================================
//  ApiService – Robust network response parsing utility
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  /// Robust server response validation and string interception.
  /// Validates that the body is not an HTML document before decoding.
  static dynamic safeDecode(http.Response response) {
    final body = response.body.trim();
    if (body.startsWith('<!DOCTYPE') || body.startsWith('<html')) {
      throw FormatException(
        "Server returned an HTML error page instead of valid JSON payload. Status code: ${response.statusCode}",
      );
    }
    return jsonDecode(response.body);
  }
}
