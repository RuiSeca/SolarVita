// lib/widgets/social/social_post_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import '../../models/social/social_post.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../common/lottie_loading_widget.dart';
import '../../screens/social/post_comments_screen.dart';
import '../../screens/social/edit_post_screen.dart';
import '../../screens/social/post_revision_history_screen.dart';
import '../media/enhanced_video_player.dart';
import '../../screens/media/full_screen_video_player.dart';
import 'mention_rich_text.dart';
import 'report_content_dialog.dart';
import '../../providers/riverpod/auth_provider.dart';
import '../../providers/riverpod/firebase_social_provider.dart';
import '../../screens/profile/supporter/supporter_profile_screen.dart';
import '../../models/user/supporter.dart';

class SocialPostCard extends ConsumerStatefulWidget {
  final SocialPost post;
  final Function(String postId, ReactionType reaction)? onReaction;
  final Function(String postId)? onComment;
  final Function(String postId)? onShare;
  final Function(String postId)? onMoreOptions;
  final bool showSupporterTag;

  const SocialPostCard({
    super.key,
    required this.post,
    this.onReaction,
    this.onComment,
    this.onShare,
    this.onMoreOptions,
    this.showSupporterTag = false,
  });

  @override
  ConsumerState<SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends ConsumerState<SocialPostCard> {
  PageController? _mediaPageController;
  int _currentMediaIndex = 0;
  final Map<String, VideoPlayerController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    if (widget.post.hasMedia) {
      _mediaPageController = PageController();
      _initializeVideoControllers();
    }
  }

  void _initializeVideoControllers() {
    for (int i = 0; i < widget.post.mediaUrls.length; i++) {
      final mediaUrl = widget.post.mediaUrls[i];
      if (_isVideoUrl(mediaUrl)) {
        try {
          final controller = VideoPlayerController.networkUrl(
            Uri.parse(mediaUrl),
          );
          _videoControllers[mediaUrl] = controller;
          controller.initialize().then((_) {
            if (mounted) setState(() {});
          });
        } catch (e) {
          debugPrint('Error initializing video controller for $mediaUrl: $e');
        }
      }
    }
  }

