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
import 'package:logging/logging.dart';
import '../models/notification_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger('NotificationService');

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
      _logger.info('Starting notification service initialization...');

      // Initialize timezone first
      await _ensureTimeZoneInitialized();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize push notifications
      await _initializePushNotifications();

      _isInitialized = true;
      _logger.info('Notification service initialized successfully');
    } catch (e) {
      _logger.severe('Failed to initialize notification service: $e');
      rethrow;
    }
  }

  // Ensure timezone is properly initialized
  Future<void> _ensureTimeZoneInitialized() async {
    try {
      _logger.info('Initializing timezone...');
      tz.initializeTimeZones();

      // Try to set local timezone, fallback to UTC if it fails
      try {
        final String currentTimeZone = DateTime.now().timeZoneName;
        _logger.info('System timezone: $currentTimeZone');

        // For most cases, just use the local timezone
        tz.setLocalLocation(tz.local);
        _logger.info('Timezone set to local: ${tz.local.name}');
      } catch (e) {
        _logger.warning('Failed to set local timezone, using UTC: $e');
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    } catch (e) {
      _logger.severe('Failed to initialize timezone: $e');
      rethrow;
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      _logger.info('Initializing local notifications...');

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
        _logger.info('Local notifications initialized successfully');
      } else {
        _logger.warning('Local notifications initialization returned false');
      }
    } catch (e) {
      _logger.severe('Failed to initialize local notifications: $e');
      rethrow;
    }
  }

  // Initialize push notifications
  Future<void> _initializePushNotifications() async {
    try {
      _logger.info('Initializing push notifications...');

      // Request permission
      final hasPermission = await _requestNotificationPermissions();
      _logger.info('Notification permissions granted: $hasPermission');

      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      _logger.info('FCM Token: ${token?.substring(0, 20)}...');

      // Configure message handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      _logger.info('Push notifications initialized successfully');
    } catch (e) {
      _logger.severe('Failed to initialize push notifications: $e');
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
        // For Android, request permission
        final status = await Permission.notification.request();
        return status.isGranted;
      }
    } catch (e) {
      _logger.severe('Failed to request notification permissions: $e');
      return false;
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    _logger.info('Notification tapped: ${response.payload}');
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        _handleNotificationNavigation(data);
      } catch (e) {
        _logger.warning('Failed to parse notification payload: $e');
      }
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    _logger.info('Foreground message: ${message.notification?.title}');
    _showLocalNotificationFromRemote(message);
  }

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    final logger = Logger('NotificationService');
    logger.info('Background message: ${message.notification?.title}');
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
      _logger.severe('Failed to show local notification from remote: $e');
    }
  }

  // Handle notification navigation
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    _logger.info('Handling navigation for notification type: $type');

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
  // DEBUG METHODS
  // ====================

  // Simple immediate notification for testing
  Future<void> testSimpleNotification() async {
    try {
      _logger.info('Testing simple notification...');

      const androidDetails = AndroidNotificationDetails(
        'test_simple',
        'Test Simple',
        channelDescription: 'Simple test notifications',
        importance: Importance.high,
        priority: Priority.high,
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

      await _localNotifications.show(
        _generateNotificationId(),
        '✅ Simple Test Notification',
        'This notification appeared immediately! ${DateTime.now().toString().substring(11, 19)}',
        details,
      );

      _logger.info('Simple notification sent successfully');
    } catch (e) {
      _logger.severe('Failed to send simple notification: $e');
      rethrow;
    }
  }

  // Test scheduled notification with better error handling
  Future<void> testScheduledNotification({
    required String title,
    required String body,
    int delaySeconds = 5,
    String? type,
  }) async {
    try {
      _logger.info(
          'Scheduling test notification with $delaySeconds second delay...');

      if (!_isInitialized) {
        throw Exception('Notification service not initialized');
      }

      const androidDetails = AndroidNotificationDetails(
        'test_scheduled',
        'Test Scheduled',
        channelDescription: 'Test scheduled notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final scheduledTime = DateTime.now().add(Duration(seconds: delaySeconds));
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
      final notificationId = _generateNotificationId();

      _logger.info('Current time: ${DateTime.now()}');
      _logger.info('Scheduled time: $scheduledTime');
      _logger.info('TZ Scheduled time: $tzScheduledTime');
      _logger.info('Notification ID: $notificationId');

      final payload = json.encode({
        'type': type ?? 'test_scheduled',
        'scheduledTime': scheduledTime.toIso8601String(),
      });

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

      _logger.info('Test notification scheduled successfully');
    } catch (e) {
      _logger.severe('Failed to schedule test notification: $e');
      rethrow;
    }
  }

  // Alternative delayed notification using Timer
  Future<void> testDelayedNotification({
    required String title,
    required String body,
    int delaySeconds = 5,
  }) async {
    try {
      _logger.info('Setting up delayed notification with Timer...');

      Timer(Duration(seconds: delaySeconds), () async {
        try {
          const androidDetails = AndroidNotificationDetails(
            'delayed_test',
            'Delayed Test',
            channelDescription: 'Delayed test notifications',
            importance: Importance.high,
            priority: Priority.high,
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

          await _localNotifications.show(
            _generateNotificationId(),
            title,
            body,
            details,
          );

          _logger.info('Delayed notification sent successfully');
        } catch (e) {
          _logger.severe('Failed to send delayed notification: $e');
        }
      });

      _logger.info('Delayed notification timer set for $delaySeconds seconds');
    } catch (e) {
      _logger.severe('Failed to set up delayed notification: $e');
      rethrow;
    }
  }

  // Get debug information
  Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      final token = await _firebaseMessaging.getToken();

      bool hasPermissions = false;
      try {
        if (Platform.isAndroid) {
          final status = await Permission.notification.status;
          hasPermissions = status.isGranted;
        } else {
          final settings = await _firebaseMessaging.getNotificationSettings();
          hasPermissions =
              settings.authorizationStatus == AuthorizationStatus.authorized;
        }
      } catch (e) {
        _logger.warning('Failed to check permissions: $e');
      }

      final pendingNotifications =
          await _localNotifications.pendingNotificationRequests();

      return {
        'isInitialized': _isInitialized,
        'hasPermissions': hasPermissions,
        'fcmToken': token != null,
        'fcmTokenLength': token?.length ?? 0,
        'platform': Platform.operatingSystem,
        'timezone': tz.local.name,
        'currentTime': DateTime.now().toString(),
        'pendingNotifications': pendingNotifications.length,
      };
    } catch (e) {
      _logger.severe('Failed to get debug info: $e');
      return {'error': e.toString()};
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
      _logger.info('Workout reminders are disabled');
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

      _logger.info(
          'Scheduling workout reminder at $tzScheduledTime (ID: $notificationId)');

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

      _logger
          .info('Workout reminder scheduled successfully for $scheduledTime');
    } catch (e) {
      _logger.severe('Failed to schedule workout reminder: $e');
      rethrow;
    }
  }

  // Schedule water reminder
  Future<void> scheduleWaterReminder() async {
    if (!await _isNotificationTypeEnabled(_waterRemindersKey)) {
      _logger.info('Water reminders are disabled');
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

      _logger.info('Water reminders scheduled successfully');
    } catch (e) {
      _logger.severe('Failed to schedule water reminders: $e');
      rethrow;
    }
  }

  // Schedule eco tip
  Future<void> scheduleEcoTip({
    required String tip,
    DateTime? scheduledTime,
  }) async {
    if (!await _isNotificationTypeEnabled(_ecoTipsKey)) {
      _logger.info('Eco tips are disabled');
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

      _logger.info('Eco tip scheduled for $time');
    } catch (e) {
      _logger.severe('Failed to schedule eco tip: $e');
      rethrow;
    }
  }

  // Send progress celebration
  Future<void> sendProgressCelebration({
    required String achievement,
    required String message,
  }) async {
    if (!await _isNotificationTypeEnabled(_progressUpdatesKey)) {
      _logger.info('Progress updates are disabled');
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

      _logger.info('Progress celebration sent: $achievement');
    } catch (e) {
      _logger.severe('Failed to send progress celebration: $e');
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
      _logger.info('Meal reminders are disabled');
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

      _logger.info(
          'Scheduling meal reminder: $mealType at $tzScheduledTime (ID: $notificationId)');

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

      _logger.info(
          'Meal reminder scheduled successfully: $mealType for $scheduledTime');
    } catch (e) {
      _logger.severe('Failed to schedule meal reminder: $e');
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
      _logger.info('Cancelled existing meal reminder for $mealType (ID: $id)');
    } catch (e) {
      _logger.warning('Failed to cancel meal reminder for $mealType: $e');
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
        playSound: true,
        enableVibration: true,
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
      _logger.severe('Failed to schedule repeating notification: $e');
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
      _logger.warning('Failed to check notification preference for $key: $e');
      return true;
    }
  }

  Future<void> setNotificationPreference(String key, bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, enabled);
      _logger.info('Notification preference set: $key = $enabled');
    } catch (e) {
      _logger.severe('Failed to set notification preference for $key: $e');
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
        return '🍳 Breakfast Time!';
      case 'lunch':
        return '🥗 Lunch Time!';
      case 'dinner':
        return '🍽️ Dinner Time!';
      case 'snacks':
        return '🍎 Snack Time!';
      default:
        return '🍽️ Meal Time!';
    }
  }

  String _getMealReminderBody(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'Start your day with a nutritious breakfast!';
      case 'lunch':
        return 'Fuel your afternoon with a healthy lunch!';
      case 'dinner':
        return 'End your day with a satisfying dinner!';
      case 'snacks':
        return 'Time for a healthy snack to keep you energized!';
      default:
        return 'Don\'t forget to eat a healthy meal!';
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
      _logger.severe('Failed to get pending notifications: $e');
      return [];
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      _logger.info('All notifications cancelled');
    } catch (e) {
      _logger.severe('Failed to cancel all notifications: $e');
      rethrow;
    }
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      _logger.info('Notification $id cancelled');
    } catch (e) {
      _logger.severe('Failed to cancel notification $id: $e');
      rethrow;
    }
  }

  // Get FCM token for push notifications
  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      _logger.severe('Failed to get FCM token: $e');
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
      _logger.info('Enhanced notification preferences saved');
    } catch (e) {
      _logger.severe('Failed to save enhanced notification preferences: $e');
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
      _logger.severe('Failed to load enhanced notification preferences: $e');
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
      await _cancelNotificationsByType('workout');

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

        _logger.info('Scheduled workout notification for $day at ${scheduledTime.toString()}');
      }
    } catch (e) {
      _logger.severe('Failed to schedule personalized workout reminders: $e');
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
      await _cancelNotificationsByType('diary');

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

      _logger.info('Scheduled diary notification at ${scheduledTime.toString()}');
    } catch (e) {
      _logger.severe('Failed to schedule personalized diary reminders: $e');
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
      await _cancelNotificationsByType('meal');

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

        _logger.info('Scheduled meal notification for $mealType at ${scheduledTime.toString()}');
      }
    } catch (e) {
      _logger.severe('Failed to schedule personalized meal reminders: $e');
      rethrow;
    }
  }

  /// Cancel notifications by type
  Future<void> _cancelNotificationsByType(String type) async {
    try {
      final pendingNotifications = await getPendingNotifications();
      for (final notification in pendingNotifications) {
        if (notification.payload != null && notification.payload!.contains('"type":"$type"')) {
          await cancelNotification(notification.id);
        }
      }
    } catch (e) {
      _logger.warning('Failed to cancel notifications by type $type: $e');
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
    } else if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    
    return scheduled;
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
      _logger.severe('Failed to schedule notification: $e');
      rethrow;
    }
  }
}
