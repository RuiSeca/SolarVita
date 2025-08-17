import 'package:logger/logger.dart';
import 'health_alert_models.dart';

// Health package imports - install with: flutter pub add health
// If health package is not available, all methods will return null gracefully
class HealthFactory {
  // Mock implementation - replace with actual health package when added
  Future<bool> hasPermissions(List<dynamic> permissions) async {
    return false; // No permissions without actual health package
  }
  
  Future<bool> requestAuthorization(List<dynamic> permissions) async {
    return false; // No authorization without actual health package
  }
  
  Future<List<HealthDataPoint>> getHealthDataFromTypes(
    DateTime startTime,
    DateTime endTime,
    List<dynamic> types,
  ) async {
    return []; // No data without actual health package
  }
}

class HealthDataType {
  static const heartRate = 'HEART_RATE';
  static const sleepInBed = 'SLEEP_IN_BED';
  static const sleepAsleep = 'SLEEP_ASLEEP';
  static const water = 'WATER';
  static const steps = 'STEPS';
}

class HealthDataPoint {
  final dynamic value;
  final DateTime dateFrom;
  final DateTime dateTo;
  final dynamic type;
  
  HealthDataPoint({
    required this.value,
    required this.dateFrom,
    required this.dateTo,
    required this.type,
  });
}

class HealthSensorService {
  static final Logger _logger = Logger();
  static HealthFactory? _health;
  static bool _isInitialized = false;

  static Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _health = HealthFactory();
      
      // Request permissions for health data
      final permissions = [
        HealthDataType.heartRate,
        HealthDataType.sleepInBed,
        HealthDataType.sleepAsleep,
        HealthDataType.water,
        HealthDataType.steps,
      ];
      
      final hasPermissions = await _health!.hasPermissions(permissions);
      
      if (!hasPermissions) {
        final granted = await _health!.requestAuthorization(permissions);
        if (!granted) {
          _logger.w('Health permissions not granted');
          return false;
        }
      }
      
