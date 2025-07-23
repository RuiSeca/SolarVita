import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiApiConfig {
  // Hybrid approach: try dart-define first, fallback to dotenv
  static String get apiKey {
    const dartDefine = String.fromEnvironment('GEMINI_API_KEY');
    if (dartDefine.isNotEmpty) return dartDefine;
    
    // Fallback to dotenv for local development, but handle if not initialized
    try {
      if (dotenv.isInitialized) {
        return dotenv.env['GEMINI_API_KEY'] ?? '';
      }
    } catch (e) {
      // dotenv not initialized, using empty API key
    }
    return '';
  }

  // Validate API key at runtime
  static bool isConfigured() {
    if (apiKey.isEmpty) {
      return false;
    }
    return true;
  }

  // Debug helper for troubleshooting API credentials
  static void logKeyInfo() {
    // Debug logging removed
  }
}
