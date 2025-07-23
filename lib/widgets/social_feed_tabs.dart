import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/social_service.dart';
import '../services/tribe_service.dart';
import '../models/social_activity.dart';
import '../models/community_challenge.dart';
import '../models/tribe_post.dart';
import '../theme/app_theme.dart';
import '../screens/tribes/tribe_discovery_screen.dart';
import '../screens/chat/conversations_screen.dart';
import '../providers/riverpod/chat_provider.dart';

enum SocialFeedTab {
  allPosts,
  tribes,
  supporters, 
  challenges,
}

class SocialFeedTabs extends ConsumerStatefulWidget {
  const SocialFeedTabs({
    super.key,
  });

  @override
  ConsumerState<SocialFeedTabs> createState() => _SocialFeedTabsState();
}

class _SocialFeedTabsState extends ConsumerState<SocialFeedTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SocialService _socialService = SocialService();
  final TribeService _tribeService = TribeService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
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
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
            tabs: const [
              Tab(text: 'All Posts'),
              Tab(text: 'Tribes'),
              Tab(text: 'Supporters'),
              Tab(text: 'Challenges'),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Tab Content
        SizedBox(
          height: 350,
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
    return StreamBuilder<List<SocialActivity>>(
      stream: _socialService.getCommunityFeed(limit: 20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final activities = snapshot.data ?? [];
        
        if (activities.isEmpty) {
          return _buildEmptyState(
            icon: '🌍',
            title: 'No community posts yet',
            subtitle: 'Be the first to share with the community!',
          );
        }

        return _buildExpandedFeed(activities);
      },
    );
  }

  Widget _buildTribesTab() {
    // Always show Discover Button at top, then activity feed
    return Column(
      children: [
        // Discover Tribes Button - Always visible at top right
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TribeDiscoveryScreen(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.explore,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                label: Text(
                  'Discover Tribes',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Activity Feed
        Expanded(
          child: StreamBuilder<List<TribePost>>(
            stream: _tribeService.getAllTribesActivityFeed(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final posts = snapshot.data ?? [];
              
              if (posts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '💬',
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tribe activity yet',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join tribes and start sharing!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _buildTribePostCard(post);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSupportersTab() {
    // Instagram-like dual view: Activity Feed + Messages
    return Column(
      children: [
        // Top Section: Messages Header with unread count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Messages',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 8),
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
                                builder: (context) => const ConversationsScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            'Message',
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
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
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
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        'Message',
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
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        'Message',
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
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final activities = snapshot.data ?? [];
              
              if (activities.isEmpty) {
                return _buildEmptyState(
                  icon: '👥',
                  title: 'No supporter activities',
                  subtitle: 'Connect with supporters to see their activities and start chatting',
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
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final challenges = snapshot.data ?? [];
        
        if (challenges.isEmpty) {
          return _buildEmptyState(
            icon: '🏆',
            title: 'No active challenges',
            subtitle: 'Check back for new community challenges!',
          );
        }

        return _buildExpandedChallenges(challenges);
      },
    );
  }


  Widget _buildExpandedFeed(List<SocialActivity> activities, {bool showSupporterBadge = false}) {
    return ListView.builder(
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildExpandedActivityCard(activity, showSupporterBadge: showSupporterBadge);
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


  Widget _buildExpandedActivityCard(SocialActivity activity, {bool showSupporterBadge = false}) {
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
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '👥 Supporter',
                                style: TextStyle(fontSize: 10, color: Colors.green),
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
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
                Icon(Icons.favorite_border, size: 20, color: theme.textTheme.bodySmall?.color),
                const SizedBox(width: 4),
                Text('${activity.likes.length}'),
                const SizedBox(width: 16),
                Icon(Icons.comment_outlined, size: 20, color: theme.textTheme.bodySmall?.color),
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
                Text(
                  '🏆',
                  style: const TextStyle(fontSize: 24),
                ),
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
            Text(
              challenge.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 16),
                const SizedBox(width: 4),
                Text('${challenge.participants.length} participants'),
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
          Text(
            icon,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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
      return 'Ended';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours left';
    } else {
      return 'Ending soon';
    }
  }


  Widget _buildTribePostCard(TribePost post) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: post.authorPhotoURL != null
                      ? NetworkImage(post.authorPhotoURL!)
                      : null,
                  child: post.authorPhotoURL == null
                      ? Text(
                          post.authorName.isNotEmpty 
                              ? post.authorName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(fontSize: 12),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Tribe',
                              style: TextStyle(
                                fontSize: 8,
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        post.getTimeAgo(),
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  post.getPostTypeIcon(),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Post Content
            if (post.title != null) ...[
              Text(
                post.title!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
            ],
            
            Text(
              post.content,
              style: const TextStyle(fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            
            // Post Actions
            Row(
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 16,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.likes.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.comment_outlined,
                  size: 16,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.commentCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}