import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/modern_stats_row.dart';
import '../../theme/app_theme.dart';
import '../../providers/user_profile_provider.dart';
import 'package:solar_vitas/utils/translation_helper.dart';
import '../../services/social_service.dart';
import '../../models/supporter.dart';
import 'supporter_requests_screen.dart';
import 'add_friend_screen.dart';
import 'supporters_list_screen.dart';
import 'friend_activity_feed_screen.dart';
import 'following_list_screen.dart';
import 'settings_main_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SocialService _socialService = SocialService();

  @override
  void initState() {
    super.initState();
    // Refresh user profile when profile screen loads to get latest supporter count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProfileProvider>(context, listen: false).refreshSupporterCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(context),
              _buildSupporterRequestNotification(context),
              const ModernStatsRow(),
              const SizedBox(height: 24),
              _buildWeeklySummary(context),
              const SizedBox(height: 24),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildAchievementsSection(context),
              const SizedBox(height: 24),
              _buildDebugMigrationSection(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, userProfileProvider, _) {
        final userProfile = userProfileProvider.userProfile;
        final displayName = userProfile?.displayName ?? 'User';
        final photoURL = userProfile?.photoURL;
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                backgroundColor: AppTheme.cardColor(context),
                child: photoURL == null
                    ? const Icon(
                        Icons.person,
                        size: 32,
                        color: AppColors.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr(context, 'eco_enthusiast'),
                      style: TextStyle(
                        color: AppTheme.textColor(context).withAlpha(153),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: AppColors.primary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsMainScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupporterRequestNotification(BuildContext context) {
    return StreamBuilder<List<SupporterRequest>>(
      stream: _socialService.getPendingSupporterRequests(),
      builder: (context, snapshot) {
        final pendingRequests = snapshot.data ?? [];
        
        if (pendingRequests.isEmpty) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final count = pendingRequests.length;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupporterRequestsScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.primaryColor.withAlpha(76),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.person_add,
                            color: Colors.white,
                            size: 20,
                          ),
                          if (count > 0)
                            Positioned(
                              right: -6,
                              top: -6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  count > 9 ? '9+' : count.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            count == 1 
                                ? 'You have 1 supporter request'
                                : 'You have $count supporter requests',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to view and respond',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.primaryColor.withAlpha(179),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }


  Widget _buildAchievementsSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'achievements',
      child: SizedBox(
        height: 100,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          children: [
            _buildAchievement(
              context,
              icon: Icons.directions_run,
              label: 'achievement_10k',
              isUnlocked: true,
            ),
            _buildAchievement(
              context,
              icon: Icons.eco,
              label: 'achievement_tree',
              isUnlocked: true,
            ),
            _buildAchievement(
              context,
              icon: Icons.fitness_center,
              label: 'achievement_gym',
              isUnlocked: true,
            ),
            _buildAchievement(
              context,
              icon: Icons.local_dining,
              label: 'achievement_veggie',
              isUnlocked: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievement(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isUnlocked,
  }) {
    final Color iconColor = isUnlocked ? AppColors.gold : Colors.grey;
    final Color backgroundColor = isUnlocked
        ? AppTheme.cardColor(context)
        : AppColors.primary.withValues(alpha: 21);
    final Color textColor = isUnlocked
        ? AppTheme.textColor(context)
        : AppTheme.textColor(context).withValues(alpha: 153);

    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, label),
            style: TextStyle(
              color: textColor,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummary(BuildContext context) {
    final theme = Theme.of(context);
    
    return _buildSection(
      context,
      title: 'This Week\'s Progress',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor.withAlpha(25),
              theme.primaryColor.withAlpha(13),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.primaryColor.withAlpha(76),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildWeeklyStatCard(
                  context,
                  icon: Icons.fitness_center,
                  label: 'Workouts',
                  value: '4',
                  target: '5',
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildWeeklyStatCard(
                  context,
                  icon: Icons.restaurant,
                  label: 'Meals Logged',
                  value: '18',
                  target: '21',
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildWeeklyStatCard(
                  context,
                  icon: Icons.eco,
                  label: 'CO2 Saved',
                  value: '2.3kg',
                  target: '3kg',
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                _buildWeeklyStatCard(
                  context,
                  icon: Icons.local_fire_department,
                  label: 'Streak',
                  value: '12',
                  target: 'days',
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String target,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '/ $target',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return _buildSection(
      context,
      title: 'Quick Actions',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.add_circle,
                  label: 'Log Workout',
                  color: Colors.blue,
                  onTap: () {
                    // Navigate to log workout screen
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.camera_alt,
                  label: 'Add Meal',
                  color: Colors.orange,
                  onTap: () {
                    // Navigate to meal logging screen
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.person_add,
                  label: 'Add Supporter',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddSupporterScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.people,
                  label: 'Supporters',
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SupportersListScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.timeline,
                  label: 'Supporter Activities',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FriendActivityFeedScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.person_search,
                  label: 'Supporting',
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FollowingListScreen(),
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
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withAlpha(76),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugMigrationSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Debug - Migration Tools',
      child: Column(
        children: [
          const Text(
            'Migration tools for bidirectional following and supporter counts',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.sync,
                  label: 'Migrate Follows',
                  color: Colors.amber,
                  onTap: () => _runMigration(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.info,
                  label: 'Debug State',
                  color: Colors.cyan,
                  onTap: () => _debugState(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.people_outline,
                  label: 'Fix My Count',
                  color: Colors.purple,
                  onTap: () => _runSupporterCountMigration(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.refresh,
                  label: 'Refresh Count',
                  color: Colors.green,
                  onTap: () => _refreshSupporterCount(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _runMigration() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Running migration...'),
            ],
          ),
        ),
      );

      await _socialService.migrateSupporterRequestsToMutualSupporting();

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Migration completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _debugState() async {
    try {
      final state = await _socialService.debugRelationshipState();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Debug State'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('User ID: ${state['currentUserId']}'),
                  const SizedBox(height: 8),
                  Text('Supporters: ${state['supporters']['total']}'),
                  Text('Supporting: ${state['supporting']['supporting']}'),
                  Text('Followers: ${state['follows']['followers']}'),
                  const SizedBox(height: 16),
                  const Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(state.toString(), style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _runSupporterCountMigration() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Fixing your supporter count...'),
            ],
          ),
        ),
      );

      final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
      await userProfileProvider.initializeSupportersCount();

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your supporter count has been fixed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshSupporterCount() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Refreshing supporter count...'),
            ],
          ),
        ),
      );

      await _socialService.refreshCurrentUserSupporterCount();
      
      if (mounted) {
        final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
        await userProfileProvider.refreshSupporterCount();
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supporter count refreshed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refresh failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
