// lib/config/vision_api_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VisionApiConfig {
  // Hybrid approach: try dart-define first, fallback to dotenv
  static String get apiKey {
    const dartDefine = String.fromEnvironment('GOOGLE_VISION_API_KEY');
    if (dartDefine.isNotEmpty) return dartDefine;
    
    // Fallback to dotenv for local development, but handle if not initialized
    try {
      if (dotenv.isInitialized) {
        return dotenv.env['GOOGLE_VISION_API_KEY'] ?? '';
      }
    } catch (e) {
      // dotenv not initialized, using empty Vision API key
    }
    return '';
  }
  static const String baseUrl =
      'https://vision.googleapis.com/v1/images:annotate';

  // Headers for API requests
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Get API URL with key
  static String get apiUrl => '$baseUrl?key=$apiKey';

  // Strict validation that will return false if API key is missing
  static bool isConfigured() {
    if (apiKey.isEmpty) {
      return false;
    }
    return true;
  }
}
