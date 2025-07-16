import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/notification_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Public getter for the local notifications plugin
  FlutterLocalNotificationsPlugin get localNotifications => _localNotifications;

  // Notification preferences keys
  static const String _workoutRemindersKey = 'workout_reminders';
  static const String _ecoTipsKey = 'eco_tips';
  static const String _progressUpdatesKey = 'progress_updates';
  static const String _waterRemindersKey = 'water_reminders';
  static const String _mealRemindersKey = 'meal_reminders';
  static const String _enhancedNotificationPreferencesKey = 'enhanced_notification_preferences';

  bool _isInitialized = false;

  // Getter for initialization status
  bool get isInitialized => _isInitialized;

  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {

      // Initialize timezone first
      await _ensureTimeZoneInitialized();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize push notifications
      await _initializePushNotifications();

      _isInitialized = true;
    } catch (e) {
      rethrow;
    }
  }

  // Ensure timezone is properly initialized
  Future<void> _ensureTimeZoneInitialized() async {
    try {
      tz.initializeTimeZones();

      // Try to set local timezone, fallback to UTC if it fails
      try {
        // For most cases, just use the local timezone
        tz.setLocalLocation(tz.local);
      } catch (e) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    } catch (e) {
      rethrow;
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        
        // Register Android notification channels
        await _createNotificationChannels();
      } else {
      }
    } catch (e) {
      rethrow;
    }
  }

  // Create and register all notification channels for Android
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;
    
    try {
      
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin == null) {
        return;
      }

      final channels = [
        const AndroidNotificationChannel(
          'default_channel',
          '🌟 SolarVita',
          description: 'General SolarVita notifications',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF4CAF50),
          showBadge: true,
        ),
        const AndroidNotificationChannel(
          'test_simple',
          'Test Simple',
          description: 'Simple test notifications',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
        const AndroidNotificationChannel(
          'test_scheduled',
          'Test Scheduled',
          description: 'Test scheduled notifications',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
        const AndroidNotificationChannel(
          'delayed_test',
          'Delayed Test',
          description: 'Delayed test notifications',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
        const AndroidNotificationChannel(
          'workout_reminders',
          '💪 Fitness Reminders',
          description: 'Your personal workout motivation',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFFFF5722),
          showBadge: true,
        ),
        const AndroidNotificationChannel(
          'water_reminders',
          '💧 Hydration Alerts',
          description: 'Stay healthy, stay hydrated',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF2196F3),
          showBadge: true,
        ),
        const AndroidNotificationChannel(
          'eco_tips',
          '🌱 Green Living',
          description: 'Daily sustainability inspiration',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF4CAF50),
          showBadge: true,
        ),
        const AndroidNotificationChannel(
          'progress_updates',
          '🎉 Achievements',
          description: 'Celebrate your amazing progress',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFFFFD700),
          showBadge: true,
        ),
        const AndroidNotificationChannel(
          'meal_reminders',
          '🍽️ Nutrition Time',
          description: 'Fuel your body right',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFFFF9800),
          showBadge: true,
        ),
        const AndroidNotificationChannel(
          'solar_vitas_reminders',
          '✨ Personal Coach',
          description: 'Your AI-powered wellness companion',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF9C27B0),
          showBadge: true,
        ),
      ];

      for (final channel in channels) {
        await androidPlugin.createNotificationChannel(channel);
      }
      
    } catch (e) {
      rethrow;
    }
  }

  // Initialize push notifications
  Future<void> _initializePushNotifications() async {
    try {

      // Request permission
      await _requestNotificationPermissions();

      // Get FCM token
      await _firebaseMessaging.getToken();

      // Configure message handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    } catch (e) {
      // Don't rethrow - push notifications are optional
    }
  }

  // Request notification permissions
  Future<bool> _requestNotificationPermissions() async {
    try {
      if (Platform.isIOS) {
        final settings = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        return settings.authorizationStatus == AuthorizationStatus.authorized;
      } else {
        // For Android, request notification permission
        final notificationStatus = await Permission.notification.request();
        
        // For Android 13+, also request schedule exact alarm permission
        if (Platform.isAndroid) {
          try {
            await Permission.scheduleExactAlarm.request();
          } catch (e) {
            // Permission request failed, continue without schedule exact alarm
          }
        }
        
        return notificationStatus.isGranted;
      }
    } catch (e) {
      return false;
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        _handleNotificationNavigation(data);
      } catch (e) {
        // Failed to parse notification payload
      }
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotificationFromRemote(message);
  }

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  }

  // Show local notification from remote message
  Future<void> _showLocalNotificationFromRemote(RemoteMessage message) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'default_channel',
        'Default Channel',
        channelDescription: 'Default notification channel',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        message.notification?.title ?? 'SolarVita',
        message.notification?.body ?? '',
        details,
        payload: json.encode(message.data),
      );
    } catch (e) {
      // Failed to show local notification from remote message
    }
  }

  // Handle notification navigation
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] ?? '';

    switch (type) {
      case 'workout_reminder':
        // Navigate to workout screen
        break;
      case 'progress_update':
        // Navigate to progress screen
        break;
      case 'eco_tip':
        // Navigate to eco tips screen
        break;
      case 'water_reminder':
        // Navigate to health/hydration screen
        break;
      default:
        // Navigate to main screen
        break;
    }
  }


  // ====================
  // NOTIFICATION METHODS
  // ====================

  // Schedule workout reminder
  // Update this method in NotificationService
  Future<void> scheduleWorkoutReminder({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? workoutType,
  }) async {
    if (!await _isNotificationTypeEnabled(_workoutRemindersKey)) {
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'workout_reminders',
        'Workout Reminders',
        channelDescription: 'Reminders for scheduled workouts',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final payload = json.encode({
        'type': 'workout_reminder',
        'workoutType': workoutType,
      });

      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
      final notificationId = _generateNotificationId();


      await _localNotifications.zonedSchedule(
        notificationId,
        title,
        body,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

    } catch (e) {
      rethrow;
    }
  }

  // Schedule water reminder
  Future<void> scheduleWaterReminder() async {
    if (!await _isNotificationTypeEnabled(_waterRemindersKey)) {
      return;
    }

    try {
      // Schedule multiple water reminders throughout the day
      final now = DateTime.now();
      final reminderTimes = [10, 12, 15, 17, 19]; // Hours of the day

      for (final hour in reminderTimes) {
        final scheduledTime = DateTime(now.year, now.month, now.day, hour);

        if (scheduledTime.isAfter(now)) {
          await _scheduleRepeatingNotification(
            id: _generateNotificationId(),
            title: '💧 Stay Hydrated!',
            body: 'Time for a glass of water. Your body will thank you!',
            scheduledTime: scheduledTime,
            repeatInterval: RepeatInterval.daily,
            channelId: 'water_reminders',
            channelName: 'Water Reminders',
            notificationType: 'water_reminder',
          );
        }
      }

    } catch (e) {
      rethrow;
    }
  }

  // Schedule eco tip
  Future<void> scheduleEcoTip({
    required String tip,
    DateTime? scheduledTime,
  }) async {
    if (!await _isNotificationTypeEnabled(_ecoTipsKey)) {
      return;
    }

    try {
      final time =
          scheduledTime ?? DateTime.now().add(const Duration(hours: 2));

      await _scheduleRepeatingNotification(
        id: _generateNotificationId(),
        title: '🌱 Eco Tip of the Day',
        body: tip,
        scheduledTime: time,
        repeatInterval: RepeatInterval.daily,
        channelId: 'eco_tips',
        channelName: 'Eco Tips',
        notificationType: 'eco_tip',
      );

    } catch (e) {
      rethrow;
    }
  }

  // Send progress celebration
  Future<void> sendProgressCelebration({
    required String achievement,
    required String message,
  }) async {
    if (!await _isNotificationTypeEnabled(_progressUpdatesKey)) {
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'progress_updates',
        'Progress Updates',
        channelDescription: 'Celebrations and progress milestones',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4CAF50),
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final payload = json.encode({
        'type': 'progress_update',
        'achievement': achievement,
      });

      await _localNotifications.show(
        _generateNotificationId(),
        '🎉 $achievement',
        message,
        details,
        payload: payload,
      );

    } catch (e) {
      rethrow;
    }
  }

  // Schedule meal reminder
  Future<void> scheduleMealReminder({
    required String mealType,
    required DateTime scheduledTime,
    String? customMessage,
  }) async {
    if (!await _isNotificationTypeEnabled(_mealRemindersKey)) {
      return;
    }

    try {
      final title = _getMealReminderTitle(mealType);
      final body = customMessage ?? _getMealReminderBody(mealType);

      // Cancel any existing meal reminders for this type first
      await _cancelMealReminder(mealType);

      const androidDetails = AndroidNotificationDetails(
        'meal_reminders',
        'Meal Reminders',
        channelDescription: 'Daily meal reminder notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final payload = json.encode({
        'type': 'meal_reminder',
        'mealType': mealType,
      });

      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      // Use a consistent ID for each meal type so we can cancel/update them
      final notificationId = _getMealNotificationId(mealType);


      await _localNotifications.zonedSchedule(
        notificationId,
        title,
        body,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents:
            DateTimeComponents.time, // This makes it repeat daily!
      );

    } catch (e) {
      rethrow;
    }
  }

