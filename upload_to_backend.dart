// ignore_for_file: avoid_print
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;

const String baseUrl = 'https://api.maacare.co';
const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3OC0xMjM0LTU2NzgtOTBhYi1jZGVmMTIzNDU2NzgiLCJlbWFpbCI6ImFub25AbWFhY2FyZS5jbyIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNzc1MTA0MDkxfQ.placeholder';
const String bucketName = 'weeks';

void main() async {
  final dir = Directory('assets/images/weeks');
  if (!await dir.exists()) {
    print('Error: assets/images/weeks folder not found!');
    return;
  }

  print('1. Skipping bucket creation (bucket "weeks" already verified)...');

  print('2. Reading files for upload...');
  final files = await dir.list().where((f) => f is File).map((f) => f as File).toList();
  print('Found ${files.length} images to upload.');

  for (var file in files) {
    final fileName = file.uri.pathSegments.last;
    final bytes = await file.readAsBytes();
    
    // MaaCare Backend upload endpoint
    final url = Uri.parse('$baseUrl/api/storage/buckets/$bucketName/objects/$fileName');
    final request = http.MultipartRequest('PUT', url)
      ..headers.addAll({'Authorization': 'Bearer $anonKey'})
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: http_parser.MediaType('image', 'jpeg'),
      ));

    try {
      final response = await request.send();
      final body = await response.stream.bytesToString();
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Uploaded $fileName');
      } else if (response.statusCode == 409 || (response.statusCode == 400 && body.contains('already'))) {
        print('$fileName already exists (Skipping)');
      } else {
        print('Failed to upload $fileName: ${response.statusCode} - $body');
      }
    } catch (e) {
      print('Error uploading $fileName: $e');
    }
  }
  print('Done uploading to MaaCare Backend!');
}
