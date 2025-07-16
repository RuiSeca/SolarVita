import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../models/supporter.dart';
import '../../services/social_service.dart';
import '../../utils/translation_helper.dart';
import '../../providers/riverpod/user_profile_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _logger.d('FriendProfileScreen initialized for user: ${widget.supporter.userId} (${widget.supporter.displayName})');
    _checkFollowAndFriendStatus();
  }

  Future<void> _checkFollowAndFriendStatus() async {
    try {
      _logger.d('Checking follow and friend status for user: ${widget.supporter.userId}');
      
      // Check support status
      final isSupporting = await _socialService.isSupporting(widget.supporter.userId);
      
      // Get actual supporter count from database
      final supporterCount = await _socialService.getSupporterCount(widget.supporter.userId);
      
      _logger.d('Is supporting: $isSupporting');
      _logger.d('Actual supporter count: $supporterCount');
      
      if (mounted) {
        setState(() {
          _isSupporting = isSupporting;
          _actualSupporterCount = supporterCount;
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

  Future<void> _toggleFollow() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _logger.d('Toggle follow called. Current state: $_isSupporting');
      _logger.d('Target user ID: ${widget.supporter.userId}');
      _logger.d('Target user name: ${widget.supporter.displayName}');
      
      // Handle follow/unfollow based on actual follow status, regardless of friendship
      if (_isSupporting) {
        _logger.d('Attempting to unfollow user: ${widget.supporter.userId}');
        // Double-check the follow status before unfollowing
        final actuallyFollowing = await _socialService.isSupporting(widget.supporter.userId);
        _logger.d('Double-checking: Actually following = $actuallyFollowing');
        
        if (actuallyFollowing) {
          await _socialService.unsupportUser(widget.supporter.userId);
          _logger.d('Unfollow operation completed successfully');
        } else {
          _logger.w('User claims to be following but database shows otherwise');
          // Just update the UI state to match reality
          if (mounted) {
            setState(() {
              _isSupporting = false;
            });
          }
          return; // Skip the rest of the unfollow process
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
              content: Text('Unsupported ${widget.supporter.displayName}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        _logger.d('Attempting to follow user: ${widget.supporter.userId}');
        await _socialService.supportUser(widget.supporter.userId);
        if (mounted) {
          setState(() {
            _isSupporting = true;
          });
          // Refresh supporter count in the current user's profile
          ref.read(userProfileNotifierProvider.notifier).refreshSupporterCount();
          
          // Refresh supporter count for the user being viewed
          _refreshViewedUserSupporterCount();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Now supporting ${widget.supporter.displayName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _logger.e('Error in _toggleFollow: $e');
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
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProfileInfo(context),
                const SizedBox(height: 24),
                _buildStatsSection(context),
                const SizedBox(height: 24),
                _buildAchievementsSection(context),
                const SizedBox(height: 24),
                _buildActionsSection(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40), // Account for status bar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: widget.supporter.photoURL != null
                      ? CachedNetworkImageProvider(widget.supporter.photoURL!)
                      : null,
                  child: widget.supporter.photoURL == null
                      ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.supporter.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.supporter.username != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@${widget.supporter.username}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'profile.profile_info'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.supporter.ecoScore != null) ...[
            _buildInfoRow(
              context,
              icon: Icons.eco,
              label: tr(context, 'profile.eco_score'),
              value: widget.supporter.ecoScore!,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
          ],
          _buildInfoRow(
            context,
            icon: Icons.people,
            label: tr(context, 'profile.supporters'),
            value: _actualSupporterCount?.toString() ?? widget.supporter.supportersCount?.toString() ?? '0',
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            icon: Icons.person,
            label: tr(context, 'profile.member_since'),
            value: 'Recently', // You could add joinDate to Friend model
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final stats = widget.supporter.stats;
    if (stats == null || stats.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.lock_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              tr(context, 'profile.stats_private'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'profile.fitness_stats'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.fitness_center,
                  label: tr(context, 'profile.workouts'),
                  value: stats['workouts']?.toString() ?? '0',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.local_fire_department,
                  label: tr(context, 'profile.calories'),
                  value: stats['calories']?.toString() ?? '0',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'profile.achievements'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildAchievement(
                  context,
                  icon: Icons.directions_run,
                  label: tr(context, 'profile.achievement_runner'),
                  isUnlocked: true,
                ),
                _buildAchievement(
                  context,
                  icon: Icons.eco,
                  label: tr(context, 'profile.achievement_eco'),
                  isUnlocked: true,
                ),
                _buildAchievement(
                  context,
                  icon: Icons.fitness_center,
                  label: tr(context, 'profile.achievement_strong'),
                  isUnlocked: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievement(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isUnlocked,
  }) {
    final Color iconColor = isUnlocked ? Colors.amber : Colors.grey;
    final Color backgroundColor = isUnlocked
        ? Colors.amber.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.1);

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
            label,
            style: TextStyle(
              color: isUnlocked ? AppTheme.textColor(context) : Colors.grey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Follow/Unfollow Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _toggleFollow,
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
          const SizedBox(height: 12),
          // Secondary Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          tr(context, 'profile.message_coming_soon'),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.message),
                  label: Text(tr(context, 'profile.message')),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryColor, width: 1),
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          tr(context, 'profile.activities_coming_soon'),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.timeline),
                  label: Text(tr(context, 'profile.view_activities')),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryColor, width: 1),
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    if (_isLoading) return 'Loading...';
    
    // If I'm already supporting them
    if (_isSupporting) {
      return 'Unsupport';
    }
    
    // For now, just handle basic support/unfollow
    return 'Support';
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
    
    return Icons.person_add;
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
}