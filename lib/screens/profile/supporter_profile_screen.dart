import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/supporter.dart';
import '../../models/privacy_settings.dart';
import '../../models/user_progress.dart';
import '../../models/health_data.dart';
import '../../services/social_service.dart';
import '../../services/supporter_profile_service.dart';
import '../../providers/riverpod/user_profile_provider.dart';
import '../../providers/riverpod/chat_provider.dart';
import '../../screens/chat/chat_screen.dart';
import 'widgets/supporter_profile_header.dart';
import 'widgets/supporter_daily_goals_widget.dart';
import 'widgets/supporter_weekly_summary.dart';
import 'widgets/supporter_achievements.dart';
import 'widgets/supporter_meal_sharing_widget.dart';

class SupporterProfileScreen extends ConsumerStatefulWidget {
  final Supporter supporter;

  const SupporterProfileScreen({
    super.key,
    required this.supporter,
  });

  @override
  ConsumerState<SupporterProfileScreen> createState() => _SupporterProfileScreenState();
}

class _SupporterProfileScreenState extends ConsumerState<SupporterProfileScreen> {
  final SocialService _socialService = SocialService();
  final Logger _logger = Logger();
  bool _isSupporting = false;
  bool _isLoading = true;
  int? _actualSupporterCount;
  PrivacySettings? _privacySettings;
  UserProgress? _supporterProgress;
  HealthData? _supporterHealthData;
  Map<String, dynamic>? _weeklyData;
  List<Achievement>? _achievements;
  Map<String, List<Map<String, dynamic>>>? _dailyMeals;

  @override
  void initState() {
    super.initState();
    _logger.d('SupporterProfileScreen initialized for user: ${widget.supporter.userId} (${widget.supporter.displayName})');
    _checkFollowAndFriendStatus();
  }

