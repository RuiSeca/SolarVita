import 'package:flutter_dotenv/flutter_dotenv.dart';

class MealDBApiConfig {
  static String get apiKey {
    final key = dotenv.env['MEALDB_API_KEY'];
    if (key == null || key.isEmpty) {
      // Fallback to hardcoded key if not in .env
      return '65232507';
    }
    return key;
  }

  static String get baseUrl => 'https://www.themealdb.com/api/json/v2/$apiKey';
  
  // Test the exact URL structure from the email
  static String get testUrl => 'https://www.themealdb.com/api/json/v2/65232507/latest.php';
}