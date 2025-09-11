import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:math';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import 'package:solar_vitas/utils/translation_helper.dart';
import 'meals/meal_plan_screen.dart';
import '../../widgets/common/rive_water_widget.dart';
import '../../widgets/common/oriented_image.dart';
import '../../widgets/common/sleep_toggle_widget.dart';
import 'water_detail_screen.dart';
import 'health_setup_screen.dart';
import '../../providers/riverpod/health_data_provider.dart';
import '../../providers/riverpod/user_progress_provider.dart';
import '../../models/health/health_data.dart';
import '../../models/user/user_progress.dart';
import '../../providers/riverpod/scroll_controller_provider.dart';
import '../../services/database/notification_service.dart';
import '../../widgets/health/daily_exercise_summary_card.dart';

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen>
    with TickerProviderStateMixin {
  double waterIntake = 0.0; // Start with 0ml
  double waterDailyLimit = 2.0; // Default 2000ml = 2.0L
  double manualSleepHours = 0.0; // Manual sleep tracking
  late AnimationController _rippleController;
  late Map<String, AnimationController> _iconAnimationControllers;
  bool _isWaterAnimating = false;

  @override
  void initState() {
    super.initState();
    
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize animation controllers for each stat
    _iconAnimationControllers = {
      'steps': AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: this,
      ),
      'active': AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      ),
      'calories': AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      ),
      'sleep': AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      ),
      'heart': AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    };

    _loadWaterIntake();
    _loadManualSleepData();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    for (final controller in _iconAnimationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Calculate heart rate progress based on age-based target zones
  double _calculateHeartRateProgress(double heartRate) {
    if (heartRate <= 0) return 0.0;

    // Estimated age-based calculation (can be improved with actual user age)
    const estimatedAge = 30; // Default assumption
    final maxHeartRate = 220 - estimatedAge;
    final targetZoneMin = maxHeartRate * 0.5; // 50% of max
    final targetZoneMax = maxHeartRate * 0.85; // 85% of max

    if (heartRate < targetZoneMin) {
      // Below target zone - show partial progress
      return (heartRate / targetZoneMin * 0.5).clamp(0.0, 0.5);
    } else if (heartRate <= targetZoneMax) {
      // In target zone - excellent progress
      return 0.5 +
          ((heartRate - targetZoneMin) / (targetZoneMax - targetZoneMin) * 0.5);
    } else {
      // Above target zone - cap at 100% but indicate it's high
      return 1.0;
    }
  }

  Future<void> _loadWaterIntake() async {
    final prefs = await SharedPreferences.getInstance();
    // Use consistent date format that matches health platform reset timing
    final today = _getHealthPlatformDateString();
    final lastDate = prefs.getString('water_last_date') ?? '';

    // Load water daily limit
    final dailyLimit = prefs.getDouble('water_daily_limit') ?? 2.0;

    if (lastDate != today) {
      // Reset for new day - synchronized with health platform
      setState(() {
        waterIntake = 0.0;
        waterDailyLimit = dailyLimit;
      });
      await prefs.setString('water_last_date', today);
      await prefs.setDouble('water_intake', 0.0);
    } else {
      setState(() {
        waterIntake = prefs.getDouble('water_intake') ?? 0.0;
        waterDailyLimit = dailyLimit;
      });
    }
    
    // Check and reschedule water reminders if needed
    await _checkWaterReminderSchedule();
  }

  /// Get today's date string that matches health platform reset timing
  String _getHealthPlatformDateString() {
    final now = DateTime.now();
    // Match the same format as sleep toggle widget
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadManualSleepData() async {
    final prefs = await SharedPreferences.getInstance();
    final sleepHours = prefs.getDouble('sleep_duration') ?? 0.0;
    final sleepDate = prefs.getString('sleep_date') ?? '';
    final today = _getHealthPlatformDateString();
    
    // Only use today's sleep data
    if (sleepDate == today) {
      setState(() {
        manualSleepHours = sleepHours;
      });
    } else {
      setState(() {
        manualSleepHours = 0.0;
      });
    }
  }

  void _onSleepUpdated(double sleepHours) {
    setState(() {
      manualSleepHours = sleepHours;
    });
  }

  Future<void> _checkWaterReminderSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersEnabled = prefs.getBool('water_reminders_enabled') ?? false;
      
      if (!remindersEnabled) {
        return; // User has disabled reminders
      }
      
      // Check when reminders were last scheduled
      final lastScheduled = prefs.getString('water_reminders_last_scheduled');
      final now = DateTime.now();
      
      bool shouldReschedule = false;
      
      if (lastScheduled == null) {
        // Never scheduled before
        shouldReschedule = true;
      } else {
        final lastScheduledDate = DateTime.parse(lastScheduled);
        final daysSinceScheduled = now.difference(lastScheduledDate).inDays;
        
        // Reschedule if it's been more than 5 days (leaving 2 days buffer from 7-day schedule)
        if (daysSinceScheduled >= 5) {
          shouldReschedule = true;
        }
      }
      
      if (shouldReschedule) {
        // Import and call the scheduling logic
        await _rescheduleWaterReminders();
        await prefs.setString('water_reminders_last_scheduled', now.toIso8601String());
      }
    } catch (e) {
      // Silently handle any errors in background scheduling
    }
  }

  Future<void> _rescheduleWaterReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reminderFrequency = prefs.getString('water_reminder_frequency') ?? '2';
      final customHours = prefs.getInt('water_custom_hours') ?? 2;
      final customMinutes = prefs.getInt('water_custom_minutes') ?? 0;
      
      // Calculate interval based on frequency setting (same logic as water_detail_screen)
      Duration interval;
      switch (reminderFrequency) {
        case '1':
          interval = const Duration(hours: 1);
          break;
        case '2':
          interval = const Duration(hours: 2);
          break;
        case '3':
          interval = const Duration(hours: 3);
          break;
        case 'custom':
          interval = Duration(hours: customHours, minutes: customMinutes);
          break;
        default:
          interval = const Duration(hours: 2);
      }

      if (interval.inMinutes == 0) {
        return;
      }

      // Cancel existing water reminders and schedule new ones
      final notificationService = NotificationService();
      await notificationService.cancelNotificationsByType('water_reminder');

      // Schedule reminders for the next 7 days (same logic as water_detail_screen)
      final now = DateTime.now();
      DateTime currentDay = DateTime(now.year, now.month, now.day);
      int notificationId = 1;

      for (int day = 0; day < 7; day++) {
        final dayStart = currentDay.add(Duration(days: day));
        
        final firstReminder = DateTime(dayStart.year, dayStart.month, dayStart.day, 8, 0);
        final lastReminder = DateTime(dayStart.year, dayStart.month, dayStart.day, 22, 0);
        
        DateTime nextReminder = firstReminder;
        
        while (nextReminder.isBefore(lastReminder) && notificationId <= 84) {
          if (nextReminder.isAfter(now)) {
            await notificationService.scheduleWaterReminderAt(
              scheduledTime: nextReminder,
              title: '💧 Stay Hydrated!',
              body: 'Time for a glass of water. Your body will thank you!',
            );
          }

          nextReminder = nextReminder.add(interval);
          notificationId++;
        }
      }
    } catch (e) {
      // Silently handle any errors
    }
  }

  Future<void> _addWater() async {
    if (waterIntake < waterDailyLimit) {
      final prefs = await SharedPreferences.getInstance();
      final bool wasCompleted = waterIntake >= waterDailyLimit;

      setState(() {
        waterIntake = (waterIntake + 0.25).clamp(0.0, waterDailyLimit);
        _isWaterAnimating = true;
      });
      await prefs.setDouble('water_intake', waterIntake);

      // Stop the water animation after a delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _isWaterAnimating = false;
          });
        }
      });

      // Check if goal was just completed
      if (!wasCompleted && waterIntake >= waterDailyLimit) {
        _rippleController.forward().then((_) {
          _rippleController.reset();
        });
        
        // Update progress tracking and save stats
        await _trackGoalCompletion('waterIntake');
        
        // Show completion message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.celebration, color: Colors.white),
                  SizedBox(width: 8),
                  Text(tr(context, 'daily_water_goal_completed')),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /// Track goal completion and update stats
  Future<void> _trackGoalCompletion(String goalType) async {
    try {
      // Get current health data
      final healthDataAsync = ref.read(healthDataNotifierProvider);
      
      if (healthDataAsync.hasValue) {
        final healthData = healthDataAsync.value!;
        
        // Update user progress with health data (this will save stats automatically)
        final progressNotifier = ref.read(userProgressNotifierProvider.notifier);
        await progressNotifier.updateProgress(healthData);
      }
    } catch (e) {
      // Error tracking goal completion: $e
    }
  }
  
  /// Check all goal completions when health data updates
  Future<void> _checkAllGoalCompletions() async {
    try {
      final healthDataAsync = ref.read(healthDataNotifierProvider);
      
      if (healthDataAsync.hasValue) {
        final healthData = healthDataAsync.value!;
        
        // Update user progress with health data (this will save stats automatically)
        final progressNotifier = ref.read(userProgressNotifierProvider.notifier);
        await progressNotifier.updateProgress(healthData);
      }
    } catch (e) {
      // Error checking goal completions: $e
    }
  }

  // Helper method to build platform-specific health profile image
  Widget _buildHealthProfileImage(AsyncValue<HealthPermissionStatus> permissionsStatus) {
    return permissionsStatus.when(
      data: (permissions) {
        if (permissions.isGranted) {
          // Show platform-specific health app icon when connected
          if (Platform.isAndroid) {
            return OrientedImage(
              imageUrl: 'assets/images/health/health_profile/health_connect.png',
              fit: BoxFit.cover,
              width: 60,
              height: 60,
            );
          } else if (Platform.isIOS) {
            return OrientedImage(
              imageUrl: 'assets/images/health/health_profile/apple_health.png',
              fit: BoxFit.cover,
              width: 60,
              height: 60,
            );
          }
        }
        // Fallback to default profile image when not connected
        return OrientedImage(
          imageUrl: 'assets/images/health/health_profile/profile.webp',
          fit: BoxFit.cover,
          width: 60,
          height: 60,
        );
      },
      loading: () => OrientedImage(
        imageUrl: 'assets/images/health/health_profile/profile.webp',
        fit: BoxFit.cover,
        width: 60,
        height: 60,
      ),
      error: (_, __) => OrientedImage(
        imageUrl: 'assets/images/health/health_profile/profile.webp',
        fit: BoxFit.cover,
        width: 60,
        height: 60,
      ),
    );
  }

  // Helper method to get platform-specific health connection text
  String _getHealthConnectionText(BuildContext context, AsyncValue<HealthPermissionStatus> permissionsStatus) {
    return permissionsStatus.when(
      data: (permissions) {
        if (permissions.isGranted) {
          if (Platform.isAndroid) {
            return tr(context, 'connected_with_health_connect');
          } else if (Platform.isIOS) {
            return tr(context, 'connected_with_apple_health');
          }
        }
        return tr(context, 'stats');
      },
      loading: () => tr(context, 'stats'),
      error: (_, __) => tr(context, 'stats'),
    );
  }

  void _navigateToWaterDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WaterDetailScreen(
          currentWaterIntake: waterIntake,
          onWaterIntakeChanged: (newIntake) {
            setState(() {
              waterIntake = newIntake;
            });
          },
        ),
      ),
    ).then((_) {
      // Reload water settings when returning from detail screen
      _loadWaterIntake();
    });
  }

  void _handleHealthProfileTap(AsyncValue<HealthPermissionStatus> permissionsStatus) {
    permissionsStatus.when(
      data: (permissions) {
        if (permissions.isGranted) {
          // Connected - show options to disconnect or open health app
          _showHealthConnectedDialog();
        } else {
          // Not connected - go to setup screen
          _navigateToHealthSetup();
        }
      },
      loading: () => _navigateToHealthSetup(),
      error: (_, __) => _navigateToHealthSetup(),
    );
  }

  void _navigateToHealthSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthSetupScreen(
          onSetupComplete: () {
            ref.invalidate(healthDataNotifierProvider);
            ref.invalidate(healthPermissionsNotifierProvider);
          },
        ),
      ),
    );
  }

  void _showHealthConnectedDialog() {
    final healthAppName = Platform.isAndroid ? 'Health Connect' : 'Apple Health';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'health_data_connected')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(context, 'health_data_is_syncing').replaceAll('{app}', healthAppName)),
            const SizedBox(height: 16),
            Text(
              tr(context, 'what_would_you_like_to_do'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr(context, 'cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final service = ref.read(healthDataServiceProvider);
              await service.openHealthConnectSettings();
            },
            child: Text(tr(context, 'open_health_app').replaceAll('{app}', healthAppName)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showDisconnectConfirmation();
            },
            child: Text(
              tr(context, 'disconnect'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showDisconnectConfirmation() {
    final healthAppName = Platform.isAndroid ? 'Health Connect' : 'Apple Health';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'disconnect_health_data')),
        content: Text(
          tr(context, 'disconnect_health_confirmation').replaceAll('{app}', healthAppName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr(context, 'cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _disconnectHealthData();
            },
            child: Text(
              tr(context, 'disconnect'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnectHealthData() async {
    try {
      // Clear permissions status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('health_permissions_granted', false);
      
      // Clear cached health data
      await prefs.remove('cached_health_data');
      await prefs.remove('last_health_sync');
      
      // Refresh providers to reflect disconnected state
      ref.invalidate(healthDataNotifierProvider);
      ref.invalidate(healthPermissionsNotifierProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'health_data_disconnected')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr(context, 'error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthDataAsync = ref.watch(healthDataNotifierProvider);
    final permissionsStatus = ref.watch(healthPermissionsNotifierProvider);
    final lastSyncAsync = ref.watch(lastSyncTimeProvider);
    
    // Listen for health data changes and check goal completions
    ref.listen<AsyncValue<HealthData>>(healthDataNotifierProvider, (previous, next) {
      if (next.hasValue && previous?.value != next.value) {
        // Health data updated, check if any goals were completed
        _checkAllGoalCompletions();
      }
    });
    
    // Get scroll controller directly in build method
    final scrollController = ref.read(scrollControllerNotifierProvider.notifier).getController('health');

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final notifier = ref.read(healthDataNotifierProvider.notifier);
            await notifier.syncHealthData();
          },
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr(context, 'fitness_profile'),
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildConnectionStatus(permissionsStatus),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildHealthDataStatus(
                    healthDataAsync,
                    permissionsStatus,
                    lastSyncAsync,
                  ),
                  const SizedBox(height: 20),
                  _buildUserOverviewCard(context, permissionsStatus),
                  const SizedBox(height: 20),
                  _buildMealsSection(context),
                  const SizedBox(height: 24),
                  _buildStatsGrid(context, healthDataAsync),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserOverviewCard(BuildContext context, AsyncValue<HealthPermissionStatus> permissionsStatus) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.2),
                AppColors.primary.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.1),
                spreadRadius: 0,
                blurRadius: 40,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _handleHealthProfileTap(permissionsStatus),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildHealthProfileImage(permissionsStatus),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(context, 'solarvita_fitness'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getHealthConnectionText(context, permissionsStatus),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ref.watch(dayStreakProvider)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    tr(context, 'day_streak'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(
    AsyncValue<HealthPermissionStatus> permissionsStatus,
  ) {
    return permissionsStatus.when(
      data: (permissions) {
        if (!permissions.isGranted) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HealthSetupScreen(
                    onSetupComplete: () {
                      ref.invalidate(healthDataNotifierProvider);
                      ref.invalidate(healthPermissionsNotifierProvider);
                    },
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(51),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withAlpha(102), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    tr(context, 'setup'),
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withAlpha(51),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withAlpha(102), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 4),
              Text(
                tr(context, 'connected'),
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.withAlpha(51),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.withAlpha(102), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              tr(context, 'connecting'),
              style: TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      error: (error, _) => GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HealthSetupScreen(
                onSetupComplete: () {
                  ref.invalidate(healthDataNotifierProvider);
                  ref.invalidate(healthPermissionsNotifierProvider);
                },
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(51),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withAlpha(102), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error, color: Colors.red, size: 16),
              const SizedBox(width: 4),
              Text(
                tr(context, 'error'),
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthDataStatus(
    AsyncValue<HealthData> healthDataAsync,
    AsyncValue<HealthPermissionStatus> permissionsStatus,
    AsyncValue<DateTime?> lastSyncAsync,
  ) {
    return permissionsStatus.when(
      data: (permissions) {
        if (!permissions.isGranted) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.health_and_safety, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr(context, 'connect_health_data_for_insights'),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HealthSetupScreen(
                          onSetupComplete: () {
                            ref.invalidate(healthDataNotifierProvider);
                            ref.invalidate(healthPermissionsNotifierProvider);
                          },
                        ),
                      ),
                    );
                  },
                  child: Text(tr(context, 'setup')),
                ),
              ],
            ),
          );
        }

        return lastSyncAsync.when(
          data: (lastSync) {
            final syncText = lastSync != null
                ? tr(
                    context,
                    'last_sync',
                  ).replaceAll('{time}', _formatSyncTime(context, lastSync))
                : tr(context, 'health_data_connected');

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      syncText,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (healthDataAsync.value?.isDataAvailable == true)
                    Icon(Icons.sync, color: Colors.green, size: 16),
                ],
              ),
            );
          },
          loading: () => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  tr(context, 'syncing_health_data'),
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          error: (error, _) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr(context, 'error_syncing_health_data'),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              tr(context, 'checking_health_permissions'),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tr(context, 'health_data_setup_error'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSyncTime(BuildContext context, DateTime syncTime) {
    final now = DateTime.now();
    final difference = now.difference(syncTime);

    if (difference.inMinutes < 1) {
      return tr(context, 'just_now');
    } else if (difference.inMinutes < 60) {
      return tr(
        context,
        'minutes_ago',
      ).replaceAll('{minutes}', difference.inMinutes.toString());
    } else if (difference.inHours < 24) {
      return tr(
        context,
        'hours_ago',
      ).replaceAll('{hours}', difference.inHours.toString());
    } else {
      return tr(
        context,
        'days_ago',
      ).replaceAll('{days}', difference.inDays.toString());
    }
  }

  Widget _buildStatsGrid(
    BuildContext context,
    AsyncValue<HealthData> healthDataAsync,
  ) {
    return healthDataAsync.when(
      data: (healthData) {
        // Get user's actual daily goals from user progress provider
        final userProgressAsync = ref.watch(userProgressNotifierProvider);

        // Calculate progress values using actual user goals
        final userProgress = userProgressAsync.value;
        final stepsGoal =
            userProgress?.dailyGoals.stepsGoal.toDouble() ?? 8000.0;
        final activeGoal =
            userProgress?.dailyGoals.activeMinutesGoal.toDouble() ?? 45.0;
        final caloriesGoal =
            userProgress?.dailyGoals.caloriesBurnGoal.toDouble() ?? 800.0;
        final sleepGoal =
            userProgress?.dailyGoals.sleepHoursGoal.toDouble() ?? 8.0;

        final stepsProgress = (healthData.steps / stepsGoal).clamp(0.0, 1.0);
        final activeProgress = (healthData.activeMinutes / activeGoal).clamp(
          0.0,
          1.0,
        );
        final caloriesProgress = (healthData.caloriesBurned / caloriesGoal)
            .clamp(0.0, 1.0);

        // Calculate proper heart rate progress based on target zones (resting: 60-70, target: 70-85% max)
        final heartRateProgress = healthData.heartRate > 0
            ? _calculateHeartRateProgress(healthData.heartRate)
            : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              _buildHorizontalStatCard(
                context,
                Icons.directions_walk,
                _formatNumber(healthData.steps),
                tr(context, 'steps'),
                tr(context, 'daily_walking_goal'),
                stepsProgress,
                Colors.blue,
                'steps',
                isHealthData: healthData.isDataAvailable,
              ),
              const SizedBox(height: 12),
              _buildHorizontalStatCard(
                context,
                Icons.directions_run,
                '${healthData.activeMinutes}min',
                tr(context, 'active_time'),
                tr(context, 'stats'),
                activeProgress,
                Colors.green,
                'active',
                isHealthData: healthData.isDataAvailable,
              ),
              const SizedBox(height: 12),
              _buildHorizontalStatCard(
                context,
                Icons.local_fire_department,
                _formatNumber(healthData.caloriesBurned),
                tr(context, 'calories_burned'),
                tr(context, 'energy_used_today'),
                caloriesProgress,
                Colors.orange,
                'calories',
                isHealthData: healthData.isDataAvailable,
              ),
              const SizedBox(height: 12),
              _buildWaterHorizontalCard(context),
              const SizedBox(height: 12),
              _buildSleepHorizontalCard(context, sleepGoal),
              const SizedBox(height: 12),
              _buildHorizontalStatCard(
                context,
                Icons.favorite,
                healthData.heartRate > 0
                    ? '${healthData.heartRate.toInt()} BPM'
                    : 'N/A',
                tr(context, 'heart_rate'),
                tr(context, 'cardiovascular_health'),
                heartRateProgress,
                Colors.red,
                'heart',
                isHealthData: healthData.isDataAvailable,
              ),
              const SizedBox(height: 12),
              const DailyExerciseSummaryCard(),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            for (int i = 0; i < 7; i++) ...[
              Container(
                height: 76,
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.textColor(context).withValues(alpha: 0.3),
                    ),
                    strokeWidth: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            // Show mock data on error
            _buildHorizontalStatCard(
              context,
              Icons.directions_walk,
              '2,146',
              tr(context, 'steps'),
              tr(context, 'daily_walking_goal'),
              0.7,
              Colors.blue,
              'steps',
              isHealthData: false,
            ),
            const SizedBox(height: 12),
            _buildHorizontalStatCard(
              context,
              Icons.directions_run,
              '45min',
              tr(context, 'active_time'),
              tr(context, 'stats'),
              0.8,
              Colors.green,
              'active',
              isHealthData: false,
            ),
            const SizedBox(height: 12),
            _buildHorizontalStatCard(
              context,
              Icons.local_fire_department,
              '320',
              tr(context, 'calories_burned'),
              tr(context, 'energy_used_today'),
              0.6,
              Colors.orange,
              'calories',
              isHealthData: false,
            ),
            const SizedBox(height: 12),
            _buildWaterHorizontalCard(context),
            const SizedBox(height: 12),
            _buildSleepHorizontalCard(context, 8.0),
            const SizedBox(height: 12),
            _buildHorizontalStatCard(
              context,
              Icons.favorite,
              '72 BPM',
              tr(context, 'heart_rate'),
              tr(context, 'cardiovascular_health'),
              0.85,
              Colors.red,
              'heart',
              isHealthData: false,
            ),
            const SizedBox(height: 12),
            const DailyExerciseSummaryCard(),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  Widget _buildHorizontalStatCard(
    BuildContext context,
    IconData icon,
    String value,
    String title,
    String subtitle,
    double progress,
    Color iconColor,
    String statType, {
    bool isHealthData = false,
  }) {
    return GestureDetector(
      onTap: () => _navigateWithAnimation(statType, iconColor),
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.textColor(context).withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Animated Icon
            AnimatedBuilder(
              animation: _iconAnimationControllers[statType]!,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    _getAnimationOffset(
                      statType,
                      _iconAnimationControllers[statType]!.value,
                    ),
                    0,
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            value,
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isHealthData)
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.health_and_safety,
                                  color: Colors.white,
                                  size: 8,
                                ),
                              ),
                            if (isHealthData) const SizedBox(width: 4),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(
                                color: iconColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textColor(
                          context,
                        ).withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Progress indicator
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                value: progress,
                backgroundColor: iconColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getAnimationOffset(String statType, double animationValue) {
    switch (statType) {
      case 'steps':
        // Walking animation - step by step
        return sin(animationValue * 4 * pi) * 8;
      case 'active':
        // Running animation - faster movement
        return sin(animationValue * 6 * pi) * 12;
      case 'calories':
        // Fire flickering
        return sin(animationValue * 8 * pi) * 4;
      case 'sleep':
        // Gentle floating like sleeping
        return sin(animationValue * 2 * pi) * 6;
      case 'heart':
        // Heart beat rhythm
        return animationValue < 0.5
            ? sin(animationValue * 8 * pi) * 10
            : sin(animationValue * 2 * pi) * 3;
      default:
        return 0;
    }
  }

  Future<void> _navigateWithAnimation(String statType, Color color) async {
    // Start the witty animation
    await _iconAnimationControllers[statType]!.forward();

    // Navigate to detail page
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StatDetailPage(statType: statType, color: color),
        ),
      );
    }

    // Reset animation
    _iconAnimationControllers[statType]!.reset();
  }

  Widget _buildWaterHorizontalCard(BuildContext context) {
    final waterPercentage = waterIntake / waterDailyLimit;
    final isGoalReached = waterIntake >= waterDailyLimit;

    return GestureDetector(
      onTap: isGoalReached ? _navigateToWaterDetail : _addWater,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 90,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyan.withValues(alpha: 0.15),
                  Colors.cyan.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isGoalReached
                    ? Colors.green.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isGoalReached
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.cyan.withValues(alpha: 0.1),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
                  spreadRadius: 0,
                  blurRadius: 40,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Rive water animation container
                RiveWaterWidget(
                  width: 48,
                  height: 48,
                  waterLevel: waterPercentage.clamp(0.0, 1.0),
                  isAnimating: _isWaterAnimating,
                  onAnimationComplete: () {
                    // Animation completed callback
                  },
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(waterIntake * 1000).toInt()}ml',
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${((waterIntake / waterDailyLimit) * 100).toInt()}%',
                                style: TextStyle(
                                  color: isGoalReached
                                      ? Colors.green
                                      : Colors.cyan,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isGoalReached) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        tr(context, 'water_intake'),
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        isGoalReached
                            ? tr(context, 'goal_completed_tap_to_manage')
                            : tr(context, 'tap_to_add_250ml').replaceAll(
                                '{goal}',
                                (waterDailyLimit * 1000).toInt().toString(),
                              ),
                        style: TextStyle(
                          color: AppTheme.textColor(
                            context,
                          ).withValues(alpha: 0.6),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Progress indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: waterPercentage.clamp(0.0, 1.0),
                    backgroundColor: Colors.cyan.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isGoalReached ? Colors.green : Colors.cyan,
                    ),
                    strokeWidth: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSleepHorizontalCard(BuildContext context, double sleepGoal) {
    final sleepProgress = manualSleepHours > 0 ? (manualSleepHours / sleepGoal).clamp(0.0, 1.0) : 0.0;
    final isGoalReached = manualSleepHours >= sleepGoal;

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sleep Toggle Widget
          SleepToggleWidget(
            width: 40,
            height: 40,
            onSleepUpdated: _onSleepUpdated,
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          manualSleepHours > 0 
                              ? '${manualSleepHours.toStringAsFixed(1)}h'
                              : tr(context, 'no_data'),
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isGoalReached)
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 8,
                              ),
                            ),
                          if (isGoalReached) const SizedBox(width: 4),
                          Text(
                            '${(sleepProgress * 100).toInt()}%',
                            style: TextStyle(
                              color: Colors.indigo,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Text(
                    tr(context, 'sleep_quality'),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    manualSleepHours > 0
                        ? tr(context, 'tap_to_edit_sleep')
                        : tr(context, 'tap_to_log_sleep'),
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Progress indicator
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              value: sleepProgress,
              backgroundColor: Colors.indigo.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
              strokeWidth: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'friendly_meals'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildMealPlanningCard(context),
      ],
    );
  }

  Widget _buildMealPlanningCard(BuildContext context) {
    return Container(
      width: double
          .infinity, // Makes the card expand to the full width of its parent
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            OrientedImage(
              imageUrl: 'assets/images/health/meals/meal.webp',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 180,
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    tr(context, 'meal_planning'),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'plan_healthy_eco_meals'),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      height: 1.3,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MealPlanScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        tr(context, 'explore_meals'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final BuildContext context;

  const StatItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          tr(context, title),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          tr(context, subtitle),
          style: TextStyle(
            color: AppTheme.textColor(context).withValues(alpha: 153),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class StatDetailPage extends ConsumerWidget {
  final String statType;
  final Color color;

  const StatDetailPage({
    super.key,
    required this.statType,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthDataAsync = ref.watch(healthDataNotifierProvider);
    final userProgressAsync = ref.watch(userProgressNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textColor(context)),
        ),
        title: Text(
          _getStatTitle(context, statType),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Hero card
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.3),
                        color.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatIcon(statType),
                        color: color,
                        size: 56, // Reduced from 64
                      ),
                      const SizedBox(height: 12), // Reduced from 16
                      Flexible(
                        child: Text(
                          _getStatValue(
                            statType,
                            healthDataAsync,
                            userProgressAsync,
                          ),
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontSize: 32, // Reduced from 36
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: Text(
                          _getStatSubtitle(context, statType),
                          style: TextStyle(
                            color: AppTheme.textColor(
                              context,
                            ).withValues(alpha: 0.7),
                            fontSize: 14, // Reduced from 16
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Details cards
            ..._getDetailCards(
              context,
              statType,
              color,
              healthDataAsync,
              userProgressAsync,
            ),
          ],
        ),
      ),
    );
  }

  String _getStatTitle(BuildContext context, String statType) {
    switch (statType) {
      case 'steps':
        return tr(context, 'steps_tracking');
      case 'active':
        return tr(context, 'active_time');
      case 'calories':
        return tr(context, 'calories_burned');
      case 'sleep':
        return tr(context, 'sleep_quality');
      case 'heart':
        return tr(context, 'heart_rate');
      default:
        return tr(context, 'health_stats');
    }
  }

  IconData _getStatIcon(String statType) {
    switch (statType) {
      case 'steps':
        return Icons.directions_walk;
      case 'active':
        return Icons.directions_run;
      case 'calories':
        return Icons.local_fire_department;
      case 'sleep':
        return Icons.bedtime;
      case 'heart':
        return Icons.favorite;
      default:
        return Icons.analytics;
    }
  }

  String _getStatValue(
    String statType,
    AsyncValue<HealthData> healthDataAsync,
    AsyncValue<UserProgress> userProgressAsync,
  ) {
    return healthDataAsync.when(
      data: (healthData) {
        switch (statType) {
          case 'steps':
            return StatDetailPage._formatNumber(healthData.steps);
          case 'active':
            return '${healthData.activeMinutes}min';
          case 'calories':
            return StatDetailPage._formatNumber(healthData.caloriesBurned);
          case 'sleep':
            return '${healthData.sleepHours.toStringAsFixed(1)}h';
          case 'heart':
            return healthData.heartRate > 0
                ? '${healthData.heartRate.toInt()}'
                : 'N/A';
          default:
            return '0';
        }
      },
      loading: () => '...',
      error: (_, __) => 'N/A',
    );
  }

  String _getStatSubtitle(BuildContext context, String statType) {
    switch (statType) {
      case 'steps':
        return tr(context, 'steps_today');
      case 'active':
        return tr(context, 'active_minutes');
      case 'calories':
        return tr(context, 'calories_burned_subtitle');
      case 'sleep':
        return tr(context, 'hours_of_sleep');
      case 'heart':
        return tr(context, 'bpm_average');
      default:
        return tr(context, 'data_points');
    }
  }

  List<Widget> _getDetailCards(
    BuildContext context,
    String statType,
    Color color,
    AsyncValue<HealthData> healthDataAsync,
    AsyncValue<UserProgress> userProgressAsync,
  ) {
    return [
      _buildDetailCard(
        context,
        tr(context, 'today_goal'),
        _getTodayGoal(context, statType, healthDataAsync, userProgressAsync),
        _getTodayProgress(
          context,
          statType,
          healthDataAsync,
          userProgressAsync,
        ),
        color,
      ),
      const SizedBox(height: 16),
      _buildDetailCard(
        context,
        tr(context, 'best_this_week'),
        _getBestWeek(context, statType, healthDataAsync),
        _getWeeklyProgress(context, statType, healthDataAsync),
        color,
      ),
      const SizedBox(height: 16),
      _buildDetailCard(
        context,
        tr(context, 'data_status'),
        _getDataStatus(context, statType, healthDataAsync),
        _getDataStatusProgress(context, statType, healthDataAsync),
        color,
      ),
    ];
  }

  Widget _buildDetailCard(
    BuildContext context,
    String title,
    String value,
    double progress,
    Color color,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textColor(
                          context,
                        ).withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTodayGoal(
    BuildContext context,
    String statType,
    AsyncValue<HealthData> healthDataAsync,
    AsyncValue<UserProgress> userProgressAsync,
  ) {
    return healthDataAsync.when(
      data: (healthData) {
        return userProgressAsync.when(
          data: (userProgress) {
            switch (statType) {
              case 'steps':
                final goal = userProgress.dailyGoals.stepsGoal;
                return '${StatDetailPage._formatNumber(healthData.steps)} / ${StatDetailPage._formatNumber(goal)}';
              case 'active':
                final goal = userProgress.dailyGoals.activeMinutesGoal;
                return '${healthData.activeMinutes} / $goal min';
              case 'calories':
                final goal = userProgress.dailyGoals.caloriesBurnGoal;
                return '${StatDetailPage._formatNumber(healthData.caloriesBurned)} / ${StatDetailPage._formatNumber(goal)} cal';
              case 'sleep':
                final goal = userProgress.dailyGoals.sleepHoursGoal
                    .toStringAsFixed(1);
                return '${healthData.sleepHours.toStringAsFixed(1)} / $goal hrs';
              case 'heart':
                if (healthData.heartRate > 0) {
                  final hr = healthData.heartRate.toInt();
                  final status = hr < 60
                      ? tr(context, 'low')
                      : hr > 100
                      ? tr(context, 'high')
                      : tr(context, 'normal');
                  return '$hr BPM ($status)';
                }
                return tr(context, 'no_data');
              default:
                return 'N/A';
            }
          },
          loading: () => tr(context, 'loading_goals'),
          error: (_, __) => tr(context, 'goal_unavailable'),
        );
      },
      loading: () => tr(context, 'loading'),
      error: (_, __) => tr(context, 'data_unavailable'),
    );
  }

  double _getTodayProgress(
    BuildContext context,
    String statType,
    AsyncValue<HealthData> healthDataAsync,
    AsyncValue<UserProgress> userProgressAsync,
  ) {
    return healthDataAsync.when(
      data: (healthData) {
        return userProgressAsync.when(
          data: (userProgress) {
            switch (statType) {
              case 'steps':
                final goal = userProgress.dailyGoals.stepsGoal.toDouble();
                return (healthData.steps / goal).clamp(0.0, 1.0);
              case 'active':
                final goal = userProgress.dailyGoals.activeMinutesGoal
                    .toDouble();
                return (healthData.activeMinutes / goal).clamp(0.0, 1.0);
              case 'calories':
                final goal = userProgress.dailyGoals.caloriesBurnGoal
                    .toDouble();
                return (healthData.caloriesBurned / goal).clamp(0.0, 1.0);
              case 'sleep':
                final goal = userProgress.dailyGoals.sleepHoursGoal;
                return (healthData.sleepHours / goal).clamp(0.0, 1.0);
              case 'heart':
                // For heart rate, show health status instead of goal progress
                if (healthData.heartRate > 0) {
                  final hr = healthData.heartRate;
                  // Optimal heart rate range is roughly 50-90 BPM at rest
                  if (hr >= 50 && hr <= 90) return 1.0; // Perfect
                  if (hr >= 40 && hr <= 100) return 0.8; // Good
                  if (hr >= 35 && hr <= 110) return 0.6; // Fair
                  return 0.3; // Needs attention
                }
                return 0.0;
              default:
                return 0.0;
            }
          },
          loading: () => 0.0,
          error: (_, __) => 0.0,
        );
      },
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );
  }

  String _getBestWeek(
    BuildContext context,
    String statType,
    AsyncValue<HealthData> healthDataAsync,
  ) {
    return healthDataAsync.when(
      data: (healthData) {
        switch (statType) {
          case 'steps':
            // Estimate best day this week (current × 1.2)
            final best = (healthData.steps * 1.2).round();
            return '${StatDetailPage._formatNumber(best)} ${tr(context, 'best_day')}';
          case 'active':
            final best = (healthData.activeMinutes * 1.3).round();
            return '$best min ${tr(context, 'best_day')}';
          case 'calories':
            final best = (healthData.caloriesBurned * 1.4).round();
            return '${StatDetailPage._formatNumber(best)} cal ${tr(context, 'best_day')}';
          case 'sleep':
            final best = (healthData.sleepHours + 0.8).clamp(0.0, 12.0);
            return '${best.toStringAsFixed(1)} hrs ${tr(context, 'best_night')}';
          case 'heart':
            if (healthData.heartRate > 0) {
              return '${healthData.heartRate.toInt()} BPM ${tr(context, 'current')}';
            }
            return tr(context, 'no_recent_data');
          default:
            return 'N/A';
        }
      },
      loading: () => tr(context, 'loading'),
      error: (_, __) => tr(context, 'data_unavailable'),
    );
  }

  double _getWeeklyProgress(
    BuildContext context,
    String statType,
    AsyncValue<HealthData> healthDataAsync,
  ) {
    return healthDataAsync.when(
      data: (healthData) {
        switch (statType) {
          case 'steps':
            // Progress based on data availability and reasonable performance
            return healthData.steps > 0 ? 0.8 : 0.1;
          case 'active':
            return healthData.activeMinutes > 0 ? 0.85 : 0.1;
          case 'calories':
            return healthData.caloriesBurned > 0 ? 0.75 : 0.1;
          case 'sleep':
            return healthData.sleepHours > 0 ? 0.9 : 0.1;
          case 'heart':
            return healthData.heartRate > 0 ? 0.85 : 0.1;
          default:
            return 0.0;
        }
      },
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );
  }

  String _getDataStatus(
    BuildContext context,
    String statType,
    AsyncValue<HealthData> healthDataAsync,
  ) {
    return healthDataAsync.when(
      data: (healthData) {
        final lastUpdated = healthData.lastUpdated;
        final hoursAgo = DateTime.now().difference(lastUpdated).inHours;

        if (healthData.isDataAvailable) {
          if (hoursAgo < 1) {
            return tr(context, 'real_time_sync');
          } else if (hoursAgo < 24) {
            return tr(
              context,
              'synced_hours_ago',
            ).replaceAll('{hours}', hoursAgo.toString());
          } else {
            return tr(
              context,
              'last_sync_days_ago',
            ).replaceAll('{days}', (hoursAgo / 24).round().toString());
          }
        } else {
          return tr(context, 'no_health_data_connected');
        }
      },
      loading: () => tr(context, 'connecting_to_health_data'),
      error: (_, __) => tr(context, 'health_data_sync_error'),
    );
  }

  double _getDataStatusProgress(
    BuildContext context,
    String statType,
    AsyncValue<HealthData> healthDataAsync,
  ) {
    return healthDataAsync.when(
      data: (healthData) {
        if (!healthData.isDataAvailable) return 0.0;

        final hoursAgo = DateTime.now()
            .difference(healthData.lastUpdated)
            .inHours;
        if (hoursAgo < 1) return 1.0;
        if (hoursAgo < 6) return 0.8;
        if (hoursAgo < 24) return 0.6;
        return 0.3;
      },
      loading: () => 0.5,
      error: (_, __) => 0.0,
    );
  }

  static String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
