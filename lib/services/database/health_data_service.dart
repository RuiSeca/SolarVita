import 'dart:io';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import '../../models/health/health_data.dart';
import '../chat/data_sync_service.dart';

/// Health Data Service with proper Health Connect aggregate API support
/// Optimized for accurate "Move Minutes" / active minutes tracking
class HealthDataService {
  static final Logger _logger = Logger('HealthDataService');
  static final HealthDataService _instance = HealthDataService._internal();
  factory HealthDataService() => _instance;
  HealthDataService._internal();

  static const String _healthDataKey = 'cached_health_data';
  static const String _lastSyncKey = 'last_health_sync';
  static const String _permissionsGrantedKey = 'health_permissions_granted';

  // Health instance
  final Health _health = Health();

  // Health data types we want to access
  static List<HealthDataType> get _healthDataTypes {
    if (Platform.isIOS) {
      return [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.TOTAL_CALORIES_BURNED,
        HealthDataType.HEART_RATE,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
        HealthDataType.WATER,
        HealthDataType.WORKOUT,
        HealthDataType.DISTANCE_DELTA,
      ];
    } else {
      // Android - Health Connect compatible types
      return [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.TOTAL_CALORIES_BURNED,
        HealthDataType.HEART_RATE,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.WATER,
        HealthDataType.WORKOUT, // Use workout sessions for active minutes
        HealthDataType.DISTANCE_DELTA,
      ];
    }
  }

  // Permissions for each data type
  static List<HealthDataAccess> get _permissions {
    return List.generate(
      _healthDataTypes.length,
      (index) => HealthDataAccess.READ,
    );
  }

  /// Fetch health data using Health Connect aggregate API for accurate active minutes
  Future<HealthData> fetchHealthData() async {
    try {
      // Define time range for today only
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final endOfToday = today.add(const Duration(days: 1));

      _logger.info('Fetching health data for: ${today.toString()} to ${endOfToday.toString()}');

      // Get active minutes using Health Connect aggregate API (most accurate)
      int activeMinutes = 0;
      if (Platform.isAndroid) {
        activeMinutes = await _getActiveMinutesHealthConnect(today, endOfToday);
      } else {
        activeMinutes = await _getActiveMinutesiOS(today, endOfToday);
      }

      // Get other health data using standard methods
      final healthData = await _health.getHealthDataFromTypes(
        types: _healthDataTypes,
        startTime: today,
        endTime: endOfToday,
      );

      _logger.info('Retrieved ${healthData.length} health data points');

      // Process the health data
      int steps = 0;
      double waterIntake = 0.0;
      double sleepHours = 0.0;
      double heartRate = 0.0;
      int heartRateCount = 0;

      for (final point in healthData) {
        switch (point.type) {
          case HealthDataType.STEPS:
            final stepValue = (point.value as NumericHealthValue).numericValue.toInt();
            steps += stepValue;
            break;

          case HealthDataType.WATER:
            final waterValue = (point.value as NumericHealthValue).numericValue.toDouble();
            waterIntake += waterValue;
            break;

          case HealthDataType.SLEEP_ASLEEP:
          case HealthDataType.SLEEP_DEEP:
          case HealthDataType.SLEEP_REM:
            final duration = point.dateTo.difference(point.dateFrom);
            sleepHours += duration.inMinutes / 60.0;
            break;

          case HealthDataType.HEART_RATE:
            final heartRateValue = (point.value as NumericHealthValue).numericValue.toDouble();
            if (heartRateValue > 0 && heartRateValue < 250) {
              heartRate += heartRateValue;
              heartRateCount++;
            }
            break;

          default:
            break;
        }
      }

      // Calculate average heart rate
      if (heartRateCount > 0) {
        heartRate = heartRate / heartRateCount;
      }

      // Estimate calories based on activity
      int estimatedCalories = _estimateCaloriesFromActivity(steps, activeMinutes);

      // Combine local water intake with health app data
      final combinedWaterIntake = await _getCombinedWaterIntake(waterIntake);

      _logger.info('Final health data: Steps: $steps, Active: $activeMinutes min, Calories: $estimatedCalories');

      final result = HealthData(
        steps: _validateSteps(steps),
        activeMinutes: _validateActiveMinutes(activeMinutes),
        caloriesBurned: _validateCalories(estimatedCalories),
        sleepHours: sleepHours.clamp(0.0, 24.0),
        heartRate: heartRate.clamp(0.0, 220.0),
        waterIntake: combinedWaterIntake / 1000, // Convert ml to liters
        lastUpdated: DateTime.now(),
        isDataAvailable: steps > 0 || activeMinutes > 0 || waterIntake > 0,
      );

      // Cache the result and sync to Firebase
      await _cacheHealthData(result);
      await _updateLastSyncTime();
      await _syncToFirebase(result);

      return result;
    } catch (e) {
      _logger.severe('Error fetching health data: $e');
      // Return cached data if available
      final cachedData = await _getCachedHealthData();
      if (cachedData != null) {
        _logger.info('Returning cached health data');
        return cachedData;
      }
      rethrow;
    }
  }

