import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Import all our health services
import 'health_alert_models.dart';
import 'weather_service.dart';
import '../database/user_profile_service.dart';
import 'air_quality_service.dart';
import 'health_sensor_service.dart';
import 'health_alert_evaluator.dart';

class SmartHealthDataCollector extends ChangeNotifier {
  static final Logger _logger = Logger();
  static SmartHealthDataCollector? _instance;
  
  // Data collection state
  bool _isInitialized = false;
  bool _isCollecting = false;
  Timer? _dataCollectionTimer;
  Timer? _alertCleanupTimer;
  
  // Current health data
  WeatherData? _currentWeather;
  AirQualityData? _currentAirQuality;
  int? _currentHeartRate;
  SleepData? _lastSleepData;
  double? _currentHydration;
  
  // Current alerts
  final List<HealthAlert> _activeAlerts = [];
  AlertLevel _currentAlertLevel = AlertLevel.normal;
  
  // Cache settings
  static const Duration _dataUpdateInterval = Duration(minutes: 15);
  static const Duration _alertCleanupInterval = Duration(minutes: 2); // Check more frequently for expiration
  static const Duration _cacheExpiry = Duration(hours: 1);
  
  // Singleton pattern
  static SmartHealthDataCollector get instance {
    _instance ??= SmartHealthDataCollector._internal();
    return _instance!;
  }
  
  SmartHealthDataCollector._internal();
  
  // Check if mock data should be used based on .env setting
  bool get _shouldUseMockData {
    final mockEnabled = dotenv.env['MOCK_DATA_ENABLED']?.toLowerCase();
    return mockEnabled == 'true';
  }
  
  // Getters for current data
  WeatherData? get currentWeather => _currentWeather;
  AirQualityData? get currentAirQuality => _currentAirQuality;
  int? get currentHeartRate => _currentHeartRate;
  SleepData? get lastSleepData => _lastSleepData;
  double? get currentHydration => _currentHydration;
  List<HealthAlert> get activeAlerts => List.unmodifiable(_activeAlerts);
  AlertLevel get currentAlertLevel => _currentAlertLevel;
  bool get isCollecting => _isCollecting;
  
  // Initialize the health data collector
  Future<bool> initialize({bool enableSensors = true}) async {
    if (_isInitialized) return true;
    
    try {
      _logger.i('Initializing SmartHealthDataCollector...');
      
      // Initialize health sensors if requested
      if (enableSensors) {
        await HealthSensorService.initialize();
      }
      
      // Load cached data
      await _loadCachedData();
      
      // Start data collection
      await startDataCollection();
      
      _isInitialized = true;
      _logger.i('SmartHealthDataCollector initialized successfully');
      return true;
      
    } catch (e) {
      _logger.e('Failed to initialize SmartHealthDataCollector: $e');
      return false;
    }
  }
  
  // Start automatic data collection
  Future<void> startDataCollection() async {
    if (_isCollecting) return;
    
    _logger.i('Starting health data collection...');
    _isCollecting = true;
    
    // Collect initial data immediately
    await _collectHealthData();
    
    // Set up periodic data collection
    _dataCollectionTimer = Timer.periodic(_dataUpdateInterval, (_) {
      _collectHealthData();
    });
    
    // Set up alert cleanup timer
    _alertCleanupTimer = Timer.periodic(_alertCleanupInterval, (_) {
      _cleanupExpiredAlerts();
    });
    
    notifyListeners();
  }
  
  // Stop data collection
  void stopDataCollection() {
    if (!_isCollecting) return;
    
    _logger.i('Stopping health data collection...');
    _isCollecting = false;
    
    _dataCollectionTimer?.cancel();
    _alertCleanupTimer?.cancel();
    
    notifyListeners();
  }
  
  // Manually trigger data collection
  Future<void> refreshData() async {
    await _collectHealthData();
  }
  
  // Main data collection method
  Future<void> _collectHealthData() async {
    try {
      _logger.d('Collecting health data...');
      
      // Collect data from all sources in parallel for efficiency
      final futures = <Future>[
        _collectWeatherData(),
        _collectAirQualityData(),
        _collectSensorData(),
        _collectHydrationFromHealthScreen(),
      ];
      
      await Future.wait(futures, eagerError: false);
      
      // Evaluate health status and generate alerts
      await _evaluateHealthStatus();
      
      // Cache the collected data
      await _cacheHealthData();
      
      _logger.d('Health data collection completed');
      notifyListeners();
      
    } catch (e) {
      _logger.e('Error during health data collection: $e');
    }
  }
  
