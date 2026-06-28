// ============================================================
//  UserProvider – MaaCare State Management (InsForge)
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/maacare_backend_service.dart';
import '../services/auth_service.dart';
import '../services/bmi_helper.dart';
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
        _user = await MaaCareBackendService.instance.fetchUser(userId);

        // 3. Auto-create profile for OAuth users who don't have a DB row yet
        if (_user == null) {
          final authUser = await MaaCareBackendService.instance.getCurrentUser();
          final fallbackName = authUser?['name'] as String? ??
              authUser?['email'] as String? ??
              'Mama';
          final defaultUser = UserModel(
            id: userId,
            name: fallbackName,
            email: authUser?['email'] as String?,
            userRole: '',
            points: 0,
            streak: 0,
            language: 'en',
            isPremium: false,
            trialUsesLeft: 10,
            createdAt: DateTime.now(),
          );
          await MaaCareBackendService.instance.upsertUser(defaultUser);
          _user = defaultUser;
        }
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
      await MaaCareBackendService.instance.upsertUser(user);
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
      await MaaCareBackendService.instance.updateMood(_user!.id, mood);
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
      await MaaCareBackendService.instance.updatePoints(_user!.id, newPoints);
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
      await MaaCareBackendService.instance.updatePremiumStatus(
        userId: _user!.id,
        isPremium: true,
        planName: planName,
        paymentId: paymentId,
      );
    } catch (_) {}
  }

  Future<void> updateTrialUses(int count) async {
    if (_user == null) return;
    final oldUses = _user!.trialUsesLeft;
    _user = _user!.copyWith(trialUsesLeft: count);
    notifyListeners();

    try {
      await MaaCareBackendService.instance.updateTrialUses(_user!.id, count);
    } catch (_) {
      _user = _user!.copyWith(trialUsesLeft: oldUses);
      notifyListeners();
    }
  }

  Future<void> decrementTrialUses() async {
    if (_user == null) return;
    final currentUses = _user!.trialUsesLeft;
    if (currentUses <= 0) return;
    final newUses = currentUses - 1;
    _user = _user!.copyWith(trialUsesLeft: newUses);
    notifyListeners();

    try {
      await MaaCareBackendService.instance.updateTrialUses(_user!.id, newUses);
    } catch (_) {
      _user = _user!.copyWith(trialUsesLeft: currentUses);
      notifyListeners();
    }
  }

  void updateUserLocally(UserModel user) {
    _user = user;
    notifyListeners();
  }

  Future<void> updateBmiMetrics({required double heightCm, required double weightKg}) async {
    if (_user == null) return;

    final bmiScore = BmiHelper.calculateBmi(heightCm: heightCm, weightKg: weightKg);
    final weightStatus = BmiHelper.getBmiStatus(bmiScore);

    final oldUser = _user;
    _user = _user!.copyWith(heightCm: heightCm, weightKg: weightKg);
    notifyListeners();

    try {
      await MaaCareBackendService.instance.updateBmiMetrics(
        userId: _user!.id,
        heightCm: heightCm,
        weightKg: weightKg,
      );
      if (bmiScore > 0) {
        await MaaCareBackendService.instance.logBmi(
          userId: _user!.id,
          bmiScore: bmiScore,
          weightStatus: weightStatus,
        );
      }
    } catch (e) {
      debugPrint('updateBmiMetrics provider error: $e');
      _user = oldUser;
      notifyListeners();
      rethrow;
    }
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
