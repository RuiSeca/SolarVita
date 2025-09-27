// lib/services/firebase_push_notification_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logging/logging.dart';

enum NotificationType {
  like,
  comment,
  follow,
  mention,
  post,
  chat,
  achievement,
  reminder,
  system,
  supportRequest,
  supportAccepted,
  supportRejected,
  social,
  challengeUpdate,
  challengeInvite,
  ecoTip,
}

class PushNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final String? actionUrl;

  PushNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.actionUrl,
  });

  factory PushNotification.fromMap(Map<String, dynamic> map) {
    // Handle both Timestamp (from Firestore) and int (from JSON)
    DateTime timestamp;
    final timestampValue = map['timestamp'];
    if (timestampValue is Timestamp) {
      timestamp = timestampValue.toDate();
    } else if (timestampValue is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue);
    } else {
      timestamp = DateTime.now(); // Fallback
    }

    return PushNotification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => NotificationType.system,
      ),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      timestamp: timestamp,
      isRead: map['isRead'] ?? false,
      imageUrl: map['imageUrl'],
      actionUrl: map['actionUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.toString(),
      'data': data,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };
  }

  // For JSON encoding (local notifications payload)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.toString(),
      'data': data,
      'timestamp': timestamp.millisecondsSinceEpoch, // Convert to int for JSON
      'isRead': isRead,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };
  }
}

class FirebasePushNotificationService {
  static final FirebasePushNotificationService _instance = 
      FirebasePushNotificationService._internal();
  factory FirebasePushNotificationService() => _instance;
  FirebasePushNotificationService._internal();

  final _logger = Logger('FirebasePushNotificationService');

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  static const String _notificationsCollection = 'notifications';
  static const String _tokensCollection = 'fcm_tokens';

  bool _initialized = false;
  Function(PushNotification)? _onNotificationTapped;
  Function(PushNotification)? _onNotificationReceived;

  /// Initialize push notification service
  Future<void> initialize({
    Function(PushNotification)? onNotificationTapped,
    Function(PushNotification)? onNotificationReceived,
  }) async {
    if (_initialized) return;

    _onNotificationTapped = onNotificationTapped;
    _onNotificationReceived = onNotificationReceived;

    // Request permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Configure Firebase Messaging
    await _configureFirebaseMessaging();

    // Get and save FCM token
    await _updateFCMToken();

    _initialized = true;
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    // Request notification permission
    await Permission.notification.request();
    
    // Request Firebase Messaging permission
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
           settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'social_notifications',
        'Social Notifications',
        description: 'Notifications for likes, comments, and follows',
        importance: Importance.high,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'chat_notifications',
        'Chat Messages',
        description: 'New chat messages',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'achievement_notifications',
        'Achievements',
        description: 'Achievement and milestone notifications',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'reminder_notifications',
        'Reminders',
        description: 'Workout and wellness reminders',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Configure Firebase Messaging handlers
  Future<void> _configureFirebaseMessaging() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tapped when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTapped);

    // Handle notification tapped when app is terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTapped(initialMessage);
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    final notification = _createNotificationFromMessage(message);
    
    // Store notification in Firestore
    await _storeNotification(notification);
    
    // Show local notification in foreground (original working behavior)
    await _showLocalNotification(notification);
    