  // Collect weather data
  Future<void> _collectWeatherData() async {
    try {
      if (_shouldUseMockData) {
        _logger.i('Using mock weather data (MOCK_DATA_ENABLED=true)');
        _currentWeather = await WeatherService.getMockWeatherData();
      } else {
        _logger.i('Fetching real weather data from OpenWeatherMap API');
        _currentWeather = await WeatherService.getCurrentWeather();
      }
      _logger.d('Weather data updated: ${_currentWeather?.temperature}°C');
    } catch (e) {
      _logger.w('Failed to collect weather data: $e');
      // Fallback to mock data if real API fails
      _logger.i('Falling back to mock weather data due to API error');
      _currentWeather = await WeatherService.getMockWeatherData();
    }
  }
  
  // Collect air quality data
  Future<void> _collectAirQualityData() async {
    try {
      if (_shouldUseMockData) {
        _logger.i('Using mock air quality data (MOCK_DATA_ENABLED=true)');
        _currentAirQuality = await AirQualityService.getMockAirQualityData();
      } else {
        _logger.i('Fetching real air quality data from OpenWeatherMap API');
        _currentAirQuality = await AirQualityService.getAirQuality();
      }
      _logger.d('Air quality updated: AQI ${_currentAirQuality?.aqi}');
    } catch (e) {
      _logger.w('Failed to collect air quality data: $e');
      // Fallback to mock data if real API fails
      _logger.i('Falling back to mock air quality data due to API error');
      _currentAirQuality = await AirQualityService.getMockAirQualityData();
    }
  }
  
  // Collect sensor data (heart rate, sleep)
  Future<void> _collectSensorData() async {
    try {
      // Try to get heart rate
      if (_shouldUseMockData) {
        _currentHeartRate = await HealthSensorService.getMockHeartRate();
      } else {
        // First try to get heart rate from health screen data
        _currentHeartRate = await _getHeartRateFromHealthScreen();
        
        // If not available, try device sensors
        _currentHeartRate ??= await HealthSensorService.getCurrentHeartRate();
        
        // Final fallback to mock if sensors not available
        _currentHeartRate ??= await HealthSensorService.getMockHeartRate();
      }
      
      // Try to get sleep data (only once per day)
      if (_lastSleepData == null || _shouldUpdateSleepData()) {
        if (_shouldUseMockData) {
          _lastSleepData = await HealthSensorService.getMockSleepData();
        } else {
          _lastSleepData = await HealthSensorService.getLastNightSleep();
          // Fallback to mock if sensors not available
          _lastSleepData ??= await HealthSensorService.getMockSleepData();
        }
      }
      
      _logger.d('Sensor data updated - HR: $_currentHeartRate, Sleep: ${_lastSleepData?.totalSleep.inHours}h');
    } catch (e) {
      _logger.w('Failed to collect sensor data: $e');
    }
  }
  
  // Get hydration data from health screen (integrate with your existing water tracking)
  Future<void> _collectHydrationFromHealthScreen() async {
    try {
      // Get water intake from health screen SharedPreferences or health sensors
      
      double? waterIntake;
      if (_shouldUseMockData) {
        // Mock hydration level for testing
        waterIntake = 1800.0; // 1.8L
      } else {
        // Try to get from health sensors first
        waterIntake = await HealthSensorService.getTodaysWaterIntake();
        
        // If not available, try to get from your health screen data
        waterIntake ??= await _getWaterIntakeFromHealthScreen();
        
        // Final fallback to mock data
        waterIntake ??= 1800.0;
      }
      
      // Calculate hydration level using medical recommendations and user goal
      final hydrationAssessment = await _calculateHydrationLevel(waterIntake);
      _currentHydration = hydrationAssessment;
      
      _logger.d('Hydration updated: ${_currentHydration?.toStringAsFixed(2)}');
    } catch (e) {
      _logger.w('Failed to collect hydration data: $e');
    }
  }
  
