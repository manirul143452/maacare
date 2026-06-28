// ============================================================
//  MaaCareBackendService – MaaCare Backend (REST Implementation)
// ============================================================

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';
import '../models/post_model.dart';
import '../models/symptom_vaccination_model.dart';
import '../models/doctor_model.dart';
import '../models/booking_model.dart';
import '../constants.dart';
import 'dart:async';
import 'auth_service.dart';
import 'api_service.dart';

class MaaCareBackendService {
  MaaCareBackendService._();
  static final MaaCareBackendService instance = MaaCareBackendService._();

  String? _accessToken;

  String get _baseUrl => AppConstants.backendUrl;
  String get _anonKey => AppConstants.backendAnonKey;

  Map<String, String> get _headers {
    final token = AuthService.instance.accessToken ?? _accessToken;
    final isMock = token != null && token.contains('mock_signature');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${isMock ? _anonKey : (token ?? _anonKey)}',
    };
  }

  Future<List<UserModel>> fetchUsers({int limit = 10}) async {
    try {
      final url = Uri.parse('$_baseUrl/api/database/records/users?limit=$limit');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List data = ApiService.safeDecode(response);
        return data
            .map((d) => UserModel.fromMap(d as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // ─────────────────── Auth ───────────────────

  Future<String> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
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
        if (response.body.isEmpty) return 'email_verification_required';
        final data = ApiService.safeDecode(response);
        if (data['accessToken'] == null ||
            data['requireEmailVerification'] == true) {
          return 'email_verification_required';
        }
        _accessToken = data['accessToken'];
        if (_accessToken != null) await _saveToken(_accessToken!);
        return 'success';
      }
      return 'HTTP ${response.statusCode}: ${response.body}';
    } catch (e) {
      return 'Exception: $e';
    }
  }

  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    try {
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
        final data = ApiService.safeDecode(response);
        _accessToken = data['accessToken'];
        if (_accessToken != null) {
          await _saveToken(_accessToken!);
          return 'success';
        }
        return 'No access token in response';
      }
      return 'HTTP ${response.statusCode}: ${response.body}';
    } catch (e) {
      return 'Network Exception: $e';
    }
  }

  // ─────────────────── OAuth PKCE (legacy, not used) ───────────────────

  String _generateRandomString(int length) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  Future<void> initiateOAuthFlow(String provider) async {
    final codeVerifier = _generateRandomString(64);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('oauth_code_verifier', codeVerifier);

    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    final codeChallenge = base64UrlEncode(digest.bytes).replaceAll('=', '');

    final currentUrl = Uri.base.toString();
    final redirectUri =
        currentUrl.contains('#') ? currentUrl.split('#')[0] : currentUrl;

    final authUrl = Uri.parse('$_baseUrl/api/auth/oauth/$provider')
        .replace(queryParameters: {
      'redirect_uri': redirectUri,
      'code_challenge': codeChallenge,
    });

    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl, webOnlyWindowName: '_self');
    }
  }

  Future<bool> exchangeOAuthCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final codeVerifier = prefs.getString('oauth_code_verifier');
      if (codeVerifier == null) return false;

      final url =
          Uri.parse('$_baseUrl/api/auth/oauth/exchange?client_type=web');
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'code': code,
          'code_verifier': codeVerifier,
        }),
      );

      if (response.statusCode == 200) {
        final data = ApiService.safeDecode(response);
        if (data['accessToken'] != null) {
          _accessToken = data['accessToken'];
          await _saveToken(_accessToken!);
          await prefs.remove('oauth_code_verifier');
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
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
    final token = prefs.getString('insforge_token');
    if (token != null && _isTokenValid(token)) {
      _accessToken = token;
    } else {
      // Token missing or expired — clear it to force re-login
      _accessToken = null;
      if (token != null) await prefs.remove('insforge_token');
    }
  }

  /// Returns true if the JWT is structurally valid and not expired
  bool _isTokenValid(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      String normalized = parts[1];
      switch (normalized.length % 4) {
        case 0:
          break;
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
        default:
          return false;
      }
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      final exp = payload['exp'];
      if (exp == null) return true; // No expiry = assume valid
      final expiry = DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
      return DateTime.now().isBefore(expiry);
    } catch (_) {
      return false;
    }
  }

  bool get isLoggedIn =>
      (AuthService.instance.isLoggedIn) ||
      (_accessToken != null && _isTokenValid(_accessToken!));

  int? debugTokenLength() => _accessToken?.length;

  String? getCurrentUserId() {
    final authUserId = AuthService.instance.getCurrentUserId();
    if (authUserId != null) return authUserId;
    if (_accessToken == null) return null;
    try {
      final parts = _accessToken!.split('.');
      if (parts.length != 3) return null;
      String normalized = parts[1];
      switch (normalized.length % 4) {
        case 0:
          break;
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
        default:
          return null;
      }
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      // Check expiry before returning user ID
      final exp = payload['exp'];
      if (exp != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
        if (DateTime.now().isAfter(expiry)) return null; // Token expired
      }
      // Railway backend signs with { id, email } — fallback to 'sub' for compatibility
      return (payload['id'] ?? payload['sub']) as String?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (_accessToken == null) return null;
    final url = Uri.parse('$_baseUrl/api/auth/sessions/current');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = ApiService.safeDecode(response);
      return data['user'];
    }
    return null;
  }

  // ─────────────────── User Profile ───────────────────

  Future<void> upsertUser(UserModel user) async {
    final url = Uri.parse('$_baseUrl/api/database/records/users?on_conflict=id');
    final response = await http.post(
      url,
      headers: {
        ..._headers,
        'Prefer': 'resolution=merge-duplicates',
      },
      body: jsonEncode([user.toMap()]), // Backend requires array
    );
    if (response.statusCode >= 400) {
      throw Exception(
          'DB save failed (${response.statusCode}): ${response.body}');
    }
  }

  Future<UserModel?> fetchUser(String userId) async {
    final url = Uri.parse('$_baseUrl/api/database/records/users?id=eq.$userId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List data = ApiService.safeDecode(response);
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

  Future<void> updateTrialUses(String userId, int trialUsesLeft) async {
    final url = Uri.parse('$_baseUrl/api/database/records/users?id=eq.$userId');
    await http.patch(
      url,
      headers: _headers,
      body: jsonEncode({'trial_uses_left': trialUsesLeft}),
    );
  }

  Future<void> updatePremiumStatus({
    required String userId,
    required bool isPremium,
    required String planName,
    required String paymentId,
  }) async {
    final url = Uri.parse('$_baseUrl/api/database/records/users?id=eq.$userId');
    await http.patch(
      url,
      headers: _headers,
      body: jsonEncode({
        'is_premium': isPremium,
        'premium_plan': planName,
        'razorpay_payment_id': paymentId,
      }),
    );

    try {
      final subCheckUrl = Uri.parse('$_baseUrl/api/database/records/user_subscriptions?user_id=eq.$userId');
      final checkRes = await http.get(subCheckUrl, headers: _headers);
      if (checkRes.statusCode == 200) {
        final List list = ApiService.safeDecode(checkRes);
        if (list.isEmpty) {
          await http.post(
            Uri.parse('$_baseUrl/api/database/records/user_subscriptions'),
            headers: _headers,
            body: jsonEncode([{
              'user_id': userId,
              'is_premium': isPremium,
              'ai_message_count': 0,
            }]),
          );
        } else {
          await http.patch(
            subCheckUrl,
            headers: _headers,
            body: jsonEncode({
              'is_premium': isPremium,
            }),
          );
        }
      }
    } catch (e) {
      debugPrint('updatePremiumStatus sub sync error: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchUserSubscription(String userId) async {
    final url = Uri.parse('$_baseUrl/api/database/records/user_subscriptions?user_id=eq.$userId');
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List list = ApiService.safeDecode(response);
        if (list.isNotEmpty) {
          return list.first as Map<String, dynamic>;
        } else {
          // Initialize default row if not exists
          final createRes = await http.post(
            Uri.parse('$_baseUrl/api/database/records/user_subscriptions'),
            headers: _headers,
            body: jsonEncode([{
              'user_id': userId,
              'is_premium': false,
              'free_cycle_generation_count': 0,
              'free_pregnancy_generation_count': 0,
              'free_ai_chat_count': 0,
            }]),
          );
          if (createRes.statusCode == 200 || createRes.statusCode == 201) {
            final List newList = ApiService.safeDecode(createRes);
            if (newList.isNotEmpty) {
              return newList.first as Map<String, dynamic>;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('fetchUserSubscription error: $e');
    }
    return null;
  }

  Future<void> updateUserSubscription(String userId, Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/api/database/records/user_subscriptions?user_id=eq.$userId');
    try {
      await http.patch(
        url,
        headers: _headers,
        body: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('updateUserSubscription error: $e');
    }
  }

  // ─────────────────── Chat & Conversations ───────────────────

  Future<List<ConversationModel>> fetchConversations(String userId) async {
    final url = Uri.parse(
        '$_baseUrl/api/database/records/conversations?user_id=eq.$userId&order=created_at.desc');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List data = ApiService.safeDecode(response);
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
    final url = Uri.parse(
        '$_baseUrl/api/database/records/conversations?id=eq.$conversationId');
    await http.delete(url, headers: _headers);
  }

  Future<List<ChatMessage>> fetchChatHistory(String userId,
      {String? conversationId}) async {
    var urlStr =
        '$_baseUrl/api/database/records/chats?user_id=eq.$userId&order=created_at.asc&limit=100';
    if (conversationId != null) {
      urlStr += '&conversation_id=eq.$conversationId';
    }
    final url = Uri.parse(urlStr);
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List data = ApiService.safeDecode(response);
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
    final url = Uri.parse(
        '$_baseUrl/api/database/records/chats?conversation_id=eq.$conversationId');
    await http.delete(url, headers: _headers);
  }

  // ─────────────────── Community Posts ───────────────────

  Future<List<PostModel>> fetchPosts({int? weekTag, int? limit}) async {
    var urlStr =
        '$_baseUrl/api/database/records/posts?order=created_at.desc&limit=${limit ?? 50}';
    if (weekTag != null) {
      urlStr += '&week_tag=eq.$weekTag';
    }
    final url = Uri.parse(urlStr);
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List data = ApiService.safeDecode(response);
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
      final List data = ApiService.safeDecode(response);
      if (data.isNotEmpty) {
        return PostModel.fromMap(data.first);
      }
    } else {
      debugPrint('Post creation failed: ${response.statusCode} - ${response.body}');
    }
    return null;
  }

  Future<List<PostModel>> fetchPostsByUser(String userId) async {
    final url = Uri.parse(
        '$_baseUrl/api/database/records/posts?user_id=eq.$userId&order=created_at.desc');
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List data = ApiService.safeDecode(response);
        return data.map((p) => PostModel.fromMap(p)).toList();
      }
    } catch (e) {
      debugPrint('fetchPostsByUser error: $e');
    }
    return [];
  }

  Future<bool> deletePost(String postId) async {
    final url = Uri.parse('$_baseUrl/api/database/records/posts?id=eq.$postId');
    try {
      final response = await http.delete(url, headers: _headers);
      return response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 201;
    } catch (e) {
      debugPrint('deletePost error: $e');
      return false;
    }
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
    final url = Uri.parse(
        '$_baseUrl/api/database/records/replies?post_id=eq.$postId&order=created_at.asc');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List data = ApiService.safeDecode(response);
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
      body: jsonEncode([
        {
          'post_id': postId,
          'user_id': userId,
          'content': content,
          'author_name': authorName,
          'anonymous': anonymous,
        }
      ]),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final List data = ApiService.safeDecode(response);
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
      body: jsonEncode([
        {
          'user_id': userId,
          'symptoms': symptoms,
          'risk_level': riskLevel,
          'created_at': DateTime.now().toIso8601String(),
        }
      ]),
    );
  }

  Future<List<SymptomCheckModel>> fetchSymptomChecks(String userId) async {
    final url = Uri.parse(
        '$_baseUrl/api/database/records/symptoms?user_id=eq.$userId&order=created_at.desc');
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List data = ApiService.safeDecode(response);
        return data.map((v) => SymptomCheckModel.fromMap(v)).toList();
      }
    } catch (e) {
      debugPrint('fetchSymptomChecks error: $e');
    }
    return [];
  }

  // ─────────────────── Vaccinations ───────────────────

  Future<List<VaccinationModel>> fetchVaccinations(String userId) async {
    final url = Uri.parse(
        '$_baseUrl/api/database/records/vaccinations?user_id=eq.$userId&order=due_date.asc');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List data = ApiService.safeDecode(response);
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
    final url = Uri.parse(
        '$_baseUrl/api/database/records/vaccinations?id=eq.$vaccinationId');
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
    try {
      final token = AuthService.instance.accessToken ?? _accessToken;
      final isMock = token != null && token.contains('mock_signature');
      final authToken = isMock ? _anonKey : (token ?? _anonKey);

      final uploadUrl = Uri.parse('$_baseUrl/api/storage/buckets/$bucket/objects/$fileName');
      final request = http.MultipartRequest('PUT', uploadUrl)
        ..headers.addAll({
          'Authorization': 'Bearer $authToken',
        })
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: contentType != null ? http_parser.MediaType.parse(contentType) : null,
        ));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = ApiService.safeDecode(response) as Map<String, dynamic>;
        var url = responseData['url'] as String;
        if (url.startsWith('/')) {
          url = '$_baseUrl$url';
        }
        return url;
      } else {
        debugPrint('Upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stack) {
      debugPrint('MaaCare Backend upload error: $e\n$stack');
      return null;
    }
  }

  // ─────────────────── Edge Functions (AI Companion) ───────────────────

  Future<Map<String, dynamic>?> invokeAiChat(
      List<Map<String, dynamic>> messages, {String? systemPrompt}) async {
    final url = Uri.parse('$_baseUrl/functions/ai_chat');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'messages': messages,
          if (systemPrompt != null) 'system_prompt': systemPrompt,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = ApiService.safeDecode(response);
        return data;
      } else {
        debugPrint('Edge Function Error: ${response.statusCode} - ${response.body}');
        try {
          return ApiService.safeDecode(response);
        } catch (_) {
          return {'error': 'HTTP ${response.statusCode}', 'details': response.body};
        }
      }
    } catch (e) {
      debugPrint('Edge Function Exception: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> invokeNutritionPlan(Map<String, dynamic> payload) async {
    final url = Uri.parse('$_baseUrl/functions/generate_nutrition_plan');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiService.safeDecode(response);
      } else {
        debugPrint('Edge Function Error: ${response.statusCode} - ${response.body}');
        return {'error': response.body};
      }
    } catch (e) {
      debugPrint('Edge Function Exception: $e');
      return {'error': e.toString()};
    }
  }

  // ─────────────────── Doctors ───────────────────

  Future<List<DoctorModel>> fetchDoctors() async {
    final urlStr =
        '$_baseUrl/api/database/records/doctors?order=rating.desc';
    final url = Uri.parse(urlStr);
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List data = ApiService.safeDecode(response);
      return data.map((d) => DoctorModel.fromMap(d)).toList();
    } else if (response.statusCode == 404) {
      throw Exception('Table "doctors" missing in backend (404)');
    } else {
      throw Exception('Database Error ${response.statusCode}: ${response.body}');
    }
  }

  Future<DoctorModel?> fetchDoctorByUserId(String userId) async {
    final urlStr = '$_baseUrl/api/database/records/doctors?user_id=eq.$userId';
    final url = Uri.parse(urlStr);
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List data = ApiService.safeDecode(response);
        if (data.isNotEmpty) return DoctorModel.fromMap(data.first);
      }
    } catch (_) {}
    return null;
  }

  Future<DoctorModel?> fetchDoctorById(String id) async {
    final url = Uri.parse('$_baseUrl/api/database/records/doctors?id=eq.$id');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List data = ApiService.safeDecode(response);
      if (data.isNotEmpty) {
        return DoctorModel.fromMap(data.first);
      }
    }
    return null;
  }

  Future<bool> registerDoctor(DoctorModel doctor) async {
    final url = Uri.parse('$_baseUrl/api/database/records/doctors');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode([doctor.toMap()..remove('id')]),
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          doctor.avatarUrl != null &&
          doctor.avatarUrl!.isNotEmpty) {
        try {
          final userUrl = Uri.parse('$_baseUrl/api/database/records/users?id=eq.${doctor.userId}');
          await http.patch(
            userUrl,
            headers: _headers,
            body: jsonEncode({'avatar_url': doctor.avatarUrl}),
          );
          debugPrint('Avatar synced to users table successfully');
        } catch (e) {
          debugPrint('Failed to sync avatar to users table: $e');
        }
      }
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Doctor registration failed: $e');
      return false;
    }
  }

  Future<bool> updateDoctorProfile(
      String id, Map<String, dynamic> updates) async {
    final url = Uri.parse('$_baseUrl/api/database/records/doctors?id=eq.$id');
    try {
      final response = await http.patch(
        url,
        headers: _headers,
        body: jsonEncode(updates),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Doctor update failed: $e');
      return false;
    }
  }

  Future<bool> bookAppointment(BookingModel booking) async {
    final url = Uri.parse('$_baseUrl/api/database/records/appointments');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode([booking.toMap()..remove('id')]), // DB generates ID
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Appointment booking failed: $e');
      return false;
    }
  }

  Future<bool> updateAppointmentStatus(String id, String status) async {
    final url = Uri.parse('$_baseUrl/api/database/records/appointments?id=eq.$id');
    try {
      final response = await http.patch(
        url,
        headers: _headers,
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Failed to update appointment status: $e');
      return false;
    }
  }

  Future<List<BookingModel>> fetchAppointmentsForPatient(String userId) async {
    final urlStr =
        '$_baseUrl/api/database/records/appointments?user_id=eq.$userId&order=appointment_date.desc';
    final url = Uri.parse(urlStr);
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List data = ApiService.safeDecode(response);
        return data.map((b) => BookingModel.fromMap(b)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<BookingModel>> fetchAppointmentsForDoctor(String doctorId) async {
    final urlStr =
        '$_baseUrl/api/database/records/appointments?doctor_id=eq.$doctorId&order=created_at.desc';
    final url = Uri.parse(urlStr);
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List data = ApiService.safeDecode(response);
        return data.map((b) => BookingModel.fromMap(b)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> upsertDoctorProfile({
    required String userId,
    required String medicalRegistrationNo,
    required String specialization,
    required String hospitalAffiliation,
  }) async {
    final url = Uri.parse('$_baseUrl/api/database/records/doctor_profiles?on_conflict=user_id');
    final response = await http.post(
      url,
      headers: {
        ..._headers,
        'Prefer': 'resolution=merge-duplicates',
      },
      body: jsonEncode([{
        'user_id': userId,
        'medical_registration_no': medicalRegistrationNo,
        'specialization': specialization,
        'hospital_affiliation': hospitalAffiliation,
        'is_verified': false,
      }]),
    );
    if (response.statusCode >= 400) {
      throw Exception('Doctor profile save failed (${response.statusCode}): ${response.body}');
    }
  }

  // ─────────────────── Menstrual Logs ───────────────────

  Future<Map<String, dynamic>?> fetchMenstrualLogs(String userId) async {
    final url = Uri.parse('$_baseUrl/api/database/records/menstrual_logs?user_id=eq.$userId');
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List data = ApiService.safeDecode(response);
        if (data.isNotEmpty) return data.first as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('fetchMenstrualLogs error: $e');
    }
    return null;
  }

  Future<bool> upsertMenstrualLogs(Map<String, dynamic> log) async {
    final url = Uri.parse('$_baseUrl/api/database/records/menstrual_logs');
    try {
      final response = await http.post(
        url,
        headers: {
          ..._headers,
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode([log]),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('upsertMenstrualLogs error: $e');
      return false;
    }
  }

  Future<void> invokeSymptomWebhook({
    required String userId,
    required String symptom,
    required String severity,
  }) async {
    final url = Uri.parse('$_baseUrl/functions/symptom_webhook');
    try {
      await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'symptom_name': symptom,
          'severity_level': severity,
          'logged_at': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('invokeSymptomWebhook error: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchConsultationSession(
      String doctorId, String patientId) async {
    final url = Uri.parse(
        '$_baseUrl/api/database/records/consultation_sessions?doctor_id=eq.$doctorId&patient_id=eq.$patientId&order=created_at.desc&limit=1');
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List data = ApiService.safeDecode(response);
        if (data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('fetchConsultationSession error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> createConsultationSession(
      Map<String, dynamic> session) async {
    final url = Uri.parse('$_baseUrl/api/database/records/consultation_sessions');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode([session]),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List data = ApiService.safeDecode(response);
        if (data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('createConsultationSession error: $e');
    }
    return null;
  }

  Future<bool> updateConsultationSession(
      String sessionId, Map<String, dynamic> updates) async {
    final url = Uri.parse(
        '$_baseUrl/api/database/records/consultation_sessions?id=eq.$sessionId');
    try {
      final response = await http.patch(
        url,
        headers: _headers,
        body: jsonEncode(updates),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('updateConsultationSession error: $e');
      return false;
    }
  }

  Future<bool> updateUserRole(String userId, String role) async {
    final url = Uri.parse('$_baseUrl/api/database/records/users?id=eq.$userId');
    try {
      final response = await http.patch(
        url,
        headers: _headers,
        body: jsonEncode({'user_role': role}),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('updateUserRole error: $e');
      return false;
    }
  }

  Future<bool> updateBmiMetrics({
    required String userId,
    required double heightCm,
    required double weightKg,
  }) async {
    final url = Uri.parse('$_baseUrl/api/database/records/users?id=eq.$userId');
    try {
      final response = await http.patch(
        url,
        headers: _headers,
        body: jsonEncode({
          'height_cm': heightCm,
          'weight_kg': weightKg,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('updateBmiMetrics error: $e');
      return false;
    }
  }

  Future<bool> logBmi({
    required String userId,
    required double bmiScore,
    required String weightStatus,
  }) async {
    final url = Uri.parse('$_baseUrl/api/database/records/bmi_logs');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode([{
          'user_id': userId,
          'bmi_score': bmiScore,
          'weight_status': weightStatus,
        }]),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('logBmi error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchBmiLogs(String userId) async {
    final url = Uri.parse('$_baseUrl/api/database/records/bmi_logs?user_id=eq.$userId&order=recorded_at.desc&limit=10');
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> list = ApiService.safeDecode(response);
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('fetchBmiLogs error: $e');
    }
    return [];
  }

  // ─────────────────── Patient Reports ───────────────────

  Future<bool> submitPatientReport({
    required String patientId,
    required String doctorId,
    required String fileUrl,
  }) async {
    final url = Uri.parse('$_baseUrl/api/database/records/patient_reports');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode([{
          'patient_id': patientId,
          'doctor_id': doctorId,
          'file_url': fileUrl,
        }]),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Patient report submission failed: $e');
      return false;
    }
  }

  Future<String?> fetchPatientReportUrl({
    required String patientId,
    required String doctorId,
  }) async {
    final url = Uri.parse('$_baseUrl/api/database/records/patient_reports?patient_id=eq.$patientId&doctor_id=eq.$doctorId&order=submitted_at.desc&limit=1');
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List data = ApiService.safeDecode(response);
        if (data.isNotEmpty) {
          return data.first['file_url'] as String?;
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch patient report URL: $e');
    }
    return null;
  }

  // ─────────────────── Menstrual Log (PCOS etc.) ───────────────────

  /// Upsert menstrual_logs row for the user.
  /// [extraFields] can include any PCOS / cycle fields to merge.
  Future<void> saveMenstrualLog({
    required String userId,
    Map<String, dynamic>? extraFields,
  }) async {
    final url = Uri.parse(
        '$_baseUrl/api/database/records/menstrual_logs?on_conflict=user_id');
    final payload = <String, dynamic>{
      'user_id': userId,
      'updated_at': DateTime.now().toIso8601String(),
      ...?extraFields,
    };
    try {
      final response = await http.post(
        url,
        headers: {
          ..._headers,
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode([payload]),
      );
      if (response.statusCode >= 400) {
        debugPrint('saveMenstrualLog error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('saveMenstrualLog exception: $e');
      rethrow;
    }
  }

  // ─────────────────── Child Profile & Growth ───────────────────

  /// Fetch child profile (including weight/height logs) from DB.
  Future<Map<String, dynamic>?> fetchChildProfile(String userId) async {
    final url = Uri.parse(
        '$_baseUrl/api/database/records/child_profiles?user_id=eq.$userId&limit=1');
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List data = ApiService.safeDecode(response);
        if (data.isNotEmpty) return data.first as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('fetchChildProfile error: $e');
    }
    return null;
  }

  /// Upsert child profile row including growth log JSONB columns.
  Future<void> upsertChildProfile({
    required String userId,
    required String name,
    required String dateOfBirth,
    String gender = 'other',
    List<Map<String, dynamic>>? weightLogs,
    List<Map<String, dynamic>>? heightLogs,
    List<String>? completedMilestones,
  }) async {
    final url = Uri.parse(
        '$_baseUrl/api/database/records/child_profiles?on_conflict=user_id');
    final payload = {
      'user_id': userId,
      'name': name,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      if (weightLogs != null) 'weight_logs': weightLogs,
      if (heightLogs != null) 'height_logs': heightLogs,
      if (completedMilestones != null) 'completed_milestones': completedMilestones,
    };
    try {
      final response = await http.post(
        url,
        headers: {
          ..._headers,
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode([payload]),
      );
      if (response.statusCode >= 400) {
        debugPrint('upsertChildProfile error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('upsertChildProfile exception: $e');
      rethrow;
    }
  }
}


