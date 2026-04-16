// ============================================================
//  UserProvider – MaaCare State Management (InsForge)
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/insforge_service.dart';
import '../services/auth_service.dart';
import '../constants.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<void> loadUser() async {
    _setLoading(true);
    try {
      // 1. Get current user ID from AuthService (SecureStorage)
      final userId = AuthService.instance.getCurrentUserId();
      
      if (userId != null) {
        // 2. Fetch profile from database
        _user = await InsForgeService.instance.fetchUser(userId);
      } else {
        _user = null;
      }
      _error = null;
    } catch (e) {
      _error = 'Could not load profile. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createOrUpdateUser(UserModel user) async {
    _setLoading(true);
    try {
      await InsForgeService.instance.upsertUser(user);
      _user = user;
      _error = null;

      // Cache onboarding completion and ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      await prefs.setString('user_id', user.id);
      await prefs.setString('user_name', user.name);
    } catch (e) {
      _error = 'Could not save profile. Please try again.';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateMood(String mood) async {
    if (_user == null) return;
    final oldMood = _user!.mood;
    _user = _user!.copyWith(mood: mood);
    notifyListeners();

    try {
      await InsForgeService.instance.updateMood(_user!.id, mood);
      // Award mood points
      await addPoints(AppConstants.pointsPerMoodCheck);
    } catch (_) {
      // Soft rollback
      _user = _user!.copyWith(mood: oldMood);
      notifyListeners();
    }
  }

  Future<void> addPoints(int points) async {
    if (_user == null) return;
    final oldPoints = _user!.points;
    final newPoints = oldPoints + points;
    _user = _user!.copyWith(points: newPoints);
    notifyListeners();

    try {
      await InsForgeService.instance.updatePoints(_user!.id, newPoints);
    } catch (_) {
      // Soft rollback
      _user = _user!.copyWith(points: oldPoints);
      notifyListeners();
    }
  }

  Future<void> markPremium({required String planName, required String paymentId}) async {
    if (_user == null) return;
    _user = _user!.copyWith(isPremium: true, premiumPlan: planName);
    notifyListeners();

    try {
      await InsForgeService.instance.updatePremiumStatus(
        userId: _user!.id,
        isPremium: true,
        planName: planName,
        paymentId: paymentId,
      );
    } catch (_) {}
  }

  void updateUserLocally(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> signOut() async {
    await AuthService.instance.signOut();
    _user = null;
    notifyListeners();
  }
}
