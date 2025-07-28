import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../config/google_maps_config.dart';

class GoogleMapsService {
  static const MethodChannel _channel = MethodChannel('com.solarvita.googlemaps');
  
  static Future<void> initialize() async {
    try {
      final apiKey = GoogleMapsConfig.apiKey;
      
      // For iOS, we need to pass the API key through method channel
      // For Android, it's handled through the AndroidManifest.xml placeholder
      await _channel.invokeMethod('setGoogleMapsApiKey', apiKey);
    } catch (e) {
      // Method channel might not be implemented on all platforms
      // This is expected for Android as we use AndroidManifest.xml
      if (kDebugMode) {
        debugPrint('Google Maps API key setup: $e');
      }
    }
  }
}