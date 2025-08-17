import 'dart:math';
import 'package:logger/logger.dart';
import 'health_alert_models.dart';

class HealthAlertEvaluator {
  static final Logger _logger = Logger();

  // Main evaluation method that combines all health factors
  static List<HealthAlert> evaluateHealthStatus({
    WeatherData? weather,
    AirQualityData? airQuality,
    int? heartRate,
    SleepData? sleepData,
    double? hydrationLevel,
    int? userAge,
  }) {
    List<HealthAlert> alerts = [];

    try {
      // 1. Air Quality Evaluation (Always available via API)
      if (airQuality != null) {
        final airAlert = _evaluateAirQuality(airQuality);
        if (airAlert != null) alerts.add(airAlert);
      }

      // 2. Weather Evaluation (Always available via API)
      if (weather != null) {
        final weatherAlert = _evaluateWeather(weather);
        if (weatherAlert != null) alerts.add(weatherAlert);
      }

      // 3. Hydration Evaluation (From health screen water tracking)
      if (hydrationLevel != null) {
        final hydrationAlert = _evaluateHydration(hydrationLevel);
        if (hydrationAlert != null) alerts.add(hydrationAlert);
      }

      // 4. Heart Rate Evaluation (Only if sensor available)
      if (heartRate != null && userAge != null) {
        final heartRateAlert = _evaluateHeartRate(heartRate, userAge);
        if (heartRateAlert != null) alerts.add(heartRateAlert);
      }

      // 5. Sleep Evaluation (Only if sensor available)
      if (sleepData != null) {
        final sleepAlert = _evaluateSleep(sleepData);
        if (sleepAlert != null) alerts.add(sleepAlert);
      }

      _logger.d('Generated ${alerts.length} health alerts');
      
    } catch (e) {
      _logger.e('Error evaluating health status: $e');
    }

    return alerts;
  }

  // Air Quality Alert Evaluation
  static HealthAlert? _evaluateAirQuality(AirQualityData airQuality) {
    if (airQuality.aqi > 200) {
      return HealthAlert(
        type: AlertType.airQualityDangerous,
        level: AlertLevel.critical,
        message: '🌫️ Air quality very unhealthy - avoid outdoor exercise',
        actionMessage: 'Consider indoor activities today',
        timestamp: DateTime.now(),
        duration: Duration(hours: 2),
      );
    } else if (airQuality.aqi > 150) {
      return HealthAlert(
        type: AlertType.airQualityDangerous,
        level: AlertLevel.high,
        message: '🌫️ Air quality unhealthy for sensitive groups',
        actionMessage: 'Limit outdoor exercise if you have respiratory conditions',
        timestamp: DateTime.now(),
        duration: Duration(hours: 1),
      );
    } else if (airQuality.aqi > 100) {
      return HealthAlert(
        type: AlertType.airQualityModerate,
        level: AlertLevel.warning,
        message: '🌫️ Air quality moderate - sensitive individuals should limit outdoor activity',
        actionMessage: 'Monitor how you feel during outdoor exercise',
        timestamp: DateTime.now(),
        duration: Duration(minutes: 30),
      );
    }
    
    return null; // Good air quality - no alert needed
  }

  // Weather Alert Evaluation
  static HealthAlert? _evaluateWeather(WeatherData weather) {
    // Extreme temperature alerts
    if (weather.temperature > 35) {
      return HealthAlert(
        type: AlertType.weatherExtreme,
        level: AlertLevel.critical,
        message: '🌡️ Extreme heat - exercise dangerous outdoors',
        actionMessage: 'Stay indoors and stay hydrated',
        timestamp: DateTime.now(),
        duration: Duration(hours: 3),
      );
    } else if (weather.temperature < -5) {
      return HealthAlert(
        type: AlertType.weatherExtreme,
        level: AlertLevel.critical,
        message: '❄️ Extreme cold - risk of frostbite during exercise',
        actionMessage: 'Exercise indoors or wear appropriate gear',
        timestamp: DateTime.now(),
        duration: Duration(hours: 2),
      );
    }
    
    // High UV alerts (only during daytime)
    if (weather.isDaytime && weather.uvIndex > 8) {
      return HealthAlert(
        type: AlertType.weatherHighUV,
        level: AlertLevel.high,
        message: '☀️ Very high UV index - risk of sunburn',
        actionMessage: 'Use sunscreen SPF 30+, seek shade between 10 AM - 4 PM',
        timestamp: DateTime.now(),
        duration: Duration(hours: 1),
      );
    } else if (weather.isDaytime && weather.uvIndex > 6) {
      return HealthAlert(
        type: AlertType.weatherHighUV,
        level: AlertLevel.warning,
        message: '☀️ High UV index - use sun protection',
        actionMessage: 'Apply sunscreen before outdoor activities',
        timestamp: DateTime.now(),
        duration: Duration(minutes: 30),
      );
    }
    
    return null; // Good weather - no alert needed
  }

