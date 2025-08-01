import 'package:flutter/material.dart';

class SettingsItem {
  final IconData icon;
  final String title;
  final String? value;
  final Widget Function(BuildContext) onTapScreen;

  SettingsItem({
    required this.icon,
    required this.title,
    this.value,
    required this.onTapScreen,
  });
}
