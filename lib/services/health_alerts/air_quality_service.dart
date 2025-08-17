import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'health_alert_models.dart';

class AirQualityService {
  static final Logger _logger = Logger();
  
  // Get API key from environment variables
  static String get _apiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? 'YOUR_OPENWEATHER_API_KEY';
  static const String _baseUrl = 'http://api.openweathermap.org/data/2.5';
  
  static Future<AirQualityData> getAirQuality() async {
    try {
      return await _getOpenWeatherAirPollution();
    } catch (e) {
      _logger.e('Air quality API failed: $e');
      return AirQualityData.defaultSafe();
    }
  }
  
  static Future<AirQualityData> _getOpenWeatherAirPollution() async {
    final position = await _getCurrentLocation();
    
    // Get location name from weather API first
    String? city, country;
    try {
      final weatherResponse = await http.get(
        Uri.parse(
          '$_baseUrl/weather'
          '?lat=${position.latitude}'
          '&lon=${position.longitude}'
          '&appid=$_apiKey'
        ),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 5));
      
      if (weatherResponse.statusCode == 200) {
        final weatherData = json.decode(weatherResponse.body);
        city = weatherData['name'] as String?;
        country = weatherData['sys']?['country'] as String?;
      }
    } catch (e) {
      _logger.w('Failed to get location name from weather API: $e');
    }
    
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/air_pollution'
        '?lat=${position.latitude}'
        '&lon=${position.longitude}'
        '&appid=$_apiKey'
      ),
      headers: {'Accept': 'application/json'},
    ).timeout(Duration(seconds: 10));
    
    if (response.statusCode != 200) {
      throw Exception('OpenWeather Air Pollution API returned ${response.statusCode}');
    }
    
    final data = json.decode(response.body);
    return AirQualityData.fromOpenWeatherAirPollution(
      data,
      city: city,
      country: country,
    );
  }
  
  static Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );
  }
  
  // Test method for development
  static Future<AirQualityData> getMockAirQualityData({int? mockAQI}) async {
    await Future.delayed(Duration(seconds: 1));
    
    return AirQualityData(
      aqi: mockAQI ?? 45, // Good air quality
      pollutants: {
        'pm2_5': 12.0,
        'pm10': 20.0,
        'no2': 15.0,
        'o3': 80.0,
        'so2': 5.0,
        'co': 200.0,
      },
      source: 'Mock Data',
      timestamp: DateTime.now(),
      city: 'Mock City',
      country: 'MC',
    );
  }
}