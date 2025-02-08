// lib/utils/translation_helper.dart
import 'package:flutter/material.dart';
import 'package:solar_vitas/i18n/app_localizations.dart'; // Use relative path

String tr(BuildContext context, String key) {
  return AppLocalizations.of(context)?.translate(key) ?? key;
}
