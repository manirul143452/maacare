// ============================================================
//  InsForgeService – MaaCare Backend (REST Implementation)
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';
import '../models/post_model.dart';
import '../models/symptom_vaccination_model.dart';
import '../constants.dart';

class InsForgeService {
  InsForgeService._();
  static final InsForgeService instance = InsForgeService._();

  String? _accessToken;

  String get _baseUrl => AppConstants.insForgeUrl;
  String get _anonKey => AppConstants.insForgeAnonKey;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_accessToken ?? _anonKey}',
  };

  // ─────────────────── Auth ───────────────────

  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    final url = Uri.parse('$_baseUrl/api/auth/users');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        if (name != null) 'name': name,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      _accessToken = data['accessToken'];
      await _saveToken(_accessToken!);
      return true;
    }
    return false;
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/api/auth/sessions');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['accessToken'];
      await _saveToken(_accessToken!);
      return true;
    }
    return false;
  }

  Future<void> signOut() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('insforge_token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('insforge_token', token);
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('insforge_token');
  }

  bool get isLoggedIn => _accessToken != null;

  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (_accessToken == null) return null;
    final url = Uri.parse('$_baseUrl/api/auth/sessions/current');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['user'];
    }
    return null;
  }

  // ─────────────────── User Profile ───────────────────

  Future<void> upsertUser(UserModel user) async {
    final url = Uri.parse('$_baseUrl/api/database/records/users');
    await http.post(
      url,
      headers: {
        ..._headers,
        'Prefer': 'resolution=merge-duplicates',
      },
      body: jsonEncode([user.toMap()]), // InsForge requires array
    );
  }

  Future<UserModel?> fetchUser(String userId) async {
    final url = Uri.parse('$_baseUrl/api/database/records/users?id=eq.$userId');
    final response = await http.get(url, headers: _headers);
    
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        return UserModel.fromMap(data.first);
      }
    }
    return null;
  }

  Future<void> updatePoints(String userId, int newPoints) async {
    final url = Uri.parse('$_baseUrl/api/database/records/users?id=eq.$userId');
    await http.patch(
      url,
      headers: _headers,
      body: jsonEncode({'points': newPoints}),
    );
  }

  Future<void> updateMood(String userId, String mood) async {
    final url = Uri.parse('$_baseUrl/api/database/records/users?id=eq.$userId');
    await http.patch(
      url,
      headers: _headers,
      body: jsonEncode({'mood': mood}),
    );
  }

  // ─────────────────── Chat & Conversations ───────────────────

  Future<List<ConversationModel>> fetchConversations(String userId) async {
    final url = Uri.parse('$_baseUrl/api/database/records/conversations?user_id=eq.$userId&order=created_at.desc');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((c) => ConversationModel.fromMap(c)).toList();
    }
    return [];
  }

  Future<void> createConversation(ConversationModel conversation) async {
    final url = Uri.parse('$_baseUrl/api/database/records/conversations');
    await http.post(
      url,
      headers: _headers,
      body: jsonEncode([conversation.toMap()]),
    );
  }

  Future<void> deleteConversation(String conversationId) async {
    final url = Uri.parse('$_baseUrl/api/database/records/conversations?id=eq.$conversationId');
    await http.delete(url, headers: _headers);
  }

  Future<List<ChatMessage>> fetchChatHistory(String userId, {String? conversationId}) async {
    var urlStr = '$_baseUrl/api/database/records/chats?user_id=eq.$userId&order=created_at.asc&limit=100';
    if (conversationId != null) {
      urlStr += '&conversation_id=eq.$conversationId';
    }
    final url = Uri.parse(urlStr);
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((m) => ChatMessage.fromMap(m)).toList();
    }
    return [];
  }

  Future<void> saveMessage(ChatMessage message) async {
    final url = Uri.parse('$_baseUrl/api/database/records/chats');
    await http.post(
      url,
      headers: _headers,
      body: jsonEncode([message.toMap()]),
    );
  }

  Future<void> deleteChatHistory(String conversationId) async {
    final url = Uri.parse('$_baseUrl/api/database/records/chats?conversation_id=eq.$conversationId');
    await http.delete(url, headers: _headers);
  }

  // ─────────────────── Community Posts ───────────────────

  Future<List<PostModel>> fetchPosts({int? weekTag}) async {
    var urlStr = '$_baseUrl/api/database/records/posts?order=created_at.desc&limit=50';
    if (weekTag != null) {
      urlStr += '&week_tag=eq.$weekTag';
    }
    final url = Uri.parse(urlStr);
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((p) => PostModel.fromMap(p)).toList();
    }
    return [];
  }

  Future<PostModel?> createPost(PostModel post) async {
    final url = Uri.parse('$_baseUrl/api/database/records/posts');
    final response = await http.post(
      url,
      headers: {
        ..._headers,
        'Prefer': 'return=representation',
      },
      body: jsonEncode([post.toMap()]),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        return PostModel.fromMap(data.first);
      }
    }
    return null;
  }

  Future<void> likePost(String postId, int currentLikes) async {
    final url = Uri.parse('$_baseUrl/api/database/records/posts?id=eq.$postId');
    await http.patch(
      url,
      headers: _headers,
      body: jsonEncode({'likes': currentLikes}),
    );
  }

  // ─────────────────── Replies ───────────────────

  Future<List<Map<String, dynamic>>> fetchReplies(String postId) async {
    final url = Uri.parse('$_baseUrl/api/database/records/replies?post_id=eq.$postId&order=created_at.asc');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>?> createReply({
    required String postId,
    required String userId,
    required String content,
    String? authorName,
    bool anonymous = true,
  }) async {
    final url = Uri.parse('$_baseUrl/api/database/records/replies');
    final response = await http.post(
      url,
      headers: {
        ..._headers,
        'Prefer': 'return=representation',
      },
      body: jsonEncode([{
        'post_id': postId,
        'user_id': userId,
        'content': content,
        'author_name': authorName,
        'anonymous': anonymous,
      }]),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      if (data.isNotEmpty) return data.first;
    }
    return null;
  }

  // ─────────────────── Symptoms ───────────────────

  Future<void> saveSymptomCheck({
    required String userId,
    required List<String> symptoms,
    required String riskLevel,
  }) async {
    final url = Uri.parse('$_baseUrl/api/database/records/symptoms');
    await http.post(
      url,
      headers: _headers,
      body: jsonEncode([{
        'user_id': userId,
        'symptoms': symptoms,
        'risk_level': riskLevel,
      }]),
    );
  }

  // ─────────────────── Vaccinations ───────────────────

  Future<List<VaccinationModel>> fetchVaccinations(String userId) async {
    final url = Uri.parse('$_baseUrl/api/database/records/vaccinations?user_id=eq.$userId&order=due_date.asc');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((v) => VaccinationModel.fromMap(v)).toList();
    }
    return [];
  }

  Future<void> upsertVaccinations(List<VaccinationModel> vaccinations) async {
    final url = Uri.parse('$_baseUrl/api/database/records/vaccinations');
    final maps = vaccinations.map((v) => v.toMap()).toList();
    await http.post(
      url,
      headers: {
        ..._headers,
        'Prefer': 'resolution=merge-duplicates',
      },
      body: jsonEncode(maps),
    );
  }

  Future<void> markVaccinationComplete(String vaccinationId) async {
    final url = Uri.parse('$_baseUrl/api/database/records/vaccinations?id=eq.$vaccinationId');
    await http.patch(
      url,
      headers: _headers,
      body: jsonEncode({'completed': true}),
    );
  }

  Future<String?> uploadFile({
    required String bucket,
    required String fileName,
    required List<int> bytes,
    String? contentType,
  }) async {
    final url = Uri.parse('$_baseUrl/api/storage/buckets/$bucket/upload');
    
    final request = http.MultipartRequest('POST', url)
      ..headers.addAll({
        'Authorization': 'Bearer ${_accessToken ?? _anonKey}',
      })
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: contentType != null ? http_parser.MediaType.parse(contentType) : null,
      ));

    final response = await request.send();
    if (response.statusCode == 200 || response.statusCode == 201) {
      // Assuming return public URL or relative path
      // In many cases, it returns metadata. We might need to construct the public URL.
      return '$_baseUrl/api/storage/buckets/$bucket/public/$fileName';
    }
    return null;
  }
}