      _isInitialized = true;
      return true;
    } catch (e) {
      _logger.e('Failed to initialize health services: $e');
      return false;
    }
  }

  // Heart Rate Detection
  static Future<int?> getCurrentHeartRate() async {
    if (!_isInitialized || _health == null) {
      await initialize();
    }
    
    try {
      final now = DateTime.now();
      final heartRateData = await _health!.getHealthDataFromTypes(
        now.subtract(Duration(minutes: 10)), // Last 10 minutes
        now,
        [HealthDataType.heartRate],
      );
      
      if (heartRateData.isNotEmpty) {
        // Get the most recent heart rate reading
        heartRateData.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
        final latestReading = heartRateData.first;
        
        _logger.d('Heart rate found: ${latestReading.value} bpm');
        return latestReading.value.toInt();
      }
      
      _logger.d('No recent heart rate data available');
      return null;
      
    } catch (e) {
      _logger.w('Failed to get heart rate: $e');
      return null;
    }
  }

  // Sleep Data Detection
  static Future<SleepData?> getLastNightSleep() async {
    if (!_isInitialized || _health == null) {
      await initialize();
    }
    
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(Duration(days: 1));
      
      // Get sleep data from yesterday
      final sleepData = await _health!.getHealthDataFromTypes(
        yesterday.subtract(Duration(hours: 12)), // From noon yesterday
        now.subtract(Duration(hours: 6)),        // To 6 AM today
        [HealthDataType.sleepInBed, HealthDataType.sleepAsleep],
      );
      
      if (sleepData.isNotEmpty) {
        Duration totalSleep = Duration.zero;
        Duration deepSleep = Duration.zero;
        
        for (final entry in sleepData) {
          final duration = entry.dateTo.difference(entry.dateFrom);
          
          if (entry.type == HealthDataType.sleepAsleep) {
            totalSleep += duration;
          } else if (entry.type == HealthDataType.sleepInBed) {
            // If we don't have SLEEP_ASLEEP data, use SLEEP_IN_BED as approximation
            if (totalSleep.inMinutes == 0) {
              totalSleep += duration;
            }
          }
        }
        
        // Calculate a simple sleep score (0-100)
        int sleepScore = _calculateSleepScore(totalSleep);
        
        _logger.d('Sleep data found: ${totalSleep.inHours}h ${totalSleep.inMinutes % 60}m');
        
        return SleepData(
          totalSleep: totalSleep,
          deepSleep: deepSleep,
          sleepScore: sleepScore,
          date: yesterday,
        );
      }
      
      _logger.d('No sleep data available for last night');
      return null;
      
    } catch (e) {
      _logger.w('Failed to get sleep data: $e');
      return null;
    }
  }

  // Water Intake from Health Data
  static Future<double?> getTodaysWaterIntake() async {
    if (!_isInitialized || _health == null) {
      await initialize();
    }
    
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      final waterData = await _health!.getHealthDataFromTypes(
        startOfDay,
        now,
        [HealthDataType.water],
      );
      
      if (waterData.isNotEmpty) {
        double totalWater = 0.0;
        for (final entry in waterData) {
          totalWater += entry.value.toDouble();
        }
        
        _logger.d('Water intake found: ${totalWater}ml today');
        return totalWater;
      }
      
      _logger.d('No water intake data available');
      return null;
      
    } catch (e) {
      _logger.w('Failed to get water intake: $e');
      return null;
    }
  }

  // Steps Count
  static Future<int?> getTodaysSteps() async {
    if (!_isInitialized || _health == null) {
      await initialize();
    }
    
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      final stepsData = await _health!.getHealthDataFromTypes(
        startOfDay,
        now,
        [HealthDataType.steps],
      );
      
      if (stepsData.isNotEmpty) {
        int totalSteps = 0;
        for (final entry in stepsData) {
          totalSteps += (entry.value as num).toInt();
        }
        
        _logger.d('Steps found: $totalSteps today');
        return totalSteps;
      }
      
      _logger.d('No steps data available');
      return null;
      
    } catch (e) {
      _logger.w('Failed to get steps: $e');
      return null;
    }
  }

  static int _calculateSleepScore(Duration totalSleep) {
    final hours = totalSleep.inMinutes / 60.0;
    
    if (hours >= 8.0) return 100;
    if (hours >= 7.0) return 90;
    if (hours >= 6.0) return 75;
    if (hours >= 5.0) return 60;
    if (hours >= 4.0) return 40;
    return 20;
  }

  // Check if health sensors are available
  static Future<Map<String, bool>> checkSensorAvailability() async {
    try {
      await initialize();
      
      // Check for recent data availability
      final heartRate = await getCurrentHeartRate();
      final sleep = await getLastNightSleep();
      final water = await getTodaysWaterIntake();
      final steps = await getTodaysSteps();
      
      return {
        'heart_rate': heartRate != null,
        'sleep': sleep != null,
        'water': water != null,
        'steps': steps != null,
      };
    } catch (e) {
      _logger.e('Failed to check sensor availability: $e');
      return {
        'heart_rate': false,
        'sleep': false,
        'water': false,
        'steps': false,
      };
    }
  }

  // Mock data for testing
  static Future<int?> getMockHeartRate({int? bpm}) async {
    await Future.delayed(Duration(milliseconds: 500));
    return bpm ?? 75; // Normal resting heart rate
  }

  static Future<SleepData?> getMockSleepData({Duration? sleepDuration}) async {
    await Future.delayed(Duration(milliseconds: 500));
    final duration = sleepDuration ?? Duration(hours: 7, minutes: 30);
    
    return SleepData(
      totalSleep: duration,
      deepSleep: Duration(hours: 2),
      sleepScore: _calculateSleepScore(duration),
      date: DateTime.now().subtract(Duration(days: 1)),
    );
  }
}