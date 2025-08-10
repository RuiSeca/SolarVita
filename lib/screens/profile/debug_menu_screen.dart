// Debug menu screen for development tools
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database/social_service.dart';
import '../../services/database/firebase_push_notification_service.dart';
import '../../services/database/firebase_routine_service.dart';
import '../../services/database/routine_service.dart';
import '../../providers/riverpod/user_profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../debug/quantum_coach_analyzer.dart';
import '../../debug/quantum_coach_clothing_tester.dart';
import '../avatar_store/quantum_coach_customization_screen.dart';
import '../avatar_store/enhanced_quantum_coach_screen.dart';

class DebugMenuScreen extends ConsumerStatefulWidget {
  const DebugMenuScreen({super.key});

  @override
  ConsumerState<DebugMenuScreen> createState() => _DebugMenuScreenState();
}

class _DebugMenuScreenState extends ConsumerState<DebugMenuScreen> {
  final SocialService _socialService = SocialService();
  final FirebasePushNotificationService _notificationService =
      FirebasePushNotificationService();
  final FirebaseRoutineService _firebaseRoutineService =
      FirebaseRoutineService();
  final RoutineService _routineService = RoutineService();
  bool _isLoading = false;
  String? _lastResult;

  Future<void> _checkAndFixSupporterCount() async {
    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      final result = await _socialService.checkAndFixMySuppoterCount();

      setState(() {
        _lastResult =
            'Supporter Count Check:\n'
            'User ID: ${result['userId']}\n'
            'Stored Count: ${result['storedCount']}\n'
            'Actual Count: ${result['actualCount']}\n'
            'Was Fixed: ${result['wasFixed'] ? 'Yes' : 'No'}';
      });

      // Refresh the UI if something was fixed
      if (result['wasFixed'] == true) {
        // Use silent refresh to avoid loading states that might trigger navigation
        await ref
            .read(userProfileNotifierProvider.notifier)
            .silentRefreshSupporterCount();

        _showSnackBar(
          '✅ Fixed! Count updated from ${result['storedCount']} to ${result['actualCount']}. Changes applied!',
          Colors.green,
        );
      } else {
        _showSnackBar(
          '✅ No fix needed - counts already match (${result['actualCount']})',
          Colors.blue,
        );
      }
    } catch (e) {
      setState(() {
        _lastResult = 'Error: $e';
      });
      _showSnackBar('❌ Error: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testNotifications() async {
    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      // Get current FCM token
      final token = await _notificationService.getCurrentToken();

      // Send test notification
      await _notificationService.sendTestNotification();

      setState(() {
        _lastResult =
            'Test Notification Sent!\n'
            'FCM Token: ${token?.substring(0, 20)}...\n'
            'Check your notification tray.';
      });

      _showSnackBar('🔥 Test notification sent!', Colors.orange);
    } catch (e) {
      setState(() {
        _lastResult = 'Error: $e';
      });
      _showSnackBar('❌ Notification test failed: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testChatNotification() async {
    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('Not logged in');
      }

      // Send a test chat notification to yourself
      await _notificationService.sendMessageNotification(
        receiverId: currentUserId,
        senderName: 'Test Sender',
        messagePreview: 'This is a test chat notification!',
        chatId: 'test_chat_123',
      );

      setState(() {
        _lastResult =
            'Chat Notification Test:\n'
            'Sent to: $currentUserId\n'
            'Type: Chat\n'
            'Check your notification tray and Firestore.';
      });

      _showSnackBar('💬 Chat notification test sent!', Colors.blue);
    } catch (e) {
      setState(() {
        _lastResult = 'Error: $e';
      });
      _showSnackBar('❌ Chat notification test failed: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _debugRelationshipState() async {
    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      final result = await _socialService.debugRelationshipState();

      setState(() {
        _lastResult =
            'Relationship Debug:\n'
            'Current User: ${result['currentUserId']}\n'
            'Supporter Requests: ${result['supporterRequests']['total']}\n'
            '- As Requester: ${result['supporterRequests']['asRequester']}\n'
            '- As Receiver: ${result['supporterRequests']['asReceiver']}\n'
            'Supports:\n'
            '- Supporting: ${result['supports']['supporting']}\n'
            '- Supporters: ${result['supports']['supporters']}\n\n'
            'Full Details:\n${result.toString()}';
      });

      _showSnackBar('✅ Debug data generated', Colors.blue);
    } catch (e) {
      setState(() {
        _lastResult = 'Error: $e';
      });
      _showSnackBar('❌ Error: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeSupportersCount() async {
    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      await _socialService.initializeSupportersCount();

      // Use silent refresh to avoid loading states that might trigger navigation
      await ref
          .read(userProfileNotifierProvider.notifier)
          .silentRefreshSupporterCount();

      setState(() {
        _lastResult =
            'Supporters count initialized successfully. Changes applied!';
      });

      _showSnackBar(
        '✅ Supporters count initialized! Changes applied.',
        Colors.green,
      );
    } catch (e) {
      setState(() {
        _lastResult = 'Error: $e';
      });
      _showSnackBar('❌ Error: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncRoutinesToFirebase() async {
    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      // Load local routines
      final manager = await _routineService.loadRoutineManager();

      if (manager.routines.isEmpty) {
        setState(() {
          _lastResult = 'No local routines found to sync.';
        });
        _showSnackBar('ℹ️ No routines to sync', Colors.blue);
        return;
      }

      // Sync each routine to Firebase
      int syncedCount = 0;
      int failedCount = 0;
      List<String> syncedRoutines = [];
      List<String> failedRoutines = [];

      for (final routine in manager.routines) {
        final success = await _firebaseRoutineService.syncUserRoutine(routine);
        if (success) {
          syncedCount++;
          syncedRoutines.add(routine.name);
        } else {
          failedCount++;
          failedRoutines.add(routine.name);
        }
      }

      setState(() {
        _lastResult =
            'Firebase Routine Sync Complete:\n'
            'Total Routines: ${manager.routines.length}\n'
            'Successfully Synced: $syncedCount\n'
            'Failed: $failedCount\n\n'
            'Synced Routines:\n${syncedRoutines.join('\n')}'
            '${failedRoutines.isNotEmpty ? '\n\nFailed Routines:\n${failedRoutines.join('\n')}' : ''}';
      });

      if (failedCount == 0) {
        _showSnackBar(
          '✅ All $syncedCount routines synced to Firebase!',
          Colors.green,
        );
      } else {
        _showSnackBar(
          '⚠️ $syncedCount synced, $failedCount failed',
          Colors.orange,
        );
      }
    } catch (e) {
      final errorMessage = e.toString().contains('permission-denied')
          ? 'Permission Denied: Please set up Firestore security rules for user_routines collection'
          : 'Error syncing routines: $e';

      setState(() {
        _lastResult = errorMessage;
      });

      final snackMessage = e.toString().contains('permission-denied')
          ? '🔒 Permission denied - Check Firestore rules'
          : '❌ Sync failed: $e';

      _showSnackBar(snackMessage, Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncWeeklyProgressToFirebase() async {
    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      // Load local routines to get active routine
      final manager = await _routineService.loadRoutineManager();
      final activeRoutine = manager.routines
          .where((r) => r.isActive)
          .firstOrNull;

      if (activeRoutine == null) {
        setState(() {
          _lastResult = 'No active routine found to sync progress for.';
        });
        _showSnackBar('ℹ️ No active routine to sync progress', Colors.blue);
        return;
      }

      // Generate basic weekly progress data
      final now = DateTime.now();
      final currentWeek =
          ((now.difference(DateTime(now.year, 1, 1)).inDays +
                      DateTime(now.year, 1, 1).weekday -
                      1) /
                  7)
              .ceil();

      final progressData = <String, dynamic>{
        'routineId': activeRoutine.id,
        'weekOfYear': currentWeek,
        'year': now.year,
        'weekStartDate': now
            .subtract(Duration(days: now.weekday - 1))
            .toIso8601String(),
        'dailyProgress': <String, dynamic>{},
        'lastUpdated': now.toIso8601String(),
      };

      // Initialize daily progress for each day
      final dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final dailyProgress =
          progressData['dailyProgress'] as Map<String, dynamic>;

      for (int i = 0; i < dayNames.length; i++) {
        final dayName = dayNames[i];
        final dayWorkout = activeRoutine.weeklyPlan.firstWhere(
          (day) => day.dayName.toLowerCase() == dayName.toLowerCase(),
          orElse: () => activeRoutine.weeklyPlan.first,
        );

        dailyProgress[dayName] = {
          'dayName': dayName,
          'plannedExercises': dayWorkout.exercises.length,
          'completedExerciseIds': <String>[],
          'isRestDay': dayWorkout.isRestDay,
          'lastUpdated': now.toIso8601String(),
        };
      }

      // Sync to Firebase
      final success = await _firebaseRoutineService.syncWeeklyProgress(
        progressData,
      );

      setState(() {
        _lastResult =
            'Weekly Progress Sync ${success ? 'Successful' : 'Failed'}:\\n'
            'Routine: ${activeRoutine.name}\\n'
            'Week: $currentWeek of ${now.year}\\n'
            'Days Initialized: ${dayNames.length}\\n'
            'Status: ${success ? 'Synced to Firebase' : 'Failed to sync'}';
      });

      if (success) {
        _showSnackBar('✅ Weekly progress synced to Firebase!', Colors.green);
      } else {
        _showSnackBar('❌ Failed to sync weekly progress', Colors.red);
      }
    } catch (e) {
      setState(() {
        _lastResult = 'Error syncing weekly progress: $e';
      });
      _showSnackBar('❌ Sync failed: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openQuantumCoachAnalyzer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuantumCoachAnalyzer(),
      ),
    );
  }

  void _openQuantumCoachCustomization() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuantumCoachCustomizationScreen(),
      ),
    );
  }

  void _openEnhancedQuantumCoachStudio() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EnhancedQuantumCoachScreen(),
      ),
    );
  }

  void _openClothingTester() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuantumCoachClothingTester(),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Menu'),
        backgroundColor: AppTheme.surfaceColor(context),
        foregroundColor: AppTheme.textColor(context),
      ),
      backgroundColor: AppTheme.surfaceColor(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withAlpha(76)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Developer Tools',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                        Text(
                          'These tools are for debugging and fixing data issues',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textColor(context).withAlpha(179),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Debug Actions
            Text(
              'Supporter System Debug',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),

            const SizedBox(height: 16),

            // Check and Fix Supporter Count
            _buildDebugCard(
              title: 'Check & Fix Supporter Count',
              description: 'Verifies and corrects your supporter count',
              icon: Icons.healing,
              color: Colors.green,
              onTap: _isLoading ? null : _checkAndFixSupporterCount,
            ),

            const SizedBox(height: 12),

            // Test Notifications
            _buildDebugCard(
              title: 'Test Firebase Notifications',
              description: 'Send a test notification to verify setup',
              icon: Icons.notifications_active,
              color: Colors.orange,
              onTap: _isLoading ? null : _testNotifications,
            ),

            const SizedBox(height: 12),

            // Test Chat Notifications
            _buildDebugCard(
              title: 'Test Chat Notifications',
              description:
                  'Send a test chat notification to verify message flow',
              icon: Icons.chat_bubble,
              color: Colors.cyan,
              onTap: _isLoading ? null : _testChatNotification,
            ),

            const SizedBox(height: 12),

            // Debug Relationship State
            _buildDebugCard(
              title: 'Debug Relationship State',
              description: 'Shows detailed relationship data for analysis',
              icon: Icons.analytics,
              color: Colors.blue,
              onTap: _isLoading ? null : _debugRelationshipState,
            ),

            const SizedBox(height: 12),

            // Initialize Supporters Count
            _buildDebugCard(
              title: 'Initialize Supporters Count',
              description:
                  'Force recalculate supporters count from actual data',
              icon: Icons.refresh,
              color: Colors.purple,
              onTap: _isLoading ? null : _initializeSupportersCount,
            ),

            const SizedBox(height: 24),

            // Firebase Routines Section
            Text(
              'Firebase Routines Debug',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),

            const SizedBox(height: 16),

            // Sync Routines to Firebase
            _buildDebugCard(
              title: 'Sync Routines to Firebase',
              description: 'Upload all local routines to Firebase for sharing',
              icon: Icons.cloud_upload,
              color: Colors.indigo,
              onTap: _isLoading ? null : _syncRoutinesToFirebase,
            ),

            const SizedBox(height: 12),

            // Sync Weekly Progress to Firebase
            _buildDebugCard(
              title: 'Sync Weekly Progress to Firebase',
              description:
                  'Initialize weekly progress data for current routine',
              icon: Icons.trending_up,
              color: Colors.teal,
              onTap: _isLoading ? null : _syncWeeklyProgressToFirebase,
            ),

            const SizedBox(height: 24),

            // RIVE/Avatar Debug Section
            Text(
              'RIVE Avatar Debug',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),

            const SizedBox(height: 16),

            // Quantum Coach RIVE Analyzer
            _buildDebugCard(
              title: 'Analyze Quantum Coach RIVE',
              description: 'Examine animations, state machines, and customization options',
              icon: Icons.analytics_outlined,
              color: Colors.purple,
              onTap: _isLoading ? null : _openQuantumCoachAnalyzer,
            ),

            const SizedBox(height: 12),

            // Quantum Coach Customization Screen
            _buildDebugCard(
              title: 'Test Quantum Coach Customization',
              description: 'Test the full customization UI with asset validation',
              icon: Icons.palette_outlined,
              color: Colors.deepPurple,
              onTap: _isLoading ? null : _openQuantumCoachCustomization,
            ),

            const SizedBox(height: 12),

            // Enhanced Quantum Coach Studio
            _buildDebugCard(
              title: 'Enhanced Quantum Coach Studio',
              description: 'Professional customization UI with 153 animations & features',
              icon: Icons.psychology,
              color: Colors.cyan,
              onTap: _isLoading ? null : _openEnhancedQuantumCoachStudio,
            ),

            const SizedBox(height: 12),

            // Clothing System Tester
            _buildDebugCard(
              title: 'Test Clothing System',
              description: 'Diagnostic tool to test clothing changes and asset loading',
              icon: Icons.checkroom_outlined,
              color: Colors.orange,
              onTap: _isLoading ? null : _openClothingTester,
            ),

            const SizedBox(height: 24),

            // Loading indicator
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Processing...'),
                  ],
                ),
              ),

            // Results
            if (_lastResult != null && !_isLoading) ...[
              Text(
                'Last Result:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.textColor(context).withAlpha(12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.textColor(context).withAlpha(76),
                  ),
                ),
                child: Text(
                  _lastResult!,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Footer
            Center(
              child: Text(
                'Debug Mode Only - Not visible in production',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textColor(context).withAlpha(128),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textColor(context).withAlpha(179),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textColor(context).withAlpha(128),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
