// ============================================================
//  LocaleProvider – MaaCare (12 Indian Languages + English)
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  static const List<MaaLanguage> supportedLanguages = [
    MaaLanguage('en', 'English',    'English',    '🇬🇧'),
    MaaLanguage('hi', 'हिन्दी',     'Hindi',      '🇮🇳'),
    MaaLanguage('bn', 'বাংলা',      'Bengali',    '🇮🇳'),
    MaaLanguage('as', 'অসমীয়া',    'Assamese',   '🇮🇳'),
    MaaLanguage('ta', 'தமிழ்',      'Tamil',      '🇮🇳'),
    MaaLanguage('te', 'తెలుగు',     'Telugu',     '🇮🇳'),
    MaaLanguage('mr', 'मराठी',      'Marathi',    '🇮🇳'),
    MaaLanguage('gu', 'ગુજરાતી',    'Gujarati',   '🇮🇳'),
    MaaLanguage('kn', 'ಕನ್ನಡ',      'Kannada',    '🇮🇳'),
    MaaLanguage('ml', 'മലയാളം',     'Malayalam',  '🇮🇳'),
    MaaLanguage('pa', 'ਪੰਜਾਬੀ',     'Punjabi',    '🇮🇳'),
    MaaLanguage('or', 'ଓଡ଼ିଆ',      'Odia',       '🇮🇳'),
  ];

  static List<String> get supportedCodes =>
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toList();

  String get currentLanguageName =>
      supportedLanguages
          .firstWhere((l) => l.code == _locale.languageCode,
              orElse: () => supportedLanguages.first)
          .nativeName;

  MaaLanguage get currentLanguage =>
      supportedLanguages.firstWhere((l) => l.code == _locale.languageCode,
          orElse: () => supportedLanguages.first);

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale_code') ?? _systemLocaleCode();
    _locale = Locale(code);
    notifyListeners();
  }

  /// Auto-detect system locale, fallback to English
  String _systemLocaleCode() {
    final sys = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return supportedCodes.contains(sys) ? sys : 'en';
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale.languageCode == locale.languageCode) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale_code', locale.languageCode);
  }

  Future<void> setLocaleByCode(String code) async {
    await setLocale(Locale(code));
  }
}

/// Immutable language descriptor
class MaaLanguage {
  final String code;
  final String nativeName;
  final String englishName;
  final String flag;

  const MaaLanguage(this.code, this.nativeName, this.englishName, this.flag);
}
