import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:share_plus/share_plus.dart';
import '../../models/tribe.dart';
import '../../models/tribe_member.dart';
import '../../models/tribe_post.dart';
import '../../services/tribe_service.dart';
import '../../theme/app_theme.dart';
import 'create_tribe_post_screen.dart';

class TribeDetailScreen extends ConsumerStatefulWidget {
  final String tribeId;
  final String? inviteCode;

  const TribeDetailScreen({
    super.key,
    required this.tribeId,
    this.inviteCode,
  });

  @override
  ConsumerState<TribeDetailScreen> createState() => _TribeDetailScreenState();
}

class _TribeDetailScreenState extends ConsumerState<TribeDetailScreen>
    with SingleTickerProviderStateMixin {
  final TribeService _tribeService = TribeService();
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  
  bool _isJoining = false;
  bool _showFloatingButton = false;
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
    if (_scrollController.offset > 200 && !_showFloatingButton) {
      setState(() => _showFloatingButton = true);
    } else if (_scrollController.offset <= 200 && _showFloatingButton) {
      setState(() => _showFloatingButton = false);
    }
  }

  Future<void> _loadMembershipStatus() async {
    final currentUserId = _tribeService.currentUserId;
    if (currentUserId == null) return;
    
    final isMember = await _tribeService.isUserTribeMember(widget.tribeId, currentUserId);
    if (isMember && mounted) {
      final member = await _tribeService.getTribeMember(widget.tribeId, currentUserId);
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
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildTribeHeader(tribe),
              ),
              actions: [
                IconButton(
                  onPressed: () => _shareInvite(tribe),
                  icon: const Icon(Icons.share),
                ),
                IconButton(
                  onPressed: () => _showTribeOptions(tribe),
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ];
        },
        body: Column(
          children: [
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: theme.primaryColor,
                labelColor: theme.primaryColor,
                unselectedLabelColor: theme.textTheme.bodyMedium?.color,
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'Members'),
                  Tab(text: 'About'),
                ],
              ),
            ),
            
            // Tab Content
            Expanded(
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
      floatingActionButton: isMember && _showFloatingButton
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.primaryColor.withValues(alpha: 0.8),
            theme.primaryColor.withValues(alpha: 0.6),
            Colors.transparent,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Cover Image
          if (tribe.coverImage != null)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: tribe.coverImage!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: theme.primaryColor.withValues(alpha: 0.2)),
                errorWidget: (context, url, error) => Container(color: theme.primaryColor.withValues(alpha: 0.2)),
              ),
            ),
          
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tribe.getCategoryIcon(),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Tribe Name
                Text(
                  tribe.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Quick Stats
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.people,
                      text: '${tribe.memberCount} members',
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      icon: tribe.isPrivate ? Icons.lock : Icons.public,
                      text: tribe.getVisibilityText(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
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

        return CustomScrollView(
          slivers: [
            // Create Post Button (for members)
            if (isMember)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.add,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    title: const Text('Share something with the tribe...'),
                    onTap: () => _createPost(tribe),
                  ),
                ),
              ),
            
            // Posts List
            if (posts.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyPostsState(isMember),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildPostCard(posts[index]),
                  childCount: posts.length,
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
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) => _buildMemberCard(members[index]),
        );
      },
    );
  }

  Widget _buildAboutTab(Tribe tribe) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          _buildInfoCard(
            title: 'Description',
            icon: Icons.description,
            child: Text(
              tribe.description,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Category
          _buildInfoCard(
            title: 'Category',
            icon: Icons.category,
            child: Chip(
              label: Text(tribe.getCategoryName()),
              avatar: Text(tribe.getCategoryIcon()),
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
              icon: Icons.tag,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tribe.tags.map((tag) => Chip(
                  label: Text('#$tag'),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
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
      ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildPostCard(TribePost post) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          ListTile(
            leading: CircleAvatar(
              backgroundImage: post.authorPhotoURL != null
                  ? CachedNetworkImageProvider(post.authorPhotoURL!)
                  : null,
              child: post.authorPhotoURL == null
                  ? Text(post.authorName.isNotEmpty ? post.authorName[0] : 'U')
                  : null,
            ),
            title: Text(
              post.authorName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(post.getTimeAgo()),
            trailing: post.isAnnouncement
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Announcement',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  )
                : null,
          ),
          
          // Post Content
          if (post.title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                post.title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(post.content),
          ),
          
          // Post Actions
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _likePost(post),
                  icon: Icon(
                    Icons.favorite,
                    color: post.likes.contains(_tribeService.currentUserId)
                        ? Colors.red
                        : theme.iconTheme.color,
                  ),
                ),
                Text('${post.likes.length}'),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => _commentOnPost(post),
                  icon: const Icon(Icons.comment),
                ),
                Text('${post.commentCount}'),
              ],
            ),
          ),
        ],
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
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
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
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
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
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
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
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _commentOnPost(TribePost post) {
    // TODO: Navigate to comments screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comments feature coming soon!')),
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