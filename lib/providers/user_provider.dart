// ============================================================
//  UserProvider – MaaCare State Management (InsForge)
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/insforge_service.dart';
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
    // In InsForge REST, we might store the user ID in prefs upon login
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    if (userId == null) return;

    _setLoading(true);
    try {
      _user = await InsForgeService.instance.fetchUser(userId);
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
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateMood(String mood) async {
    if (_user == null) return;
    _user = _user!.copyWith(mood: mood);
    notifyListeners();

    try {
      await InsForgeService.instance.updateMood(_user!.id, mood);
      // Award mood points
      await addPoints(AppConstants.pointsPerMoodCheck);
    } catch (_) {}
  }

  Future<void> addPoints(int points) async {
    if (_user == null) return;
    final newPoints = _user!.points + points;
    _user = _user!.copyWith(points: newPoints);
    notifyListeners();

    try {
      await InsForgeService.instance.updatePoints(_user!.id, newPoints);
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
}
