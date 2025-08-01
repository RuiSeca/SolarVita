import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/database/social_service.dart';
import '../../models/social/social_activity.dart';
import '../../models/community/community_challenge.dart';
import '../../models/social/social_post.dart' as social;
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../screens/chat/conversations_screen.dart';
import '../../screens/social/create_post_screen.dart';
import '../../screens/social/social_feed_screen.dart';
import '../../providers/riverpod/chat_provider.dart';
import 'social_post_card.dart';
import '../common/lottie_loading_widget.dart';
import '../../screens/tribes/tribes_screen.dart';

enum SocialFeedTab { allPosts, tribes, supporters, challenges }

class SocialFeedTabs extends ConsumerStatefulWidget {
  const SocialFeedTabs({super.key});

  @override
  ConsumerState<SocialFeedTabs> createState() => _SocialFeedTabsState();
}

class _SocialFeedTabsState extends ConsumerState<SocialFeedTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SocialService _socialService = SocialService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: AppTheme.textFieldBackground(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              Tab(text: tr(context, 'all_posts')),
              Tab(text: tr(context, 'tribes')),
              Tab(text: tr(context, 'supporters')),
              Tab(text: tr(context, 'challenges')),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tab Content
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAllPostsTab(),
              _buildTribesTab(),
              _buildSupportersTab(),
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

  Widget _buildSupportersTab() {
    return Column(
      children: [
        // Messages button only (header removed)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Spacer(),
              Consumer(
                builder: (context, ref, child) {
                  final totalUnreadAsync = ref.watch(totalUnreadCountProvider);
                  return totalUnreadAsync.when(
                    data: (unreadCount) => Stack(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ConversationsScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: Icon(
                            Icons.message,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          label: Text(
                            tr(context, 'messages'),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                unreadCount > 99
                                    ? '99+'
                                    : unreadCount.toString(),
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
                    loading: () => TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ConversationsScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(
                        Icons.message,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      label: Text(
                        tr(context, 'messages'),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    error: (_, __) => TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ConversationsScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(
                        Icons.message,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      label: Text(
                        tr(context, 'messages'),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Activity Feed Section
        Expanded(
          child: StreamBuilder<List<SocialActivity>>(
            stream: _socialService.getSupportersActivityFeed(limit: 15),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final activities = snapshot.data ?? [];

              if (activities.isEmpty) {
                return _buildEmptyState(
                  icon: '👥',
                  title: tr(context, 'no_supporter_activities'),
                  subtitle: tr(context, 'connect_see_activities'),
                );
              }

              return _buildExpandedFeed(activities, showSupporterBadge: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChallengesTab() {
    return StreamBuilder<List<CommunityChallenge>>(
      stream: _socialService.getActiveChallenges(),
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

  Widget _buildExpandedFeed(
    List<SocialActivity> activities, {
    bool showSupporterBadge = false,
  }) {
    return ListView.builder(
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildExpandedActivityCard(
          activity,
          showSupporterBadge: showSupporterBadge,
        );
      },
    );
  }

  Widget _buildExpandedChallenges(List<CommunityChallenge> challenges) {
    return ListView.builder(
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return _buildExpandedChallengeCard(challenge);
      },
    );
  }

  Widget _buildExpandedActivityCard(
    SocialActivity activity, {
    bool showSupporterBadge = false,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: activity.userPhotoURL != null
                      ? NetworkImage(activity.userPhotoURL!)
                      : null,
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
                  child: activity.userPhotoURL == null
                      ? Text(
                          activity.userName.isNotEmpty
                              ? activity.userName[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            activity.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (showSupporterBadge) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '👥 ${tr(context, 'supporter')}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        activity.getTimeAgo(),
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  activity.getActivityIcon(),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              activity.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            if (activity.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                activity.description,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 20,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 4),
                Text('${activity.likes.length}'),
                const SizedBox(width: 16),
                Icon(
                  Icons.comment_outlined,
                  size: 20,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 4),
                Text('${activity.commentsCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedChallengeCard(CommunityChallenge challenge) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('🏆', style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(challenge.description, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${challenge.participants.length} ${tr(context, 'participants')}',
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(_formatChallengeDate(challenge.endDate)),
              ],
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
