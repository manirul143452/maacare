// ============================================================
//  AuthService – MaaCare Premium Authentication
//  SecureStorage, Auto Token Refresh, Persistent Sessions
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import 'secure_storage_service.dart';
import 'result.dart';
import 'api_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  String? _accessToken;
  Timer? _refreshTimer;
  final _authStateController = StreamController<bool>.broadcast();

  Stream<bool> get authStateChanges => _authStateController.stream;
  String? get accessToken => _accessToken;

  bool get isLoggedIn => _accessToken != null && !_isTokenExpired(_accessToken!);

  late final GoogleSignIn googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '360113998315-ivot5n0ilmblm505op3o9ug6sfcn9fqv.apps.googleusercontent.com' : null,
    serverClientId: kIsWeb ? null : '360113998315-ivot5n0ilmblm505op3o9ug6sfcn9fqv.apps.googleusercontent.com', 
  );

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
      if (token != null && !_isTokenExpired(token)) {
        // Load any non-expired token (even near-expiry) so refresh can be attempted
        _accessToken = token;
        _authStateController.add(true);
        debugPrint('AUTH_DEBUG: Valid session loaded from storage');
      } else if (token != null) {
        // Token is expired — try to refresh before clearing
        _accessToken = token;
        final refreshed = await _refreshToken();
        if (refreshed) {
           _authStateController.add(true);
           debugPrint('AUTH_DEBUG: Expired session recovered via refresh token');
        } else {
           _accessToken = null;
           await SecureStorageService.instance.delete('insforge_token');
           await SecureStorageService.instance.delete('insforge_refresh_token');
           _authStateController.add(false);
           debugPrint('AUTH_DEBUG: Stored token is expired and refresh failed, cleared');
        }
      } else {
        _accessToken = null;
        _authStateController.add(false);
        debugPrint('AUTH_DEBUG: No stored session found');
      }
    } catch (e) {
      debugPrint('AUTH_DEBUG: Error loading session: $e');
      _authStateController.add(_accessToken != null);
    }
  }

  Future<void> _saveSession(String token, {String? refreshToken}) async {
    _accessToken = token;
    await SecureStorageService.instance.write('insforge_token', token);
    if (refreshToken != null) {
      await SecureStorageService.instance.write('insforge_refresh_token', refreshToken);
    }
    _authStateController.add(true);
    _startAutoRefresh();
  }

  Future<void> clearSession() async {
    _accessToken = null;
    _refreshTimer?.cancel();
    await SecureStorageService.instance.delete('insforge_token');
    await SecureStorageService.instance.delete('insforge_refresh_token');
    _authStateController.add(false);
    debugPrint('AUTH_DEBUG: Session cleared');
  }

  // ─────────────────── Authentication ───────────────────

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {


    try {
      final url = Uri.parse('${AppConstants.backendUrl}/api/auth/sessions');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.backendAnonKey}',
        },
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
        }),
      );

      debugPrint('AUTH_DEBUG: signIn response ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final data = ApiService.safeDecode(response);
        final token = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        
        if (token != null) {
          await _saveSession(token, refreshToken: refreshToken);
          return AuthResult.success(userId: _getUserIdFromToken(token));
        }
        return AuthResult.error('No access token received');
      }
      
      // Return the actual server error message
      final errData = ApiService.safeDecode(response);
      final errorMsg = errData['error'] as String? ?? 'Invalid credentials';
      return AuthResult.error(errorMsg);
    } catch (e) {
      debugPrint('AUTH_DEBUG: Sign in error: $e');
      return AuthResult.error('Network error. Please try again.');
    }
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? name,
    required String userRole,
    String? medicalRegistrationNo,
    String? specialization,
    String? hospitalAffiliation,
  }) async {
    try {
      // Use Railway Express backend for signup
      final url = Uri.parse('${AppConstants.backendUrl}/api/auth/users');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.backendAnonKey}',
        },
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
          if (name != null && name.isNotEmpty) 'name': name.trim(),
          'user_role': userRole,
          if (medicalRegistrationNo != null && medicalRegistrationNo.isNotEmpty)
            'medical_registration_no': medicalRegistrationNo.trim(),
          if (specialization != null && specialization.isNotEmpty)
            'specialization': specialization.trim(),
          if (hospitalAffiliation != null && hospitalAffiliation.isNotEmpty)
            'hospital_affiliation': hospitalAffiliation.trim(),
        }),
      );

      debugPrint('AUTH_DEBUG: signUp response ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = ApiService.safeDecode(response);
        // Railway returns { accessToken, refreshToken } directly — no nested 'data'
        final token = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        if (token != null) {
          await _saveSession(token, refreshToken: refreshToken);
          return AuthResult.success(userId: _getUserIdFromToken(token));
        }
        return AuthResult.error('Account created but no token received');
      }
      
      final errData = ApiService.safeDecode(response);
      final errorMsg = errData['error'] as String? ?? 'Failed to create account';
      return AuthResult.error(errorMsg);
    } catch (e) {
      debugPrint('AUTH_DEBUG: Sign up error: $e');
      return AuthResult.error('Network error. Please try again.');
    }
  }

  // ─────────────────── Password Recovery ───────────────────

  /// Send password reset code to user's email
  Future<AuthResult> sendResetPasswordEmail({required String email}) async {
    try {
      final url = Uri.parse('${AppConstants.backendUrl}/api/auth/email/send-reset-password');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.backendAnonKey}',
        },
        body: jsonEncode({
          'email': email.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResult.success(userId: null);
      }
      final data = ApiService.safeDecode(response);
      return AuthResult.error(data['message'] ?? 'Failed to send reset email');
    } catch (e) {
      debugPrint('AUTH_DEBUG: sendResetPasswordEmail error: $e');
      return AuthResult.error('Network error. Please try again.');
    }
  }

  /// Exchange 6-digit OTP code for a temporary reset token
  Future<Result<String>> exchangeResetPasswordToken({
    required String email,
    required String code,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.backendUrl}/api/auth/email/exchange-reset-password-token');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.backendAnonKey}',
        },
        body: jsonEncode({
          'email': email.trim(),
          'code': code.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = ApiService.safeDecode(response);
        final token = data['token'] as String?;
        if (token != null) {
          return Result.success(token);
        }
      }
      final data = ApiService.safeDecode(response);
      return Result.failure(data['message'] ?? 'Failed to exchange reset token');
    } catch (e) {
      debugPrint('AUTH_DEBUG: exchangeResetPasswordToken error: $e');
      return Result.failure('Network error. Please try again.');
    }
  }

  /// Finalize password reset using the token and new password
  Future<AuthResult> resetPassword({
    required String newPassword,
    required String token,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.backendUrl}/api/auth/email/reset-password');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.backendAnonKey}',
        },
        body: jsonEncode({
          'newPassword': newPassword.trim(),
          'otp': token.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResult.success(userId: null);
      }
      final data = ApiService.safeDecode(response);
      return AuthResult.error(data['message'] ?? 'Failed to reset password');
    } catch (e) {
      debugPrint('AUTH_DEBUG: resetPassword error: $e');
      return AuthResult.error('Network error. Please try again.');
    }
  }

  Future<void> signOut() async {
    // Also disconnect Google Sign In if active
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {}
    
    await clearSession();
  }

  // ─────────────────── OAuth Sign In ───────────────────

  /// Google OAuth Sign In
  Future<AuthResult> signInWithGoogle() async {
    if (kIsWeb) {
      debugPrint('AUTH_DEBUG: Starting Web Google Sign In via GoogleSignIn package...');
      try {
        // Use GoogleSignIn package directly — opens real Google popup on web
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          return AuthResult.error('Google sign-in cancelled');
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Send Google credentials to our backend to get a JWT
        final response = await http.post(
          Uri.parse('${AppConstants.backendUrl}/api/auth/google/token'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'idToken': googleAuth.idToken,
            'email': googleUser.email,
            'name': googleUser.displayName,
            'photoUrl': googleUser.photoUrl,
            'googleId': googleUser.id,
          }),
        );

        if (response.statusCode == 200) {
          final data = ApiService.safeDecode(response);
          final token = data['accessToken'] as String?;
          final refreshToken = data['refreshToken'] as String?;
          if (token != null) {
            await _saveSession(token, refreshToken: refreshToken);
            debugPrint('AUTH_DEBUG: Google web login successful for ${googleUser.email}');
            return AuthResult.success(userId: _getUserIdFromToken(token));
          }
        }
        debugPrint('AUTH_DEBUG: Backend token exchange failed: ${response.statusCode} ${response.body}');
        return AuthResult.error('Login failed. Please try again.');
      } catch (e) {
        debugPrint('AUTH_DEBUG: Google web sign-in error: $e');
        return AuthResult.error('Google sign-in error: $e');
      }
    }
    // Android / iOS — use browser-based PKCE flow (no Firebase needed)
    debugPrint('AUTH_DEBUG: Starting Native Google Sign In via PKCE...');
    await initiateOAuthFlowNative('google');
    return AuthResult.error('Redirecting to Google...'); // Browser opens
  }

  /// Android/iOS PKCE OAuth flow — opens browser, returns via deep link maacare://auth/callback
  Future<void> initiateOAuthFlowNative(String provider) async {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    final codeVerifier = List.generate(64, (_) => charset[random.nextInt(charset.length)]).join();

    await SecureStorageService.instance.write('oauth_code_verifier', codeVerifier);

    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    final codeChallenge = base64UrlEncode(digest.bytes).replaceAll('=', '');

    const redirectUri = 'maacare://auth/callback';

    final authUrl = Uri.parse('${AppConstants.backendUrl}/api/auth/oauth/$provider')
        .replace(queryParameters: {
      'redirect_uri': redirectUri,
      'code_challenge': codeChallenge,
      'code_challenge_method': 's256',
    });

    try {
      final response = await http.get(authUrl);
      if (response.statusCode == 200) {
        final data = ApiService.safeDecode(response);
        final targetUrl = data['authUrl'] as String?;
        if (targetUrl != null) {
          final uriToLaunch = Uri.parse(targetUrl);
          if (await canLaunchUrl(uriToLaunch)) {
            await launchUrl(uriToLaunch, mode: LaunchMode.externalApplication);
          }
        } else {
          debugPrint('AUTH_DEBUG: No authUrl in response');
        }
      } else {
        debugPrint('AUTH_DEBUG: Failed OAuth init, status: ${response.statusCode}, body: ${response.body}');
      }
    } catch (e) {
      debugPrint('AUTH_DEBUG: Error initiating native OAuth: $e');
    }
  }

  /// Web-specific PKCE OAuth Flow Initiation
  Future<void> initiateOAuthFlowWeb(String provider) async {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    final codeVerifier = List.generate(64, (_) => charset[random.nextInt(charset.length)]).join();
    
    await SecureStorageService.instance.write('oauth_code_verifier', codeVerifier);

    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    final codeChallenge = base64UrlEncode(digest.bytes).replaceAll('=', '');

    final currentUrl = Uri.base.toString();
    final redirectUri = currentUrl.split('#')[0].split('?')[0];

    final authUrl = Uri.parse('${AppConstants.backendUrl}/api/auth/oauth/$provider')
        .replace(queryParameters: {
      'redirect_uri': redirectUri,
      'code_challenge': codeChallenge,
      'code_challenge_method': 's256',
    });

    try {
      final response = await http.get(authUrl);
      if (response.statusCode == 200) {
        final data = ApiService.safeDecode(response);
        final targetUrl = data['authUrl'] as String?;
        if (targetUrl != null) {
          final uriToLaunch = Uri.parse(targetUrl);
          if (await canLaunchUrl(uriToLaunch)) {
            await launchUrl(uriToLaunch, webOnlyWindowName: '_self');
          }
        } else {
          debugPrint('AUTH_DEBUG: No authUrl found in response');
        }
      } else {
        debugPrint('AUTH_DEBUG: Failed to get OAuth URL, status: ${response.statusCode}, body: ${response.body}');
      }
    } catch (e) {
      debugPrint('AUTH_DEBUG: Error initiating OAuth flow: $e');
    }
  }

  /// Web-specific callback handler for OAuth Code Exchange
  Future<AuthResult> exchangeOAuthCodeWeb(String code) async {
    try {
      final codeVerifier = await SecureStorageService.instance.read('oauth_code_verifier');
      if (codeVerifier == null) return AuthResult.error('No code verifier found in storage');

      final url = Uri.parse('${AppConstants.backendUrl}/api/auth/oauth/exchange?client_type=web');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.backendAnonKey}',
        },
        body: jsonEncode({
          'code': code,
          'code_verifier': codeVerifier,
        }),
      );

      if (response.statusCode == 200) {
        final data = ApiService.safeDecode(response);
        final token = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        
        if (token != null) {
          await _saveSession(token, refreshToken: refreshToken);
          await SecureStorageService.instance.delete('oauth_code_verifier');
          return AuthResult.success(userId: _getUserIdFromToken(token));
        }
      }
      return AuthResult.error('Failed to exchange code');
    } catch (e) {
      debugPrint('AUTH_DEBUG: Exchange error: $e');
      return AuthResult.error('Network exception: $e');
    }
  }
  
  /// Public wrapper to save session directly when token is extracted from URL fragment
  Future<void> saveSessionWeb(String accessToken, {String? refreshToken}) async {
    await _saveSession(accessToken, refreshToken: refreshToken);
  }

  /// Apple OAuth Sign In
  Future<AuthResult> signInWithApple() async {
    try {
      // Trigger Native Apple Sign In
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String? idToken = credential.identityToken;

      if (idToken == null) {
         return AuthResult.error('Failed to retrieve Apple Identity Token');
      }

      // Authenticate with InsForge Backend
      return await _insForgeOAuthLogin('apple', idToken);

    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
         return AuthResult.error('Sign in canceled by user');
      }
      return AuthResult.error('Apple Sign-In failed. Please try again.');
    } catch (e) {
      debugPrint('AUTH_DEBUG: Apple Sign In Error: $e');
      return AuthResult.error('Network error. Please try again.');
    }
  }

  /// Helper to send OAuth ID tokens to InsForge
  Future<AuthResult> _insForgeOAuthLogin(String provider, String idToken) async {
    try {
      // Endpoint to exchange OAuth ID token for an InsForge session
      final url = Uri.parse('${AppConstants.backendUrl}/api/auth/token?grant_type=id_token');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.backendAnonKey}',
        },
        body: jsonEncode({
          'provider': provider,
          'id_token': idToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = ApiService.safeDecode(response);
        final token = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        
        if (token != null) {
          await _saveSession(token, refreshToken: refreshToken);
          return AuthResult.success(userId: _getUserIdFromToken(token));
        }
        return AuthResult.error('Authentication succeeded but no access token received.');
      }
      
      debugPrint('AUTH_DEBUG: InsForge OAuth failed: ${response.body}');
      return AuthResult.error('Server error during authentication.');
    } catch (e) {
      debugPrint('AUTH_DEBUG: InsForge OAuth network error: $e');
      return AuthResult.error('Network connection failed: $e');
    }
  }

  // ─────────────────── Session Restore (for Splash Screen) ───────────────────

  Future<bool> restoreSession() async {
    if (_accessToken != null && !_isTokenExpired(_accessToken!)) {
      debugPrint('AUTH_DEBUG: restoreSession – in-memory token is valid');
      return true;
    }

    await _loadSession();
    if (_accessToken == null) {
      debugPrint('AUTH_DEBUG: restoreSession – no stored session');
      return false;
    }

    if (_shouldRefreshToken(_accessToken!)) {
      debugPrint('AUTH_DEBUG: restoreSession – token near expiry, refreshing...');
      await _refreshToken();
    }

    final valid = _accessToken != null && !_isTokenExpired(_accessToken!);
    debugPrint('AUTH_DEBUG: restoreSession – final result: $valid');
    return valid;
  }

  // ─────────────────── Auto Token Refresh ───────────────────

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _refreshToken();
    });
  }

  Future<bool> _refreshToken() async {
    if (_accessToken == null) return false;
    
    try {
      final storedRefreshToken = await SecureStorageService.instance.read('insforge_refresh_token');
      
      if (storedRefreshToken != null) {
        // Refresh token via proper endpoint
        final url = Uri.parse('${AppConstants.backendUrl}/api/auth/token?grant_type=refresh_token');
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AppConstants.backendAnonKey}',
          },
          body: jsonEncode({
            'refresh_token': storedRefreshToken,
          }),
        );

        if (response.statusCode == 200) {
          final data = ApiService.safeDecode(response);
          final newToken = data['accessToken'] as String?;
          final newRefreshToken = data['refreshToken'] as String?;
          if (newToken != null) {
            await _saveSession(newToken, refreshToken: newRefreshToken);
            debugPrint('AUTH_DEBUG: Token refreshed successfully via refresh_token');
            return true;
          }
        }
      }
      
      // Fallback: try to refresh using current session endpoint if refresh_token failed/missing
      if (_shouldRefreshToken(_accessToken!)) {
        final url = Uri.parse('${AppConstants.backendUrl}/api/auth/sessions/current');
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        );

        if (response.statusCode == 200) {
          final data = ApiService.safeDecode(response);
          final newToken = data['accessToken'] as String?;
          if (newToken != null) {
            await _saveSession(newToken);
            debugPrint('AUTH_DEBUG: Token refreshed successfully via sessions/current');
            return true;
          }
        } else if (response.statusCode == 401) {
          await clearSession();
          return false;
        }
      }
    } catch (e) {
      debugPrint('AUTH_DEBUG: Token refresh error: $e');
    }
    return false;
  }

  // ─────────────────── Token Utilities ───────────────────

  /// Returns true if the token is fully expired (past expiry, no grace period).
  bool _isTokenExpired(String token) {
    try {
      // Reject forged/unsigned mock tokens immediately
      final parts = token.split('.');
      if (parts.length == 3 && parts[2] == 'mock_signature') return true;
      final exp = _getTokenExpiry(token);
      if (exp == null) return true; // No expiry claim → treat as expired (fail safe)
      return DateTime.now().isAfter(exp);
    } catch (_) {
      return true; // On parse error → fail safe, force re-login
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
      // Railway backend signs with { id, email } — 'sub' is not set.
      // Try 'id' first, then fall back to 'sub' for any other provider.
      return (payload['id'] ?? payload['sub']) as String?;
    } catch (_) {
      return null;
    }
  }

  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_accessToken ?? AppConstants.backendAnonKey}',
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
