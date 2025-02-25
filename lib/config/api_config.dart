import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static final String rapidApiKey = dotenv.env['RAPID_API_KEY'] ?? '';
  static const String rapidApiHost = 'exercisedb.p.rapidapi.com';
  static const String baseUrl = 'https://exercisedb.p.rapidapi.com'; // Root URL

  static Map<String, String> get headers => {
        'X-RapidAPI-Key': rapidApiKey.trim(), // Trim to remove any whitespace
        'X-RapidAPI-Host': rapidApiHost,
      };

  // Validate API key at runtime
  static void validateApiKey() {
    if (rapidApiKey.isEmpty) {
      throw Exception('RAPID_API_KEY is not set in .env file');
    }
  }
}
