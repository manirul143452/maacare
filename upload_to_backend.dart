// ignore_for_file: avoid_print
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;

const String baseUrl = 'https://96if48kf.ap-southeast.insforge.app';
const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3OC0xMjM0LTU2NzgtOTBhYi1jZGVmMTIzNDU2NzgiLCJlbWFpbCI6ImFub25AaW5zZm9yZ2UuY29tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUxMDQwOTF9.VaMaOGNQNj8XlUFSiBCxaOmxjTcfxc6Bxkb6LDLY0J0';
const String bucketName = 'weeks';

void main() async {
  final dir = Directory('assets/images/weeks');
  if (!await dir.exists()) {
    print('Error: assets/images/weeks folder not found!');
    return;
  }

  print('1. Attempting to create bucket "$bucketName"...');
  try {
    final bucketUrl = Uri.parse('$baseUrl/api/storage/buckets');
    final bucketResponse = await http.post(
      bucketUrl,
      headers: {
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
      },
      body: '{"id": "$bucketName", "name": "$bucketName", "public": true}',
    );
    if (bucketResponse.statusCode == 200 || bucketResponse.statusCode == 201) {
      print('Bucket created successfully.');
    } else {
      print('Bucket might already exist or creation failed: ${bucketResponse.statusCode} ${bucketResponse.body}');
    }
  } catch (e) {
    print('Could not call create bucket: $e');
  }

  print('2. Reading files for upload...');
  final files = await dir.list().where((f) => f is File).map((f) => f as File).toList();
  print('Found ${files.length} images to upload.');

  for (var file in files) {
    final fileName = file.uri.pathSegments.last;
    final bytes = await file.readAsBytes();
    
    // InsForge upload endpoint
    final url = Uri.parse('$baseUrl/api/storage/buckets/$bucketName/upload');
    final request = http.MultipartRequest('POST', url)
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
  print('Done uploading to InsForge!');
}
