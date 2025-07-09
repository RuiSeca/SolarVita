import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class GeminiApiConfig {
  static final Logger _logger = Logger();
  static final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  // Validate API key at runtime
  static bool isConfigured() {
    if (apiKey.isEmpty) {
      _logger.e('GEMINI_API_KEY is not set in .env file');
      return false;
    }
    return true;
  }

  // Debug helper for troubleshooting API credentials
  static void logKeyInfo() {
    if (apiKey.isNotEmpty) {
      _logger.d('Gemini API Key length: ${apiKey.length}');
      _logger.d(
          'Gemini API Key first/last chars: ${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}');
    } else {
      _logger.e('Gemini API Key is empty!');
    }
  }
}