  /// Get active minutes using Health Connect (Android)
  /// Manually calculates active minutes from ExerciseSessionRecord durations
  /// This is the proper Health Connect approach since EXERCISE_TIME is not available
  Future<int> _getActiveMinutesHealthConnect(DateTime startTime, DateTime endTime) async {
    try {
      _logger.info('Calculating active minutes from Health Connect ExerciseSessionRecord');
      
      // Query exercise sessions (ExerciseSessionRecord) from Health Connect
      // Using HealthDataType.WORKOUT which maps to ExerciseSessionRecord
      final exerciseSessionData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT], // Maps to ExerciseSessionRecord
        startTime: startTime,
        endTime: endTime,
      );

      int totalActiveMinutes = 0;
      
      if (exerciseSessionData.isNotEmpty) {
        _logger.info('Found ${exerciseSessionData.length} exercise sessions from Health Connect');
        
        // Calculate active minutes manually by summing exercise session durations
        for (final session in exerciseSessionData) {
          if (session.type == HealthDataType.WORKOUT) {
            // Each record has startTime (dateFrom) and endTime (dateTo)
            // Duration = endTime - startTime
            final sessionDuration = session.dateTo.difference(session.dateFrom);
            final sessionMinutes = sessionDuration.inMinutes;
            
            // Apply reasonable bounds for exercise sessions
            if (sessionMinutes > 0 && sessionMinutes <= 480) { // 0-8 hours max
              totalActiveMinutes += sessionMinutes;
              _logger.fine('Exercise session: $sessionMinutes minutes (${session.dateFrom} to ${session.dateTo})');
            } else if (sessionMinutes > 480) {
              _logger.warning('Capping extremely long session: $sessionMinutes minutes -> 480 minutes');
              totalActiveMinutes += 480;
            }
          }
        }
        
        _logger.info('Health Connect active minutes calculation: ${exerciseSessionData.length} sessions = $totalActiveMinutes minutes');
      } else {
        _logger.info('No exercise sessions found in Health Connect for the specified time range');
        
        // Optional: Fallback to estimating from steps if no exercise sessions
        // This provides some activity tracking even without formal workouts
        totalActiveMinutes = await _estimateActiveMinutesFromSteps(startTime, endTime);
      }

