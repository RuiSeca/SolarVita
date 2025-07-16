// lib/config/nutritionix_api_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class NutritionixApiConfig {
  static final Logger _logger = Logger();
  // Hybrid approach: try dart-define first, fallback to dotenv
  static String get appId {
    const dartDefine = String.fromEnvironment('NUTRITIONIX_APP_ID');
    if (dartDefine.isNotEmpty) return dartDefine;
    
    // Fallback to dotenv for local development
    return dotenv.env['NUTRITIONIX_APP_ID'] ?? '';
  }
  static String get appKey {
    const dartDefine = String.fromEnvironment('NUTRITIONIX_APP_KEY');
    if (dartDefine.isNotEmpty) return dartDefine;
    
    // Fallback to dotenv for local development
    return dotenv.env['NUTRITIONIX_APP_KEY'] ?? '';
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
      _logger.e('NUTRITIONIX_APP_ID is not set in .env file or dart-define');
      return false;
    }
    if (appKey.isEmpty) {
      _logger.e('NUTRITIONIX_APP_KEY is not set in .env file or dart-define');
      return false;
    }
    return true;
  }

  // Debug helper for troubleshooting API credentials
  static void logKeyInfo() {
    if (appId.isNotEmpty) {
      _logger.d('App ID length: ${appId.length}');
      _logger.d(
          'App ID first/last chars: ${appId.substring(0, 2)}...${appId.substring(appId.length - 2)}');
    } else {
      _logger.e('App ID is empty!');
    }

    if (appKey.isNotEmpty) {
      _logger.d('App Key length: ${appKey.length}');
      _logger.d(
          'App Key first/last chars: ${appKey.substring(0, 2)}...${appKey.substring(appKey.length - 2)}');
    } else {
      _logger.e('App Key is empty!');
    }
  }
}