    // Trigger callback for in-app handling
    _onNotificationReceived?.call(notification);
  }

  /// Handle notification tapped
  void _handleNotificationTapped(RemoteMessage message) async {
    final notification = _createNotificationFromMessage(message);
    
    // Mark as read
    await markNotificationAsRead(notification.id);
    
    // Trigger callback
    _onNotificationTapped?.call(notification);
  }

  /// Handle local notification tapped
  void _onLocalNotificationTapped(NotificationResponse response) async {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      final notification = PushNotification.fromMap(data);
      
      // Mark as read
      await markNotificationAsRead(notification.id);
      
      // Trigger callback
      _onNotificationTapped?.call(notification);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(PushNotification notification) async {
    final androidDetails = AndroidNotificationDetails(
      _getChannelId(notification.type),
      _getChannelName(notification.type),
      importance: _getImportance(notification.type),
      priority: Priority.high,
      showWhen: true,
      when: notification.timestamp.millisecondsSinceEpoch,
      largeIcon: null, // Simplified for now - image handling disabled
      styleInformation: BigTextStyleInformation(notification.body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(notification.toJson()),
    );
  }

  /// Create notification from Firebase message
  PushNotification _createNotificationFromMessage(RemoteMessage message) {
    final data = message.data;
    
    return PushNotification(
      id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? data['title'] ?? '',
      body: message.notification?.body ?? data['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => NotificationType.system,
      ),
      data: data,
      timestamp: DateTime.now(),
      imageUrl: message.notification?.android?.imageUrl ??
                message.notification?.apple?.imageUrl ??
                data['imageUrl'],
      actionUrl: data['actionUrl'],
    );
  }

  /// Update FCM token
  Future<void> _updateFCMToken() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection(_tokensCollection)
            .doc('current')
            .set({
          'token': token,
          'platform': Platform.operatingSystem,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      _logger.severe('Error updating FCM token: $e');
    }
  }

  /// Store notification in Firestore
  Future<void> _storeNotification(PushNotification notification) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection(_notificationsCollection)
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      _logger.severe('Error storing notification: $e');
    }
  }

  /// Send notification to user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
  }) async {
    try {
      // Get user's FCM tokens
      final tokensSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(_tokensCollection)
          .get();

      if (tokensSnapshot.docs.isEmpty) return;

      final tokens = tokensSnapshot.docs
          .map((doc) => doc.data()['token'] as String)
          .toList();

      // Create notification
      final notification = PushNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        data: data ?? {},
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        actionUrl: actionUrl,
      );

      // Store in recipient's notifications
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(_notificationsCollection)
          .doc(notification.id)
          .set(notification.toMap());

      // Send FCM message (requires server-side implementation)
      // This would typically be done via Cloud Functions or your backend
      await _sendFCMMessage(tokens, notification);
    } catch (e) {
      _logger.severe('Error sending notification: $e');
    }
  }

  /// Send support request notification
  Future<void> sendSupportRequestNotification({
    required String receiverId,
    required String requesterName,
    String? message,
  }) async {
    await sendNotificationToUser(
      userId: receiverId,
      title: 'New Support Request',
      body: message != null && message.isNotEmpty
          ? '$requesterName wants to support you: "$message"'
          : '$requesterName wants to support you',
      type: NotificationType.supportRequest,
      data: {
        'requesterId': _auth.currentUser?.uid,
        'requesterName': requesterName,
        'message': message,
      },
      actionUrl: '/supporter-requests',
    );
  }

  /// Send support accepted notification
  Future<void> sendSupportAcceptedNotification({
    required String requesterId,
    required String acceptorName,
  }) async {
    await sendNotificationToUser(
      userId: requesterId,
      title: 'Support Request Accepted',
      body: '$acceptorName accepted your support request',
      type: NotificationType.supportAccepted,
      data: {
        'acceptorId': _auth.currentUser?.uid,
        'acceptorName': acceptorName,
      },
      actionUrl: '/supporters',
    );
  }

  /// Send support rejected notification
  Future<void> sendSupportRejectedNotification({
    required String requesterId,
    required String rejectorName,
  }) async {
    await sendNotificationToUser(
      userId: requesterId,
      title: 'Support Request Declined',
      body: '$rejectorName declined your support request',
      type: NotificationType.supportRejected,
      data: {
        'rejectorId': _auth.currentUser?.uid,
        'rejectorName': rejectorName,
      },
    );
  }

  /// Send message notification
  Future<void> sendMessageNotification({
    required String receiverId,
    required String senderName,
    required String messagePreview,
    required String chatId,
  }) async {
    await sendNotificationToUser(
      userId: receiverId,
      title: senderName,
      body: messagePreview,
      type: NotificationType.chat,
      data: {
        'senderId': _auth.currentUser?.uid,
        'senderName': senderName,
        'chatId': chatId,
      },
      actionUrl: '/chat/$chatId',
    );
  }

  /// Send FCM message via Cloud Functions
  Future<void> _sendFCMMessage(List<String> tokens, PushNotification notification) async {
    // The actual FCM sending is now handled by Cloud Functions
    // This method is called automatically when notifications are stored in Firestore
    // The Cloud Function 'sendNotification' will trigger and send the push notification
    _logger.info('Notification stored - Cloud Function will handle FCM delivery to ${tokens.length} tokens');
  }

  /// Get user notifications stream
  Stream<List<PushNotification>> getUserNotifications({int limit = 50}) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection(_notificationsCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PushNotification.fromMap(doc.data()))
            .toList());
  }

  /// Get unread notifications count
  Stream<int> getUnreadNotificationsCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection(_notificationsCollection)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      _logger.severe('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection(_notificationsCollection)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      _logger.severe('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection(_notificationsCollection)
          .doc(notificationId)
          .delete();
    } catch (e) {
      _logger.severe('Error deleting notification: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection(_notificationsCollection)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      _logger.severe('Error clearing all notifications: $e');
    }
  }

  /// Helper methods
  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.chat:
        return 'chat_notifications';
      case NotificationType.achievement:
        return 'achievement_notifications';
      case NotificationType.reminder:
        return 'reminder_notifications';
      case NotificationType.supportRequest:
      case NotificationType.supportAccepted:
      case NotificationType.supportRejected:
        return 'social_notifications';
      default:
        return 'social_notifications';
    }
  }

  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.chat:
        return 'Chat Messages';
      case NotificationType.achievement:
        return 'Achievements';
      case NotificationType.reminder:
        return 'Reminders';
      case NotificationType.supportRequest:
      case NotificationType.supportAccepted:
      case NotificationType.supportRejected:
        return 'Social Notifications';
      default:
        return 'Social Notifications';
    }
  }

  Importance _getImportance(NotificationType type) {
    switch (type) {
      case NotificationType.chat:
        return Importance.max;
      case NotificationType.reminder:
        return Importance.high;
      case NotificationType.supportRequest:
        return Importance.high;
      case NotificationType.supportAccepted:
      case NotificationType.supportRejected:
        return Importance.defaultImportance;
      default:
        return Importance.defaultImportance;
    }
  }


  /// Test notification functionality
  Future<void> sendTestNotification() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final notification = PushNotification(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        title: '🔥 Test Notification',
        body: 'If you see this, Firebase notifications are working!',
        type: NotificationType.system,
        data: {'type': 'test'},
        timestamp: DateTime.now(),
      );

      // Store notification in Firestore
      await _storeNotification(notification);
      
      // Show local notification immediately
      await _showLocalNotification(notification);
      
      _logger.info('Test notification sent successfully');
    } catch (e) {
      _logger.severe('Failed to send test notification: $e');
    }
  }

  /// Get current FCM token for debugging
  Future<String?> getCurrentToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      _logger.severe('Error getting FCM token: $e');
      return null;
    }
  }


  /// Cleanup
  void dispose() {
    // Clean up resources if needed
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final logger = Logger('FirebaseMessagingBackgroundHandler');
  logger.info('📱 App in background - processing message: ${message.messageId}');
  
  try {
    // Initialize Firebase if not already done
    await Firebase.initializeApp();
    
    // Store notification in Firestore for when user opens app
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && message.data.isNotEmpty) {
      final notification = PushNotification(
        id: message.data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? message.data['title'] ?? '',
        body: message.notification?.body ?? message.data['body'] ?? '',
        type: NotificationType.values.firstWhere(
          (e) => e.toString() == message.data['type'],
          orElse: () => NotificationType.system,
        ),
        data: message.data,
        timestamp: DateTime.now(),
        imageUrl: message.data['imageUrl']?.isNotEmpty == true ? message.data['imageUrl'] : null,
        actionUrl: message.data['actionUrl'],
      );
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
    }
    
    // System automatically shows notification since we have notification payload
    logger.info('✅ Background notification processed - system will display notification automatically');
  } catch (e) {
    logger.severe('❌ Error processing background message: $e');
  }
}