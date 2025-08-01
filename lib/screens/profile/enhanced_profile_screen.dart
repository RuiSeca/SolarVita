// lib/screens/profile/enhanced_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/lottie_loading_widget.dart';
import '../../providers/riverpod/firebase_user_profile_provider.dart';
import '../../providers/riverpod/auth_provider.dart';
import '../../models/user/user_profile.dart';
import 'widgets/enhanced_profile_header.dart';

class EnhancedProfileScreen extends ConsumerStatefulWidget {
  final String? userId; // If null, shows current user's profile

  const EnhancedProfileScreen({super.key, this.userId});

  @override
  ConsumerState<EnhancedProfileScreen> createState() =>
      _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends ConsumerState<EnhancedProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Update activity when viewing profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activityTrackerProvider.notifier).trackActivity();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    _isCurrentUser = widget.userId == null || widget.userId == currentUser?.uid;

    final profileProvider = _isCurrentUser
        ? currentUserProfileProvider
        : userProfileProvider(widget.userId!);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider);
          if (_isCurrentUser) {
            ref.invalidate(currentUserSocialStatsProvider);
            ref.invalidate(profileCompletionStatusProvider);
          } else {
            ref.invalidate(userSocialStatsProvider(widget.userId!));
          }
        },
        child: Consumer(
          builder: (context, ref, child) {
            final profileAsync = ref.watch(profileProvider);

            return profileAsync.when(
              data: (profile) => profile != null
                  ? _buildProfileContent(context, profile)
                  : _buildNotFoundState(),
              loading: () => const Center(child: LottieLoadingWidget()),
              error: (error, stackTrace) => _buildErrorState(error.toString()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserProfile profile) {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: AppTheme.surfaceColor(context),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            profile.displayName,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (_isCurrentUser) ...[
              IconButton(
                icon: Icon(Icons.edit, color: AppTheme.textColor(context)),
                onPressed: () => _navigateToEditProfile(profile),
              ),
              IconButton(
                icon: Icon(Icons.settings, color: AppTheme.textColor(context)),
                onPressed: () => _showProfileSettings(),
              ),
            ] else ...[
              IconButton(
                icon: Icon(Icons.more_vert, color: AppTheme.textColor(context)),
                onPressed: () => _showUserOptions(profile),
              ),
            ],
          ],
        ),

        // Profile Header
        SliverToBoxAdapter(
          child: EnhancedProfileHeader(
            profile: profile,
            isCurrentUser: _isCurrentUser,
            onAvatarTap: () => _showAvatarPreview(profile.photoURL),
          ),
        ),

        // Action Buttons - Placeholder for missing widget
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_isCurrentUser) ...[
                  ElevatedButton(
                    onPressed: () => _navigateToEditProfile(profile),
                    child: const Text('Edit Profile'),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () => _toggleFollowUser(profile.uid),
                    child: const Text('Follow'),
                  ),
                  ElevatedButton(
                    onPressed: () => _startConversation(profile.uid),
                    child: const Text('Message'),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Profile Completion (only for current user)
        if (_isCurrentUser)
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, child) {
                final completionAsync = ref.watch(
                  profileCompletionStatusProvider,
                );
                return completionAsync.when(
                  data: (status) => status.isComplete
                      ? const SizedBox.shrink()
                      : Card(
                          margin: const EdgeInsets.all(16.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Complete Your Profile (${status.completionPercentage}%)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: status.completionPercentage / 100,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () =>
                                      _navigateToEditProfile(profile),
                                  child: const Text('Complete Profile'),
                                ),
                              ],
                            ),
                          ),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
          ),

        // Stats Section - Placeholder for missing widget
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer(
              builder: (context, ref, child) {
                final statsAsync = _isCurrentUser
                    ? ref.watch(currentUserSocialStatsProvider)
                    : ref.watch(userSocialStatsProvider(profile.uid));

                return statsAsync.when(
                  data: (stats) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn(
                        'Posts',
                        stats['postsCount']?.toString() ?? '0',
                        () => _scrollToPostsTab(),
                      ),
                      _buildStatColumn(
                        'Followers',
                        stats['followersCount']?.toString() ?? '0',
                        () => _navigateToFollowers(profile.uid),
                      ),
                      _buildStatColumn(
                        'Following',
                        stats['followingCount']?.toString() ?? '0',
                        () => _navigateToFollowing(profile.uid),
                      ),
                    ],
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Failed to load stats'),
                );
              },
            ),
          ),
        ),

        // Tab Bar
        SliverPersistentHeader(
          pinned: true,
          delegate: _SliverTabBarDelegate(
            TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).primaryColor,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: AppTheme.textColor(context).withAlpha(153),
              tabs: const [
                Tab(text: 'Posts'),
                Tab(text: 'Saved'),
                Tab(text: 'About'),
              ],
            ),
          ),
        ),

        // Tab Content
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsTab(profile.uid),
              _isCurrentUser
                  ? _buildSavedPostsTab()
                  : _buildRestrictedTab('Saved posts are private'),
              _buildAboutTab(profile),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSavedPostsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final savedPostsAsync = ref.watch(savedPostsProvider());

        return savedPostsAsync.when(
          data: (posts) => posts.isEmpty
              ? _buildEmptyState(
                  'No saved posts yet',
                  'Posts you save will appear here',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(posts[index].content),
                        subtitle: Text('By ${posts[index].userName}'),
                      ),
                    );
                  },
                ),
          loading: () => const Center(child: LottieLoadingWidget()),
          error: (error, _) => _buildErrorState('Failed to load saved posts'),
        );
      },
    );
  }

  Widget _buildAboutTab(UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            _buildAboutSection('Bio', profile.bio!),
            const SizedBox(height: 24),
          ],

          if (profile.interests.isNotEmpty) ...[
            _buildAboutSection(
              'Interests',
              null,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.interests
                      .map(
                        (interest) => Chip(
                          label: Text(interest),
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withAlpha(51),
                          labelStyle: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          _buildAboutSection('Member Since', _formatDate(profile.createdAt)),

          if (profile.lastActive != null) ...[
            const SizedBox(height: 16),
            _buildAboutSection(
              'Last Active',
              _formatLastActive(profile.lastActive!),
            ),
          ],

          if (profile.isVerified) ...[
            const SizedBox(height: 16),
            _buildAboutSection('Verification', 'Verified User ✅'),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutSection(
    String title,
    String? content, {
    List<Widget>? children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        if (content != null)
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textColor(context).withAlpha(204),
              height: 1.4,
            ),
          ),
        if (children != null) ...children,
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppTheme.textColor(context).withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textColor(context).withAlpha(153),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictedTab(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: AppTheme.textColor(context).withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            'Private Content',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textColor(context).withAlpha(153),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 64,
            color: AppTheme.textColor(context).withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            'User Not Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This user doesn\'t exist or has been removed',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textColor(context).withAlpha(153),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.withAlpha(128)),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textColor(context).withAlpha(153),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (_isCurrentUser) {
                ref.invalidate(currentUserProfileProvider);
              } else {
                ref.invalidate(userProfileProvider(widget.userId!));
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // Event handlers
  void _navigateToEditProfile(UserProfile profile) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit Profile feature coming soon!')),
    );
  }

  void _navigateToFollowers(String userId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Followers feature coming soon!')),
    );
  }

  void _navigateToFollowing(String userId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Following feature coming soon!')),
    );
  }

  void _scrollToPostsTab() {
    _tabController.animateTo(0);
  }

  void _showAvatarPreview(String? photoURL) {
    if (photoURL == null || photoURL.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(child: Image.network(photoURL)),
      ),
    );
  }

  void _toggleFollowUser(String userId) async {
    try {
      HapticFeedback.lightImpact();
      await ref
          .read(userProfileActionsProvider.notifier)
          .toggleFollowUser(userId);

      // Refresh follow status and stats
      ref.invalidate(isFollowingUserProvider(userId));
      ref.invalidate(userSocialStatsProvider(userId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update follow status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startConversation(String userId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Messaging feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showProfileSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile settings coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showUserOptions(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Profile'),
              onTap: () {
                Navigator.pop(context);
                _shareProfile(profile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report User'),
              onTap: () {
                Navigator.pop(context);
                _reportUser(profile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block User'),
              onTap: () {
                Navigator.pop(context);
                _blockUser(profile);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareProfile(UserProfile profile) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Share feature coming soon!')));
  }

  void _reportUser(UserProfile profile) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report feature coming soon!')),
    );
  }

  void _blockUser(UserProfile profile) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Block feature coming soon!')));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return 'Today';
    }
  }

  String _formatLastActive(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 5) {
      return 'Active now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return _formatDate(lastActive);
    }
  }

  Widget _buildStatColumn(String label, String count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textColor(context).withAlpha(153),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab(String userId) {
    return Consumer(
      builder: (context, ref, child) {
        final postsAsync = ref.watch(userPostsProvider(userId));

        return postsAsync.when(
          data: (posts) {
            if (posts.isEmpty) {
              return const Center(child: Text('No posts yet'));
            }

            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.content,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.timestamp.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textColor(context).withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        );
      },
    );
  }
}

// Custom SliverTabBarDelegate for pinned tab bar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppTheme.surfaceColor(context), child: tabBar);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