  bool _isVideoUrl(String url) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
    return videoExtensions.any((ext) => url.toLowerCase().contains(ext));
  }

  @override
  void dispose() {
    _mediaPageController?.dispose();
    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.zero, // Edge-to-edge design
        border: Border(
          bottom: BorderSide(
            color: AppTheme.textColor(context).withAlpha(26),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostHeader(),
          if (widget.post.content.isNotEmpty) _buildPostContent(),
          if (widget.post.hasMedia) _buildMediaSection(),
          _buildPostActions(),
          _buildPostStats(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // User Avatar - Tappable
          GestureDetector(
            onTap: () => _navigateToUserProfile(),
            child: CircleAvatar(
              radius: 22,
              backgroundImage: widget.post.userAvatarUrl != null
                  ? CachedNetworkImageProvider(widget.post.userAvatarUrl!)
                  : null,
              backgroundColor: AppTheme.textFieldBackground(context),
              child: widget.post.userAvatarUrl == null
                  ? Icon(
                      Icons.person,
                      color: AppTheme.textColor(context).withAlpha(128),
                      size: 24,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // User Info and Post Meta - Tappable
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToUserProfile(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.post.userName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                      if (widget.post.autoGenerated) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withAlpha(51),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tr(context, 'auto'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                      if (widget.showSupporterTag) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(51),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tr(context, 'supporter'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _formatTimestamp(widget.post.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textColor(context).withAlpha(153),
                        ),
                      ),
                      if (widget.post.pillars.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            color: AppTheme.textColor(context).withAlpha(153),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildPillarTags(),
                      ],
                      // Privacy indicator
                      const SizedBox(width: 8),
                      Icon(
                        _getVisibilityIcon(widget.post.visibility),
                        size: 14,
                        color: AppTheme.textColor(context).withAlpha(128),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // More options button
          IconButton(
            onPressed: () => _showMoreOptions(),
            icon: Icon(
              Icons.more_horiz,
              color: AppTheme.textColor(context).withAlpha(153),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarTags() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: widget.post.pillars.take(2).map((pillar) {
        return Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getPillarColor(pillar).withAlpha(51),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _getPillarDisplayName(pillar),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _getPillarColor(pillar),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPostContent() {
    // Parse mentions from the post content
    final mentions = MentionUtils.parseMentions(widget.post.content);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MentionRichText(
        text: widget.post.content,
        mentions: mentions,
        baseStyle: TextStyle(
          fontSize: 16,
          height: 1.4,
          color: AppTheme.textColor(context),
        ),
        mentionStyle: TextStyle(
          fontSize: 16,
          height: 1.4,
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w600,
        ),
        onMentionTap: (mention) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr(
                  context,
                  'tapped_mention',
                ).replaceAll('{name}', mention.displayName),
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMediaSection() {
    final allMedia = [
      ...widget.post.mediaUrls.map(
        (url) => MediaItem(url: url, isVideo: false),
      ),
      ...widget.post.videoUrls.map((url) => MediaItem(url: url, isVideo: true)),
    ];

    if (allMedia.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.zero,
      width: double.infinity,
      height: 400, // Instagram-style fixed height
      child: Stack(
        children: [
          PageView.builder(
            controller: _mediaPageController,
            onPageChanged: (index) {
              setState(() {
                _currentMediaIndex = index;
              });
            },
            itemCount: allMedia.length,
            itemBuilder: (context, index) {
              final media = allMedia[index];
              return _buildMediaItem(media, index);
            },
          ),
          // Media indicators
          if (allMedia.length > 1) _buildMediaIndicators(allMedia.length),
          // Media counter
          if (allMedia.length > 1) _buildMediaCounter(allMedia.length),
        ],
      ),
    );
  }

  Widget _buildMediaItem(MediaItem media, int index) {
    if (media.isVideo) {
      // Use enhanced video player for videos
      return EnhancedVideoPlayer(
        videoUrl: media.url,
        width: double.infinity,
        height: 400,
        autoPlay: false,
        showControls: true,
        showDuration: true,
        onVideoTap: () {
          // Handle video tap - could open full screen player
          _showFullScreenVideo(media.url);
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: media.url,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (context, url) => Container(
        color: AppTheme.cardColor(context),
        child: const Center(child: LottieLoadingWidget(width: 60, height: 60)),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.error, size: 48, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildMediaIndicators(int mediaCount) {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(mediaCount, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentMediaIndex == index
                  ? Colors.white
                  : Colors.white.withAlpha(128),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMediaCounter(int mediaCount) {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(153),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${_currentMediaIndex + 1}/$mediaCount',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPostActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Consumer(
        builder: (context, ref, child) {
          final currentUser = ref.watch(currentUserProvider);

          // Get user's reaction on this post
          final userReaction = currentUser != null
              ? widget.post.getUserReaction(currentUser.uid)
              : null;

          return Row(
            children: [
              // Like button
              _buildActionButton(
                icon: Icons.favorite_border,
                activeIcon: Icons.favorite,
                isActive: userReaction == ReactionType.like,
                onTap: () =>
                    widget.onReaction?.call(widget.post.id, ReactionType.like),
              ),
              const SizedBox(width: 16),
              // Celebrate button
              _buildActionButton(
                icon: Icons.celebration_outlined,
                activeIcon: Icons.celebration,
                isActive: userReaction == ReactionType.celebrate,
                onTap: () => widget.onReaction?.call(
                  widget.post.id,
                  ReactionType.celebrate,
                ),
              ),
              const SizedBox(width: 16),
              // Boost button (SolarVita unique)
              _buildActionButton(
                icon: Icons.eco_outlined,
                activeIcon: Icons.eco,
                isActive: userReaction == ReactionType.boost,
                onTap: () =>
                    widget.onReaction?.call(widget.post.id, ReactionType.boost),
              ),
              const SizedBox(width: 16),
              // Motivate button
              _buildActionButton(
                icon: Icons.fitness_center_outlined,
                activeIcon: Icons.fitness_center,
                isActive: userReaction == ReactionType.motivate,
                onTap: () => widget.onReaction?.call(
                  widget.post.id,
                  ReactionType.motivate,
                ),
              ),
              const SizedBox(width: 16),
              // Comment button
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble_outline,
                isActive: false,
                onTap: () {
                  if (widget.onComment != null) {
                    widget.onComment!(widget.post.id);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PostCommentsScreen(post: widget.post),
                      ),
                    );
                  }
                },
              ),
              const Spacer(),
              // Share button
              _buildActionButton(
                icon: Icons.share_outlined,
                activeIcon: Icons.share_outlined,
                isActive: false,
                onTap: () => widget.onShare?.call(widget.post.id),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required IconData activeIcon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          isActive ? activeIcon : icon,
          size: 24,
          color: isActive
              ? Theme.of(context).primaryColor
              : AppTheme.textColor(context).withAlpha(153),
        ),
      ),
    );
  }

  Widget _buildPostStats() {
    if (widget.post.totalReactions == 0 && widget.post.commentCount == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.post.totalReactions > 0) _buildReactionStats(),
          if (widget.post.commentCount > 0) ...[
            const SizedBox(height: 4),
            _buildCommentStats(),
          ],
        ],
      ),
    );
  }

  Widget _buildReactionStats() {
    return Text(
      widget.post.totalReactions == 1
          ? tr(context, 'one_reaction')
          : tr(
              context,
              'reactions_count',
            ).replaceAll('{count}', '${widget.post.totalReactions}'),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textColor(context),
      ),
    );
  }

  Widget _buildCommentStats() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostCommentsScreen(post: widget.post),
          ),
        );
      },
      child: Text(
        widget.post.commentCount == 1
            ? tr(context, 'view_one_comment')
            : tr(
                context,
                'view_all_comments',
              ).replaceAll('{count}', '${widget.post.commentCount}'),
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textColor(context).withAlpha(153),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return tr(context, 'just_now');
    }
  }

  IconData _getVisibilityIcon(PostVisibility visibility) {
    switch (visibility) {
      case PostVisibility.public:
        return Icons.public;
      case PostVisibility.supporters:
        return Icons.people;
      case PostVisibility.private:
        return Icons.lock;
    }
  }

  void _showMoreOptions() {
    final currentUser = ref.read(currentUserProvider);
    final isOwner = currentUser?.uid == widget.post.userId;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.textColor(context).withAlpha(102),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Owner-only options
                    if (isOwner) ...[
                      _buildOptionTile(
                        icon: Icons.edit,
                        title: tr(context, 'edit_post'),
                        subtitle: tr(context, 'make_changes_post'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditPostScreen(post: widget.post),
                            ),
                          );
                        },
                      ),
                      _buildOptionTile(
                        icon: Icons.delete_outline,
                        title: tr(context, 'delete_post'),
                        subtitle: tr(context, 'permanently_delete'),
                        onTap: () {
                          Navigator.pop(context);
                          _showDeleteConfirmation();
                        },
                      ),
                      _buildOptionTile(
                        icon: Icons.history,
                        title: tr(context, 'view_history'),
                        subtitle: tr(context, 'see_changes'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostRevisionHistoryScreen(
                                postId: widget.post.id,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    // Common options for all users
                    _buildOptionTile(
                      icon: Icons.bookmark_border,
                      title: tr(context, 'save_post'),
                      subtitle: tr(context, 'save_post_description'),
                      onTap: () {
                        Navigator.pop(context);
                        _handleSavePost();
                      },
                    ),
                    _buildOptionTile(
                      icon: Icons.share,
                      title: tr(context, 'share'),
                      subtitle: tr(context, 'share_post_description'),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onShare?.call(widget.post.id);
                      },
                    ),
                    _buildOptionTile(
                      icon: Icons.copy,
                      title: tr(context, 'copy_link'),
                      subtitle: tr(context, 'copy_link_description'),
                      onTap: () {
                        Navigator.pop(context);
                        // Copy link functionality to be implemented
                      },
                    ),
                    if (!isOwner)
                      _buildOptionTile(
                        icon: Icons.report,
                        title: tr(context, 'report'),
                        subtitle: tr(context, 'report_post_description'),
                        onTap: () {
                          Navigator.pop(context);
                          _showReportDialog();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSavePost() async {
    final currentContext = context; // Capture context before async operation
    try {
      // Save post to Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('saved_posts')
          .doc(widget.post.id)
          .set({
            'postId': widget.post.id,
            'savedAt': FieldValue.serverTimestamp(),
            'postAuthor': widget.post.userName,
            'postContent': widget.post.content,
            'postImageUrl': widget.post.mediaUrls.isNotEmpty
                ? widget.post.mediaUrls.first
                : null,
          });

      if (mounted && currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.bookmark, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(tr(context, 'post_saved_success')),
              ],
            ),
            backgroundColor: Theme.of(currentContext).primaryColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted && currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(
              tr(context, 'failed_save_post').replaceAll('{error}', '$e'),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.textColor(context).withAlpha(26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.textColor(context), size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.textColor(context),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.textColor(context).withAlpha(153),
          fontSize: 12,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showFullScreenVideo(String videoUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenVideoPlayer(videoUrl: videoUrl),
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => ReportContentDialog(
        contentId: widget.post.id,
        contentType: 'post',
        contentOwnerId: widget.post.userId,
        contentOwnerName: widget.post.userName,
        onReportSubmitted: (report) async {
          final currentContext =
              context; // Capture context before async operation
          try {
            // Submit report to Firebase
            await FirebaseFirestore.instance.collection('reports').add({
              'reporterId': FirebaseAuth.instance.currentUser?.uid,
              'reporterName':
                  FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous',
              'contentId': widget.post.id,
              'contentType': 'post',
              'contentOwnerId': widget.post.userId,
              'contentOwnerName': widget.post.userName,
              'reason': report.reason,
              'description': report.description,
              'reportedAt': FieldValue.serverTimestamp(),
              'status': 'pending', // pending, reviewed, resolved
              'postContent': widget.post.content,
              'postImageUrl': widget.post.mediaUrls.isNotEmpty
                  ? widget.post.mediaUrls.first
                  : null,
            });

            if (mounted && currentContext.mounted) {
              ScaffoldMessenger.of(currentContext).showSnackBar(
                SnackBar(
                  content: Text(tr(currentContext, 'report_submitted')),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (mounted && currentContext.mounted) {
              ScaffoldMessenger.of(currentContext).showSnackBar(
                SnackBar(
                  content: Text(
                    tr(
                      context,
                      'failed_submit_report',
                    ).replaceAll('{error}', '$e'),
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          tr(context, 'delete_post'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          tr(context, 'delete_post_confirmation'),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              tr(context, 'cancel'),
              style: TextStyle(
                color: AppTheme.textColor(context).withAlpha(153),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost();
            },
            child: Text(
              tr(context, 'delete'),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(tr(context, 'deleting_post')),
            ],
          ),
          backgroundColor: AppTheme.textColor(context),
          duration: const Duration(seconds: 2),
        ),
      );

      // Delete the post using the social posts provider
      await ref
          .read(firebaseSocialPostsServiceProvider)
          .deletePost(widget.post.id);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(tr(context, 'post_deleted_success')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  tr(
                    context,
                    'failed_delete_post',
                  ).replaceAll('{error}', e.toString()),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getPillarDisplayName(PostPillar pillar) {
    switch (pillar) {
      case PostPillar.fitness:
        return tr(context, 'fitness');
      case PostPillar.nutrition:
        return tr(context, 'nutrition');
      case PostPillar.eco:
        return tr(context, 'eco');
    }
  }

  Color _getPillarColor(PostPillar pillar) {
    switch (pillar) {
      case PostPillar.fitness:
        return const Color(0xFF2196F3); // Blue
      case PostPillar.nutrition:
        return const Color(0xFF4CAF50); // Green
      case PostPillar.eco:
        return const Color(0xFF8BC34A); // Light Green
    }
  }

  void _navigateToUserProfile() {
    final currentUser = ref.read(currentUserProvider);

    // Don't navigate to own profile
    if (currentUser?.uid == widget.post.userId) {
      return;
    }

    // Create a Supporter object from the post data
    final supporter = Supporter(
      userId: widget.post.userId,
      displayName: widget.post.userName,
      photoURL: widget.post.userAvatarUrl,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupporterProfileScreen(supporter: supporter),
      ),
    );
  }
}

// Helper class for media handling
class MediaItem {
  final String url;
  final bool isVideo;

  MediaItem({required this.url, required this.isVideo});
}
