import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/community/community_challenge_service.dart';
import '../../models/community/community_challenge.dart';
import '../../models/social/social_post.dart' as social;
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../screens/social/create_post_screen.dart';
import '../../screens/social/social_feed_screen.dart';
import '../../screens/challenges/challenge_detail_screen.dart';
import 'social_post_card.dart';
import '../common/lottie_loading_widget.dart';
import '../common/oriented_image.dart';
import '../../screens/tribes/tribes_screen.dart';

enum SocialFeedTab { allPosts, tribes, challenges }

class SocialFeedTabs extends ConsumerStatefulWidget {
  const SocialFeedTabs({super.key});

  @override
  ConsumerState<SocialFeedTabs> createState() => _SocialFeedTabsState();
}

class _SocialFeedTabsState extends ConsumerState<SocialFeedTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CommunityChallengeService _challengeService = CommunityChallengeService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // Tab change handling can be added here if needed
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Bar - Enhanced Design
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.textFieldBackground(context),
                AppTheme.textFieldBackground(context).withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            tabs: [
              Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.feed, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          tr(context, 'all_posts'),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.groups, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          tr(context, 'tribes'),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          tr(context, 'challenges'),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tab Content
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildAllPostsTab(),
              _buildTribesTab(),
              _buildChallengesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllPostsTab() {
    // Navigate to full-screen social feed
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.feed,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr(context, 'view_full_social_feed'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'tap_explore_community'),
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textColor(context).withAlpha(153),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SocialFeedScreen(),
                ),
              );
            },
            icon: const Icon(Icons.explore),
            label: Text(tr(context, 'open_social_feed')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTribesTab() {
    // Navigate to full-screen tribes screen
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.groups,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr(context, 'explore_tribes'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'join_communities'),
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textColor(context).withAlpha(153),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TribesScreen()),
              );
            },
            icon: const Icon(Icons.explore),
            label: Text(tr(context, 'open_tribes')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildChallengesTab() {
    return StreamBuilder<List<CommunityChallenge>>(
      stream: _challengeService.getActiveChallenges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final challenges = snapshot.data ?? [];

        if (challenges.isEmpty) {
          return _buildEmptyState(
            icon: '🏆',
            title: tr(context, 'no_active_challenges'),
            subtitle: tr(context, 'check_back_challenges'),
          );
        }

        return _buildExpandedChallenges(challenges);
      },
    );
  }

  Widget _buildExpandedChallenges(List<CommunityChallenge> challenges) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return _buildBeautifulChallengeCard(challenge);
      },
    );
  }

  Widget _buildBeautifulChallengeCard(CommunityChallenge challenge) {
    final theme = Theme.of(context);
    final totalParticipants = challenge.getTotalParticipants();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChallengeDetailScreen(challenge: challenge),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section with overlay
            Stack(
              children: [
                // Challenge image or gradient background
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: challenge.imageUrl != null && challenge.imageUrl!.isNotEmpty
                      ? OrientedImage(
                          imageUrl: challenge.imageUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _getChallengeGradientColor(challenge.type),
                                _getChallengeGradientColor(challenge.type).withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              challenge.icon,
                              style: const TextStyle(fontSize: 64),
                            ),
                          ),
                        ),
                ),
                // Category badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _getChallengeTypeLabel(challenge.type),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Status badge
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(challenge.status),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(challenge.status),
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusLabel(challenge.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    challenge.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    challenge.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      color: AppTheme.textColor(context).withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  // Community Goal Progress
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.emoji_events, size: 16, color: theme.primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              tr(context, 'community_goal'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${challenge.communityGoal.currentProgress}/${challenge.communityGoal.targetValue}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: challenge.communityGoalProgress / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              challenge.isCommunityGoalReached ? Colors.green : theme.primaryColor,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${challenge.communityGoalProgress.toInt()}% towards ${challenge.communityGoal.unit} goal',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textColor(context).withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats row
                  Row(
                    children: [
                      _buildStatChip(
                        icon: Icons.people,
                        label: '$totalParticipants',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        icon: _getModeIcon(challenge.mode),
                        label: _getModeLabel(challenge.mode),
                        color: _getModeColor(challenge.mode),
                      ),
                      const SizedBox(width: 8),
                      if (challenge.prizeConfiguration.communityPrize != null)
                        _buildStatChip(
                          icon: Icons.card_giftcard,
                          label: challenge.prizeConfiguration.communityPrize!,
                          color: Colors.amber,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress and time info
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: AppTheme.textColor(context).withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatChallengeDate(challenge.endDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textColor(context).withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      // Progress indicator
                      Text(
                        '${challenge.progressPercentage.toInt()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: challenge.progressPercentage / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getChallengeGradientColor(ChallengeType type) {
    switch (type) {
      case ChallengeType.fitness:
        return Colors.deepOrange;
      case ChallengeType.nutrition:
        return Colors.green;
      case ChallengeType.sustainability:
        return Colors.teal;
      case ChallengeType.community:
        return Colors.indigo;
    }
  }

  String _getChallengeTypeLabel(ChallengeType type) {
    switch (type) {
      case ChallengeType.fitness:
        return tr(context, 'fitness');
      case ChallengeType.nutrition:
        return tr(context, 'nutrition');
      case ChallengeType.sustainability:
        return tr(context, 'sustainability');
      case ChallengeType.community:
        return tr(context, 'community');
    }
  }

  String _getModeLabel(ChallengeMode mode) {
    switch (mode) {
      case ChallengeMode.individual:
        return tr(context, 'individual');
      case ChallengeMode.team:
        return tr(context, 'team');
      case ChallengeMode.mixed:
        return tr(context, 'mixed');
    }
  }

  IconData _getModeIcon(ChallengeMode mode) {
    switch (mode) {
      case ChallengeMode.individual:
        return Icons.person;
      case ChallengeMode.team:
        return Icons.group;
      case ChallengeMode.mixed:
        return Icons.diversity_1;
    }
  }

  Color _getModeColor(ChallengeMode mode) {
    switch (mode) {
      case ChallengeMode.individual:
        return Colors.blue;
      case ChallengeMode.team:
        return Colors.green;
      case ChallengeMode.mixed:
        return Colors.purple;
    }
  }

  Color _getStatusColor(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.upcoming:
        return Colors.orange;
      case ChallengeStatus.active:
        return Colors.green;
      case ChallengeStatus.completed:
        return Colors.blue;
      case ChallengeStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.upcoming:
        return Icons.schedule;
      case ChallengeStatus.active:
        return Icons.play_circle;
      case ChallengeStatus.completed:
        return Icons.check_circle;
      case ChallengeStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusLabel(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.upcoming:
        return tr(context, 'upcoming');
      case ChallengeStatus.active:
        return tr(context, 'active');
      case ChallengeStatus.completed:
        return tr(context, 'completed');
      case ChallengeStatus.cancelled:
        return tr(context, 'cancelled');
    }
  }

  String _formatChallengeDate(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.isNegative) {
      return tr(context, 'ended');
    } else if (difference.inDays > 0) {
      return tr(
        context,
        'days_left',
      ).replaceAll('{days}', '${difference.inDays}');
    } else if (difference.inHours > 0) {
      return tr(
        context,
        'hours_left',
      ).replaceAll('{hours}', '${difference.inHours}');
    } else {
      return tr(context, 'ending_soon');
    }
  }

  // Removed _buildTribePostCard - now handled by ModernTribesTab
}

// Embedded Social Feed Content for Instagram-style posts
class SocialFeedContent extends StatefulWidget {
  const SocialFeedContent({super.key});

  @override
  State<SocialFeedContent> createState() => _SocialFeedContentState();
}

class _SocialFeedContentState extends State<SocialFeedContent> {
  final List<social.SocialPost> _posts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate some mock posts for demo
      final mockPosts = _generateMockPosts();
      setState(() {
        _posts.clear();
        _posts.addAll(mockPosts);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<social.SocialPost> _generateMockPosts() {
    return [
      social.SocialPost(
        id: 'post_1',
        userId: 'user_1',
        userName: 'Alex Chen',
        content:
            'Just completed my morning workout! 💪 Feeling energized and ready to tackle the day. Nothing beats that post-exercise endorphin rush!',
        type: social.PostType.fitnessProgress,
        pillars: [social.PostPillar.fitness],
        mediaUrls: ['https://picsum.photos/400/400?random=1'],
        videoUrls: [],
        visibility: social.PostVisibility.supporters,
        autoGenerated: false,
        reactions: {
          'user_2': social.ReactionType.like,
          'user_3': social.ReactionType.celebrate,
        },
        commentCount: 3,
        tags: [],
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      social.SocialPost(
        id: 'post_2',
        userId: 'user_2',
        userName: 'Maria Garcia',
        content:
            'Made this delicious plant-based smoothie bowl! Perfect fuel for the afternoon. Recipe in the comments! 🥣✨',
        type: social.PostType.nutritionUpdate,
        pillars: [social.PostPillar.nutrition],
        mediaUrls: ['https://picsum.photos/400/400?random=2'],
        videoUrls: [],
        visibility: social.PostVisibility.public,
        autoGenerated: false,
        reactions: {
          'user_1': social.ReactionType.boost,
          'user_3': social.ReactionType.like,
        },
        commentCount: 7,
        tags: [],
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      social.SocialPost(
        id: 'post_3',
        userId: 'user_3',
        userName: 'David Kim',
        content:
            'Walked to work instead of driving today. Small steps toward a greener lifestyle! Every choice matters. 🌱🚶‍♂️',
        type: social.PostType.ecoAchievement,
        pillars: [social.PostPillar.eco],
        mediaUrls: [],
        videoUrls: [],
        visibility: social.PostVisibility.supporters,
        autoGenerated: true,
        reactions: {'user_1': social.ReactionType.boost},
        commentCount: 1,
        tags: [],
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: LottieLoadingWidget(width: 60, height: 60));
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.celebration_outlined,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr(context, 'welcome_social'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              tr(context, 'share_wellness_journey'),
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor(context).withAlpha(153),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const CreatePostScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.easeOutCubic;

                          var tween = Tween(
                            begin: begin,
                            end: end,
                          ).chain(CurveTween(curve: curve));

                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                    transitionDuration: const Duration(milliseconds: 400),
                    reverseTransitionDuration: const Duration(
                      milliseconds: 300,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(tr(context, 'create_post')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero, // Edge-to-edge posts
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return SocialPostCard(
          post: post,
          showSupporterTag:
              false, // No supporter tags in embedded social feed tabs
          onReaction: (postId, reaction) {
            debugPrint('Reaction: $reaction on post $postId');
          },
          onComment: (postId) {
            debugPrint('Comment on post $postId');
          },
          onShare: (postId) {
            debugPrint('Share post $postId');
          },
          onMoreOptions: (postId) {
            debugPrint('More options for post $postId');
          },
        );
      },
    );
  }
}