  Future<void> _checkFollowAndFriendStatus() async {
    try {
      _logger.d('Checking follow and friend status for user: ${widget.supporter.userId}');
      
      // Check support status
      final isSupporting = await _socialService.isSupporting(widget.supporter.userId);
      
      // Get actual supporter count from database
      final supporterCount = await _socialService.getSupporterCount(widget.supporter.userId);
      
      // Load privacy settings
      final privacySettings = await _loadSupporterPrivacySettings();
      
      // Load supporter data based on privacy settings
      UserProgress? progress;
      HealthData? healthData;
      Map<String, dynamic>? weeklyData;
      List<Achievement>? achievements;
      Map<String, List<Map<String, dynamic>>>? dailyMeals;
      
      if (privacySettings?.showWorkoutStats == true || 
          privacySettings?.showAchievements == true ||
          privacySettings?.showNutritionStats == true) {
        final supporterProfileService = SupporterProfileService();
        
        if (privacySettings!.showWorkoutStats) {
          progress = await supporterProfileService.getSupporterProgress(
            widget.supporter.userId, 
            privacySettings
          );
          healthData = await supporterProfileService.getSupporterHealthData(
            widget.supporter.userId,
            privacySettings
          );
          weeklyData = await supporterProfileService.getSupporterWeeklyData(
            widget.supporter.userId,
            privacySettings
          );
        }
        
        if (privacySettings.showAchievements) {
          achievements = await supporterProfileService.getSupporterAchievements(
            widget.supporter.userId,
            privacySettings
          );
        }

        if (privacySettings.showNutritionStats) {
          dailyMeals = await supporterProfileService.getSupporterDailyMeals(
            widget.supporter.userId,
            privacySettings
          );
        }
      }
      
      _logger.d('Is supporting: $isSupporting');
      _logger.d('Actual supporter count: $supporterCount');
      _logger.d('Privacy settings loaded: $privacySettings');
      _logger.d('Progress data loaded: $progress');
      _logger.d('Health data loaded: $healthData');
      _logger.d('Weekly data loaded: $weeklyData');
      _logger.d('Achievements loaded: $achievements');
      _logger.d('Daily meals loaded: $dailyMeals');
      
      if (mounted) {
        setState(() {
          _isSupporting = isSupporting;
          _actualSupporterCount = supporterCount;
          _privacySettings = privacySettings;
          _supporterProgress = progress;
          _supporterHealthData = healthData;
          _weeklyData = weeklyData;
          _achievements = achievements;
          _dailyMeals = dailyMeals;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e('Error checking follow/friend status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<PrivacySettings?> _loadSupporterPrivacySettings() async {
    try {
      final supporterProfileService = SupporterProfileService();
      return await supporterProfileService.getSupporterPrivacySettings(widget.supporter.userId);
    } catch (e) {
      _logger.e('Error loading privacy settings: $e');
      return null;
    }
  }


  Future<void> _handleSupportAction() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _logger.d('Support action called. Current state: $_isSupporting');
      _logger.d('Target user ID: ${widget.supporter.userId}');
      _logger.d('Target user name: ${widget.supporter.displayName}');
      
      if (_isSupporting) {
        // Remove support (silent removal, no notification to other user)
        _logger.d('Attempting to remove support for user: ${widget.supporter.userId}');
        final actuallySupporting = await _socialService.isSupporting(widget.supporter.userId);
        _logger.d('Double-checking: Actually supporting = $actuallySupporting');
        
        if (actuallySupporting) {
          await _socialService.unsupportUser(widget.supporter.userId);
          _logger.d('Support removal completed successfully');
        } else {
          _logger.w('User claims to be supporting but database shows otherwise');
          // Just update the UI state to match reality
          if (mounted) {
            setState(() {
              _isSupporting = false;
            });
          }
          return;
        }
        if (mounted) {
          setState(() {
            _isSupporting = false;
          });
          _logger.d('Updated UI state: _isSupporting = false');
          // Refresh supporter count in the current user's profile
          ref.read(userProfileNotifierProvider.notifier).refreshSupporterCount();
          
          // Refresh supporter count for the user being viewed
          _refreshViewedUserSupporterCount();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed support for ${widget.supporter.displayName}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Show support request dialog with optional message
        _showSupportRequestDialog();
      }
    } catch (e) {
      _logger.e('Error in support action: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.surfaceColor(context),
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceColor(context),
          elevation: 0,
          title: Text(
            widget.supporter.displayName,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Back button overlay
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(38),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withAlpha(77),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              
              // Enhanced Profile Header
              if (_privacySettings != null)
                SupporterProfileHeader(
                  supporter: widget.supporter,
                  privacySettings: _privacySettings,
                  actualSupporterCount: _actualSupporterCount,
                  isOnline: false, // Could be determined from Firebase presence
                  supporterProgress: _supporterProgress,
                  supporterHealthData: _supporterHealthData,
                ),
              
              // Daily Goals Progress (Privacy-Aware)
              if (_privacySettings != null)
                SupporterDailyGoalsWidget(
                  supporterId: widget.supporter.userId,
                  privacySettings: _privacySettings!,
                  supporterProgress: _supporterProgress,
                  supporterHealthData: _supporterHealthData,
                ),
              
              // Weekly Summary (Privacy-Aware)
              if (_privacySettings != null)
                SupporterWeeklySummary(
                  supporterId: widget.supporter.userId,
                  privacySettings: _privacySettings!,
                  weeklyData: _weeklyData,
                ),
              
              // Achievements (Privacy-Aware)
              if (_privacySettings != null)
                SupporterAchievements(
                  supporterId: widget.supporter.userId,
                  privacySettings: _privacySettings!,
                  achievements: _achievements,
                ),
              
              // Daily Meal Plan Sharing (Privacy-Aware)
              if (_privacySettings != null)
                SupporterMealSharingWidget(
                  supporterId: widget.supporter.userId,
                  privacySettings: _privacySettings!,
                  dailyMeals: _dailyMeals,
                ),
              
              // Action Buttons
              _buildActionsSection(context),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }




  Widget _buildActionsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Primary Support Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleSupportAction,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(_getButtonIcon()),
              label: Text(_getButtonText()),
              style: _getButtonStyle(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Secondary Actions Grid
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.message_outlined,
                  label: 'Message',
                  onPressed: () => _openChat(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.timeline_outlined,
                  label: 'Activity',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Activity feed coming soon!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getButtonText() {
    if (_isLoading) return 'Loading...';
    
    // If I'm already supporting them
    if (_isSupporting) {
      return 'Remove Support';
    }
    
    // Send support request instead of automatic support
    return 'Send Request';
  }

  ButtonStyle _getButtonStyle() {
    if (_isLoading) {
      return ElevatedButton.styleFrom(
        backgroundColor: Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }
    
    // If supporting, use outline style
    if (_isSupporting) {
      return OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.orange, width: 2),
        foregroundColor: Colors.orange,
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }
    
    // Default support button
    return ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  IconData _getButtonIcon() {
    if (_isLoading) return Icons.hourglass_empty;
    
    if (_isSupporting) {
      return Icons.person_remove;
    }
    
    return Icons.person_add_outlined;
  }

  void _showSupportRequestDialog() {
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          'Send Support Request',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send a support request to ${widget.supporter.displayName}',
              style: TextStyle(
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLength: 250,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Optional message',
                hintText: 'Introduce yourself or explain why you\'d like to connect...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textColor(context).withAlpha(153),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendSupportRequestWithMessage(messageController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text(
              'Send Request',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSupportRequestWithMessage(String message) async {
    try {
      _logger.d('Attempting to send support request to: ${widget.supporter.userId}');
      await _socialService.sendSupporterRequest(
        widget.supporter.userId, 
        message: message.isNotEmpty ? message : null
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Support request sent to ${widget.supporter.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error sending support request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshViewedUserSupporterCount() async {
    try {
      // Get updated supporter count for the user being viewed
      final updatedCount = await _socialService.getSupporterCount(widget.supporter.userId);
      
      if (mounted) {
        setState(() {
          _actualSupporterCount = updatedCount;
        });
      }
      
      _logger.d('Refreshed supporter count for ${widget.supporter.displayName}: $updatedCount');
    } catch (e) {
      _logger.e('Error refreshing supporter count for viewed user: $e');
    }
  }

  Future<void> _openChat() async {
    try {
      final chatActions = ref.read(chatActionsProvider);
      final conversationId = await chatActions.getOrCreateConversation(widget.supporter.userId);
      
      if (conversationId != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationId,
              otherUserId: widget.supporter.userId,
              otherUserName: widget.supporter.displayName,
              otherUserPhotoURL: widget.supporter.photoURL,
            ),
          ),
        );
      }
    } catch (e) {
      _logger.e('Error opening chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}