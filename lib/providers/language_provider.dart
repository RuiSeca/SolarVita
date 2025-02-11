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
  ];

  Locale _locale = const Locale('en');
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  Locale get locale => _locale;

  Language get currentLanguage => supportedLanguages.firstWhere(
        (lang) => lang.code == _locale.languageCode,
        orElse: () => supportedLanguages.first,
      );

  LanguageProvider() {
    loadLanguage();
  }

  Future<void> loadLanguage() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      String languageCode = prefs.getString(_languageKey) ?? 'en';
      _locale = Locale(languageCode);
    } catch (e) {
      debugPrint('Error loading language: $e');
      _locale = const Locale('en');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (_locale.languageCode != code) {
      _isLoading = true;
      notifyListeners();

      // Save the new language code
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, code);

      // Update the locale
      _locale = Locale(code);

      _isLoading = false;
      notifyListeners();
    }
  }
}
