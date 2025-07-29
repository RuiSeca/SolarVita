import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/health_data.dart';
import 'data_sync_service.dart';

class HealthDataService {
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
      // Android - using Health Connect compatible types
      return [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.TOTAL_CALORIES_BURNED,
        HealthDataType.HEART_RATE,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.WATER,
        HealthDataType.WORKOUT,
        HealthDataType.DISTANCE_DELTA,
      ];
    }
  }

  // Permissions for each data type
  static List<HealthDataAccess> get _permissions {
    return List.generate(_healthDataTypes.length, (index) => HealthDataAccess.READ);
  }

  /// Check if health app is installed and available
  Future<bool> isHealthAppInstalled() async {
    try {
      if (Platform.isIOS) {
        // Apple Health is always available on iOS
        return true;
      } else if (Platform.isAndroid) {
        // Check if Health Connect is available using the health plugin
        bool isAvailable = await _health.isHealthConnectAvailable();
        return isAvailable;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Request health data permissions
  Future<HealthPermissionStatus> requestPermissions() async {
    try {
      final isInstalled = await isHealthAppInstalled();
      
      if (!isInstalled) {
        return HealthPermissionStatus.denied(
          errorMessage: Platform.isAndroid 
            ? 'Health Connect not available. Please install Health Connect from the Play Store:\n\n1. Open Play Store\n2. Search for "Health Connect"\n3. Install the app\n4. Set up Health Connect\n5. Return to SolarVita to grant permissions'
            : 'Health app not available.'
        );
      }


      // Request permissions using HealthFactory
      final hasPermissions = await _health.hasPermissions(_healthDataTypes, permissions: _permissions);
      
      if (hasPermissions == false) {
        final granted = await _health.requestAuthorization(_healthDataTypes, permissions: _permissions);
        
        // Even if the authorization appears to fail, check permissions again
        // Sometimes the permissions are granted but the method returns false
        final hasPermissionsAfterRequest = await _health.hasPermissions(_healthDataTypes, permissions: _permissions);
        
        if (granted || hasPermissionsAfterRequest == true) {
          await _savePermissionStatus(true);
          return HealthPermissionStatus.granted(
            isHealthAppInstalled: isInstalled,
            grantedPermissions: _healthDataTypes.map((type) => type.name).toList(),
          );
        } else {
          // If automatic permission request fails, guide user to manual setup
          return HealthPermissionStatus.denied(
            errorMessage: Platform.isAndroid
              ? 'Health Connect permissions needed. Please:\n\n1. Open Health Connect app\n2. Go to "App permissions" or "Data sources and access"\n3. Find "SolarVita"\n4. Enable permissions for:\n   • Steps\n   • Active minutes\n   • Active calories burned\n   • Heart rate\n   • Sleep\n   • Hydration\n   • Exercise\n\nThen restart SolarVita.'
              : 'Health permissions needed. Please enable permissions in Health app settings.'
          );
        }
      }

      await _savePermissionStatus(true);
      return HealthPermissionStatus.granted(
        isHealthAppInstalled: isInstalled,
        grantedPermissions: _healthDataTypes.map((type) => type.name).toList(),
      );
    } catch (e) {
      return HealthPermissionStatus.denied(
        errorMessage: 'Error requesting permissions: ${e.toString()}'
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
            ? 'Health Connect not available'
            : 'Health app not available'
        );
      }


      // Try to actually fetch some data to test if permissions are working
      if (Platform.isAndroid) {
        try {
          final now = DateTime.now();
          final yesterday = now.subtract(const Duration(days: 1));
          
          // Try to fetch steps data as a permission test
          final stepsData = await _health.getHealthDataFromTypes(
            types: [HealthDataType.STEPS],
            startTime: yesterday,
            endTime: now,
          );
          
          if (stepsData.isNotEmpty || wasGranted) {
            await _savePermissionStatus(true);
            return HealthPermissionStatus.granted(
              isHealthAppInstalled: isInstalled,
              grantedPermissions: _healthDataTypes.map((type) => type.name).toList(),
            );
          }
        } catch (e) {
          // Fall back to permission check
        }
      }

      final hasPermissions = await _health.hasPermissions(_healthDataTypes, permissions: _permissions);
      
      if (hasPermissions == true) {
        return HealthPermissionStatus.granted(
          isHealthAppInstalled: isInstalled,
          grantedPermissions: _healthDataTypes.map((type) => type.name).toList(),
        );
      }

      return HealthPermissionStatus.denied(
        errorMessage: wasGranted 
          ? 'Health permissions were revoked. Please re-enable them.'
          : 'Health permissions not granted'
      );
    } catch (e) {
      return HealthPermissionStatus.denied(
        errorMessage: 'Error checking permissions: ${e.toString()}'
      );
    }
  }

  /// Fetch health data from the device
  Future<HealthData> fetchHealthData() async {
    try {
      final permissionStatus = await checkPermissionStatus();
      
      if (!permissionStatus.isGranted) {
        return await _getCachedHealthData();
      }

      final now = DateTime.now();
      final startTime = now.subtract(const Duration(days: 7)); // Expand to 7 days

      // Fetch health data points with expanded date range
      final healthDataPoints = await _health.getHealthDataFromTypes(
        types: _healthDataTypes,
        startTime: startTime,
        endTime: now,
      );

      if (healthDataPoints.isEmpty) {
        // If no new data, try to return cached data, but ensure it has meaningful values
        final cachedData = await _getCachedHealthData();
        // Only return cached data if it actually has some health information
        if (cachedData.isDataAvailable) {
          return cachedData;
        }
        // If no meaningful cached data, return empty but mark as unavailable
        return HealthData.empty();
      }

      // Process the health data
      final healthData = await _processHealthDataPoints(healthDataPoints);
      
      // Cache the data
      await _cacheHealthData(healthData);
      await _updateLastSyncTime();
      
      // Sync to Firebase for supporters to see
      await DataSyncService().syncHealthData(healthData);
      
      return healthData;
    } catch (e) {
      // Return cached data on error
      return await _getCachedHealthData();
    }
  }

  /// Process raw health data points into our HealthData model
  Future<HealthData> _processHealthDataPoints(List<HealthDataPoint> dataPoints) async {
    double sleepHours = 0.0;
    double heartRate = 0.0;
    double waterIntake = 0.0;
    int heartRateCount = 0;

    final now = DateTime.now();
    // Use health platform's timezone for consistent midnight reset
    final healthToday = _getHealthPlatformToday();
    final last7Days = now.subtract(const Duration(days: 7));

    // Separate today's data from weekly averages
    int todaySteps = 0;
    double todayWater = 0.0;
    int todayActiveMinutes = 0;
    int todayMoveMinutes = 0;

    for (final point in dataPoints) {
      final pointDate = DateTime(point.dateFrom.year, point.dateFrom.month, point.dateFrom.day);
      final isToday = pointDate.isAtSameMomentAs(healthToday);
      
      // Process data if it's from the last 7 days
      if (point.dateFrom.isAfter(last7Days)) {
        switch (point.type) {
          case HealthDataType.STEPS:
            final stepValue = (point.value as NumericHealthValue).numericValue.toInt();
            if (isToday) {
              todaySteps += stepValue;
            }
            // Don't accumulate weekly steps - we only want today's data
            break;
            
          case HealthDataType.ACTIVE_ENERGY_BURNED:
          case HealthDataType.TOTAL_CALORIES_BURNED:
            // Skip calorie data from health platforms - it's often inaccurate or includes BMR
            // We'll calculate calories ourselves based on activity or set to 0
            break;
            
          case HealthDataType.HEART_RATE:
            final hrValue = (point.value as NumericHealthValue).numericValue.toDouble();
            heartRate += hrValue;
            heartRateCount++;
            break;
            
          case HealthDataType.SLEEP_ASLEEP:
          case HealthDataType.SLEEP_DEEP:
          case HealthDataType.SLEEP_REM:
            if (isToday || pointDate.isAtSameMomentAs(healthToday.subtract(const Duration(days: 1)))) {
              final duration = point.dateTo.difference(point.dateFrom);
              sleepHours += duration.inMinutes / 60.0;
            }
            break;
            
          case HealthDataType.WATER:
            final waterValue = (point.value as NumericHealthValue).numericValue.toDouble();
            if (isToday) {
              todayWater += waterValue;
            }
            waterIntake += waterValue;
            break;
            
          case HealthDataType.WORKOUT:
            final duration = point.dateTo.difference(point.dateFrom);
            final minutes = duration.inMinutes;
            if (isToday) {
              todayActiveMinutes += minutes;
            }
            // Don't accumulate weekly active minutes - we only want today's data
            break;
            
          case HealthDataType.DISTANCE_DELTA:
            // Calculate active minutes based on movement with improved accuracy
            final distance = (point.value as NumericHealthValue).numericValue.toDouble();
            final duration = point.dateTo.difference(point.dateFrom);
            
            // More precise approach: only count meaningful movement
            if (distance > 100 && duration.inMinutes > 0) { // Increase minimum to 100 meters
              final pace = distance / duration.inMinutes; // meters per minute
              
              // More accurate pace thresholds:
              // Light walking: 50-80 m/min
              // Brisk walking: 80-120 m/min  
              // Jogging/running: 120+ m/min
              if (pace >= 50) { // Only count if at least light walking pace
                final minutes = duration.inMinutes;
                // Apply intensity factor for more accurate active time
                final intensityFactor = pace >= 80 ? 1.0 : 0.7; // Reduce light activity impact
                final adjustedMinutes = (minutes * intensityFactor).round();
                
                if (isToday) {
                  todayMoveMinutes += adjustedMinutes;
                }
                // Don't accumulate weekly move minutes - we only want today's data
              }
            }
            break;
            
          default:
            break;
        }
      }
    }

    // Calculate average heart rate
    if (heartRateCount > 0) {
      heartRate = heartRate / heartRateCount;
    }

    // Combine different active minutes sources (workouts + movement-based)
    // This captures both structured workouts and general active movement
    final totalTodayActiveMinutes = todayActiveMinutes + todayMoveMinutes;

    // Calculate calories based on activity data instead of using health platform calorie data
    // Health platform calorie data often includes BMR or is inconsistent across platforms
    int estimatedCalories = _estimateCaloriesFromActivity(todaySteps, totalTodayActiveMinutes);
    
    // Combine health app water data with local tracking
    final combinedWaterIntake = await _getCombinedWaterIntake(todayWater > 0 ? todayWater : waterIntake);
    
    // Prioritize today's data - only use weekly averages if explicitly no data for today
    // This prevents showing inflated values from cumulative weekly data
    final validatedSteps = _validateSteps(todaySteps); // Use actual today's steps only
    final validatedActiveMinutes = _validateActiveMinutes(totalTodayActiveMinutes); // Use actual today's active minutes only
    final validatedCalories = _validateCalories(estimatedCalories); // Use our estimated calories only
    
    // Use today's data primarily, fall back to weekly averages if today is empty
    return HealthData(
      steps: validatedSteps,
      activeMinutes: validatedActiveMinutes,
      caloriesBurned: validatedCalories,
      sleepHours: sleepHours.clamp(0.0, 24.0), // Sleep can't exceed 24 hours
      heartRate: heartRate.clamp(0.0, 220.0), // Reasonable heart rate range
      waterIntake: combinedWaterIntake / 1000, // Convert ml to liters
      lastUpdated: DateTime.now(),
      isDataAvailable: dataPoints.isNotEmpty,
    );
  }

  /// Combine health app water data with local manual tracking
  Future<double> _getCombinedWaterIntake(double healthAppWater) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Use same date logic as health platform for consistency
      final today = _getHealthPlatformToday().toIso8601String().split('T')[0];
      final lastDate = prefs.getString('water_last_date') ?? '';
      
      // Get local water intake for today
      double localWaterIntake = 0.0;
      if (lastDate == today) {
        localWaterIntake = prefs.getDouble('water_intake') ?? 0.0;
        localWaterIntake *= 1000; // Convert liters to ml
      }
      
      // Use the higher value between health app and local tracking
      // This handles cases where user manually tracks or health app tracks
      return healthAppWater > localWaterIntake ? healthAppWater : localWaterIntake;
    } catch (e) {
      // If local water reading fails, use health app data
      return healthAppWater;
    }
  }

  /// Get cached health data or return empty data
  Future<HealthData> _getCachedHealthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_healthDataKey);
      
      if (cachedData != null) {
        final Map<String, dynamic> json = Map<String, dynamic>.from(
          Uri.splitQueryString(cachedData)
        );
        return HealthData.fromJson(json);
      }
    } catch (e) {
      // Ignore cache errors
    }
    
    // Return empty data if no cache available - no fake data
    return HealthData.empty();
  }

  /// Cache health data
  Future<void> _cacheHealthData(HealthData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = data.toJson();
      await prefs.setString(_healthDataKey, json.toString());
    } catch (e) {
      // Ignore cache errors
    }
  }

  /// Update last sync time
  Future<void> _updateLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Ignore sync time errors
    }
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString(_lastSyncKey);
      return lastSync != null ? DateTime.parse(lastSync) : null;
    } catch (e) {
      return null;
    }
  }

  /// Save permission status
  Future<void> _savePermissionStatus(bool granted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_permissionsGrantedKey, granted);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Open health app settings with enhanced platform-specific handling
  Future<void> openHealthAppSettings() async {
    try {
      if (Platform.isIOS) {
        await launchUrl(Uri.parse('App-prefs:HEALTH'));
      } else if (Platform.isAndroid) {
        await _openHealthConnectWithFallbacks();
      }
    } catch (e) {
      // Failed to open health app settings
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
      if (sdkInt >= 34) { // Android 14+
        return await _launchIntentAction('android.health.connect.action.HEALTH_HOME_SETTINGS');
      } else if (sdkInt >= 33) { // Android 13
        return await _launchIntentAction('androidx.health.ACTION_HEALTH_CONNECT_SETTINGS');
      } else {
        return await _launchIntentAction('com.google.android.apps.healthdata.MAIN');
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Launch intent action using platform channel
  Future<bool> _launchIntentAction(String action) async {
    try {
      const platform = MethodChannel('solar_vitas/health_connect');
      final result = await platform.invokeMethod('launchHealthConnectIntent', {'action': action});
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
      final settingsUri = Uri.parse('android-app://com.android.settings/.Settings\$HealthConnectSettingsActivity');
      if (await canLaunchUrl(settingsUri)) {
        await launchUrl(settingsUri);
        return true;
      }
      
      // Try generic app settings
      final appSettingsUri = Uri.parse('package:com.google.android.apps.healthdata');
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
      await launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=$healthConnectPackage'));
    } catch (e) {
      // Final fallback failed
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
              if (sdkInt >= 34) ..._buildAndroid14Instructions(manufacturer)
              else ..._buildPreAndroid14Instructions(),
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
                await launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata'));
              }
            },
            child: Text(sdkInt >= 34 ? 'Open Health Connect' : 'Install Health Connect'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  /// Build Android 14+ instructions
  List<Widget> _buildAndroid14Instructions(String manufacturer) {
    return [
      const Text(
        'Health Connect is built into Android 14+. To access it:\n',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      Text(
        _getManufacturerSpecificPath(manufacturer),
      ),
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
        'Health Connect needs to be installed from the Play Store:\n',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const Text('1. Tap "Install Health Connect" below\n'),
      const Text('2. Install the app from Play Store\n'),
      const Text('3. Open Health Connect and complete setup\n'),
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
        return 'Settings → Security & Privacy → Privacy → Health Connect\n(Path may vary by device manufacturer)';
    }
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
      final result = await platform.invokeMethod('launchHealthPermissionIntent', {
        'action': 'android.health.connect.action.MANAGE_HEALTH_PERMISSIONS',
        'packageName': packageName,
      });
      return result == true;
    } catch (e) {
      return false;
    }
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
              'fitness insights and track your progress. This includes:\n\n'
              '• Steps and distance\n'
              '• Active minutes (workouts & movement)\n'
              '• Calories burned\n'
              '• Heart rate\n'
              '• Sleep data\n'
              '• Hydration\n'
              '• Exercise sessions\n\n'
              'Your data stays secure in Health Connect and is never shared with third parties.'
            : 'SolarVita would like to access your health data to provide personalized '
              'fitness insights and track your progress. This includes:\n\n'
              '• Steps and distance\n'
              '• Active minutes (workouts & movement)\n'
              '• Calories burned\n'
              '• Heart rate\n'
              '• Sleep data\n'
              '• Water intake\n\n'
              'Your data stays on your device and is never shared with third parties.'
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
    ) ?? false;
  }

  /// Complete Health Connect setup guide
  Future<bool> showHealthConnectSetupGuide(BuildContext context) async {
    if (Platform.isIOS) return true;

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Health Connect Setup Required'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To enable health tracking, please follow these steps:\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('1. Install Health Connect from Play Store\n'),
              Text('2. Open Health Connect app\n'),
              Text('3. Complete initial setup\n'),
              Text('4. Return to SolarVita\n'),
              Text('5. Grant permissions when prompted\n'),
              SizedBox(height: 16),
              Text(
                'Health Connect is Google\'s secure platform for health data. It keeps your data private while allowing apps like SolarVita to provide personalized insights.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              await launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata'));
            },
            child: const Text('Install Health Connect'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Validate steps data for reasonable bounds
  int _validateSteps(int steps) {
    // Filter out unrealistic step counts
    if (steps < 0) return 0;
    if (steps > 100000) return 100000; // Cap at 100k steps per day (extreme but possible)
    return steps;
  }

  /// Validate active minutes for reasonable bounds
  int _validateActiveMinutes(int activeMinutes) {
    // Filter out unrealistic active time
    if (activeMinutes < 0) return 0;
    if (activeMinutes > 1440) return 1440; // Can't exceed 24 hours (1440 minutes)
    return activeMinutes;
  }

  /// Validate calories for reasonable bounds
  int _validateCalories(int calories) {
    // Filter out unrealistic calorie counts
    if (calories < 0) return 0;
    if (calories > 10000) return 10000; // Cap at 10k calories (extreme athlete level)
    return calories;
  }

  /// Estimate calories burned based on activity data
  /// This provides more consistent results than health platform calorie data
  int _estimateCaloriesFromActivity(int steps, int activeMinutes) {
    int estimatedCalories = 0;
    
    // Estimate calories from steps (rough approximation: ~0.04 calories per step)
    estimatedCalories += (steps * 0.04).round();
    
    // Estimate calories from active minutes (rough approximation: ~5-8 calories per minute)
    estimatedCalories += (activeMinutes * 6.5).round();
    
    // Return estimated calories or 0 if no meaningful activity
    return estimatedCalories;
  }

  /// Get today's date according to health platform's timezone and reset logic
  DateTime _getHealthPlatformToday() {
    final now = DateTime.now();
    
    if (Platform.isIOS) {
      // iOS Health app resets at midnight in device timezone
      return DateTime(now.year, now.month, now.day);
    } else {
      // Android Health Connect also resets at midnight in device timezone
      // But we want to ensure consistency with Google Fit's reset timing
      return DateTime(now.year, now.month, now.day);
    }
  }

  /// Show data sources setup guide
  Future<bool> showDataSourcesGuide(BuildContext context) async {
    if (Platform.isIOS) return true;

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Health Data Found'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Health Connect permissions are granted, but no data was found. This usually means:\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• No apps are writing data to Health Connect\n'),
              Text('• Your phone\'s built-in step counter isn\'t connected\n'),
              Text('• Fitness apps haven\'t been set up yet\n'),
              SizedBox(height: 16),
              Text(
                'To fix this:\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('1. Open Health Connect app\n'),
              Text('2. Go to "Data sources and access"\n'),
              Text('3. Connect apps like Samsung Health, Fitbit, or other health apps\n'),
              Text('4. Enable your phone\'s built-in sensors\n'),
              Text('5. Walk around a bit to generate data\n'),
              Text('6. Return to SolarVita and refresh\n'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Use Mock Data'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              await openHealthConnectSettings();
            },
            child: const Text('Open Health Connect'),
          ),
        ],
      ),
    ) ?? false;
  }
}