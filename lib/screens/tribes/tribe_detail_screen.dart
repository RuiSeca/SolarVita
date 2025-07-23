import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  
  bool _isJoining = false;
  bool _isLeaving = false;
  TribeMember? _currentUserMember;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMembershipStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMembershipStatus() async {
    final currentUserId = _tribeService.currentUserId;
    if (currentUserId == null) return;
    
    final isMember = await _tribeService.isUserTribeMember(widget.tribeId, currentUserId);
    if (isMember) {
      // Load full member details if needed
      setState(() {
        _currentUserMember = TribeMember(
          id: '',
          tribeId: widget.tribeId,
          userId: currentUserId,
          userName: '',
          role: TribeMemberRole.member,
          joinedAt: DateTime.now(),
        );
      });
    }
  }

  Future<void> _joinTribe(Tribe tribe) async {
    setState(() {
      _isJoining = true;
    });

    try {
      await _tribeService.joinTribe(
        widget.tribeId,
        inviteCode: tribe.isPrivate ? widget.inviteCode : null,
      );
      
      await _loadMembershipStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to ${tribe.name}! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining tribe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _leaveTribe(Tribe tribe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Tribe'),
        content: Text('Are you sure you want to leave "${tribe.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLeaving = true;
    });

    try {
      await _tribeService.leaveTribe(widget.tribeId);
      
      setState(() {
        _currentUserMember = null;
      });
      
      if (mounted) {
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
            content: Text('Error leaving tribe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLeaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tribe?>(
      stream: _tribeService.getTribeStream(widget.tribeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            ),
          );
        }

        final tribe = snapshot.data;
        if (tribe == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: const Center(
              child: Text('Tribe not found'),
            ),
          );
        }

        return _buildTribeDetailScreen(tribe);
      },
    );
  }

  Widget _buildTribeDetailScreen(Tribe tribe) {
    final theme = Theme.of(context);
    final isMember = _currentUserMember != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(tribe.name),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (isMember)
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: () => _leaveTribe(tribe),
                  child: const Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Leave Tribe'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Tribe Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.textFieldBackground(context),
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Category Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tribe.getCategoryIcon(),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Tribe Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tribe.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            tribe.getCategoryName(),
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 16,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${tribe.memberCount} members',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: tribe.isPublic 
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tribe.getVisibilityText(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: tribe.isPublic ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.w600,
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
                
                const SizedBox(height: 16),
                
                Text(
                  tribe.description,
                  style: theme.textTheme.bodyMedium,
                ),
                
                if (tribe.location != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tribe.location!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
                
                if (tribe.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tribe.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.primaryColor,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Join/Leave Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isJoining || _isLeaving) 
                        ? null 
                        : () => isMember ? _leaveTribe(tribe) : _joinTribe(tribe),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMember ? Colors.red : theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: (_isJoining || _isLeaving)
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isMember ? 'Leave Tribe' : 'Join Tribe',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          
          // Tabs (only show if member)
          if (isMember) ...[
            TabBar(
              controller: _tabController,
              labelColor: theme.primaryColor,
              unselectedLabelColor: theme.textTheme.bodyMedium?.color,
              indicatorColor: theme.primaryColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Posts', icon: Icon(Icons.forum)),
                Tab(text: 'Members', icon: Icon(Icons.people)),
              ],
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostsTab(tribe),
                  _buildMembersTab(tribe),
                ],
              ),
            ),
          ] else ...[
            // Non-member view
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '🏛️',
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Join to see posts and members',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connect with like-minded people and share your journey',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: isMember ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateTribePostScreen(tribe: tribe),
            ),
          );
          
          // Refresh posts if a new post was created
          if (result == true && mounted) {
            setState(() {
              // This will trigger a rebuild and refresh the posts
            });
          }
        },
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildPostsTab(Tribe tribe) {
    return StreamBuilder<List<TribePost>>(
      stream: _tribeService.getTribePosts(tribe.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final posts = snapshot.data ?? [];
        
        if (posts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('💬', style: TextStyle(fontSize: 48)),
                SizedBox(height: 16),
                Text('No posts yet'),
                Text('Be the first to share something!'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) => _buildPostCard(posts[index]),
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
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final members = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) => _buildMemberCard(members[index]),
        );
      },
    );
  }

  Widget _buildPostCard(TribePost post) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post.authorPhotoURL != null
                      ? NetworkImage(post.authorPhotoURL!)
                      : null,
                  child: post.authorPhotoURL == null
                      ? Text(post.authorName.isNotEmpty ? post.authorName[0] : 'U')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        post.getTimeAgo(),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  post.getPostTypeIcon(),
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Post Content
            if (post.title != null) ...[
              Text(
                post.title!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            Text(post.content),
            
            const SizedBox(height: 12),
            
            // Post Actions
            Row(
              children: [
                IconButton(
                  onPressed: () => _tribeService.likeTribePost(post.id),
                  icon: Icon(
                    post.isLikedBy(_tribeService.currentUserId ?? '')
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: post.isLikedBy(_tribeService.currentUserId ?? '')
                        ? Colors.red
                        : null,
                  ),
                ),
                Text('${post.likes.length}'),
                
                const SizedBox(width: 16),
                
                Icon(Icons.comment_outlined, size: 20),
                const SizedBox(width: 4),
                Text('${post.commentCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(TribeMember member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: member.userPhotoURL != null
              ? NetworkImage(member.userPhotoURL!)
              : null,
          child: member.userPhotoURL == null
              ? Text(member.userName.isNotEmpty ? member.userName[0] : 'U')
              : null,
        ),
        title: Row(
          children: [
            Text(member.userName),
            const SizedBox(width: 8),
            if (member.isCreator || member.isAdmin)
              Text(
                member.getRoleIcon(),
                style: const TextStyle(fontSize: 16),
              ),
          ],
        ),
        subtitle: Text(
          '${member.getRoleText()} • ${member.getJoinedTimeAgo()}',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}