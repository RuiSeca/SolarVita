// Health Alert Models
import 'package:flutter/material.dart';

enum AlertLevel {
  normal(priority: 0, colorValue: 0xFF4CAF50),    // Green
  warning(priority: 1, colorValue: 0xFFFFC107),   // Yellow  
  high(priority: 2, colorValue: 0xFFFF9800),      // Orange
  critical(priority: 3, colorValue: 0xFFF44336);  // Red

  const AlertLevel({required this.priority, required this.colorValue});
  final int priority;
  final int colorValue;
  
  Color get color => Color(colorValue);
}

enum AlertType {
  airQualityDangerous,
  airQualityModerate,
  weatherExtreme,
  weatherHighUV,
  severeDehydration,
  mildDehydration,
  heartRateHigh,
  heartRateVeryHigh,
  sleepDeprivation,
  overtraining,
}

class WeatherData {
  final double temperature;
  final int humidity;
  final double uvIndex;
  final double windSpeed;
  final String condition;
  final DateTime timestamp;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.uvIndex,
    required this.windSpeed,
    required this.condition,
    required this.timestamp,
  });

  factory WeatherData.defaultSafe() {
    return WeatherData(
      temperature: 20.0,
      humidity: 50,
      uvIndex: 3.0,
      windSpeed: 5.0,
      condition: 'clear',
      timestamp: DateTime.now(),
    );
  }

  bool get isDaytime {
    final hour = timestamp.hour;
    return hour >= 6 && hour <= 18;
  }

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: json['main']['temp'].toDouble(),
      humidity: json['main']['humidity'],
      uvIndex: 0.0, // Will be set separately
      windSpeed: json['wind']['speed'].toDouble(),
      condition: json['weather'][0]['main'].toString().toLowerCase(),
      timestamp: DateTime.now(),
    );
  }
}

class AirQualityData {
  final int aqi;
  final Map<String, double> pollutants;
  final String source;
  final DateTime timestamp;

  AirQualityData({
    required this.aqi,
    required this.pollutants,
    required this.source,
    required this.timestamp,
  });

  factory AirQualityData.defaultSafe() {
    return AirQualityData(
      aqi: 50, // Assume moderate air quality
      pollutants: {},
      source: 'default',
      timestamp: DateTime.now(),
    );
  }

  String get qualityDescription {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  factory AirQualityData.fromOpenWeatherAirPollution(Map<String, dynamic> json) {
    final pollution = json['list'][0];
    final components = pollution['components'];
    final aqi = pollution['main']['aqi']; // OpenWeather provides direct AQI (1-5 scale)
    
    // Convert OpenWeather AQI (1-5) to US AQI (0-500) scale
    int convertToUSAQI(int owAqi) {
      switch (owAqi) {
        case 1: return 25;   // Good (0-50)
        case 2: return 75;   // Fair (51-100)
        case 3: return 125;  // Moderate (101-150)
        case 4: return 175;  // Poor (151-200)
        case 5: return 250;  // Very Poor (201-300)
        default: return 50;  // Default to good
      }
    }

    return AirQualityData(
      aqi: convertToUSAQI(aqi),
      pollutants: {
        'pm2_5': components['pm2_5']?.toDouble() ?? 0,
        'pm10': components['pm10']?.toDouble() ?? 0,
        'no2': components['no2']?.toDouble() ?? 0,
        'o3': components['o3']?.toDouble() ?? 0,
        'so2': components['so2']?.toDouble() ?? 0,
        'co': components['co']?.toDouble() ?? 0,
      },
      source: 'OpenWeather Air Pollution',
      timestamp: DateTime.now(),
    );
  }
}

class SleepData {
  final Duration totalSleep;
  final Duration deepSleep;
  final int sleepScore;
  final DateTime date;

  SleepData({
    required this.totalSleep,
    required this.deepSleep,
    required this.sleepScore,
    required this.date,
  });

  bool get isGoodSleep => totalSleep.inHours >= 7 && sleepScore >= 70;
}

class HealthAlert {
  final AlertType type;
  final AlertLevel level;
  final String message;
  final String? actionMessage;
  final DateTime timestamp;
  final Duration? duration;

  HealthAlert({
    required this.type,
    required this.level,
    required this.message,
    this.actionMessage,
    required this.timestamp,
    this.duration,
  });

  bool get isExpired {
    if (duration == null) return false;
    return DateTime.now().difference(timestamp) > duration!;
  }
}