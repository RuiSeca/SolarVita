// lib/services/notification_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:logging/logging.dart';

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

  bool _isInitialized = false;

  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize push notifications
      await _initializePushNotifications();

      _isInitialized = true;
      _logger.info('Notification service initialized successfully');
    } catch (e) {
      _logger.severe('Failed to initialize notification service: $e');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
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

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Initialize push notifications
  Future<void> _initializePushNotifications() async {
    // Request permission
    await _requestNotificationPermissions();

    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    _logger.info('FCM Token: $token');

    // Configure message handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  // Request notification permissions
  Future<bool> _requestNotificationPermissions() async {
    if (Platform.isIOS) {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } else {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    _logger.info('Notification tapped: ${response.payload}');
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      _handleNotificationNavigation(data);
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    _logger.info('Foreground message: ${message.notification?.title}');

    // Show as local notification
    _showLocalNotificationFromRemote(message);
  }

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    final logger = Logger('NotificationService');
    logger.info('Background message: ${message.notification?.title}');
  }

  // Show local notification from remote message
  Future<void> _showLocalNotificationFromRemote(RemoteMessage message) async {
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
  }

  // Handle notification navigation
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Implement navigation logic based on notification type
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
      default:
        // Navigate to main screen
        break;
    }
  }

  // Fitness-specific notification methods

  // Schedule workout reminder
  Future<void> scheduleWorkoutReminder({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? workoutType,
  }) async {
    if (!await _isNotificationTypeEnabled(_workoutRemindersKey)) return;

    const androidDetails = AndroidNotificationDetails(
      'workout_reminders',
      'Workout Reminders',
      channelDescription: 'Reminders for scheduled workouts',
      importance: Importance.high,
      priority: Priority.high,
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
      'type': 'workout_reminder',
      'workoutType': workoutType,
    });

    await _localNotifications.zonedSchedule(
      _generateNotificationId(),
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    _logger.info('Workout reminder scheduled for $scheduledTime');
  }

  // Schedule water reminder
  Future<void> scheduleWaterReminder() async {
    if (!await _isNotificationTypeEnabled(_waterRemindersKey)) return;

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
  }

  // Schedule eco tip
  Future<void> scheduleEcoTip({
    required String tip,
    DateTime? scheduledTime,
  }) async {
    if (!await _isNotificationTypeEnabled(_ecoTipsKey)) return;

    final time = scheduledTime ?? DateTime.now().add(const Duration(hours: 2));

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
  }

  // Send progress celebration
  Future<void> sendProgressCelebration({
    required String achievement,
    required String message,
  }) async {
    if (!await _isNotificationTypeEnabled(_progressUpdatesKey)) return;

    final androidDetails = AndroidNotificationDetails(
      'progress_updates',
      'Progress Updates',
      channelDescription: 'Celebrations and progress milestones',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF4CAF50), // Fixed const issue
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
  }

  // Schedule meal reminder
  Future<void> scheduleMealReminder({
    required String mealType,
    required DateTime scheduledTime,
    String? customMessage,
  }) async {
    if (!await _isNotificationTypeEnabled(_mealRemindersKey)) return;

    final title = _getMealReminderTitle(mealType);
    final body = customMessage ?? _getMealReminderBody(mealType);

    await _scheduleRepeatingNotification(
      id: _generateNotificationId(),
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      repeatInterval: RepeatInterval.daily,
      channelId: 'meal_reminders',
      channelName: 'Meal Reminders',
      notificationType: 'meal_reminder',
    );
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
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
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

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // Notification preferences
  Future<bool> _isNotificationTypeEnabled(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? true; // Default to enabled
  }

  Future<void> setNotificationPreference(String key, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, enabled);
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
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Get FCM token for push notifications
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
