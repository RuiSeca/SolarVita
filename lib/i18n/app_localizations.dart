import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  final Map<String, String> _localizedStrings = {};

  static const List<String> translationFiles = [
    'nav',
    'dashboard',
    'eco_tips',
    'welcome',
    'auth',
    'search',
    'health',
  ];

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      AppLocalizationsDelegate();

  Future<bool> load() async {
    try {
      for (String fileName in translationFiles) {
        final strings = await _loadJsonFile(fileName);
        _localizedStrings.addAll(strings);
      }
      return true;
    } catch (e) {
      debugPrint('Error loading language files: $e');
      return false;
    }
  }

  Future<Map<String, String>> _loadJsonFile(String fileName) async {
    try {
      final jsonString = await rootBundle.loadString(
          'assets/i18n/${locale.languageCode}/$fileName.json'); // Updated path
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      return jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });
    } catch (e) {
      debugPrint('Error loading $fileName.json: $e');
      return {};
    }
  }

  String translate(String key) {
    final String? value = _localizedStrings[key];
    if (value == null) {
      debugPrint('Missing translation for key: $key in ${locale.languageCode}');
      return key;
    }
    return value;
  }

  String translateWithParams(String key, Map<String, String> params) {
    String translation = translate(key);
    params.forEach((key, value) {
      translation = translation.replaceAll('{$key}', value);
    });
    return translation;
  }

  Map<String, String> getCategory(String category) {
    return Map.fromEntries(
      _localizedStrings.entries
          .where((entry) => entry.key.startsWith('$category.')),
    );
  }

  bool hasTranslation(String key) {
    return _localizedStrings.containsKey(key);
  }

  Set<String> get availableKeys => _localizedStrings.keys.toSet();

  String get languageCode => locale.languageCode;

  int get translationCount => _localizedStrings.length;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'pt'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
