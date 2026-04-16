// ============================================================
//  AuthService – MaaCare Premium Authentication
//  SecureStorage, Auto Token Refresh, Persistent Sessions
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'secure_storage_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  String? _accessToken;
  Timer? _refreshTimer;
  final _authStateController = StreamController<bool>.broadcast();

  Stream<bool> get authStateChanges => _authStateController.stream;
  String? get accessToken => _accessToken;

  bool get isLoggedIn => _accessToken != null && _isTokenValid(_accessToken!);

  // ─────────────────── Initialization ───────────────────

  Future<void> initialize() async {
    debugPrint('AUTH_DEBUG: Initializing auth service...');
    await _loadSession();
    _startAutoRefresh();
  }

  // ─────────────────── Session Management ───────────────────

  Future<void> _loadSession() async {
    try {
      final token = await SecureStorageService.instance.read('insforge_token');
      if (token != null && _isTokenValid(token)) {
        _accessToken = token;
        _authStateController.add(true);
        debugPrint('AUTH_DEBUG: Valid session loaded');
      } else {
        _accessToken = null;
        _authStateController.add(false);
        debugPrint('AUTH_DEBUG: No valid session found');
      }
    } catch (e) {
      debugPrint('AUTH_DEBUG: Error loading session: $e');
      _accessToken = null;
      _authStateController.add(false);
    }
  }

  Future<void> _saveSession(String token) async {
    _accessToken = token;
    await SecureStorageService.instance.write('insforge_token', token);
    _authStateController.add(true);
    _startAutoRefresh();
  }

  Future<void> clearSession() async {
    _accessToken = null;
    _refreshTimer?.cancel();
    await SecureStorageService.instance.delete('insforge_token');
    _authStateController.add(false);
    debugPrint('AUTH_DEBUG: Session cleared');
  }

  // ─────────────────── Authentication ───────────────────

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.insForgeUrl}/api/auth/sessions');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.insForgeAnonKey}',
        },
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['accessToken'] as String?;
        
        if (token != null) {
          await _saveSession(token);
          return AuthResult.success(userId: _getUserIdFromToken(token));
        }
        return AuthResult.error('No access token received');
      }
      
      return AuthResult.error('Invalid credentials');
    } catch (e) {
      debugPrint('AUTH_DEBUG: Sign in error: $e');
      return AuthResult.error('Network error. Please try again.');
    }
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.insForgeUrl}/api/auth/users');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.insForgeAnonKey}',
        },
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
          if (name != null && name.isNotEmpty) 'name': name.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // Check if email verification is required
        if (data['requireEmailVerification'] == true) {
          return AuthResult.emailVerificationRequired();
        }
        
        final token = data['accessToken'] as String?;
        if (token != null) {
          await _saveSession(token);
          return AuthResult.success(userId: _getUserIdFromToken(token));
        }
        return AuthResult.error('Account created but no token received');
      }
      
      return AuthResult.error('Failed to create account');
    } catch (e) {
      debugPrint('AUTH_DEBUG: Sign up error: $e');
      return AuthResult.error('Network error. Please try again.');
    }
  }

  Future<void> signOut() async {
    await clearSession();
  }

  // ─────────────────── Auto Token Refresh ───────────────────

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    // Refresh token every 15 minutes before it expires
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _refreshToken();
    });
  }

  Future<void> _refreshToken() async {
    if (_accessToken == null) return;
    
    try {
      // Check if token is about to expire (within 30 minutes)
      if (_shouldRefreshToken(_accessToken!)) {
        final url = Uri.parse('${AppConstants.insForgeUrl}/api/auth/sessions/current');
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final newToken = data['accessToken'] as String?;
          if (newToken != null) {
            await _saveSession(newToken);
            debugPrint('AUTH_DEBUG: Token refreshed successfully');
          }
        } else if (response.statusCode == 401) {
          // Token expired, clear session
          await clearSession();
        }
      }
    } catch (e) {
      debugPrint('AUTH_DEBUG: Token refresh error: $e');
    }
  }

  // ─────────────────── Token Utilities ───────────────────

  bool _isTokenValid(String token) {
    try {
      final exp = _getTokenExpiry(token);
      if (exp == null) return true;
      return DateTime.now().isBefore(exp.subtract(const Duration(minutes: 5)));
    } catch (_) {
      return false;
    }
  }

  bool _shouldRefreshToken(String token) {
    try {
      final exp = _getTokenExpiry(token);
      if (exp == null) return false;
      // Refresh if expires within 30 minutes
      return DateTime.now().isAfter(exp.subtract(const Duration(minutes: 30)));
    } catch (_) {
      return false;
    }
  }

  DateTime? _getTokenExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      String normalized = parts[1];
      switch (normalized.length % 4) {
        case 2: normalized += '=='; break;
        case 3: normalized += '='; break;
      }
      
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      final exp = payload['exp'] as int?;
      if (exp == null) return null;
      
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (_) {
      return null;
    }
  }

  String? getCurrentUserId() {
    if (_accessToken == null) return null;
    return _getUserIdFromToken(_accessToken!);
  }

  String? _getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      String normalized = parts[1];
      switch (normalized.length % 4) {
        case 2: normalized += '=='; break;
        case 3: normalized += '='; break;
      }
      
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      return payload['sub'] as String?;
    } catch (_) {
      return null;
    }
  }

  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_accessToken ?? AppConstants.insForgeAnonKey}',
    };
  }

  void dispose() {
    _refreshTimer?.cancel();
    _authStateController.close();
  }
}

// ─────────────────── Auth Result Class ───────────────────

class AuthResult {
  final bool success;
  final String? userId;
  final String? error;
  final bool emailVerificationRequired;

  AuthResult._({
    required this.success,
    this.userId,
    this.error,
    this.emailVerificationRequired = false,
  });

  factory AuthResult.success({required String? userId}) => 
    AuthResult._(success: true, userId: userId);
  
  factory AuthResult.error(String error) => 
    AuthResult._(success: false, error: error);
  
  factory AuthResult.emailVerificationRequired() => 
    AuthResult._(success: false, emailVerificationRequired: true);
}
