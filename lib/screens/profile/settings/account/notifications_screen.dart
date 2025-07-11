import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:logging/logging.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/notification_service.dart';
import 'enhanced_notifications_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final Logger _logger = Logger('NotificationsScreen');

  bool _workoutReminders = true;
  bool _ecoTips = true;
  bool _progressUpdates = true;
  bool _waterReminders = true;
  bool _mealReminders = true;
  bool _isLoading = true;

  String? _fcmToken;
  Map<String, dynamic>? _debugInfo;

  @override
  void initState() {
    super.initState();
    _initializeNotificationSystem();
  }

  Future<void> _initializeNotificationSystem() async {
    try {
      _logger.info('Initializing notification system...');

      // Initialize timezone
      tz.initializeTimeZones();

      // Initialize notification service
      await _notificationService.initialize();

      // Load preferences and data
      await Future.wait([
        _loadNotificationPreferences(),
        _getFCMToken(),
        _loadDebugInfo(),
      ]);

      setState(() {
        _isLoading = false;
      });

      _logger.info('Notification system initialized successfully');
    } catch (e) {
      _logger.severe('Failed to initialize notification system: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to initialize notifications: $e');
      }
    }
  }

  Future<void> _loadNotificationPreferences() async {
    try {
      final results = await Future.wait([
        _notificationService.workoutRemindersEnabled,
        _notificationService.ecoTipsEnabled,
        _notificationService.progressUpdatesEnabled,
        _notificationService.waterRemindersEnabled,
        _notificationService.mealRemindersEnabled,
      ]);

      if (mounted) {
        setState(() {
          _workoutReminders = results[0];
          _ecoTips = results[1];
          _progressUpdates = results[2];
          _waterReminders = results[3];
          _mealReminders = results[4];
        });
      }
    } catch (e) {
      _logger.severe('Failed to load notification preferences: $e');
    }
  }

  Future<void> _getFCMToken() async {
    try {
      final token = await _notificationService.getToken();
      if (mounted) {
        setState(() => _fcmToken = token);
      }
      _logger.info('FCM Token retrieved: ${token?.substring(0, 20)}...');
    } catch (e) {
      _logger.severe('Failed to get FCM token: $e');
    }
  }

  Future<void> _loadDebugInfo() async {
    try {
      final info = await _notificationService.getDebugInfo();
      if (mounted) {
        setState(() => _debugInfo = info);
      }
    } catch (e) {
      _logger.severe('Failed to load debug info: $e');
    }
  }

  Future<void> _initializeAllNotifications() async {
    try {
      // Schedule water reminders
      if (_waterReminders) {
        await _notificationService.scheduleWaterReminder();
      }

      // Schedule eco tips (daily)
      if (_ecoTips) {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        await _notificationService.scheduleEcoTip(
          tip: 'Remember to use renewable energy sources when possible! 🌱',
          scheduledTime:
              DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0),
        );
      }

      _showInfoSnackBar('All notifications initialized successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to initialize notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.surfaceColor(context),
        foregroundColor: AppTheme.textColor(context),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshNotificationData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing notifications...'),
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    _buildSystemStatus(),
                    _buildNotificationSettings(),
                    _buildQuickTests(),
                    _buildAdvancedSettings(),
                    _buildDebugSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your notification preferences and test the notification system',
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 153),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus() {
    if (_debugInfo == null) return const SizedBox.shrink();

    return _buildSection(
      context,
      title: 'System Status',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusRow('Service Initialized',
                _debugInfo!['isInitialized']?.toString() ?? 'Unknown'),
            _buildStatusRow('Permissions',
                _debugInfo!['hasPermissions']?.toString() ?? 'Unknown'),
            _buildStatusRow(
                'FCM Token',
                _debugInfo!['fcmToken'] == true
                    ? 'Available'
                    : 'Not available'),
            _buildStatusRow(
                'Platform', _debugInfo!['platform']?.toString() ?? 'Unknown'),
            _buildStatusRow(
                'Timezone', _debugInfo!['timezone']?.toString() ?? 'Unknown'),
            _buildStatusRow('Pending Notifications',
                _debugInfo!['pendingNotifications']?.toString() ?? '0'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    final isGood = value.toLowerCase().contains('true') ||
        value.toLowerCase().contains('available') ||
        value.toLowerCase().contains('android') ||
        value.toLowerCase().contains('ios');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isGood ? Colors.green : AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSection(
      context,
      title: 'Notification Types',
      child: Column(
        children: [
          _buildNotificationTile(
            icon: Icons.fitness_center,
            title: 'Workout Reminders',
            subtitle: 'Get reminded about your scheduled workouts',
            value: _workoutReminders,
            onChanged: (value) => _updatePreference(
                'workout_reminders', value, (v) => _workoutReminders = v),
          ),
          _buildNotificationTile(
            icon: Icons.water_drop,
            title: 'Water Reminders',
            subtitle: 'Stay hydrated with regular water reminders',
            value: _waterReminders,
            onChanged: (value) => _updatePreference(
                'water_reminders', value, (v) => _waterReminders = v),
          ),
          _buildNotificationTile(
            icon: Icons.eco,
            title: 'Eco Tips',
            subtitle: 'Daily tips for sustainable living',
            value: _ecoTips,
            onChanged: (value) =>
                _updatePreference('eco_tips', value, (v) => _ecoTips = v),
          ),
          _buildNotificationTile(
            icon: Icons.trending_up,
            title: 'Progress Updates',
            subtitle: 'Celebrate your achievements and milestones',
            value: _progressUpdates,
            onChanged: (value) => _updatePreference(
                'progress_updates', value, (v) => _progressUpdates = v),
          ),
          _buildNotificationTile(
            icon: Icons.restaurant_menu,
            title: 'Meal Reminders',
            subtitle: 'Get reminded about your meals',
            value: _mealReminders,
            onChanged: (value) => _updatePreference(
                'meal_reminders', value, (v) => _mealReminders = v),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTests() {
    return _buildSection(
      context,
      title: 'Quick Tests',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testSimpleNotification,
                    icon: const Icon(Icons.notifications, size: 18),
                    label: const Text('Immediate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testScheduledNotification,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: const Text('5 Seconds'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testDelayedNotification,
                    icon: const Icon(Icons.timer, size: 18),
                    label: const Text('Timer Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testAllNotifications,
                    icon: const Icon(Icons.notifications_active, size: 18),
                    label: const Text('Test All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return _buildSection(
      context,
      title: 'Advanced Settings',
      child: Column(
        children: [
          _buildAdvancedTile(
            icon: Icons.settings,
            title: 'Personalized Notifications',
            subtitle: 'Configure detailed workout and meal reminders',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EnhancedNotificationsScreen(),
              ),
            ),
          ),
          _buildAdvancedTile(
            icon: Icons.cloud_queue,
            title: 'FCM Token',
            subtitle: _fcmToken != null
                ? '${_fcmToken!.substring(0, 20)}...'
                : 'Not available',
            onTap: () => _copyFCMToken(),
          ),
          _buildAdvancedTile(
            icon: Icons.security,
            title: 'Permissions',
            subtitle: 'Check and request notification permissions',
            onTap: _checkAndRequestPermissions,
          ),
          _buildAdvancedTile(
            icon: Icons.list,
            title: 'Pending Notifications',
            subtitle: 'View all scheduled notifications',
            onTap: _listPendingNotifications,
          ),
          _buildAdvancedTile(
            icon: Icons.refresh,
            title: 'Initialize All Notifications',
            subtitle:
                'Set up recurring notifications based on your preferences',
            onTap: _initializeAllNotifications,
          ),
        ],
      ),
    );
  }

  Widget _buildDebugSection() {
    return _buildSection(
      context,
      title: 'Debug & Developer Options',
      child: Column(
        children: [
          _buildDebugTile(
            'Show System Info',
            () => _showDebugInfo(),
          ),
          _buildDebugTile(
            'Refresh All Data',
            () => _refreshNotificationData(),
          ),
          _buildDebugTile(
            'Test Notification Types',
            () => _testNotificationTypes(),
          ),
          _buildDebugTile(
            'Force Permission Request',
            () => _forcePermissionRequest(),
          ),
          _buildDebugTile(
            'Cancel All Notifications',
            () => _cancelAllNotifications(),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 21),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textColor(context).withValues(alpha: 153),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 153),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textColor(context).withValues(alpha: 153),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugTile(String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color:
                      isDestructive ? Colors.red : AppTheme.textColor(context),
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              isDestructive ? Icons.warning : Icons.bug_report,
              color: isDestructive ? Colors.red : AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ====================
  // ACTION METHODS
  // ====================

  Future<void> _updatePreference(
      String key, bool value, Function(bool) setter) async {
    try {
      setState(() => setter(value));
      await _notificationService.setNotificationPreference(key, value);
      _logger.info('Updated preference $key to $value');
      _showInfoSnackBar('Preference updated successfully');
    } catch (e) {
      _logger.severe('Failed to update preference $key: $e');
      _showErrorSnackBar('Failed to update preference');
    }
  }

  Future<void> _testSimpleNotification() async {
    try {
      await _notificationService.testSimpleNotification();
      _showInfoSnackBar('Simple test notification sent!');
    } catch (e) {
      _showErrorSnackBar('Failed to send simple notification: $e');
    }
  }

  Future<void> _testScheduledNotification() async {
    try {
      await _notificationService.testScheduledNotification(
        title: '⏰ Scheduled Test',
        body:
            'This notification was scheduled 5 seconds ago! ${DateTime.now().toString().substring(11, 19)}',
        delaySeconds: 5,
        type: 'test_scheduled',
      );
      _showInfoSnackBar('Scheduled test notification in 5 seconds!');
    } catch (e) {
      _showErrorSnackBar('Failed to schedule test notification: $e');
    }
  }

  Future<void> _testDelayedNotification() async {
    try {
      await _notificationService.testDelayedNotification(
        title: '⏲️ Timer Test',
        body:
            'This notification used Timer instead of scheduling! ${DateTime.now().toString().substring(11, 19)}',
        delaySeconds: 3,
      );
      _showInfoSnackBar('Timer test notification in 3 seconds!');
    } catch (e) {
      _showErrorSnackBar('Failed to send timer test notification: $e');
    }
  }

  Future<void> _testNotificationTypes() async {
    try {
      // Test different notification types
      await Future.wait([
        _notificationService.scheduleWorkoutReminder(
          title: '🏋️ Test Workout',
          body: 'Test workout reminder notification!',
          scheduledTime: DateTime.now().add(const Duration(seconds: 2)),
          workoutType: 'test',
        ),
        _notificationService.scheduleEcoTip(
          tip: 'Test eco tip: Use renewable energy! 🌱',
          scheduledTime: DateTime.now().add(const Duration(seconds: 4)),
        ),
        _notificationService.scheduleMealReminder(
          mealType: 'snacks',
          scheduledTime: DateTime.now().add(const Duration(seconds: 6)),
          customMessage: 'Test meal reminder - time for a healthy snack!',
        ),
      ]);

      // Send immediate progress celebration
      await _notificationService.sendProgressCelebration(
        achievement: 'Test Achievement',
        message: 'Congratulations on testing the notification types! 🎉',
      );

      _showInfoSnackBar('All notification types tested!');
    } catch (e) {
      _showErrorSnackBar('Failed to test notification types: $e');
    }
  }

  Future<void> _testAllNotifications() async {
    try {
      await Future.wait([
        _testSimpleNotification(),
        _testScheduledNotification(),
        _testDelayedNotification(),
      ]);
      _showInfoSnackBar('All test notifications triggered!');
    } catch (e) {
      _showErrorSnackBar('Failed to test all notifications: $e');
    }
  }

  Future<void> _refreshNotificationData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadNotificationPreferences(),
        _getFCMToken(),
        _loadDebugInfo(),
      ]);

      _showInfoSnackBar('Notification data refreshed');
    } catch (e) {
      _showErrorSnackBar('Failed to refresh data');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _copyFCMToken() async {
    if (!mounted) return;

    if (_fcmToken != null) {
      _showInfoSnackBar('FCM Token: ${_fcmToken!.substring(0, 50)}...');
    } else {
      _showErrorSnackBar('No FCM token available');
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    try {
      bool hasPermission = false;

      if (Platform.isIOS) {
        final messaging = FirebaseMessaging.instance;
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        hasPermission =
            settings.authorizationStatus == AuthorizationStatus.authorized;
      } else {
        final status = await Permission.notification.request();
        hasPermission = status.isGranted;
      }

      await _loadDebugInfo(); // Refresh debug info

      _showInfoSnackBar(hasPermission
          ? 'Notification permissions granted'
          : 'Notification permissions denied');
    } catch (e) {
      _logger.severe('Failed to check permissions: $e');
      _showErrorSnackBar('Failed to check permissions');
    }
  }

  Future<void> _forcePermissionRequest() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        _showInfoSnackBar('Android permission status: $status');
      } else {
        final messaging = FirebaseMessaging.instance;
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        _showInfoSnackBar(
            'iOS permission status: ${settings.authorizationStatus}');
      }

      await _loadDebugInfo(); // Refresh debug info
    } catch (e) {
      _showErrorSnackBar('Failed to request permissions: $e');
    }
  }

  Future<void> _listPendingNotifications() async {
    try {
      if (!mounted) return;

      final notifications =
          await _notificationService.getPendingNotifications();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pending Notifications'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: notifications.isEmpty
                ? const Center(
                    child: Text(
                      'No pending notifications',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(
                            notification.title ?? 'No title',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${notification.id}'),
                              if (notification.body != null)
                                Text('Body: ${notification.body}'),
                              if (notification.payload != null)
                                Text('Payload: ${notification.payload}'),
                            ],
                          ),
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 21),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (notifications.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _cancelAllNotifications();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Cancel All'),
              ),
          ],
        ),
      );
    } catch (e) {
      _logger.severe('Failed to list pending notifications: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to list notifications: ${e.toString()}');
      }
    }
  }

  Future<void> _showDebugInfo() async {
    try {
      if (_debugInfo == null) {
        await _loadDebugInfo();
      }

      if (!mounted || _debugInfo == null) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('System Debug Information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _debugInfo!.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${entry.key}: ${entry.value}'),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadDebugInfo();
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to show debug info: $e');
    }
  }

  Future<void> _cancelAllNotifications() async {
    try {
      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel All Notifications'),
          content: const Text(
              'This will cancel all scheduled notifications. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel All'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await _notificationService.cancelAllNotifications();
        await _loadDebugInfo(); // Refresh debug info

        if (mounted) {
          _showInfoSnackBar('All notifications cancelled');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to cancel notifications');
      }
    }
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
