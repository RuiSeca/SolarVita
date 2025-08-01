import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/languages/language.dart';

part 'language_provider.g.dart';

@riverpod
List<Language> supportedLanguages(Ref ref) {
  return const [
    Language(name: 'English', code: 'en', flag: '🇺🇸'),
    Language(name: 'Español', code: 'es', flag: '🇪🇸'),
    Language(name: 'Français', code: 'fr', flag: '🇫🇷'),
    Language(name: 'Deutsch', code: 'de', flag: '🇩🇪'),
    Language(name: 'Italiano', code: 'it', flag: '🇮🇹'),
    Language(name: 'Português', code: 'pt', flag: '🇵🇹'),
    Language(name: '日本語', code: 'ja', flag: '🇯🇵'),
    Language(name: '한국어', code: 'ko', flag: '🇰🇷'),
    Language(name: '中文', code: 'zh', flag: '🇨🇳'),
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
      final languageCode = prefs.getString(_languageKey) ?? 'en';
      return Locale(languageCode);
    } catch (e) {
      return const Locale('en');
    }
  }

  Future<void> setLanguage(String code) async {
    // Update state optimistically
    state = AsyncValue.data(Locale(code));

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, code);
    } catch (e) {
      // Revert on error
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
