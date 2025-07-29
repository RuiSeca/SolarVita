// GoogleMapsConfig - DEPRECATED
// This config is no longer used since we replaced Google Maps with lightweight fitness tracker
// Keeping commented for reference in case future reversion is needed

/*
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleMapsConfig {
  static String get apiKey {
    final key = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GOOGLE_MAPS_API_KEY not found in .env file');
    }
    return key;
  }
}
*/