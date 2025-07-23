// lib/config/nutritionix_api_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NutritionixApiConfig {
  // Hybrid approach: try dart-define first, fallback to dotenv
  static String get appId {
    const dartDefine = String.fromEnvironment('NUTRITIONIX_APP_ID');
    if (dartDefine.isNotEmpty) return dartDefine;
    
    // Fallback to dotenv for local development, but handle if not initialized
    try {
      if (dotenv.isInitialized) {
        return dotenv.env['NUTRITIONIX_APP_ID'] ?? '';
      }
    } catch (e) {
      // dotenv not initialized, using empty Nutritionix app ID
    }
    return '';
  }
  static String get appKey {
    const dartDefine = String.fromEnvironment('NUTRITIONIX_APP_KEY');
    if (dartDefine.isNotEmpty) return dartDefine;
    
    // Fallback to dotenv for local development, but handle if not initialized
    try {
      if (dotenv.isInitialized) {
        return dotenv.env['NUTRITIONIX_APP_KEY'] ?? '';
      }
    } catch (e) {
      // dotenv not initialized, using empty Nutritionix app key
    }
    return '';
  }
  static const String baseUrl = 'https://trackapi.nutritionix.com/v2';

  // Headers for API requests
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'x-app-id': appId,
        'x-app-key': appKey,
      };

  // Validation for API credentials
  static bool isConfigured() {
    if (appId.isEmpty) {
      return false;
    }
    if (appKey.isEmpty) {
      return false;
    }
    return true;
  }

  // Debug helper for troubleshooting API credentials
  static void logKeyInfo() {
    // Debug logging removed
  }
}