      _logger.info('Total Health Connect active minutes: $totalActiveMinutes');
      return totalActiveMinutes;
    } catch (e) {
      _logger.warning('Error calculating Health Connect active minutes: $e');
      return 0;
    }
  }

  /// Fallback method to estimate active minutes from step data
  /// Used when no exercise sessions are available in Health Connect
  Future<int> _estimateActiveMinutesFromSteps(DateTime startTime, DateTime endTime) async {
    try {
      _logger.info('Estimating active minutes from step activity as fallback');
      
      final stepData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startTime,
        endTime: endTime,
      );

      int totalSteps = 0;
      for (final point in stepData) {
        if (point.type == HealthDataType.STEPS) {
          final steps = (point.value as NumericHealthValue).numericValue.toInt();
          totalSteps += steps;
        }
      }

      int estimatedActiveMinutes = 0;
      if (totalSteps > 2000) { // Only estimate if meaningful step count
        // Conservative estimation: ~120 steps per minute of active walking
        // This gives a more realistic estimate than 100 steps/minute
        estimatedActiveMinutes = (totalSteps / 120).round();
        
        // Apply reasonable bounds - steps shouldn't translate to more than 4 hours active
        estimatedActiveMinutes = estimatedActiveMinutes.clamp(0, 240);
        
        _logger.fine('Estimated $estimatedActiveMinutes active minutes from $totalSteps steps');
      }

      return estimatedActiveMinutes;
    } catch (e) {
      _logger.warning('Error estimating active minutes from steps: $e');
      return 0;
    }
  }

  /// Get active minutes for iOS using workout data
  Future<int> _getActiveMinutesiOS(DateTime startTime, DateTime endTime) async {
    try {
      _logger.info('Using iOS workout data for active minutes');
      final workoutData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: startTime,
        endTime: endTime,
      );

      int totalActiveMinutes = 0;
      for (final point in workoutData) {
        final duration = point.dateTo.difference(point.dateFrom);
        final minutes = duration.inMinutes;
        if (minutes > 0 && minutes < 480) { // Reasonable workout duration
          totalActiveMinutes += minutes;
          _logger.fine('iOS: Added $minutes minutes from workout');
        }
      }

      _logger.info('iOS total active minutes: $totalActiveMinutes');
      return totalActiveMinutes;
    } catch (e) {
      _logger.warning('Error getting iOS active minutes: $e');
      return 0;
    }
  }

  /// Request health permissions with proper Health Connect explanation
  Future<HealthPermissionStatus> requestPermissions() async {
    try {
      final isInstalled = await isHealthAppInstalled();
      if (!isInstalled) {
        return HealthPermissionStatus.denied(
          errorMessage: Platform.isAndroid
              ? 'Health Connect not installed. Please install Health Connect from Google Play Store to track your fitness data.'
              : 'Health app not found. Please ensure Health app is installed.',
        );
      }

      final granted = await _health.requestAuthorization(
        _healthDataTypes,
        permissions: _permissions,
      );

      if (granted) {
        await _savePermissionStatus(true);
        return HealthPermissionStatus.granted(
          isHealthAppInstalled: isInstalled,
          grantedPermissions: _healthDataTypes.map((type) => type.name).toList(),
        );
      } else {
        return HealthPermissionStatus.denied(
          errorMessage: Platform.isAndroid
              ? 'Health Connect permissions needed. Please:\n\n1. Open Health Connect app\n2. Go to "App permissions" or "Data sources and access"\n3. Find "SolarVita"\n4. Enable permissions for:\n   • Steps\n   • Exercise sessions (for Move Minutes)\n   • Active calories burned\n   • Heart rate\n   • Sleep\n   • Hydration\n\nThen restart SolarVita.'
              : 'Health permissions needed. Please enable permissions in Health app settings.',
        );
      }
    } catch (e) {
      return HealthPermissionStatus.denied(
        errorMessage: 'Error requesting permissions: ${e.toString()}',
      );
    }
  }

  /// Check current permission status
  Future<HealthPermissionStatus> checkPermissionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasGranted = prefs.getBool(_permissionsGrantedKey) ?? false;
      final isInstalled = await isHealthAppInstalled();

      if (!isInstalled) {
        return HealthPermissionStatus.denied(
          errorMessage: Platform.isAndroid
              ? 'Health Connect not installed. Please install Health Connect from Google Play Store.'
              : 'Health app not available.',
        );
      }

      if (wasGranted) {
        return HealthPermissionStatus.granted(
          isHealthAppInstalled: isInstalled,
          grantedPermissions: _healthDataTypes.map((type) => type.name).toList(),
        );
      } else {
        return HealthPermissionStatus.denied(
          errorMessage: 'Health permissions not granted.',
        );
      }
    } catch (e) {
      return HealthPermissionStatus.denied(
        errorMessage: 'Error checking permissions: ${e.toString()}',
      );
    }
  }

  /// Check if Health Connect or Health app is installed
  Future<bool> isHealthAppInstalled() async {
    if (Platform.isAndroid) {
      // Check for Health Connect
      try {
        return _health.isDataTypeAvailable(HealthDataType.STEPS);
      } catch (e) {
        return false;
      }
    } else {
      // iOS Health app is built-in
      return true;
    }
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncString = prefs.getString(_lastSyncKey);
      if (lastSyncString != null) {
        return DateTime.parse(lastSyncString);
      }
    } catch (e) {
      _logger.warning('Error getting last sync time: $e');
    }
    return null;
  }

  /// Update last sync time
  Future<void> _updateLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      _logger.warning('Error updating last sync time: $e');
    }
  }

  /// Cache health data locally
  Future<void> _cacheHealthData(HealthData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataMap = data.toJson();
      await prefs.setString(_healthDataKey, dataMap.toString());
    } catch (e) {
      _logger.warning('Error caching health data: $e');
    }
  }

  /// Get cached health data
  Future<HealthData?> _getCachedHealthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedDataString = prefs.getString(_healthDataKey);
      if (cachedDataString != null) {
        // For now, return null to force fresh data
        // In production, you'd parse the JSON back to HealthData
        return null;
      }
    } catch (e) {
      _logger.warning('Error getting cached health data: $e');
    }
    return null;
  }

  /// Sync health data to Firebase
  Future<void> _syncToFirebase(HealthData data) async {
    try {
      final dataSyncService = DataSyncService();
      await dataSyncService.syncHealthData(data);
      _logger.info('Synced health data to Firebase');
    } catch (e) {
      _logger.warning('Error syncing to Firebase: $e');
      // Don't throw - health data fetching should succeed even if Firebase sync fails
    }
  }

  /// Show enhanced health app installation dialog with version-specific guidance
  Future<bool> showHealthAppInstallDialog(BuildContext context) async {
    if (Platform.isIOS) {
      // iOS always has Health app
      return true;
    }

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;
    final manufacturer = androidInfo.manufacturer.toLowerCase();

    // Check if context is still valid after async operation
    if (!context.mounted) return false;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Health Connect Setup'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sdkInt >= 34)
                    ..._buildAndroid14Instructions(manufacturer)
                  else
                    ..._buildPreAndroid14Instructions(),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Health Connect is Google\'s secure platform for health data.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop(true);
                  if (sdkInt >= 34) {
                    await _openHealthConnectWithFallbacks();
                  } else {
                    await launchUrl(
                      Uri.parse(
                        'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata',
                      ),
                    );
                  }
                },
                child: Text(
                  sdkInt >= 34
                      ? 'Open Health Connect'
                      : 'Install Health Connect',
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Show permissions explanation dialog
  Future<bool> showPermissionsDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Health Data Access'),
            content: Text(
              Platform.isAndroid
                  ? 'SolarVita would like to access your health data through Health Connect to provide personalized '
                        'fitness insights and track your progress. This includes:\\n\\n'
                        '• Steps and distance\\n'
                        '• Active minutes (workouts & movement)\\n'
                        '• Calories burned\\n'
                        '• Heart rate\\n'
                        '• Sleep data\\n'
                        '• Hydration\\n'
                        '• Exercise sessions\\n\\n'
                        'Your data stays secure in Health Connect and is never shared with third parties.'
                  : 'SolarVita would like to access your health data to provide personalized '
                        'fitness insights and track your progress. This includes:\\n\\n'
                        '• Steps and distance\\n'
                        '• Active minutes (workouts & movement)\\n'
                        '• Calories burned\\n'
                        '• Heart rate\\n'
                        '• Sleep data\\n'
                        '• Water intake\\n\\n'
                        'Your data stays on your device and is never shared with third parties.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Grant Access'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Open Health Connect settings for permissions with enhanced targeting
  Future<void> openHealthConnectSettings() async {
    if (Platform.isAndroid) {
      await _openHealthConnectWithFallbacks();
    }
  }

  /// Open Health Connect permissions specifically
  Future<void> openHealthPermissions({String? packageName}) async {
    if (!Platform.isAndroid) return;

    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      final appPackage = packageName ?? 'com.solarvitadev.solarvita';

      // Try permission-specific intents first
      if (sdkInt >= 34) {
        // Android 14+ - direct to permission management
        if (await _launchPermissionIntent(appPackage)) return;
      }

      // Fallback to general Health Connect settings
      await openHealthConnectSettings();
    } catch (e) {
      // Fallback to general settings
      await openHealthConnectSettings();
    }
  }

  /// Launch permission-specific intent
  Future<bool> _launchPermissionIntent(String packageName) async {
    try {
      const platform = MethodChannel('solar_vitas/health_connect');
      final result = await platform
          .invokeMethod('launchHealthPermissionIntent', {
            'action': 'android.health.connect.action.MANAGE_HEALTH_PERMISSIONS',
            'packageName': packageName,
          });
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Save permission status
  Future<void> _savePermissionStatus(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsGrantedKey, granted);
  }

  /// Combine health app water intake with local tracking
  Future<double> _getCombinedWaterIntake(double healthAppWater) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localWater = prefs.getDouble('daily_water_intake') ?? 0.0;
      
      // Use the higher value (health app vs local tracking)
      final combined = healthAppWater > localWater ? healthAppWater : localWater;
      _logger.fine('Water intake - Health app: ${healthAppWater}ml, Local: ${localWater}ml, Using: ${combined}ml');
      return combined;
    } catch (e) {
      return healthAppWater;
    }
  }

  /// Estimate calories from activity data
  int _estimateCaloriesFromActivity(int steps, int activeMinutes) {
    // Base calorie burn from steps (roughly 0.04 calories per step)
    int stepCalories = (steps * 0.04).round();
    
    // Active minutes calorie burn (roughly 10 calories per minute of moderate activity)
    int activeCalories = activeMinutes * 10;
    
    // Total estimated calories (active calories only, not BMR)
    final total = stepCalories + activeCalories;
    _logger.fine('Estimated calories: $stepCalories (steps) + $activeCalories (active) = $total total');
    return total;
  }

  /// Validate steps for reasonable bounds
  int _validateSteps(int steps) {
    if (steps < 0) return 0;
    if (steps > 100000) {
      _logger.warning('Steps capped at 100,000 (was $steps)');
      return 100000;
    }
    return steps;
  }

  /// Validate active minutes for reasonable bounds
  int _validateActiveMinutes(int activeMinutes) {
    if (activeMinutes < 0) return 0;
    if (activeMinutes > 1440) {
      _logger.warning('Active minutes capped at 1440 (was $activeMinutes)');
      return 1440; // Can't exceed 24 hours
    }
    return activeMinutes;
  }

  /// Validate calories for reasonable bounds
  int _validateCalories(int calories) {
    if (calories < 0) return 0;
    if (calories > 10000) {
      _logger.warning('Calories capped at 10,000 (was $calories)');
      return 10000;
    }
    return calories;
  }

  /// Build Android 14+ instructions
  List<Widget> _buildAndroid14Instructions(String manufacturer) {
    return [
      const Text(
        'Health Connect is built into Android 14+. To access it:\\n',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      Text(_getManufacturerSpecificPath(manufacturer)),
      const SizedBox(height: 8),
      const Text(
        'Or tap "Open Health Connect" below to go directly there.',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ];
  }

  /// Build pre-Android 14 instructions
  List<Widget> _buildPreAndroid14Instructions() {
    return [
      const Text(
        'Health Connect needs to be installed from the Play Store:\\n',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const Text('1. Tap "Install Health Connect" below\\n'),
      const Text('2. Install the app from Play Store\\n'),
      const Text('3. Open Health Connect and complete setup\\n'),
      const Text('4. Return to SolarVita to grant permissions'),
    ];
  }

  /// Get manufacturer-specific settings path
  String _getManufacturerSpecificPath(String manufacturer) {
    switch (manufacturer) {
      case 'samsung':
        return 'Settings → Security and Privacy → More privacy settings → Health Connect';
      case 'google':
      case 'pixel':
        return 'Settings → Security & Privacy → Privacy → Health Connect';
      case 'oneplus':
        return 'Settings → Privacy → Health Connect';
      case 'xiaomi':
      case 'redmi':
        return 'Settings → Apps → Manage apps → Health Connect';
      case 'huawei':
        return 'Settings → Privacy → Health Connect (if available)';
      default:
        return 'Settings → Security & Privacy → Privacy → Health Connect\\n(Path may vary by device manufacturer)';
    }
  }

  /// Enhanced Health Connect access with multiple fallback strategies
  Future<void> _openHealthConnectWithFallbacks() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    // Strategy 1: Try version-specific intent actions
    if (await _tryVersionSpecificIntents(sdkInt)) return;

    // Strategy 2: Try direct package launch
    if (await _tryDirectPackageLaunch()) return;

    // Strategy 3: Try system settings approach
    if (await _trySystemSettingsApproach()) return;

    // Strategy 4: Fallback to Play Store
    await _fallbackToPlayStore();
  }

  /// Try version-specific intent actions
  Future<bool> _tryVersionSpecificIntents(int sdkInt) async {
    try {
      if (sdkInt >= 34) {
        // Android 14+
        return await _launchIntentAction(
          'android.health.connect.action.HEALTH_HOME_SETTINGS',
        );
      } else if (sdkInt >= 33) {
        // Android 13
        return await _launchIntentAction(
          'androidx.health.ACTION_HEALTH_CONNECT_SETTINGS',
        );
      } else {
        return await _launchIntentAction(
          'com.google.android.apps.healthdata.MAIN',
        );
      }
    } catch (e) {
      return false;
    }
  }

  /// Launch intent action using platform channel
  Future<bool> _launchIntentAction(String action) async {
    try {
      const platform = MethodChannel('solar_vitas/health_connect');
      final result = await platform.invokeMethod('launchHealthConnectIntent', {
        'action': action,
      });
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Try direct package launch
  Future<bool> _tryDirectPackageLaunch() async {
    try {
      const healthConnectPackage = 'com.google.android.apps.healthdata';
      final healthConnectUri = Uri.parse('package:$healthConnectPackage');

      if (await canLaunchUrl(healthConnectUri)) {
        await launchUrl(healthConnectUri);
        return true;
      }
    } catch (e) {
      // Continue to next strategy
    }
    return false;
  }

  /// Try system settings approach
  Future<bool> _trySystemSettingsApproach() async {
    try {
      // Try opening Android settings with Health Connect deep link
      final settingsUri = Uri.parse(
        'android-app://com.android.settings/.Settings\$HealthConnectSettingsActivity',
      );
      if (await canLaunchUrl(settingsUri)) {
        await launchUrl(settingsUri);
        return true;
      }

      // Try generic app settings
      final appSettingsUri = Uri.parse(
        'package:com.google.android.apps.healthdata',
      );
      if (await canLaunchUrl(appSettingsUri)) {
        await launchUrl(appSettingsUri);
        return true;
      }
    } catch (e) {
      // Continue to fallback
    }
    return false;
  }

  /// Fallback to Play Store
  Future<void> _fallbackToPlayStore() async {
    try {
      const healthConnectPackage = 'com.google.android.apps.healthdata';
      await launchUrl(
        Uri.parse(
          'https://play.google.com/store/apps/details?id=$healthConnectPackage',
        ),
      );
    } catch (e) {
      // Final fallback failed
    }
  }
}

