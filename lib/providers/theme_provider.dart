// ============================================================
//  ThemeProvider – MaaCare
//  Manages dark/light/pink theme; persists to SharedPreferences
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MaaThemeMode { dark, light, pink }

class ThemeProvider extends ChangeNotifier {
  MaaThemeMode _themeMode = MaaThemeMode.dark;

  MaaThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == MaaThemeMode.dark;
  bool get isPink => _themeMode == MaaThemeMode.pink;
  bool get isLight => _themeMode == MaaThemeMode.light;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode') ?? 'dark';
    _themeMode = _modeFromString(saved);
    notifyListeners();
  }

  Future<void> setThemeMode(MaaThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _modeToString(mode));
  }

  void toggleDark() {
    if (_themeMode == MaaThemeMode.dark) {
      setThemeMode(MaaThemeMode.light);
    } else {
      setThemeMode(MaaThemeMode.dark);
    }
  }

  String _modeToString(MaaThemeMode mode) {
    switch (mode) {
      case MaaThemeMode.dark:
        return 'dark';
      case MaaThemeMode.light:
        return 'light';
      case MaaThemeMode.pink:
        return 'pink';
    }
  }

  MaaThemeMode _modeFromString(String s) {
    switch (s) {
      case 'light':
        return MaaThemeMode.light;
      case 'pink':
        return MaaThemeMode.pink;
      default:
        return MaaThemeMode.dark;
    }
  }
}