// ADD THESE HELPER METHODS TO YOUR NotificationService:
  int _getMealNotificationId(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 1001;
      case 'lunch':
        return 1002;
      case 'dinner':
        return 1003;
      case 'snacks':
        return 1004;
      default:
        return 1000;
    }
  }

  Future<void> _cancelMealReminder(String mealType) async {
    try {
      final id = _getMealNotificationId(mealType);
      await _localNotifications.cancel(id);
    } catch (e) {
      // Failed to cancel meal reminder
    }
  }

  // Helper method for repeating notifications
  Future<void> _scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required RepeatInterval repeatInterval,
    required String channelId,
    required String channelName,
    required String notificationType,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: const BigTextStyleInformation(''),
        playSound: true,
        enableVibration: true,
        enableLights: true,
        colorized: true,
        showWhen: true,
        channelShowBadge: true,
        autoCancel: true,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final payload = json.encode({'type': notificationType});
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      rethrow;
    }
  }

  // ====================
  // PREFERENCES & UTILITY
  // ====================

  // Notification preferences
  Future<bool> _isNotificationTypeEnabled(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? true; // Default to enabled
    } catch (e) {
      return true;
    }
  }

  Future<void> setNotificationPreference(String key, bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, enabled);
    } catch (e) {
      rethrow;
    }
  }

  // Getters for notification preferences
  Future<bool> get workoutRemindersEnabled =>
      _isNotificationTypeEnabled(_workoutRemindersKey);
  Future<bool> get ecoTipsEnabled => _isNotificationTypeEnabled(_ecoTipsKey);
  Future<bool> get progressUpdatesEnabled =>
      _isNotificationTypeEnabled(_progressUpdatesKey);
  Future<bool> get waterRemindersEnabled =>
      _isNotificationTypeEnabled(_waterRemindersKey);
  Future<bool> get mealRemindersEnabled =>
      _isNotificationTypeEnabled(_mealRemindersKey);

  // Helper methods
  String _getMealReminderTitle(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '🌅 Rise & Fuel!';
      case 'lunch':
        return '☀️ Midday Energy!';
      case 'dinner':
        return '🌙 Evening Nourishment!';
      case 'snacks':
        return '⚡ Power Snack!';
      default:
        return '🍽️ Nutrition Time!';
    }
  }

  String _getMealReminderBody(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'Start your day strong with nutritious fuel for your body 💪';
      case 'lunch':
        return 'Recharge your energy with a healthy, delicious lunch 🚀';
      case 'dinner':
        return 'Wind down with a satisfying meal to recover and restore 🌟';
      case 'snacks':
        return 'Keep your energy flowing with a smart, healthy snack 🔋';
      default:
        return 'Nourish your body, fuel your dreams 💫';
    }
  }

  int _generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
  }

  // Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _localNotifications.pendingNotificationRequests();
    } catch (e) {
      return [];
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      rethrow;
    }
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
    } catch (e) {
      rethrow;
    }
  }

  // Get FCM token for push notifications
  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      return null;
    }
  }

  // ====================
  // ENHANCED NOTIFICATION PREFERENCES
  // ====================

  /// Save enhanced notification preferences
  Future<void> saveNotificationPreferences(NotificationPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(preferences.toMap());
      await prefs.setString(_enhancedNotificationPreferencesKey, jsonString);
    } catch (e) {
      rethrow;
    }
  }

  /// Load enhanced notification preferences
  Future<NotificationPreferences?> loadNotificationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_enhancedNotificationPreferencesKey);
      if (jsonString != null) {
        final Map<String, dynamic> map = jsonDecode(jsonString);
        return NotificationPreferences.fromMap(map);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Schedule personalized workout notification
  Future<void> schedulePersonalizedWorkoutReminder({
    required WorkoutNotificationSettings settings,
    required Map<String, bool> availableDays,
    required List<String> workoutTypes,
    required String preferredTime,
  }) async {
    if (!settings.enabled) return;

    try {
      // Cancel existing workout notifications
      await cancelNotificationsByType('workout');

      for (final dayEntry in availableDays.entries) {
        if (!dayEntry.value) continue; // Skip unavailable days

        final day = dayEntry.key;
        DateTime scheduledTime;

        if (settings.timingType == NotificationTimingType.specificTime && settings.specificTime != null) {
          // Use specific time
          scheduledTime = _getNextOccurrenceOfTime(day, settings.specificTime!);
        } else {
          // Use random time within preferred period
          scheduledTime = _getRandomTimeInPeriod(day, settings.timePeriod);
        }

        // Subtract advance minutes
        scheduledTime = scheduledTime.subtract(Duration(minutes: settings.advanceMinutes));

        // Generate notification ID
        final notificationId = _generateNotificationId();

        // Create notification
        await _scheduleNotification(
          id: notificationId,
          title: '🏋️ Workout Reminder',
          body: 'Time for your ${workoutTypes.isNotEmpty ? workoutTypes.first : "workout"} session!',
          scheduledDate: scheduledTime,
          payload: jsonEncode({
            'type': 'workout',
            'day': day,
            'workoutType': workoutTypes.isNotEmpty ? workoutTypes.first : 'general',
          }),
        );

      }
    } catch (e) {
      rethrow;
    }
  }

  /// Schedule personalized diary notifications
  Future<void> schedulePersonalizedDiaryReminders({
    required DiaryNotificationSettings settings,
  }) async {
    if (!settings.enabled) return;

    try {
      // Cancel existing diary notifications
      await cancelNotificationsByType('diary');

      DateTime scheduledTime;

      if (settings.timingType == NotificationTimingType.specificTime && settings.specificTime != null) {
        // Use specific time
        scheduledTime = _getNextOccurrenceOfTime('today', settings.specificTime!);
      } else {
        // Use random time within preferred period
        scheduledTime = _getRandomTimeInPeriod('today', settings.timePeriod);
      }

      // Generate notification ID
      final notificationId = _generateNotificationId();

      // Create notification
      await _scheduleNotification(
        id: notificationId,
        title: '📖 Diary Reminder',
        body: 'Time to reflect on your day and update your diary!',
        scheduledDate: scheduledTime,
        payload: jsonEncode({
          'type': 'diary',
          'scheduledTime': scheduledTime.toIso8601String(),
        }),
      );

    } catch (e) {
      rethrow;
    }
  }

  /// Schedule personalized meal notifications
  Future<void> schedulePersonalizedMealReminders({
    required MealNotificationSettings settings,
    required Map<String, String> mealTimes, // mealType -> time string
    Map<String, String>? customMealNames, // mealType -> custom name from meal plan
  }) async {
    if (!settings.enabled) return;

    try {
      // Cancel existing meal notifications
      await cancelNotificationsByType('meal');

      for (final mealEntry in mealTimes.entries) {
        final mealType = mealEntry.key;
        final mealTimeStr = mealEntry.value;
        final config = settings.mealConfigs[mealType];

        if (config == null || !config.enabled) continue;

        DateTime scheduledTime;

        if (config.timingType == NotificationTimingType.specificTime && config.specificTime != null) {
          // Use specific time
          scheduledTime = _getNextOccurrenceOfTime('today', config.specificTime!);
        } else {
          // Use meal time from dietary preferences with some randomness
          final mealTime = _parseTimeOfDay(mealTimeStr);
          final randomMinutes = (DateTime.now().millisecond % 30) - 15; // ±15 minutes
          scheduledTime = _getNextOccurrenceOfTime('today', mealTime).add(Duration(minutes: randomMinutes));
        }

        // Subtract advance minutes
        scheduledTime = scheduledTime.subtract(Duration(minutes: config.advanceMinutes));

        // Get meal name (custom from meal plan or default)
        String mealName = config.customMealName ?? 
                         customMealNames?[mealType] ?? 
                         _getMealDisplayName(mealType);

        // Generate notification ID
        final notificationId = _generateNotificationId();

        // Create notification
        await _scheduleNotification(
          id: notificationId,
          title: _getMealReminderTitle(mealType),
          body: '$mealName - Time for your $mealType!',
          scheduledDate: scheduledTime,
          payload: jsonEncode({
            'type': 'meal',
            'mealType': mealType,
            'customName': mealName,
          }),
        );

      }
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel notifications by type
  Future<void> cancelNotificationsByType(String type) async {
    try {
      final pendingNotifications = await getPendingNotifications();
      for (final notification in pendingNotifications) {
        if (notification.payload != null && notification.payload!.contains('"type":"$type"')) {
          await cancelNotification(notification.id);
        }
      }
    } catch (e) {
      // Failed to cancel notifications by type
    }
  }

  /// Parse time string to TimeOfDay
  TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  /// Get next occurrence of specific time
  DateTime _getNextOccurrenceOfTime(String day, TimeOfDay time) {
    final now = DateTime.now();
    DateTime scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    if (day != 'today') {
      // Calculate next occurrence of specific day
      final dayIndex = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'].indexOf(day);
      if (dayIndex != -1) {
        final currentDayIndex = now.weekday - 1;
        int daysToAdd = dayIndex - currentDayIndex;
        if (daysToAdd <= 0) daysToAdd += 7;
        scheduled = scheduled.add(Duration(days: daysToAdd));
      }
    } else {
      // For 'today', if the time has passed, schedule for tomorrow
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    }
    
    return scheduled;
  }

  /// Test meal notification with current time + offset for debugging
  Future<void> testMealNotificationNow({int offsetMinutes = 1}) async {
    try {
      final testTime = DateTime.now().add(Duration(minutes: offsetMinutes));
      final testId = _generateNotificationId();
      
      
      await _scheduleNotification(
        id: testId,
        title: '🍽️ Test Meal Reminder',
        body: 'This is a test meal notification scheduled for ${testTime.toString().substring(11, 16)}',
        scheduledDate: testTime,
        payload: jsonEncode({
          'type': 'test_meal',
          'timestamp': testTime.millisecondsSinceEpoch,
        }),
      );
      
    } catch (e) {
      rethrow;
    }
  }

  /// Get random time within specified period
  DateTime _getRandomTimeInPeriod(String day, String period) {
    final periodData = TimePeriods.getPeriod(period);
    if (periodData == null) return DateTime.now().add(const Duration(hours: 1));
    
    final startHour = periodData['start']!;
    final endHour = periodData['end']!;
    final randomHour = startHour + (DateTime.now().millisecond % (endHour - startHour));
    final randomMinute = DateTime.now().microsecond % 60;
    
    return _getNextOccurrenceOfTime(day, TimeOfDay(hour: randomHour, minute: randomMinute));
  }

  /// Get display name for meal type
  String _getMealDisplayName(String mealType) {
    switch (mealType) {
      case 'breakfast': return 'Breakfast';
      case 'lunch': return 'Lunch';
      case 'dinner': return 'Dinner';
      case 'snacks': return 'Snack Time';
      default: return mealType;
    }
  }

  /// Schedule a notification at specific date/time
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      final scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);
      
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTZ,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'solar_vitas_reminders',
            'SolarVita Reminders',
            channelDescription: 'Personalized reminders for workouts and meals',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      rethrow;
    }
  }
}
