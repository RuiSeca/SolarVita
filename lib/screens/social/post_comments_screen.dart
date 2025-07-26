// lib/screens/social/post_comments_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/social_post.dart';
import '../../models/post_comment.dart';
import '../../models/user_mention.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/lottie_loading_widget.dart';
import '../../widgets/social/comment_reaction_widget.dart';
import '../../widgets/social/mention_text_field.dart';
import '../../widgets/social/mention_rich_text.dart';
import '../../providers/riverpod/firebase_social_provider.dart';
import '../../providers/riverpod/auth_provider.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isPosting = false;
  String? _replyingToCommentId;
  String? _replyingToUserName;
  File? _selectedMedia;
  List<MentionInfo> _commentMentions = [];
  OverlayEntry? _reactionPickerOverlay;

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
            child: _buildCommentsContent(),
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
          Consumer(
            builder: (context, ref, child) {
              final threadsAsync = ref.watch(commentThreadsProvider(widget.post.id));
              
              return threadsAsync.when(
                data: (threads) {
                  final totalComments = threads.fold<int>(
                    0, 
                    (sum, thread) => sum + 1 + thread.replies.length,
                  );
                  return Text(
                    '$totalComments comments',
                    style: TextStyle(
                      color: AppTheme.textColor(context).withAlpha(153),
                      fontSize: 12,
                    ),
                  );
                },
                loading: () => Text(
                  'Loading...',
                  style: TextStyle(
                    color: AppTheme.textColor(context).withAlpha(153),
                    fontSize: 12,
                  ),
                ),
                error: (_, __) => Text(
                  'Error loading',
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
        IconButton(
          icon: Icon(Icons.refresh, color: AppTheme.textColor(context)),
          onPressed: () {
            HapticFeedback.lightImpact();
            ref.invalidate(commentThreadsProvider);
          },
        ),
      ],
    );
  }

  Widget _buildCommentsContent() {
    return Consumer(
      builder: (context, ref, child) {
        final threadsAsync = ref.watch(commentThreadsProvider(widget.post.id));

        return threadsAsync.when(
          data: (threads) => _buildCommentsList(threads),
          loading: () => const Center(child: LottieLoadingWidget()),
          error: (error, stackTrace) => _buildErrorState(error.toString()),
        );
      },
    );
  }

  Widget _buildCommentsList(List<CommentThread> threads) {
    if (threads.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        ref.invalidate(commentThreadsProvider);
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: threads.length,
        itemBuilder: (context, index) {
          final thread = threads[index];
          return _buildCommentThread(thread);
        },
      ),
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

  Widget _buildCommentCard(PostComment comment, {bool isMainComment = false, bool isReply = false}) {
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
                        if (comment.isPinned) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.push_pin,
                            size: 12,
                            color: Theme.of(context).primaryColor,
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
            mentions: comment.mentions,
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
              _navigateToUserProfile(mention.userId);
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
                placeholder: (context, url) => Container(
                  height: 120,
                  color: AppTheme.textFieldBackground(context),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 120,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
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
                currentUserId: ref.watch(userUidProvider) ?? '',
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
          
          // Media preview
          if (_selectedMedia != null) _buildMediaPreview(),
          
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: ref.watch(userPhotoURLProvider) != null
                    ? CachedNetworkImageProvider(ref.watch(userPhotoURLProvider)!)
                    : null,
                backgroundColor: Theme.of(context).primaryColor,
                child: ref.watch(userPhotoURLProvider) == null
                    ? const Icon(Icons.person, color: Colors.white, size: 16)
                    : null,
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
              // Media button
              IconButton(
                onPressed: _selectMedia,
                icon: Icon(
                  Icons.camera_alt,
                  color: AppTheme.textColor(context).withAlpha(153),
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              // Send button
              GestureDetector(
                onTap: _isPosting ? null : _postComment,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _commentController.text.trim().isNotEmpty || _selectedMedia != null
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
                          color: _commentController.text.trim().isNotEmpty || _selectedMedia != null
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

  Widget _buildMediaPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.textColor(context).withAlpha(51),
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _selectedMedia!,
              width: double.infinity,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _selectedMedia = null),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(128),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 12,
                ),
              ),
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

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withAlpha(128),
          ),
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
              ref.invalidate(commentThreadsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // EVENT HANDLERS

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty && _selectedMedia == null || _isPosting) return;

    setState(() => _isPosting = true);

    try {
      await ref.read(commentActionsProvider.notifier).createComment(
        postId: widget.post.id,
        content: content.isNotEmpty ? content : '',
        parentCommentId: _replyingToCommentId,
        mediaFile: _selectedMedia,
        mentions: _commentMentions,
      );
      
      // Clear input and reply state
      _commentController.clear();
      _cancelReply();
      setState(() => _selectedMedia = null);
      _commentMentions.clear();
      
      // Scroll to bottom to show new comment
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      HapticFeedback.lightImpact();
      _showSuccessSnackBar('Comment posted successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to post comment: $e');
    } finally {
      setState(() => _isPosting = false);
    }
  }

  void _startReply(PostComment comment) {
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

  void _reactToComment(String commentId, ReactionType reaction) async {
    try {
      await ref.read(commentActionsProvider.notifier).reactToComment(commentId, reaction);
      HapticFeedback.lightImpact();
      _removeReactionPicker();
    } catch (e) {
      _showErrorSnackBar('Failed to add reaction: $e');
    }
  }

  void _showReactionPicker(String commentId, PostComment comment) {
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

  void _loadMoreReplies(String commentId) async {
    try {
      await ref.read(commentActionsProvider.notifier).loadMoreReplies(commentId);
    } catch (e) {
      _showErrorSnackBar('Failed to load more replies: $e');
    }
  }

  void _selectMedia() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedMedia = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select image: $e');
    }
  }

  void _showCommentOptions(PostComment comment) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final bool isOwnComment = comment.userId == currentUser.uid;
    final bool isPostAuthor = widget.post.userId == currentUser.uid;

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
            if (isOwnComment) ...[
              _buildOptionTile(
                icon: Icons.edit,
                title: 'Edit Comment',
                onTap: () {
                  Navigator.pop(context);
                  _editComment(comment);
                },
              ),
              _buildOptionTile(
                icon: Icons.delete,
                title: 'Delete Comment',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _deleteComment(comment.id);
                },
              ),
            ],
            if (isPostAuthor && !isOwnComment) ...[
              _buildOptionTile(
                icon: comment.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                title: comment.isPinned ? 'Unpin Comment' : 'Pin Comment',
                onTap: () {
                  Navigator.pop(context);
                  _togglePinComment(comment.id);
                },
              ),
            ],
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
              title: 'Copy Text',
              onTap: () {
                Navigator.pop(context);
                _copyCommentText(comment.content);
              },
            ),
            if (!isOwnComment) ...[
              _buildOptionTile(
                icon: Icons.report,
                title: 'Report Comment',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _reportComment(comment.id);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon, 
        color: isDestructive ? Colors.red : AppTheme.textColor(context),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : AppTheme.textColor(context),
        ),
      ),
      onTap: onTap,
    );
  }

  void _editComment(PostComment comment) {
    // TODO: Implement edit comment functionality
    _showInfoSnackBar('Edit comment functionality coming soon!');
  }

  void _deleteComment(String commentId) async {
    try {
      await ref.read(commentActionsProvider.notifier).deleteComment(commentId);
      HapticFeedback.mediumImpact();
      _showSuccessSnackBar('Comment deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete comment: $e');
    }
  }

  void _togglePinComment(String commentId) async {
    try {
      await ref.read(commentActionsProvider.notifier).togglePinComment(commentId, widget.post.id);
      HapticFeedback.lightImpact();
      _showSuccessSnackBar('Comment pin status updated');
    } catch (e) {
      _showErrorSnackBar('Failed to update pin status: $e');
    }
  }

  void _copyCommentText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSuccessSnackBar('Comment copied to clipboard');
  }

  void _reportComment(String commentId) {
    // TODO: Implement report comment functionality
    _showInfoSnackBar('Report functionality coming soon!');
  }

  void _navigateToUserProfile(String userId) {
    _showInfoSnackBar('User profile functionality coming soon!');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Reaction Picker Widget (placeholder - implement based on your design)
class ReactionPickerWidget extends StatelessWidget {
  final Function(ReactionType) onReactionSelected;
  final VoidCallback onDismiss;

  const ReactionPickerWidget({
    super.key,
    required this.onReactionSelected,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: ReactionType.values.map((reaction) {
            return GestureDetector(
              onTap: () => onReactionSelected(reaction),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(8),
                child: Text(
                  _getReactionEmoji(reaction),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getReactionEmoji(ReactionType reaction) {
    switch (reaction) {
      case ReactionType.like:
        return '👍';
      case ReactionType.celebrate:
        return '🎉';
      case ReactionType.boost:
        return '🚀';
      case ReactionType.motivate:
        return '💪';
    }
  }
}