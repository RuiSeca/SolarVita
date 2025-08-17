import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'health_alert_models.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _uvUrl = 'https://api.openweathermap.org/data/2.5/uvi';
  static final Logger _logger = Logger();
  
  // Get API key from environment variables
  static String get _apiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? 'YOUR_OPENWEATHER_API_KEY';
  
  static Future<WeatherData> getCurrentWeather() async {
    try {
      final position = await _getCurrentLocation();
      
      // Get current weather
      final weatherResponse = await http.get(
        Uri.parse(
          '$_baseUrl/weather'
          '?lat=${position.latitude}'
          '&lon=${position.longitude}'
          '&appid=$_apiKey'
          '&units=metric'
        ),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 10));
      
      if (weatherResponse.statusCode != 200) {
        _logger.w('Weather API returned ${weatherResponse.statusCode}');
        return WeatherData.defaultSafe();
      }
      
      final weatherData = json.decode(weatherResponse.body);
      
      // Get UV index (separate endpoint)
      final uvIndex = await _getUVIndex(position);
      
      return WeatherData(
        temperature: weatherData['main']['temp'].toDouble(),
        humidity: weatherData['main']['humidity'],
        uvIndex: uvIndex,
        windSpeed: weatherData['wind']?['speed']?.toDouble() ?? 0.0,
        condition: _mapWeatherCondition(weatherData['weather'][0]['main']),
        timestamp: DateTime.now(),
        city: weatherData['name'] as String?,
        country: weatherData['sys']?['country'] as String?,
      );
      
    } catch (e) {
      _logger.e('Weather service error: $e');
      return WeatherData.defaultSafe();
    }
  }
  
  static Future<double> _getUVIndex(Position position) async {
    try {
      final uvResponse = await http.get(
        Uri.parse(
          '$_uvUrl'
          '?lat=${position.latitude}'
          '&lon=${position.longitude}'
          '&appid=$_apiKey'
        ),
      ).timeout(Duration(seconds: 5));
      
      if (uvResponse.statusCode == 200) {
        final uvData = json.decode(uvResponse.body);
        return uvData['value']?.toDouble() ?? 3.0;
      }
    } catch (e) {
      _logger.w('UV index fetch failed: $e');
    }
    
    return 3.0; // Default moderate UV
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
  
  static String _mapWeatherCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'sunny';
      case 'clouds':
        return 'cloudy';
      case 'rain':
      case 'drizzle':
        return 'rainy';
      case 'thunderstorm':
        return 'stormy';
      case 'snow':
        return 'snowy';
      case 'mist':
      case 'fog':
        return 'foggy';
      default:
        return 'clear';
    }
  }
  
  // Test method for development
  static Future<WeatherData> getMockWeatherData() async {
    await Future.delayed(Duration(seconds: 1)); // Simulate API delay
    
    return WeatherData(
      temperature: 22.0,
      humidity: 65,
      uvIndex: 6.0,
      windSpeed: 3.2,
      condition: 'sunny',
      timestamp: DateTime.now(),
      city: 'Mock City',
      country: 'MC',
    );
  }
}