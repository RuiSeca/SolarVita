import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatNotificationService {
  static final ChatNotificationService _instance = ChatNotificationService._internal();
  factory ChatNotificationService() => _instance;
  ChatNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _currentChatConversationId;

  // Initialize notification service
  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _requestPermissions();
    await _setupFCMListeners();
    await _saveUserToken();
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

    // Create notification channel for Android
    const androidNotificationChannel = AndroidNotificationChannel(
      'chat_channel',
      'Chat Messages',
      description: 'Notifications for chat messages',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(androidNotificationChannel);
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    // Request FCM permission
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    if (kDebugMode) {
      debugPrint('FCM Permission status: ${settings.authorizationStatus}');
    }

    // Request local notification permission for Android 13+
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Setup FCM listeners
  Future<void> _setupFCMListeners() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // Handle app opened from terminated state
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessageTap(initialMessage);
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveUserToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });

        if (kDebugMode) {
          debugPrint('FCM Token saved: $token');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving FCM token: $e');
      }
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _firestore.collection('users').doc(user.uid).update({
        'fcmToken': newToken,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    });
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final chatData = data['chatData'];
    
    // Don't show notification if user is in the same conversation
    if (_currentChatConversationId == data['conversationId']) {
      return;
    }

    // Show local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? 'You have a new message',
      payload: chatData,
    );
  }

  // Handle background message tap
  void _handleBackgroundMessageTap(RemoteMessage message) {
    final data = message.data;
    if (data['type'] == 'chat') {
      // Navigate to chat screen
      // This will be handled by the main app navigation
      _onChatNotificationTapped(data);
    }
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat Messages',
      channelDescription: 'Notifications for chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
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

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      _onChatNotificationTapped({'chatData': response.payload});
    }
  }

  // Handle chat notification tap
  void _onChatNotificationTapped(Map<String, dynamic> data) {
    // Extract chat data and navigate to chat screen
    final chatData = data['chatData'];
    if (chatData != null) {
      _navigateToChat(chatData);
    } else if (data['conversationId'] != null) {
      _navigateToChat(data);
    }
  }
  
  // Navigate to chat screen
  void _navigateToChat(dynamic chatData) {
    // This is a placeholder for navigation logic
    // In a real implementation, you would use a navigation service
    // or global navigator key to navigate to the chat screen
  }

  // Set current chat conversation (to avoid duplicate notifications)
  void setCurrentChatConversation(String? conversationId) {
    _currentChatConversationId = conversationId;
  }

  // Send notification to other user
  Future<void> sendMessageNotification({
    required String receiverId,
    required String senderName,
    required String messageContent,
    required String conversationId,
  }) async {
    try {
      // Get receiver's FCM token
      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      if (!receiverDoc.exists) return;

      final receiverData = receiverDoc.data()!;
      final fcmToken = receiverData['fcmToken'];
      if (fcmToken == null) return;

      // Send notification via Cloud Function
      await _firestore.collection('notifications').add({
        'type': 'chat_message',
        'toUserId': receiverId,
        'fromUserId': _auth.currentUser?.uid,
        'fcmToken': fcmToken,
        'title': senderName,
        'body': messageContent,
        'conversationId': conversationId,
        'timestamp': FieldValue.serverTimestamp(),
        'data': {
          'type': 'chat',
          'conversationId': conversationId,
          'senderId': _auth.currentUser?.uid,
          'senderName': senderName,
        },
      });
    } catch (e) {
      // Silent failure for notification issues
    }
  }

  // Clear all chat notifications
  Future<void> clearChatNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Update badge count
  Future<void> updateBadgeCount(int count) async {
    // This is platform-specific implementation
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(badge: true);
    }
  }
}