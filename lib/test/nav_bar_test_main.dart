import 'package:flutter/material.dart';
import 'package:solar_vitas/screens/common/nav_bar_test_screen.dart';
import 'package:solar_vitas/theme/app_theme.dart';

/// Standalone test app for the futuristic navigation bar
/// Run this with: flutter run lib/test/nav_bar_test_main.dart
void main() {
  runApp(const NavBarTestApp());
}

class NavBarTestApp extends StatelessWidget {
  const NavBarTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Futuristic Nav Bar Test',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Start in light mode to match the design
      home: const NavBarTestScreen(),
    );
  }
}
