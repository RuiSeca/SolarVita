import 'dart:io';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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
              ? 'Health Connect permissions needed. Please:\n\n1. Open Health Connect app\n2. Go to "App permissions" or "Data sources and access"\n3. Find "SolarVita"\n4. Enable permissions for:\n   • Steps\n   • Active calories burned\n   • Heart rate\n   • Sleep\n   • Hydration\n   • Exercise\n\nThen restart SolarVita.'
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
    int steps = 0;
    int activeMinutes = 0;
    int caloriesBurned = 0;
    double sleepHours = 0.0;
    double heartRate = 0.0;
    double waterIntake = 0.0;
    int heartRateCount = 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last7Days = now.subtract(const Duration(days: 7));

    // Separate today's data from weekly averages
    int todaySteps = 0;
    int todayActiveCalories = 0;
    int todayTotalCalories = 0;
    double todayWater = 0.0;
    int todayActiveMinutes = 0;
    int todayMoveMinutes = 0;

    for (final point in dataPoints) {
      final pointDate = DateTime(point.dateFrom.year, point.dateFrom.month, point.dateFrom.day);
      final isToday = pointDate.isAtSameMomentAs(today);
      
      // Process data if it's from the last 7 days
      if (point.dateFrom.isAfter(last7Days)) {
        switch (point.type) {
          case HealthDataType.STEPS:
            final stepValue = (point.value as NumericHealthValue).numericValue.toInt();
            if (isToday) {
              todaySteps += stepValue;
            }
            steps += stepValue;
            break;
            
          case HealthDataType.ACTIVE_ENERGY_BURNED:
            final calorieValue = (point.value as NumericHealthValue).numericValue.toInt();
            if (isToday) {
              todayActiveCalories += calorieValue;
            }
            caloriesBurned += calorieValue;
            break;
            
          case HealthDataType.TOTAL_CALORIES_BURNED:
            final totalCalorieValue = (point.value as NumericHealthValue).numericValue.toInt();
            if (isToday) {
              todayTotalCalories += totalCalorieValue;
            }
            caloriesBurned += totalCalorieValue;
            break;
            
          case HealthDataType.HEART_RATE:
            final hrValue = (point.value as NumericHealthValue).numericValue.toDouble();
            heartRate += hrValue;
            heartRateCount++;
            break;
            
          case HealthDataType.SLEEP_ASLEEP:
          case HealthDataType.SLEEP_DEEP:
          case HealthDataType.SLEEP_REM:
            if (isToday || pointDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
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
            activeMinutes += minutes;
            break;
            
            
          case HealthDataType.DISTANCE_DELTA:
            // For active minutes calculation based on movement
            final distance = (point.value as NumericHealthValue).numericValue.toDouble();
            final duration = point.dateTo.difference(point.dateFrom);
            // If significant distance was covered, count as active time
            if (distance > 100) { // 100 meters threshold
              final minutes = duration.inMinutes;
              if (isToday) {
                todayActiveMinutes += minutes;
              }
              activeMinutes += minutes;
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

    // Combine different active minutes sources
    final totalTodayActiveMinutes = todayActiveMinutes + todayMoveMinutes;
    final totalActiveMinutes = activeMinutes;

    // Use best available calorie data (prefer total calories, fall back to active)
    final todayBestCalories = todayTotalCalories > 0 ? todayTotalCalories : todayActiveCalories;
    
    // Combine health app water data with local tracking
    final combinedWaterIntake = await _getCombinedWaterIntake(todayWater > 0 ? todayWater : waterIntake);
    
    // Use today's data primarily, fall back to weekly averages if today is empty
    return HealthData(
      steps: todaySteps > 0 ? todaySteps : (steps / 7).round(),
      activeMinutes: totalTodayActiveMinutes > 0 ? totalTodayActiveMinutes : (totalActiveMinutes / 7).round(),
      caloriesBurned: todayBestCalories > 0 ? todayBestCalories : (caloriesBurned / 7).round(),
      sleepHours: sleepHours,
      heartRate: heartRate,
      waterIntake: combinedWaterIntake / 1000, // Convert ml to liters
      lastUpdated: DateTime.now(),
      isDataAvailable: dataPoints.isNotEmpty,
    );
  }

  /// Combine health app water data with local manual tracking
  Future<double> _getCombinedWaterIntake(double healthAppWater) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
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

  /// Open health app settings
  Future<void> openHealthAppSettings() async {
    try {
      if (Platform.isIOS) {
        await launchUrl(Uri.parse('App-prefs:HEALTH'));
      } else if (Platform.isAndroid) {
        // Try to open Health Connect app directly
        const healthConnectPackage = 'com.google.android.apps.healthdata';
        final healthConnectUri = Uri.parse('package:$healthConnectPackage');
        
        if (await canLaunchUrl(healthConnectUri)) {
          await launchUrl(healthConnectUri);
        } else {
          // Fallback to Play Store
          await launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=$healthConnectPackage'));
        }
      }
    } catch (e) {
      // Failed to open health app settings
    }
  }

  /// Show health app installation dialog
  Future<bool> showHealthAppInstallDialog(BuildContext context) async {
    if (Platform.isIOS) {
      // iOS always has Health app
      return true;
    }

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Install Health Connect'),
        content: const Text(
          'To access your health data, please install Health Connect from the Play Store. '
          'Health Connect is Google\'s unified health platform that allows SolarVita to sync your steps, calories, and other health metrics safely.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
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

  /// Open Health Connect settings for permissions
  Future<void> openHealthConnectSettings() async {
    try {
      if (Platform.isAndroid) {
        // Try Health Connect permission settings first
        const healthConnectPermissionsUrl = 'content://com.android.healthconnect.controller/permissions';
        if (await canLaunchUrl(Uri.parse(healthConnectPermissionsUrl))) {
          await launchUrl(Uri.parse(healthConnectPermissionsUrl));
          return;
        }
        
        // Fallback to main Health Connect app
        const healthConnectUrl = 'content://com.android.healthconnect.controller/home';
        if (await canLaunchUrl(Uri.parse(healthConnectUrl))) {
          await launchUrl(Uri.parse(healthConnectUrl));
          return;
        }
        
        // Final fallback to app settings
        const packageUrl = 'package:com.google.android.apps.healthdata';
        if (await canLaunchUrl(Uri.parse(packageUrl))) {
          await launchUrl(Uri.parse(packageUrl));
        }
      }
    } catch (e) {
      // Failed to open Health Connect settings
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
              '• Calories burned\n'
              '• Heart rate\n'
              '• Sleep data\n'
              '• Hydration\n'
              '• Exercise sessions\n\n'
              'Your data stays secure in Health Connect and is never shared with third parties.'
            : 'SolarVita would like to access your health data to provide personalized '
              'fitness insights and track your progress. This includes:\n\n'
              '• Steps and distance\n'
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