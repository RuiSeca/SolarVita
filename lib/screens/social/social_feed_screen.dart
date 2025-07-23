// lib/screens/social/social_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/social_post.dart';
import '../../theme/app_theme.dart';
import '../../widgets/social/social_post_card.dart';
import '../../widgets/common/lottie_loading_widget.dart';
import 'create_post_screen.dart';

class SocialFeedScreen extends ConsumerStatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  ConsumerState<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends ConsumerState<SocialFeedScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final List<SocialPost> _posts = [];
  bool _isLoading = false;
  bool _hasMorePosts = true;
  String _selectedFilter = 'all'; // all, supporters, public
  int _currentPage = 0;
  static const int _postsPerPage = 10;

  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMorePosts) {
        _loadMorePosts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(),
        ],
        body: RefreshIndicator(
          onRefresh: _refreshFeed,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildFilterTabs(),
              _buildPostsList(),
              if (_isLoading) _buildLoadingIndicator(),
              if (!_hasMorePosts && _posts.isNotEmpty) _buildEndMessage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: AppTheme.surfaceColor(context),
      elevation: 0,
      pinned: true,
      floating: true,
      snap: true,
      title: Row(
        children: [
          Text(
            'SolarVita',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'SOCIAL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreatePostScreen(),
              ),
            ).then((result) {
              if (result == true) {
                _refreshFeed();
              }
            });
          },
          icon: Icon(
            Icons.add_box_outlined,
            color: AppTheme.textColor(context),
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All Posts', Icons.feed),
                    const SizedBox(width: 8),
                    _buildFilterChip('supporters', 'Supporters', Icons.people),
                    const SizedBox(width: 8),
                    _buildFilterChip('public', 'Discover', Icons.explore),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _showFilterOptions,
              icon: Icon(
                Icons.tune,
                color: AppTheme.textColor(context).withAlpha(153),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, IconData icon) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => _changeFilter(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : AppTheme.textColor(context).withAlpha(51),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : AppTheme.textColor(context).withAlpha(153),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : AppTheme.textColor(context),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPostsList() {
    if (_posts.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= _posts.length) return null;
          
          final post = _posts[index];
          return SocialPostCard(
            post: post,
            onReaction: _handleReaction,
            onComment: _handleComment,
            onShare: _handleShare,
            onMoreOptions: _handleMoreOptions,
          );
        },
        childCount: _posts.length,
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case 'supporters':
        title = 'No supporter posts yet';
        subtitle = 'Connect with supporters to see their wellness journey';
        icon = Icons.people_outline;
        break;
      case 'public':
        title = 'Discover the community';
        subtitle = 'Explore public posts from the SolarVita community';
        icon = Icons.explore_outlined;
        break;
      default:
        title = 'Welcome to SolarVita Social!';
        subtitle = 'Share your wellness journey and connect with supporters';
        icon = Icons.celebration_outlined;
    }

    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                  icon,
                  size: 48,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textColor(context).withAlpha(153),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatePostScreen(),
                    ),
                  ).then((result) {
                    if (result == true) {
                      _refreshFeed();
                    }
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Your First Post'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: LottieLoadingWidget(width: 60, height: 60),
        ),
      ),
    );
  }

  Widget _buildEndMessage() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 32,
              color: AppTheme.textColor(context).withAlpha(128),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context).withAlpha(153),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Check back later for new posts',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor(context).withAlpha(128),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Event handlers
  Future<void> _loadInitialPosts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentPage = 0;
    });

    try {
      final newPosts = await _fetchPosts(_currentPage);
      setState(() {
        _posts.clear();
        _posts.addAll(newPosts);
        _hasMorePosts = newPosts.length == _postsPerPage;
        _currentPage++;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load posts: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newPosts = await _fetchPosts(_currentPage);
      setState(() {
        _posts.addAll(newPosts);
        _hasMorePosts = newPosts.length == _postsPerPage;
        _currentPage++;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load more posts: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshFeed() async {
    await _loadInitialPosts();
  }

  void _changeFilter(String filter) {
    if (_selectedFilter != filter) {
      setState(() {
        _selectedFilter = filter;
      });
      _loadInitialPosts();
    }
  }


  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterOption('All Content', 'all'),
            _buildFilterOption('Fitness Posts', 'fitness'),
            _buildFilterOption('Nutrition Posts', 'nutrition'),
            _buildFilterOption('Eco Posts', 'eco'),
            _buildFilterOption('Recent Posts', 'recent'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, String value) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(color: AppTheme.textColor(context)),
      ),
      trailing: _selectedFilter == value
          ? Icon(Icons.check, color: Theme.of(context).primaryColor)
          : null,
      onTap: () {
        _changeFilter(value);
        Navigator.pop(context);
      },
    );
  }

  // Mock data fetching - replace with actual Firebase calls
  Future<List<SocialPost>> _fetchPosts(int page) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Generate mock posts based on filter
    return _generateMockPosts(page);
  }

  List<SocialPost> _generateMockPosts(int page) {
    final mockPosts = <SocialPost>[];
    final startIndex = page * _postsPerPage;

    for (int i = 0; i < _postsPerPage; i++) {
      final postIndex = startIndex + i;
      if (postIndex >= 50) break; // Limit total posts for demo

      mockPosts.add(SocialPost(
        id: 'post_$postIndex',
        userId: 'user_${postIndex % 5}',
        userName: _getMockUserName(postIndex % 5),
        userAvatarUrl: null,
        content: _getMockPostContent(postIndex),
        type: PostType.values[postIndex % PostType.values.length],
        pillars: _getMockPillars(postIndex),
        mediaUrls: postIndex % 3 == 0 ? ['https://picsum.photos/400/400?random=$postIndex'] : [],
        videoUrls: [],
        visibility: PostVisibility.values[postIndex % PostVisibility.values.length],
        autoGenerated: postIndex % 5 == 0,
        reactions: {},
        commentCount: postIndex % 4,
        tags: [],
        timestamp: DateTime.now().subtract(Duration(hours: postIndex)),
      ));
    }

    return mockPosts;
  }

  String _getMockUserName(int index) {
    final names = ['Alex Chen', 'Maria Garcia', 'David Kim', 'Sarah Johnson', 'Ryan Patel'];
    return names[index % names.length];
  }

  String _getMockPostContent(int index) {
    final contents = [
      'Just completed my morning workout! 💪 Feeling energized and ready to tackle the day.',
      'Made this delicious plant-based smoothie bowl. Perfect fuel for the afternoon!',
      'Walked to work instead of driving today. Small steps toward a greener lifestyle! 🌱',
      'Grateful for this beautiful sunrise during my meditation session. Starting the day with mindfulness.',
      'Hit my step goal for the 7th day in a row! Consistency is key to building healthy habits.',
      'Tried a new yoga class today. My flexibility is slowly improving! 🧘‍♀️',
      'Meal prep Sunday complete! Ready for a week of nutritious meals.',
      'Swapped single-use plastics for reusable alternatives. Every small change matters!',
    ];
    return contents[index % contents.length];
  }

  List<PostPillar> _getMockPillars(int index) {
    final pillarSets = [
      [PostPillar.fitness],
      [PostPillar.nutrition],
      [PostPillar.eco],
      [PostPillar.fitness, PostPillar.nutrition],
      [PostPillar.eco, PostPillar.fitness],
    ];
    return pillarSets[index % pillarSets.length];
  }

  // Action handlers
  void _handleReaction(String postId, ReactionType reaction) {
    // TODO: Implement reaction handling with Firebase
    print('Reaction: $reaction on post $postId');
  }

  void _handleComment(String postId) {
    // TODO: Navigate to comments screen
    print('Comment on post $postId');
  }

  void _handleShare(String postId) {
    // TODO: Implement sharing functionality
    print('Share post $postId');
  }

  void _handleMoreOptions(String postId) {
    // TODO: Show more options (edit, delete, report, etc.)
    print('More options for post $postId');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}