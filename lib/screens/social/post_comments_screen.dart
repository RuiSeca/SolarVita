// lib/screens/social/post_comments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/social_post.dart';
import '../../models/post_comment.dart' as pc;
import '../../models/user_mention.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/lottie_loading_widget.dart';
import '../../widgets/social/comment_reaction_widget.dart';
import '../../widgets/social/mention_text_field.dart';
import '../../widgets/social/mention_rich_text.dart';

// Helper class for organizing comments with their replies
class CommentThread {
  final pc.PostComment comment;
  final List<pc.PostComment> replies;
  final bool hasMoreReplies;
  final int totalReplies;

  CommentThread({
    required this.comment,
    required this.replies,
    required this.hasMoreReplies,
    required this.totalReplies,
  });
}

class PostCommentsScreen extends ConsumerStatefulWidget {
  final SocialPost post;

  const PostCommentsScreen({
    super.key,
    required this.post,
  });

  @override
  ConsumerState<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends ConsumerState<PostCommentsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  
  List<CommentThread> _commentThreads = [];
  List<MentionInfo> _commentMentions = []; // TODO: Use when implementing Firebase integration
  bool _isLoading = false;
  bool _isPosting = false;
  String? _replyingToCommentId;
  String? _replyingToUserName;
  OverlayEntry? _reactionPickerOverlay;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    _removeReactionPicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: LottieLoadingWidget())
                : RefreshIndicator(
                    onRefresh: _loadComments,
                    child: _buildCommentsList(),
                  ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surfaceColor(context),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            '${widget.post.commentCount} comments',
            style: TextStyle(
              color: AppTheme.textColor(context).withAlpha(153),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    if (_commentThreads.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _commentThreads.length,
      itemBuilder: (context, index) {
        final thread = _commentThreads[index];
        return _buildCommentThread(thread);
      },
    );
  }

  Widget _buildCommentThread(CommentThread thread) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentCard(thread.comment, isMainComment: true),
        
        // Show replies
        if (thread.replies.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...thread.replies.map((reply) => 
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: _buildCommentCard(reply, isReply: true),
            ),
          ),
        ],
        
        // Show "load more replies" if there are more
        if (thread.hasMoreReplies) _buildLoadMoreReplies(thread),
        
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCommentCard(pc.PostComment comment, {bool isMainComment = false, bool isReply = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isReply 
            ? AppTheme.cardColor(context).withAlpha(128)
            : AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: isReply ? Border.all(
          color: AppTheme.textColor(context).withAlpha(26),
        ) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment header
          Row(
            children: [
              CircleAvatar(
                radius: isReply ? 14 : 16,
                backgroundImage: comment.userAvatarUrl != null
                    ? CachedNetworkImageProvider(comment.userAvatarUrl!)
                    : null,
                backgroundColor: AppTheme.textFieldBackground(context),
                child: comment.userAvatarUrl == null
                    ? Icon(
                        Icons.person,
                        color: AppTheme.textColor(context).withAlpha(128),
                        size: isReply ? 16 : 20,
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
                          comment.userName,
                          style: TextStyle(
                            fontSize: isReply ? 13 : 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                        if (comment.isEdited) ...[
                          const SizedBox(width: 6),
                          Text(
                            '(edited)',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textColor(context).withAlpha(128),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      comment.getTimeAgo(),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textColor(context).withAlpha(153),
                      ),
                    ),
                  ],
                ),
              ),
              // More options button
              IconButton(
                onPressed: () => _showCommentOptions(comment),
                icon: Icon(
                  Icons.more_horiz,
                  color: AppTheme.textColor(context).withAlpha(153),
                  size: 16,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Comment content with mention support
          MentionRichText(
            text: comment.content,
            mentions: MentionUtils.parseMentions(comment.content),
            baseStyle: TextStyle(
              fontSize: isReply ? 13 : 14,
              height: 1.4,
              color: AppTheme.textColor(context),
            ),
            mentionStyle: TextStyle(
              fontSize: isReply ? 13 : 14,
              height: 1.4,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
            onMentionTap: (mention) {
              // TODO: Navigate to user profile
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tapped on ${mention.displayName}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          
          // Comment media if any
          if (comment.mediaUrl != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: comment.mediaUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          
          // Comment actions
          Row(
            children: [
              // Enhanced reaction widget
              CommentReactionWidget(
                comment: comment,
                currentUserId: 'current_user_id', // TODO: Get from auth provider
                onReactionTap: _reactToComment,
                onReactionLongPress: (commentId) => _showReactionPicker(commentId, comment),
              ),
              const SizedBox(width: 16),
              // Reply button (only for main comments)
              if (isMainComment)
                _buildCommentAction(
                  icon: Icons.reply,
                  activeIcon: Icons.reply,
                  label: comment.hasReplies ? '${comment.replyCount}' : 'Reply',
                  isActive: false,
                  onTap: () => _startReply(comment),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentAction({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            size: 16,
            color: isActive
                ? Theme.of(context).primaryColor
                : AppTheme.textColor(context).withAlpha(153),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive
                    ? Theme.of(context).primaryColor
                    : AppTheme.textColor(context).withAlpha(153),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadMoreReplies(CommentThread thread) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 4),
      child: GestureDetector(
        onTap: () => _loadMoreReplies(thread.comment.id),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 1,
              color: AppTheme.textColor(context).withAlpha(77),
            ),
            const SizedBox(width: 8),
            Text(
              'View more replies',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        border: Border(
          top: BorderSide(
            color: AppTheme.textColor(context).withAlpha(51),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply indicator
          if (_replyingToCommentId != null) _buildReplyIndicator(),
          
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.person, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MentionTextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  hintText: _replyingToCommentId != null 
                      ? 'Reply to $_replyingToUserName...'
                      : 'Add a comment...',
                  maxLines: 4,
                  onMentionsChanged: (mentions) {
                    setState(() {
                      _commentMentions = mentions;
                    });
                  },
                  textStyle: TextStyle(
                    color: AppTheme.textColor(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isPosting ? null : _postComment,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _commentController.text.trim().isNotEmpty
                        ? Theme.of(context).primaryColor
                        : AppTheme.textColor(context).withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: _isPosting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.send,
                          color: _commentController.text.trim().isNotEmpty
                              ? Colors.white
                              : AppTheme.textColor(context).withAlpha(128),
                          size: 16,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Replying to $_replyingToUserName',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: _cancelReply,
            child: Icon(
              Icons.close,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppTheme.textColor(context).withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            'No comments yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to comment on this post',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textColor(context).withAlpha(153),
            ),
          ),
        ],
      ),
    );
  }

  // Event handlers
  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual Firebase fetching
      // For now, generate mock data
      await Future.delayed(const Duration(milliseconds: 800));
      _commentThreads = _generateMockComments();
    } catch (e) {
      _showErrorSnackBar('Failed to load comments: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isPosting) return;

    setState(() {
      _isPosting = true;
    });

    try {
      // TODO: Implement actual comment posting to Firebase
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Clear input and reply state
      _commentController.clear();
      _cancelReply();
      
      // Reload comments
      await _loadComments();
      
      // Scroll to bottom to show new comment
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to post comment: $e');
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  void _startReply(pc.PostComment comment) {
    setState(() {
      _replyingToCommentId = comment.id;
      _replyingToUserName = comment.userName;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
  }

  void _reactToComment(String commentId, ReactionType reaction) {
    // TODO: Implement actual comment reactions with Firebase
    // For now, show feedback
    final reactionName = _getReactionDisplayName(reaction);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$reactionName reaction ${reaction == ReactionType.like ? 'added' : 'toggled'}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Remove reaction picker if visible
    _removeReactionPicker();
  }

  void _showReactionPicker(String commentId, pc.PostComment comment) {
    _removeReactionPicker();
    
    // Find the comment widget position for proper overlay positioning
    final overlay = Overlay.of(context);
    
    _reactionPickerOverlay = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100, // Adjust based on comment position
        left: 20,
        child: ReactionPickerWidget(
          onReactionSelected: (reaction) {
            _reactToComment(commentId, reaction);
          },
          onDismiss: _removeReactionPicker,
        ),
      ),
    );
    
    overlay.insert(_reactionPickerOverlay!);
    
    // Auto-remove after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _removeReactionPicker();
    });
  }

  void _removeReactionPicker() {
    _reactionPickerOverlay?.remove();
    _reactionPickerOverlay = null;
  }

  String _getReactionDisplayName(ReactionType reaction) {
    switch (reaction) {
      case ReactionType.like:
        return 'Like';
      case ReactionType.celebrate:
        return 'Celebrate';
      case ReactionType.boost:
        return 'Boost';
      case ReactionType.motivate:
        return 'Motivate';
    }
  }

  void _loadMoreReplies(String commentId) {
    // TODO: Implement loading more replies
    print('Load more replies for comment $commentId');
  }

  void _showCommentOptions(pc.PostComment comment) {
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
          children: [
            _buildOptionTile(
              icon: Icons.reply,
              title: 'Reply',
              onTap: () {
                Navigator.pop(context);
                _startReply(comment);
              },
            ),
            _buildOptionTile(
              icon: Icons.copy,
              title: 'Copy text',
              onTap: () {
                Navigator.pop(context);
                // TODO: Copy to clipboard
              },
            ),
            _buildOptionTile(
              icon: Icons.report,
              title: 'Report',
              onTap: () {
                Navigator.pop(context);
                // TODO: Report comment
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textColor(context)),
      title: Text(
        title,
        style: TextStyle(color: AppTheme.textColor(context)),
      ),
      onTap: onTap,
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Mock data for testing
  List<CommentThread> _generateMockComments() {
    final comments = [
      pc.PostComment(
        id: 'comment_1',
        postId: widget.post.id,
        userId: 'user_1',
        userName: 'Sarah Johnson',
        content: 'This is so inspiring! I love seeing your progress. Keep up the amazing work! 💪',
        reactions: {'user_2': ReactionType.like, 'user_3': ReactionType.celebrate},
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isEdited: false,
        replyCount: 2,
        childCommentIds: ['reply_1', 'reply_2'],
      ),
      pc.PostComment(
        id: 'comment_2',
        postId: widget.post.id,
        userId: 'user_4',
        userName: 'Mike Wilson',
        content: 'Great job! What workout routine are you following?',
        reactions: {'user_1': ReactionType.like},
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isEdited: false,
        replyCount: 0,
        childCommentIds: [],
      ),
    ];

    final replies = [
      pc.PostComment(
        id: 'reply_1',
        postId: widget.post.id,
        userId: 'user_current',
        userName: 'You',
        parentCommentId: 'comment_1',
        content: 'Thank you so much! Your support means everything to me ❤️',
        reactions: {},
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        isEdited: false,
        replyCount: 0,
        childCommentIds: [],
      ),
      pc.PostComment(
        id: 'reply_2',
        postId: widget.post.id,
        userId: 'user_2',
        userName: 'Alex Chen',
        parentCommentId: 'comment_1',
        content: 'Absolutely! We\'re all cheering you on! 🎉',
        reactions: {'user_1': ReactionType.like},
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        isEdited: false,
        replyCount: 0,
        childCommentIds: [],
      ),
    ];

    return [
      CommentThread(
        comment: comments[0],
        replies: replies.where((r) => r.parentCommentId == comments[0].id).toList(),
        hasMoreReplies: false,
        totalReplies: 2,
      ),
      CommentThread(
        comment: comments[1],
        replies: [],
        hasMoreReplies: false,
        totalReplies: 0,
      ),
    ];
  }
}