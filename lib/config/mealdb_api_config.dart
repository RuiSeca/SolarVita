import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class MealDBApiConfig {
  static final Logger _logger = Logger();
  
  static String get apiKey {
    // Try dart-define first
    const dartDefine = String.fromEnvironment('MEALDB_API_KEY');
    if (dartDefine.isNotEmpty) return dartDefine;
    
    // Fallback to dotenv for local development, but handle if not initialized
    try {
      if (dotenv.isInitialized) {
        final key = dotenv.env['MEALDB_API_KEY'];
        if (key != null && key.isNotEmpty) return key;
      }
    } catch (e) {
      _logger.w('dotenv not initialized, using hardcoded MealDB API key: $e');
    }
    
    // Final fallback to hardcoded key
    return '65232507';
  }

  static String get baseUrl => 'https://www.themealdb.com/api/json/v2/$apiKey';
  
  // Test the exact URL structure from the email
  static String get testUrl => 'https://www.themealdb.com/api/json/v2/65232507/latest.php';
}