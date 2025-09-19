import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:share_plus/share_plus.dart';
import '../../models/tribe/tribe.dart';
import '../../models/tribe/tribe_member.dart';
import '../../models/tribe/tribe_post.dart';
import '../../models/social/social_post.dart';
import '../../services/database/tribe_service.dart';
import '../../theme/app_theme.dart';
import '../social/post_comments_screen.dart';
import 'create_tribe_post_screen.dart';

class TribeDetailScreen extends ConsumerStatefulWidget {
  final String tribeId;
  final String? inviteCode;

  const TribeDetailScreen({super.key, required this.tribeId, this.inviteCode});

  @override
  ConsumerState<TribeDetailScreen> createState() => _TribeDetailScreenState();
}

class _TribeDetailScreenState extends ConsumerState<TribeDetailScreen>
    with SingleTickerProviderStateMixin {
  final TribeService _tribeService = TribeService();
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  bool _isJoining = false;
  bool _showAppBarTitle = false;
  TribeMember? _currentUserMember;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadMembershipStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showTitle = _scrollController.offset > 100;
    if (showTitle != _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = showTitle;
      });
    }
  }

  Future<void> _loadMembershipStatus() async {
    final currentUserId = _tribeService.currentUserId;
    if (currentUserId == null) return;

    final isMember = await _tribeService.isUserTribeMember(
      widget.tribeId,
      currentUserId,
    );
    if (isMember && mounted) {
      final member = await _tribeService.getTribeMember(
        widget.tribeId,
        currentUserId,
      );
      setState(() {
        _currentUserMember = member;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tribe?>(
      stream: _tribeService.getTribeById(widget.tribeId),
      builder: (context, tribeSnapshot) {
        if (tribeSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (tribeSnapshot.hasError || !tribeSnapshot.hasData) {
          return _buildErrorScaffold();
        }

        final tribe = tribeSnapshot.data!;
        return _buildTribeScaffold(tribe);
      },
    );
  }

  Widget _buildTribeScaffold(Tribe tribe) {
    final theme = Theme.of(context);
    final isMember = _currentUserMember != null;

    return Scaffold(
      body: Column(
        children: [
          // Custom App Bar with Dynamic Title
          Container(
            height: 100,
            color: theme.scaffoldBackgroundColor,
            child: SafeArea(
              child: Stack(
                children: [
                  // Back button
                  Positioned(
                    left: 8,
                    top: 8,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  // Dynamic title
                  Center(
                    child: AnimatedOpacity(
                      opacity: _showAppBarTitle ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        tribe.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  // Action buttons
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline.withAlpha(60),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            iconSize: 20,
                            onPressed: () => _shareInvite(tribe),
                            icon: Icon(
                              Icons.share_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline.withAlpha(60),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            iconSize: 20,
                            onPressed: () => _showTribeOptions(tribe),
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Content
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: _buildTribeHeader(tribe),
                ),

                // Tab Bar
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withAlpha(25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.all(4),
                      dividerColor: Colors.transparent,
                      labelColor: theme.colorScheme.onPrimary,
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                      tabs: const [
                        Tab(text: 'Posts'),
                        Tab(text: 'Members'),
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
                      _buildPostsTab(tribe),
                      _buildMembersTab(tribe),
                      _buildAboutTab(tribe),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: isMember
          ? FloatingActionButton(
              onPressed: () => _createPost(tribe),
              backgroundColor: theme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: isMember ? null : _buildJoinBar(tribe),
    );
  }

  Widget _buildTribeHeader(Tribe tribe) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withAlpha(40),
            theme.primaryColor.withAlpha(20),
            AppTheme.cardColor(context).withAlpha(100),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withAlpha(15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category with Google Material 3 styling
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withAlpha(100),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withAlpha(30),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tribe.getCategoryIcon(),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tribe.getCategoryName().toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tribe Name with Material 3 typography
                  Text(
                    tribe.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.0,
                      fontSize: 20,
                      color: theme.brightness == Brightness.dark ? Colors.white : theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Enhanced Stats Row with Google Material 3 style
                  Row(
                    children: [
                      _buildStatChip(
                        icon: Icons.group_rounded,
                        text: '${tribe.memberCount}',
                        label: 'Members',
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        icon: tribe.isPrivate ? Icons.lock_rounded : Icons.public_rounded,
                        text: tribe.getVisibilityText(),
                        label: 'Access',
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String text,
    String? label,
  }) {
    final theme = Theme.of(context);

    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(180),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withAlpha(60),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (label != null)
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab(Tribe tribe) {
    final isMember = _currentUserMember != null;

    return StreamBuilder<List<TribePost>>(
      stream: _tribeService.getTribePosts(tribe.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState('Failed to load posts');
        }

        final posts = snapshot.data ?? [];

        return Column(
          children: [
            // Create Post Button (for members)
            if (isMember)
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.add_rounded,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    'Share something with the tribe...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () => _createPost(tribe),
                ),
              ),

            // Posts List
            if (posts.isEmpty)
              Expanded(child: _buildEmptyPostsState(isMember))
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) => _buildPostCard(posts[index]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMembersTab(Tribe tribe) {
    return StreamBuilder<List<TribeMember>>(
      stream: _tribeService.getTribeMembers(tribe.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState('Failed to load members');
        }

        final members = snapshot.data ?? [];

        if (members.isEmpty) {
          return _buildEmptyMembersState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: members.length,
          itemBuilder: (context, index) => _buildMemberCard(members[index]),
        );
      },
    );
  }

  Widget _buildAboutTab(Tribe tribe) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
          // Description
          _buildInfoCard(
            title: 'Description',
            icon: Icons.description,
            child: Text(tribe.description, style: theme.textTheme.bodyMedium),
          ),

          const SizedBox(height: 16),

          // Category
          _buildInfoCard(
            title: 'Category',
            icon: Icons.category_rounded,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(60),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tribe.getCategoryIcon(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tribe.getCategoryName(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Created Info
          _buildInfoCard(
            title: 'Tribe Info',
            icon: Icons.info,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Created by ${tribe.creatorName}'),
                const SizedBox(height: 4),
                Text(
                  'Created ${_formatDate(tribe.createdAt)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),

          if (tribe.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Tags',
              icon: Icons.tag_rounded,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: tribe.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.secondary.withAlpha(60),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],

          if (tribe.location != null) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Location',
              icon: Icons.location_on,
              child: Text(tribe.location!),
            ),
          ],
        ],
      );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(TribePost post) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(100),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _commentOnPost(post),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post Header - Reddit style
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    // Upvote/Like section (Material 3 style)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withAlpha(60),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _likePost(post),
                            child: Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: post.likes.contains(_tribeService.currentUserId)
                                  ? theme.primaryColor
                                  : theme.textTheme.bodyMedium?.color?.withAlpha(150),
                              size: 20,
                            ),
                          ),
                          Text(
                            '${post.likes.length}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: post.likes.contains(_tribeService.currentUserId)
                                  ? theme.primaryColor
                                  : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: theme.textTheme.bodyMedium?.color?.withAlpha(100),
                            size: 20,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Post content area
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Author info
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundImage: post.authorPhotoURL != null
                                    ? CachedNetworkImageProvider(post.authorPhotoURL!)
                                    : null,
                                child: post.authorPhotoURL == null
                                    ? Text(
                                        post.authorName.isNotEmpty ? post.authorName[0] : 'U',
                                        style: const TextStyle(fontSize: 12),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                post.authorName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: theme.textTheme.titleMedium?.color,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '•',
                                style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                post.getTimeAgo(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                              if (post.isAnnouncement) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.orange.withAlpha(30),
                                        Colors.orange.withAlpha(20),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.orange.withAlpha(60),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    'PINNED',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Post Title (Reddit style)
              if (post.title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(56, 0, 16, 8),
                  child: Text(
                    post.title!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.3,
                    ),
                  ),
                ),

              // Post Content
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                child: Text(
                  post.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    fontSize: 14,
                  ),
                ),
              ),

              // Post Actions (Reddit style)
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 0, 16, 12),
                child: Row(
                  children: [
                    // Comments
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${post.commentCount}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Share
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.share_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Share',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(TribeMember member) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: member.userPhotoURL != null
                ? CachedNetworkImageProvider(member.userPhotoURL!)
                : null,
            child: member.userPhotoURL == null
                ? Text(member.userName.isNotEmpty ? member.userName[0] : 'U')
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.userName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Joined ${_formatDate(member.joinedAt)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (member.role != TribeMemberRole.member)
            Chip(
              label: Text(member.role.name.toUpperCase()),
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                fontSize: 10,
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJoinBar(Tribe tribe) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isJoining ? null : () => _joinTribe(tribe),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isJoining
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    tribe.isPrivate ? 'Request to Join' : 'Join Tribe',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPostsState(bool isMember) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isMember
                  ? 'Be the first to share something!'
                  : 'Join the tribe to see posts',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (isMember) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _createPost(null),
                child: const Text('Create First Post'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMembersState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No members yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScaffold() {
    return Scaffold(
      appBar: AppBar(title: const Text('Tribe')),
      body: _buildErrorState('Failed to load tribe'),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${difference.inDays > 730 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${difference.inDays > 60 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return 'Today';
    }
  }

  Future<void> _joinTribe(Tribe tribe) async {
    setState(() => _isJoining = true);

    try {
      await _tribeService.joinTribe(tribe.id, inviteCode: widget.inviteCode);
      await _loadMembershipStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined ${tribe.name}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join tribe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  void _createPost(Tribe? tribe) {
    if (tribe != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateTribePostScreen(tribe: tribe),
        ),
      );
    }
  }

  Future<void> _likePost(TribePost post) async {
    try {
      await _tribeService.likeTribePost(post.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _commentOnPost(TribePost post) {
    // Navigate to the post comments screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostCommentsScreen(
          post: SocialPost(
            id: post.id,
            userId: post.authorId,
            userName: post.authorName,
            userAvatarUrl: post.authorPhotoURL,
            content: post.content,
            type: PostType.reflection, // Default type for tribe posts
            pillars: [PostPillar.fitness], // Default pillar
            mediaUrls: post.imageUrls,
            videoUrls: [], // Tribes typically don't have video
            visibility: PostVisibility.public, // Tribes are usually public
            autoGenerated: false,
            reactions: {}, // Empty reactions map
            commentCount: post.commentCount,
            tags: post.tags,
            timestamp: post.createdAt,
          ),
        ),
      ),
    );
  }

  void _shareInvite(Tribe tribe) {
    final message = tribe.isPrivate && tribe.inviteCode != null
        ? 'Join our tribe "${tribe.name}" on SolarVita with invite code: ${tribe.inviteCode}'
        : 'Check out the "${tribe.name}" tribe on SolarVita!';

    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite message copied to clipboard!')),
    );
  }

  void _showTribeOptions(Tribe tribe) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tribe.inviteCode != null) ...[
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy Invite Code'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: tribe.inviteCode!));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite code copied!')),
                  );
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Tribe'),
              onTap: () {
                Navigator.pop(context);
                _shareInvite(tribe);
              },
            ),
            if (_currentUserMember != null) ...[
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Leave Tribe'),
                onTap: () {
                  Navigator.pop(context);
                  _showLeaveConfirmation(tribe);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLeaveConfirmation(Tribe tribe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Tribe'),
        content: Text('Are you sure you want to leave "${tribe.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveTribe(tribe);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveTribe(Tribe tribe) async {
    try {
      await _tribeService.leaveTribe(tribe.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Left ${tribe.name}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave tribe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

