// lib/screens/social/social_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:ui';
import '../../models/social/social_post.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../widgets/social/social_post_card.dart';
import '../../widgets/common/lottie_loading_widget.dart';
import '../../providers/riverpod/firebase_social_provider.dart';
import '../../providers/riverpod/chat_provider.dart';
import '../../providers/riverpod/story_provider.dart';
import '../../providers/riverpod/auth_provider.dart';
import '../../services/database/social_service.dart';
import '../../models/social/story_highlight.dart';
import 'create_post_screen.dart';
import 'post_templates_screen.dart';
import '../chat/conversations_screen.dart';
import '../profile/widgets/story_viewer_screen.dart';
import '../profile/widgets/story_creation_screen.dart';

class SocialFeedScreen extends ConsumerStatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  ConsumerState<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends ConsumerState<SocialFeedScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final SocialService _socialService = SocialService();
  String _selectedFilter = 'all'; // all, supporters, public
  bool _isBottomBarVisible = true;
  bool _isScrolling = false;
  Timer? _scrollTimer;
  List<PostPillar>? _selectedPillars;
  Set<String> _supportedUserIds = {};

  // Animation controller for smooth bottom bar transitions
  late AnimationController _bottomBarController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _bottomBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _bottomBarController,
            curve: Curves.easeInOutCubic,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bottomBarController, curve: Curves.easeInOut),
    );

    // Start with bottom bar visible
    _bottomBarController.forward();

    _scrollController.addListener(_onScroll);
    _setupScrollListener();
  }

  @override
  void dispose() {
    _bottomBarController.dispose();
    _scrollController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_isBottomBarVisible) {
          _updateBottomBarVisibility(false);
        }
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_isBottomBarVisible) {
          _updateBottomBarVisibility(true);
        }
      }
    });
  }

  void _updateBottomBarVisibility(bool visible) {
    setState(() => _isBottomBarVisible = visible);
    if (visible) {
      _bottomBarController.forward();
    } else {
      _bottomBarController.reverse();
    }
  }

  void _onScroll() {
    if (!_isScrolling) {
      setState(() => _isScrolling = true);
      _scrollTimer?.cancel();
      _scrollTimer = Timer(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() => _isScrolling = false);
        }
      });
    }
  }

  void _scrollToTop() {
    HapticFeedback.lightImpact();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  PostVisibility? get _filterVisibility {
    switch (_selectedFilter) {
      case 'supporters':
        return PostVisibility.supporters;
      case 'public':
        return PostVisibility.public;
      default:
        return null; // Show all posts
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildFeedContent(),
          _buildGlassyBottomBar(),
          if (_isScrolling && !_isBottomBarVisible) _buildScrollToTopButton(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surfaceColor(context).withValues(alpha: 0.85),
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.surfaceColor(context).withValues(alpha: 0.9),
              AppTheme.surfaceColor(context).withValues(alpha: 0.8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'social_feed'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              final postsAsync = ref.watch(
                socialPostsFeedProvider(
                  visibility: _filterVisibility,
                  pillars: _selectedPillars,
                  limit: 50,
                ),
              );

              return postsAsync.when(
                data: (posts) => Text(
                  '${posts.length} posts',
                  style: TextStyle(
                    color: AppTheme.textColor(context).withAlpha(153),
                    fontSize: 12,
                  ),
                ),
                loading: () => Text(
                  tr(context, 'loading'),
                  style: TextStyle(
                    color: AppTheme.textColor(context).withAlpha(153),
                    fontSize: 12,
                  ),
                ),
                error: (_, __) => Text(
                  tr(context, 'error_loading'),
                  style: TextStyle(
                    color: Colors.red.withAlpha(153),
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        _buildFilterButton(),
        _buildMessagesButton(),
      ],
    );
  }

  Widget _buildFilterButton() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.filter_list,
        color: _selectedFilter != 'all'
            ? Theme.of(context).primaryColor
            : AppTheme.textColor(context),
      ),
      onSelected: (value) {
        setState(() {
          _selectedFilter = value;
          _supportedUserIds.clear(); // Clear cache when filter changes
        });
        HapticFeedback.selectionClick();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'all',
          child: Row(
            children: [
              Icon(
                Icons.public,
                size: 20,
                color: _selectedFilter == 'all'
                    ? Theme.of(context).primaryColor
                    : AppTheme.textColor(context),
              ),
              const SizedBox(width: 8),
              Text(tr(context, 'all_posts')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'supporters',
          child: Row(
            children: [
              Icon(
                Icons.people,
                size: 20,
                color: _selectedFilter == 'supporters'
                    ? Theme.of(context).primaryColor
                    : AppTheme.textColor(context),
              ),
              const SizedBox(width: 8),
              Text(tr(context, 'supporters_only')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'public',
          child: Row(
            children: [
              Icon(
                Icons.public,
                size: 20,
                color: _selectedFilter == 'public'
                    ? Theme.of(context).primaryColor
                    : AppTheme.textColor(context),
              ),
              const SizedBox(width: 8),
              Text(tr(context, 'public_only')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesButton() {
    return Consumer(
      builder: (context, ref, child) {
        final totalUnreadAsync = ref.watch(totalUnreadCountProvider);
        return totalUnreadAsync.when(
          data: (unreadCount) => Stack(
            children: [
              IconButton(
                icon: Icon(Icons.message, color: AppTheme.textColor(context)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConversationsScreen(),
                    ),
                  );
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
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
          loading: () => IconButton(
            icon: Icon(Icons.message, color: AppTheme.textColor(context)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConversationsScreen(),
                ),
              );
            },
          ),
          error: (_, __) => IconButton(
            icon: Icon(Icons.message, color: AppTheme.textColor(context)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConversationsScreen(),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFeedContent() {
    return Consumer(
      builder: (context, ref, child) {
        final postsAsync = ref.watch(
          socialPostsFeedProvider(
            visibility: _filterVisibility,
            pillars: _selectedPillars,
            limit: 50,
          ),
        );

        return postsAsync.when(
          data: (posts) => _buildPostsList(posts),
          loading: () => const Center(child: LottieLoadingWidget()),
          error: (error, stackTrace) => _buildErrorState(error.toString()),
        );
      },
    );
  }

  Widget _buildPostsList(List<SocialPost> posts) {
    // Load supported user IDs for tagging
    if (posts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSupportedUserIds(posts);
      });
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        ref.invalidate(socialPostsFeedProvider);
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.only(
          top: 8,
          bottom: _isBottomBarVisible ? 120 : 8, // Space for bottom bar
        ),
        itemCount: posts.length + 1, // +1 for highlights section
        itemBuilder: (context, index) {
          // First item is the story highlights
          if (index == 0) {
            return _buildStoryHighlightsSection();
          }
          
          // Rest are posts (index - 1 because highlights takes the first slot)
          final postIndex = index - 1;
          if (postIndex < posts.length) {
            final post = posts[postIndex];
            return SocialPostCard(
              post: post,
              onReaction: (postId, reaction) =>
                  _handleReaction(postId, reaction),
              showSupporterTag: _shouldShowSupporterTag(post),
            );
          }
          
          // Empty state if no posts but we still want to show highlights
          if (posts.isEmpty && index == 1) {
            return _buildEmptyState();
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
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
            _getEmptyStateTitle(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateSubtitle(),
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textColor(context).withAlpha(153),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
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
                  reverseTransitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: Text(tr(context, 'create_first_post')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            tr(context, 'something_wrong'),
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
              ref.invalidate(socialPostsFeedProvider);
            },
            icon: const Icon(Icons.refresh),
            label: Text(tr(context, 'try_again')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassyBottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context).withAlpha(200),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: AppTheme.textColor(context).withAlpha(26),
                    width: 1,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildCreatePostButton()),
                        const SizedBox(width: 12),
                        _buildTemplatesButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePostButton() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withAlpha(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withAlpha(77),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
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
                      const curve = Curves.elasticOut;

                      var tween = Tween(
                        begin: begin,
                        end: end,
                      ).chain(CurveTween(curve: curve));

                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                transitionDuration: const Duration(milliseconds: 800),
                reverseTransitionDuration: const Duration(milliseconds: 500),
              ),
            );
          },
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  tr(context, 'create_post'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplatesButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).primaryColor, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const PostTemplatesScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      const begin = Offset(0.0, 1.0);
                      const end = Offset.zero;
                      const curve = Curves.elasticOut;

                      var tween = Tween(
                        begin: begin,
                        end: end,
                      ).chain(CurveTween(curve: curve));

                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                transitionDuration: const Duration(milliseconds: 800),
                reverseTransitionDuration: const Duration(milliseconds: 500),
              ),
            );
          },
          child: Icon(
            Icons.auto_awesome,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildScrollToTopButton() {
    return Positioned(
      right: 20,
      bottom: 20,
      child: AnimatedOpacity(
        opacity: _isScrolling ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withAlpha(77),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _scrollToTop,
              child: const Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getEmptyStateTitle() {
    switch (_selectedFilter) {
      case 'supporters':
        return tr(context, 'no_supporter_posts');
      case 'public':
        return tr(context, 'no_public_posts');
      default:
        return tr(context, 'welcome_social');
    }
  }

  String _getEmptyStateSubtitle() {
    switch (_selectedFilter) {
      case 'supporters':
        return tr(context, 'connect_supporters');
      case 'public':
        return tr(context, 'first_public_post');
      default:
        return tr(context, 'share_wellness_journey');
    }
  }

  // EVENT HANDLERS

  void _handleReaction(String postId, ReactionType reaction) async {
    final failedAddReaction = tr(context, 'failed_add_reaction');

    try {
      await ref
          .read(socialPostActionsProvider.notifier)
          .reactToPost(postId, reaction);
      HapticFeedback.lightImpact();
    } catch (e) {
      _showErrorSnackBar(failedAddReaction.replaceAll('{error}', '$e'));
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _shouldShowSupporterTag(SocialPost post) {
    // Only show supporter tag in public filter for users we're supporting
    return _selectedFilter == 'public' &&
        _supportedUserIds.contains(post.userId);
  }

  Widget _buildStoryHighlightsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Consumer(
        builder: (context, ref, child) {
          final currentUser = ref.watch(currentUserProvider);
          final userId = currentUser?.uid ?? '';

          if (userId.isEmpty) {
            return const SizedBox.shrink();
          }

          // Get user's own highlights
          final userHighlights = ref.watch(userStoryHighlightsProvider(userId));
          // Get supporters' highlights (can be implemented later)
          
          return SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Add New Story button
                _buildAddNewStoryButton(ref, userId),
                const SizedBox(width: 12),
                
                // User's own highlights
                userHighlights.when(
                  loading: () => _buildLoadingHighlights(),
                  error: (error, stack) => const SizedBox.shrink(),
                  data: (highlights) => Row(
                    children: highlights.take(10).map((highlight) => 
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _buildHighlightCircle(highlight, highlights, true),
                      ),
                    ).toList(),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Supporters/Friends highlights - placeholder for now
                _buildSupportersHighlights(ref),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddNewStoryButton(WidgetRef ref, String userId) {
    return GestureDetector(
      onTap: () => _showCreateHighlightDialog(context, ref),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                width: 2,
                style: BorderStyle.solid,
              ),
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.add,
              color: Theme.of(context).primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(context, 'new'),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.black.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCircle(StoryHighlight highlight, List<StoryHighlight> allHighlights, bool isOwn) {
    final category = highlight.category;
    final colors = category.colorGradient;

    return GestureDetector(
      onTap: () => _openStoryViewer(context, allHighlights, allHighlights.indexOf(highlight), isOwn),
      onLongPress: isOwn ? () => _showHighlightOptions(context, highlight) : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: colors.map((c) => Color(c)).toList(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(colors.first).withValues(alpha: 0.3),
                  spreadRadius: 0,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceColor(context),
              ),
              child: ClipOval(
                child: Consumer(
                  builder: (context, ref, child) {
                    final currentUser = ref.watch(currentUserProvider);
                    final userPhotoUrl = currentUser?.photoURL;
                    
                    if (userPhotoUrl != null && userPhotoUrl.isNotEmpty) {
                      return Image.network(
                        userPhotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildUserInitials(currentUser),
                      );
                    } else {
                      return _buildUserInitials(currentUser);
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 90,
            child: Consumer(
              builder: (context, ref, child) {
                final currentUser = ref.watch(currentUserProvider);
                final userName = currentUser?.displayName ?? currentUser?.email?.split('@').first ?? 'You';
                
                return Text(
                  userName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.black.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildUserInitials(dynamic currentUser) {
    final userName = currentUser?.displayName ?? currentUser?.email?.split('@').first ?? 'U';
    final initials = userName.length > 0 ? userName[0].toUpperCase() : 'U';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.7),
            Theme.of(context).primaryColor.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }


  Widget _buildLoadingHighlights() {
    return Row(
      children: List.generate(3, (index) => 
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 70,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportersHighlights(WidgetRef ref) {
    // Placeholder for supporters' highlights
    // This could load highlights from supported users
    return const SizedBox.shrink();
  }

  void _openStoryViewer(BuildContext context, List<StoryHighlight> highlights, int initialIndex, bool isOwn) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StoryViewerScreen(
          highlights: highlights,
          initialHighlightIndex: initialIndex,
          isOwnStory: isOwn,
        ),
      ),
    );
  }

  void _showCreateHighlightDialog(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StoryCreationScreen(),
      ),
    );
  }

  void _showHighlightOptions(BuildContext context, StoryHighlight highlight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: Icon(Icons.edit, color: Theme.of(context).primaryColor),
              title: Text(tr(context, 'edit_highlight')),
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit highlight screen
              },
            ),
            
            ListTile(
              leading: Icon(Icons.add_photo_alternate, color: Theme.of(context).primaryColor),
              title: Text(tr(context, 'add_story')),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => StoryCreationScreen(existingHighlight: highlight),
                  ),
                );
              },
            ),
            
            ListTile(
              leading: Icon(Icons.visibility_off, color: Colors.orange),
              title: Text(tr(context, 'hide_highlight')),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text(tr(context, 'delete_highlight')),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSupportedUserIds(List<SocialPost> posts) async {
    if (_selectedFilter != 'public') return;

    final userIds = posts.map((post) => post.userId).toSet();
    final supportedIds = <String>{};

    for (final userId in userIds) {
      try {
        final isSupporting = await _socialService.isSupporting(userId);
        if (isSupporting) {
          supportedIds.add(userId);
        }
      } catch (e) {
        // Ignore errors for individual checks
      }
    }

    if (mounted) {
      setState(() {
        _supportedUserIds = supportedIds;
      });
    }
  }
}
