// ============================================================
//  LocaleProvider – MaaCare
//  Manages app language; persists choice to SharedPreferences
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  // Language display names → locale code
  static const Map<String, String> languageMap = {
    'English': 'en',
    'हिन्दी': 'hi',
    'অসমীয়া': 'as',
    'বাংলা': 'bn',
  };

  static const Map<String, String> codeToName = {
    'en': 'English',
    'hi': 'हिन्दी',
    'as': 'অসমীয়া',
    'bn': 'বাংলা',
  };

  String get currentLanguageName => codeToName[_locale.languageCode] ?? 'English';

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale_code') ?? 'en';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale_code', locale.languageCode);
  }

  Future<void> setLocaleByCode(String code) async {
    await setLocale(Locale(code));
  }
}
