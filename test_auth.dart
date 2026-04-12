// ignore_for_file: avoid_print
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'https://96if48kf.ap-southeast.insforge.app';
  const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3N1ZXIiOiJpbnNmb3JnZSIsImF1ZCI6Imluc2ZvcmdlIiwicm9sZSI6ImFub24iLCJpc3MiOiJpbnNmb3JnZSIsImV4cCI6MTkwOTM5MjUxNiwiaWF0IjoxNzUxMjk0MzE2fQ.Z6A3w1gED--uA97m9h0tU0J2N1M4X-3vQIf63L2O0rI';

  final urls = [
    '/api/auth/sessions/current',
    '/api/auth/user',
    '/api/auth/users/me',
    '/api/auth/session'
  ];

  for (var u in urls) {
    final url = Uri.parse('$baseUrl$u');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $anonKey',
    });

    print('Testing $u');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
    print('---');
  }
}
