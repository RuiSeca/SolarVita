import 'dart:io';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/languages/language.dart';

part 'language_provider.g.dart';

@riverpod
List<Language> supportedLanguages(Ref ref) {
  return const [
    Language(name: 'English', code: 'en', flag: ''),
    Language(name: 'Español', code: 'es', flag: ''),
    Language(name: 'Français', code: 'fr', flag: ''),
    Language(name: 'Deutsch', code: 'de', flag: ''),
    Language(name: 'Italiano', code: 'it', flag: ''),
    Language(name: 'Português', code: 'pt', flag: ''),
    Language(name: 'Русский', code: 'ru', flag: ''),
    Language(name: '日本語', code: 'ja', flag: ''),
    Language(name: '中文 (Traditional)', code: 'zh', flag: ''),
    Language(name: 'हिन्दी', code: 'hi', flag: ''),
    Language(name: '한국어', code: 'ko', flag: ''),
  ];
}

@riverpod
class LanguageNotifier extends _$LanguageNotifier {
  static const String _languageKey = 'selected_language';

  @override
  Future<Locale> build() async {
    return await _loadLanguage();
  }

  Future<Locale> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString(_languageKey);

      // If user has manually selected a language, use it
      if (savedLanguageCode != null) {
        return Locale(savedLanguageCode);
      }

      // Otherwise, auto-detect from system locale
      return _detectSystemLanguage();
    } catch (e) {
      return const Locale('en');
    }
  }

  Locale _detectSystemLanguage() {
    try {
      // Get system locale
      final systemLocale = Platform.localeName; // e.g., "en_US", "pt_BR", "fr_FR"
      final languageCode = systemLocale.split('_')[0]; // Extract just the language part

      // Check if we support this language
      final supportedCodes = [
        'en', 'es', 'fr', 'de', 'it', 'pt', 'ru', 'ja', 'zh', 'hi', 'ko'
      ];

      if (supportedCodes.contains(languageCode)) {
        debugPrint('🌍 Auto-detected system language: $languageCode (from $systemLocale)');
        return Locale(languageCode);
      } else {
        debugPrint('🌍 System language $languageCode not supported, falling back to English');
        return const Locale('en');
      }
    } catch (e) {
      debugPrint('🌍 Error detecting system language: $e, falling back to English');
      return const Locale('en');
    }
  }

  Future<void> setLanguage(String code) async {
    // Update state optimistically
    state = AsyncValue.data(Locale(code));

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, code);
      debugPrint('🌍 Language manually set to: $code');
    } catch (e) {
      // Revert on error
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> resetToSystemLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_languageKey);

      // Reload language (will auto-detect system)
      final systemLocale = _detectSystemLanguage();
      state = AsyncValue.data(systemLocale);
      debugPrint('🌍 Language reset to system language: ${systemLocale.languageCode}');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

@riverpod
Language currentLanguage(Ref ref) {
  final localeAsync = ref.watch(languageNotifierProvider);
  final supportedLangs = ref.watch(supportedLanguagesProvider);

  return localeAsync.when(
    data: (locale) => supportedLangs.firstWhere(
      (lang) => lang.code == locale.languageCode,
      orElse: () => supportedLangs.first,
    ),
    loading: () => supportedLangs.first,
    error: (_, __) => supportedLangs.first,
  );
}
