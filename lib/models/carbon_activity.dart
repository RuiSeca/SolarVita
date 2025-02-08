import 'package:flutter/material.dart';

class CarbonActivity {
  final String nameKey;
  final double co2Saved;
  final IconData icon;
  final DateTime date;

  const CarbonActivity({
    required this.nameKey,
    required this.co2Saved,
    required this.icon,
    required this.date,
  });
}