  // Evaluate health status and generate alerts
  Future<void> _evaluateHealthStatus() async {
    try {
      // Get current user age from profile (may have been updated)
      final physicalInfo = await _getUserPhysicalInfo();
      final currentAge = physicalInfo['age'] as int;
      
      final newAlerts = HealthAlertEvaluator.evaluateHealthStatus(
        weather: _currentWeather,
        airQuality: _currentAirQuality,
        heartRate: _currentHeartRate,
        sleepData: _lastSleepData,
        hydrationLevel: _currentHydration,
        userAge: currentAge,
      );
      
      // Update active alerts (remove duplicates and expired ones)
      _updateActiveAlerts(newAlerts);
      
      // Update current alert level
      _currentAlertLevel = HealthAlertEvaluator.getHighestPriorityLevel(_activeAlerts);
      
      _logger.d('Health evaluation completed - Alert level: $_currentAlertLevel');
      
    } catch (e) {
      _logger.e('Failed to evaluate health status: $e');
    }
  }
  
  // Update active alerts list
  void _updateActiveAlerts(List<HealthAlert> newAlerts) {
    // Remove expired alerts
    _activeAlerts.removeWhere((alert) => alert.isExpired);
    
    // Add new alerts that aren't duplicates
    for (final newAlert in newAlerts) {
      final existingAlert = _activeAlerts.firstWhere(
        (alert) => alert.type == newAlert.type,
        orElse: () => newAlert,
      );
      
      if (existingAlert == newAlert) {
        // This is a new alert
        _activeAlerts.add(newAlert);
      } else {
        // Update existing alert if new one has higher priority
        if (newAlert.level.priority > existingAlert.level.priority) {
          _activeAlerts.remove(existingAlert);
          _activeAlerts.add(newAlert);
        }
      }
    }
  }
  
  // Clean up expired alerts
  void _cleanupExpiredAlerts() {
    final initialCount = _activeAlerts.length;
    _activeAlerts.removeWhere((alert) => alert.isExpired);
    
    if (_activeAlerts.length != initialCount) {
      final previousAlertLevel = _currentAlertLevel;
      _currentAlertLevel = HealthAlertEvaluator.getHighestPriorityLevel(_activeAlerts);
      
      // Force notify listeners to update color manager even if alert level didn't change
      notifyListeners();
      
      _logger.d('Cleaned up expired alerts. Active alerts: ${_activeAlerts.length}, Alert level: ${_currentAlertLevel.name}');
      
      if (previousAlertLevel != _currentAlertLevel) {
        _logger.d('Alert level changed from ${previousAlertLevel.name} to ${_currentAlertLevel.name}');
      }
    }
  }
  
  // Check if sleep data should be updated (once per day)
  bool _shouldUpdateSleepData() {
    if (_lastSleepData == null) return true;
    
    final now = DateTime.now();
    final dataDate = _lastSleepData!.date;
    
    // Update if data is from yesterday and it's after 6 AM
    return now.day != dataDate.day && now.hour >= 6;
  }
  
  // Get heart rate from health screen data (via Riverpod provider)
  Future<int?> _getHeartRateFromHealthScreen() async {
    try {
      // Try to access health data from the health screen's HealthDataProvider
      // Note: This would typically be accessed via Riverpod, but we can't inject
      // Riverpod refs into this service. Instead, we'll need to check if there's
      // cached health data we can access directly.
      
      final prefs = await SharedPreferences.getInstance();
      
      // Check if there's recent heart rate data cached from health screen
      final heartRateTimestamp = prefs.getInt('health_heart_rate_timestamp') ?? 0;
      final heartRateValue = prefs.getDouble('health_heart_rate_value') ?? 0.0;
      
      // Only use cached data if it's from today and within the last hour
      final now = DateTime.now();
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(heartRateTimestamp);
      final isFromToday = cacheTime.day == now.day && 
                         cacheTime.month == now.month && 
                         cacheTime.year == now.year;
      final isRecent = now.difference(cacheTime).inHours < 1;
      
      if (isFromToday && isRecent && heartRateValue > 0) {
        final heartRateInt = heartRateValue.round();
        _logger.d('Heart rate from health screen cache: $heartRateInt bpm');
        return heartRateInt;
      } else {
        _logger.d('No recent heart rate data from health screen cache');
        return null;
      }
    } catch (e) {
      _logger.w('Failed to get heart rate from health screen: $e');
      return null;
    }
  }

