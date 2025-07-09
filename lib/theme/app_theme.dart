import 'package:flutter/material.dart';

class AppColors {
  // Base colors
  static const primary = Colors.green;
  static const white = Colors.white;
  static const black = Colors.black;
  static const red = Colors.red;
  static const iconBackground = Color(0xFFE6F4EA); // Light green background
  static const textFieldLight = Color(0xFFF5F5F5);
  static const textFieldDark = Color(0xFF2C2C2C);
  static const bubbleLight = Color(0xFFE6F4EA);
  static const bubbleDark = Color(0xFF1E1E1E);
  static const cardLight = Color(0xFFF5F5F5);
  static const cardDark = Color(0xFF1E1E1E);
  static const grey = Color(0x8E222121); // Cinza claro com opacidade 40%
  static const gold = Color(0xFFFFD700); // Gold color added
  static const cream = Color(0xFFFFFDD0);
}

class AppTheme {
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color isAchievementsUnlocked(BuildContext context) {
    return isDarkMode(context) ? AppColors.gold : AppColors.gold;
  }

  static Color textColor(BuildContext context) {
    return isDarkMode(context) ? AppColors.white : AppColors.black;
  }

  static Color surfaceColor(BuildContext context) {
    return isDarkMode(context) ? Colors.black : Colors.white;
  }

  static Color messageBubbleAI(BuildContext context) {
    return isDarkMode(context) ? AppColors.bubbleDark : AppColors.bubbleLight;
  }

  static Color textFieldBackground(BuildContext context) {
    return isDarkMode(context)
        ? AppColors.textFieldDark
        : AppColors.textFieldLight;
  }

  static Color cardColor(BuildContext context) {
    return isDarkMode(context) ? AppColors.cardDark : AppColors.cardLight;
  }

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.grey,
        onSurface: AppColors.white,
        onPrimary: AppColors.white,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        surface: Colors.white,
        onSurface: AppColors.black,
        onPrimary: AppColors.white,
      ),
    );
  }
}