  // Hydration Alert Evaluation
  static HealthAlert? _evaluateHydration(double hydrationLevel) {
    if (hydrationLevel < 0.3) {
      return HealthAlert(
        type: AlertType.severeDehydration,
        level: AlertLevel.critical,
        message: '💧 Severely dehydrated - drink water immediately',
        actionMessage: 'Drink at least 500ml of water now',
        timestamp: DateTime.now(),
        duration: Duration(minutes: 15),
      );
    } else if (hydrationLevel < 0.5) {
      return HealthAlert(
        type: AlertType.mildDehydration,
        level: AlertLevel.high,
        message: '💧 Mildly dehydrated - increase water intake',
        actionMessage: 'Drink a glass of water every hour',
        timestamp: DateTime.now(),
        duration: Duration(minutes: 30),
      );
    } else if (hydrationLevel < 0.7) {
      return HealthAlert(
        type: AlertType.mildDehydration,
        level: AlertLevel.warning,
        message: '💧 Low hydration - drink more water',
        actionMessage: 'Aim for 8 glasses of water daily',
        timestamp: DateTime.now(),
        duration: Duration(minutes: 20),
      );
    }
    
    return null; // Good hydration - no alert needed
  }

  // Heart Rate Alert Evaluation
  static HealthAlert? _evaluateHeartRate(int heartRate, int userAge) {
    final maxHeartRate = 220 - userAge;
    final restingHeartRate = _estimateRestingHeartRate(userAge);
    
    if (heartRate > maxHeartRate * 0.95) {
      return HealthAlert(
        type: AlertType.heartRateVeryHigh,
        level: AlertLevel.critical,
        message: '💓 Heart rate dangerously high - stop activity immediately',
        actionMessage: 'Rest and seek medical attention if symptoms persist',
        timestamp: DateTime.now(),
        duration: Duration(minutes: 10),
      );
    } else if (heartRate > maxHeartRate * 0.85) {
      return HealthAlert(
        type: AlertType.heartRateHigh,
        level: AlertLevel.high,
        message: '💓 Heart rate very high - reduce intensity',
        actionMessage: 'Take a break and monitor your heart rate',
        timestamp: DateTime.now(),
        duration: Duration(minutes: 5),
      );
    } else if (heartRate < restingHeartRate - 20) {
      return HealthAlert(
        type: AlertType.heartRateHigh,
        level: AlertLevel.warning,
        message: '💓 Heart rate unusually low',
        actionMessage: 'Monitor and consult healthcare provider if concerned',
        timestamp: DateTime.now(),
        duration: Duration(minutes: 15),
      );
    }
    
    return null; // Normal heart rate - no alert needed
  }

  // Sleep Alert Evaluation
  static HealthAlert? _evaluateSleep(SleepData sleepData) {
    final sleepHours = sleepData.totalSleep.inMinutes / 60.0;
    
    if (sleepHours < 4) {
      return HealthAlert(
        type: AlertType.sleepDeprivation,
        level: AlertLevel.critical,
        message: '😴 Severe sleep deprivation - avoid intense exercise',
        actionMessage: 'Prioritize sleep tonight and consider light activity only',
        timestamp: DateTime.now(),
        duration: Duration(hours: 8),
      );
    } else if (sleepHours < 6) {
      return HealthAlert(
        type: AlertType.sleepDeprivation,
        level: AlertLevel.high,
        message: '😴 Significant sleep debt - your body needs rest',
        actionMessage: 'Limit high-intensity workouts and focus on recovery',
        timestamp: DateTime.now(),
        duration: Duration(hours: 4),
      );
    } else if (sleepHours < 7) {
      return HealthAlert(
        type: AlertType.sleepDeprivation,
        level: AlertLevel.warning,
        message: '😴 Below recommended sleep - consider recovery focus',
        actionMessage: 'Aim for 7-9 hours of sleep tonight',
        timestamp: DateTime.now(),
        duration: Duration(hours: 2),
      );
    } else if (sleepData.sleepScore < 60) {
      return HealthAlert(
        type: AlertType.sleepDeprivation,
        level: AlertLevel.warning,
        message: '😴 Poor sleep quality detected',
        actionMessage: 'Focus on sleep hygiene and stress reduction',
        timestamp: DateTime.now(),
        duration: Duration(hours: 2),
      );
    }
    
    return null; // Good sleep - no alert needed
  }

  // Get the highest priority alert from a list
  static AlertLevel getHighestPriorityLevel(List<HealthAlert> alerts) {
    if (alerts.isEmpty) return AlertLevel.normal;
    
    return alerts
        .map((alert) => alert.level)
        .reduce((a, b) => a.priority > b.priority ? a : b);
  }

  // Get all critical alerts that need immediate attention
  static List<HealthAlert> getCriticalAlerts(List<HealthAlert> alerts) {
    return alerts
        .where((alert) => alert.level == AlertLevel.critical)
        .toList();
  }

  // Helper method to estimate resting heart rate by age
  static int _estimateRestingHeartRate(int age) {
    if (age < 25) return 65;
    if (age < 35) return 68;
    if (age < 45) return 70;
    if (age < 55) return 72;
    if (age < 65) return 74;
    return 76;
  }

  // Calculate overall health score (0.0 to 1.0)
  static double calculateHealthScore({
    required List<HealthAlert> alerts,
    WeatherData? weather,
    AirQualityData? airQuality,
    double? hydrationLevel,
    SleepData? sleepData,
  }) {
    double score = 1.0; // Start with perfect score
    
    // Deduct points for alerts
    for (final alert in alerts) {
      switch (alert.level) {
        case AlertLevel.critical:
          score -= 0.4;
          break;
        case AlertLevel.high:
          score -= 0.2;
          break;
        case AlertLevel.warning:
          score -= 0.1;
          break;
        case AlertLevel.normal:
          break;
      }
    }
    
    return max(0.0, score); // Ensure score doesn't go below 0
  }
}