  // Get water intake from health screen SharedPreferences
  Future<double?> _getWaterIntakeFromHealthScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if today's data exists (same logic as health screen)
      final today = _getHealthPlatformDateString();
      final lastDate = prefs.getString('water_last_date') ?? '';
      
      if (lastDate == today) {
        // Get today's water intake in liters, convert to milliliters
        final waterIntakeL = prefs.getDouble('water_intake') ?? 0.0;
        final waterIntakeML = waterIntakeL * 1000; // Convert L to mL
        
        _logger.d('Water intake from health screen: ${waterIntakeML}ml (${waterIntakeL}L)');
        return waterIntakeML;
      } else {
        _logger.d('No water intake data for today');
        return 0.0; // No data for today yet
      }
    } catch (e) {
      _logger.w('Failed to get water intake from health screen: $e');
      return null;
    }
  }
  
  // Get today's date string matching health platform format
  String _getHealthPlatformDateString() {
    final now = DateTime.now();
    final healthToday = DateTime(now.year, now.month, now.day);
    return healthToday.toIso8601String().split('T')[0];
  }
  
  // Get user's daily water goal from health screen settings
  Future<double> _getUserDailyWaterGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dailyLimitL = prefs.getDouble('water_daily_limit') ?? 2.0; // Default 2L
      final dailyLimitML = dailyLimitL * 1000; // Convert to mL
      
      _logger.d('User daily water goal: ${dailyLimitML}ml (${dailyLimitL}L)');
      return dailyLimitML;
    } catch (e) {
      _logger.w('Failed to get user daily water goal: $e');
      return 2000.0; // Default 2L in mL
    }
  }

  // Get user height, weight, and age from profile settings
  Future<Map<String, dynamic>> _getUserPhysicalInfo() async {
    try {
      final userProfileService = UserProfileService();
      final userProfile = await userProfileService.getCurrentUserProfile();
      
      if (userProfile != null) {
        final additionalData = userProfile.additionalData;
        
        final heightStr = additionalData['height'] as String? ?? '';
        final weightStr = additionalData['weight'] as String? ?? '';
        final ageStr = additionalData['age'] as String? ?? '';
        
        return {
          'height': double.tryParse(heightStr) ?? 170.0, // Default 170cm
          'weight': double.tryParse(weightStr) ?? 70.0,  // Default 70kg
          'age': int.tryParse(ageStr) ?? 25,             // Default 25 years
        };
      }
    } catch (e) {
      _logger.w('Failed to get user physical info from profile: $e');
    }
    
    // Fallback to SharedPreferences if profile service fails
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'height': prefs.getDouble('user_height') ?? 170.0,
        'weight': prefs.getDouble('user_weight') ?? 70.0,
        'age': prefs.getInt('user_age') ?? 25,
      };
    } catch (e) {
      _logger.w('Failed to get user physical info from SharedPreferences: $e');
      return {
        'height': 170.0, // Default values
        'weight': 70.0,
        'age': 25,
      };
    }
  }

  // Calculate hydration level using medical recommendations and user preferences
  Future<double> _calculateHydrationLevel(double waterIntakeML) async {
    try {
      final physicalInfo = await _getUserPhysicalInfo();
      final weight = physicalInfo['weight'] as double;
      final age = physicalInfo['age'] as int;
      
      // Medical recommendation: 35ml per kg body weight for adults
      // Adjust for age: +5ml/kg for 18-30, baseline for 31-55, -5ml/kg for 55+
      double baseRequirement = 35.0; // ml per kg
      
      if (age >= 18 && age <= 30) {
        baseRequirement = 40.0; // Higher needs for younger adults
      } else if (age > 55) {
        baseRequirement = 30.0; // Lower baseline for older adults
      }
      
      final medicalRecommendationML = weight * baseRequirement;
      
      // Get user's personal goal for comparison
      final userGoalML = await _getUserDailyWaterGoal();
      
      // Use the higher of medical recommendation or user goal as the target
      // This ensures medical needs are met while respecting user ambitions
      final targetIntakeML = medicalRecommendationML > userGoalML 
          ? medicalRecommendationML 
          : userGoalML;
      
      // Calculate hydration level (0.0 to 2.0+)
      final hydrationLevel = (waterIntakeML / targetIntakeML).clamp(0.0, 3.0);
      
      _logger.d('Hydration calculation: '
          'Intake: ${waterIntakeML.toInt()}ml, '
          'Medical: ${medicalRecommendationML.toInt()}ml, '
          'User Goal: ${userGoalML.toInt()}ml, '
          'Target: ${targetIntakeML.toInt()}ml, '
          'Level: ${hydrationLevel.toStringAsFixed(2)}');
      
      return hydrationLevel;
      
    } catch (e) {
      _logger.e('Error calculating hydration level: $e');
      // Fallback to simple user goal calculation
      final userGoalML = await _getUserDailyWaterGoal();
      return (waterIntakeML / userGoalML).clamp(0.0, 2.0);
    }
  }
  
  // Data persistence methods
  Future<void> _cacheHealthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'weather': _currentWeather != null ? _weatherToJson(_currentWeather!) : null,
        'airQuality': _currentAirQuality != null ? _airQualityToJson(_currentAirQuality!) : null,
        'heartRate': _currentHeartRate,
        'hydration': _currentHydration,
      };
      
      await prefs.setString('health_data_cache', json.encode(cacheData));
    } catch (e) {
      _logger.w('Failed to cache health data: $e');
    }
  }
  
  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString('health_data_cache');
      
      if (cacheString != null) {
        final cacheData = json.decode(cacheString);
        final timestamp = DateTime.parse(cacheData['timestamp']);
        
        // Only use cached data if it's not expired
        if (DateTime.now().difference(timestamp) < _cacheExpiry) {
          if (cacheData['weather'] != null) {
            _currentWeather = _weatherFromJson(cacheData['weather']);
          }
          if (cacheData['airQuality'] != null) {
            _currentAirQuality = _airQualityFromJson(cacheData['airQuality']);
          }
          _currentHeartRate = cacheData['heartRate'];
          _currentHydration = cacheData['hydration'];
          
          _logger.d('Loaded cached health data');
        }
      }
    } catch (e) {
      _logger.w('Failed to load cached data: $e');
    }
  }
  
  // JSON serialization helpers
  Map<String, dynamic> _weatherToJson(WeatherData weather) {
    return {
      'temperature': weather.temperature,
      'humidity': weather.humidity,
      'uvIndex': weather.uvIndex,
      'windSpeed': weather.windSpeed,
      'condition': weather.condition,
      'timestamp': weather.timestamp.toIso8601String(),
      'city': weather.city,
      'country': weather.country,
    };
  }
  
  WeatherData _weatherFromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: json['temperature'],
      humidity: json['humidity'],
      uvIndex: json['uvIndex'],
      windSpeed: json['windSpeed'],
      condition: json['condition'],
      timestamp: DateTime.parse(json['timestamp']),
      city: json['city'] as String?,
      country: json['country'] as String?,
    );
  }
  
  Map<String, dynamic> _airQualityToJson(AirQualityData airQuality) {
    return {
      'aqi': airQuality.aqi,
      'pollutants': airQuality.pollutants,
      'source': airQuality.source,
      'timestamp': airQuality.timestamp.toIso8601String(),
      'city': airQuality.city,
      'country': airQuality.country,
    };
  }
  
  AirQualityData _airQualityFromJson(Map<String, dynamic> json) {
    return AirQualityData(
      aqi: json['aqi'],
      pollutants: Map<String, double>.from(json['pollutants']),
      source: json['source'],
      timestamp: DateTime.parse(json['timestamp']),
      city: json['city'] as String?,
      country: json['country'] as String?,
    );
  }
  
  // Cleanup resources
  @override
  void dispose() {
    stopDataCollection();
    super.dispose();
  }
  
  // Get health summary for UI display
  Map<String, dynamic> getHealthSummary() {
    return {
      'alertLevel': _currentAlertLevel,
      'alertCount': _activeAlerts.length,
      'criticalAlerts': HealthAlertEvaluator.getCriticalAlerts(_activeAlerts).length,
      'weather': _currentWeather,
      'airQuality': _currentAirQuality,
      'heartRate': _currentHeartRate,
      'hydration': _currentHydration,
      'lastUpdated': DateTime.now(),
      'dataAvailable': {
        'weather': _currentWeather != null,
        'airQuality': _currentAirQuality != null,
        'heartRate': _currentHeartRate != null,
        'sleep': _lastSleepData != null,
        'hydration': _currentHydration != null,
      }
    };
  }
}