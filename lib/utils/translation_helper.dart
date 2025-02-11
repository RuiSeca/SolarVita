// translation_helper.dart
import 'package:flutter/material.dart';
import 'package:solar_vitas/i18n/app_localizations.dart';
import 'package:solar_vitas/utils/country_names.dart';

String tr(BuildContext context, String key) {
  return AppLocalizations.of(context)?.translate(key) ?? key;
}

String translateCountry(BuildContext context, String languageCode) {
  final currentLocale = Localizations.localeOf(context).languageCode;

  // First try to get the translation in the current locale
  final translation = countryNames[currentLocale]?[languageCode];
  if (translation != null) {
    return translation;
  }

  // Fallback to English if translation not found
  return countryNames['en']?[languageCode] ?? languageCode;
}
