// lib/providers/language_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/language.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';

  final List<Language> supportedLanguages = [
    const Language(name: 'English', code: 'en', flag: '🇺🇸'),
    const Language(name: 'Español', code: 'es', flag: '🇪🇸'),
    const Language(name: 'Français', code: 'fr', flag: '🇫🇷'),
    const Language(name: 'Deutsch', code: 'de', flag: '🇩🇪'),
    const Language(name: 'Italiano', code: 'it', flag: '🇮🇹'),
    const Language(name: 'Português', code: 'pt', flag: '🇵🇹'),
    const Language(name: '日本語', code: 'ja', flag: '🇯🇵'),
    const Language(name: '한국어', code: 'ko', flag: '🇰🇷'),
    const Language(name: '中文', code: 'zh', flag: '🇨🇳'),
    const Language(name: 'العربية', code: 'ar', flag: '🇸🇦'),
  ];

  String _currentCode = 'en';
  bool _isLoading = false;

  String get currentCode => _currentCode;
  bool get isLoading => _isLoading;

  Language get currentLanguage => supportedLanguages.firstWhere(
        (lang) => lang.code == _currentCode,
        orElse: () => supportedLanguages.first,
      );

  LanguageProvider() {
    loadLanguage();
  }

  Future<void> loadLanguage() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _currentCode = prefs.getString(_languageKey) ?? 'en';

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (_currentCode != code) {
      _isLoading = true;
      notifyListeners();

      _currentCode = code;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, code);

      _isLoading = false;
      notifyListeners();
    }
  }
}
