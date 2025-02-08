// lib/l10n/app_localizations.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_localizations_delegate.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      AppLocalizationsDelegate();

  Map<String, String> _localizedStrings = {};

  Future<bool> load() async {
    try {
      // Changed the path to match asset structure
      String jsonString = await rootBundle
          .loadString('assets/i18n/${locale.languageCode}.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });

      return true;
    } catch (e) {
      print('Error loading language file: $e');
      // Initialize with empty map rather than failing
      _localizedStrings = {};
      return true;
    }
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}
