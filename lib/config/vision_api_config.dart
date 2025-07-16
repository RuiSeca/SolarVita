// lib/config/vision_api_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class VisionApiConfig {
  static final Logger _logger = Logger();
  // Hybrid approach: try dart-define first, fallback to dotenv
  static String get apiKey {
    const dartDefine = String.fromEnvironment('GOOGLE_VISION_API_KEY');
    if (dartDefine.isNotEmpty) return dartDefine;
    
    // Fallback to dotenv for local development
    return dotenv.env['GOOGLE_VISION_API_KEY'] ?? '';
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
      _logger.e('GOOGLE_VISION_API_KEY is not set in .env file or dart-define');
      return false;
    }
    return true;
  }
}
