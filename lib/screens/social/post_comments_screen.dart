// lib/screens/social/post_comments_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/social_post.dart';
import '../../models/post_comment.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../widgets/social/report_content_dialog.dart';
import '../../widgets/common/lottie_loading_widget.dart';
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
  bool _isPosting = false;
  String? _replyingToCommentId;
  String? _replyingToUserName;
  File? _selectedMedia;
  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
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
        icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.textColor(context)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'comments'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              final threadsAsync = ref.watch(commentThreadsProvider(widget.post.id));
              
              return threadsAsync.when(
                data: (threads) {
                  final totalComments = threads.fold<int>(
                    0, 
                    (currentSum, thread) => currentSum + 1 + thread.replies.length,
                  );
                  return Text(
                    totalComments == 1 ? tr(context, 'one_comment') : tr(context, 'comments_count').replaceAll('{count}', '$totalComments'),
                    style: TextStyle(
                      color: AppTheme.textColor(context).withAlpha(128),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
                loading: () => Text(
                  tr(context, 'loading'),
                  style: TextStyle(
                    color: AppTheme.textColor(context).withAlpha(128),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: AppTheme.textColor(context).withAlpha(178)),
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
          const SizedBox(height: 6),
          ...thread.replies.map((reply) => 
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: _buildCommentCard(reply, isReply: true),
            ),
          ),
        ],
        
        // Show "load more replies" if there are more
        if (thread.hasMoreReplies) _buildLoadMoreReplies(thread),
        
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCommentCard(PostComment comment, {bool isMainComment = false, bool isReply = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isReply ? 4 : 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isReply 
            ? AppTheme.messageBubbleAI(context).withValues(alpha: 0.3)
            : AppTheme.messageBubbleAI(context),
        borderRadius: BorderRadius.circular(12),
        border: isReply ? Border(
          left: BorderSide(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            width: 3,
          ),
        ) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: isReply ? 10 : 14,
            backgroundImage: comment.userAvatarUrl != null
                ? CachedNetworkImageProvider(comment.userAvatarUrl!)
                : null,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
            child: comment.userAvatarUrl == null
                ? Icon(
                    Icons.person_rounded,
                    color: AppTheme.primaryColor,
                    size: isReply ? 8 : 12,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username and content
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: comment.userName,
                        style: TextStyle(
                          fontSize: isReply ? 12 : 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      TextSpan(
                        text: ' ${comment.content}',
                        style: TextStyle(
                          fontSize: isReply ? 12 : 13,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textColor(context),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Actions row
                Row(
                  children: [
                    Text(
                      _getTimeAgo(comment.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textColor(context).withValues(alpha: 0.6),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (!isReply) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _startReply(comment),
                        child: Text(
                          tr(context, 'reply'),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryColor.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    if (comment.totalReactions > 0) ...[
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 10,
                            color: Colors.red.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${comment.totalReactions}',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textColor(context).withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (comment.isEdited) ...[
                      const SizedBox(width: 8),
                      Text(
                        tr(context, 'edited_label'),
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.textColor(context).withValues(alpha: 0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Options button
          GestureDetector(
            onTap: () => _showCommentOptions(comment),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.more_horiz,
                color: AppTheme.textColor(context).withValues(alpha: 0.4),
                size: 14,
              ),
            ),
          ),
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
              tr(context, 'view_more_replies'),
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
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 16,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        border: Border(
          top: BorderSide(color: AppTheme.textColor(context).withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply indicator
          if (_replyingToCommentId != null) _buildReplyIndicator(),
          
          // Media preview
          if (_selectedMedia != null) _buildMediaPreview(),
          
          // Input row - AI screen style
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Main input container (like AI screen)
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 50,
                    maxHeight: 100,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.textFieldBackground(context),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: AppTheme.textColor(context).withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Text input
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _commentController,
                            focusNode: _commentFocusNode,
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 15,
                            ),
                            maxLines: 3,
                            minLines: 1,
                            textInputAction: TextInputAction.send,
                            decoration: InputDecoration(
                              hintText: _replyingToCommentId != null 
                                  ? tr(context, 'reply_to_user').replaceAll('{user}', _replyingToUserName!)
                                  : tr(context, 'add_comment'),
                              hintStyle: TextStyle(
                                color: AppTheme.textColor(context).withValues(alpha: 0.5),
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _postComment(),
                          ),
                        ),
                      ),

                      // Send button (inside input like AI screen)
                      Container(
                        margin: const EdgeInsets.only(right: 8, bottom: 8),
                        child: _isPosting
                            ? SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryColor,
                                  ),
                                ),
                              )
                            : _commentController.text.trim().isNotEmpty
                                ? SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: _postComment,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primary,
                                          ),
                                          child: const Icon(
                                            Icons.send,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox(width: 32, height: 32),
                      ),
                    ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.messageBubbleAI(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.reply,
            size: 14,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            tr(context, 'replying_to_user').replaceAll('{user}', _replyingToUserName!),
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _cancelReply,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 12,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.textColor(context).withAlpha(26),
          width: 0.5,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _selectedMedia!,
              width: double.infinity,
              height: 60,
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
                  color: Colors.black.withAlpha(153),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tr(context, 'no_comments_yet'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(context, 'first_comment'),
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textColor(context).withAlpha(128),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red.withAlpha(178),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tr(context, 'something_wrong'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor(context).withAlpha(128),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.invalidate(commentThreadsProvider);
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(tr(context, 'try_again')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HELPER METHODS
  
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return tr(context, 'just_now');
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}${tr(context, 'minutes_ago')}';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}${tr(context, 'hours_ago')}';
    } else {
      return '${difference.inDays}${tr(context, 'days_ago')}';
    }
  }

  // EVENT HANDLERS

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty && _selectedMedia == null || _isPosting) return;

    setState(() => _isPosting = true);
    final currentContext = context; // Capture context before async operation

    try {
      await ref.read(commentActionsProvider.notifier).createComment(
        postId: widget.post.id,
        content: content.isNotEmpty ? content : '',
        parentCommentId: _replyingToCommentId,
        mediaFile: _selectedMedia,
        mentions: [],
      );
      
      // Clear input and reply state
      _commentController.clear();
      _cancelReply();
      setState(() => _selectedMedia = null);
      
      // Scroll to bottom to show new comment
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      HapticFeedback.lightImpact();
      if (mounted && currentContext.mounted) {
        _showSuccessSnackBar(tr(currentContext, 'comment_posted_success'));
      }
    } catch (e) {
      if (mounted && currentContext.mounted) {
        _showErrorSnackBar(tr(currentContext, 'failed_post_comment').replaceAll('{error}', '$e'));
      }
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




  void _loadMoreReplies(String commentId) async {
    final currentContext = context; // Capture context before async operation
    try {
      await ref.read(commentActionsProvider.notifier).loadMoreReplies(commentId);
    } catch (e) {
      if (mounted && currentContext.mounted) {
        _showErrorSnackBar(tr(currentContext, 'failed_load_replies').replaceAll('{error}', '$e'));
      }
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
                title: tr(context, 'edit_comment'),
                onTap: () {
                  Navigator.pop(context);
                  _editComment(comment);
                },
              ),
              _buildOptionTile(
                icon: Icons.delete,
                title: tr(context, 'delete_comment'),
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
                title: comment.isPinned ? tr(context, 'unpin_comment') : tr(context, 'pin_comment'),
                onTap: () {
                  Navigator.pop(context);
                  _togglePinComment(comment.id);
                },
              ),
            ],
            _buildOptionTile(
              icon: Icons.reply,
              title: tr(context, 'reply'),
              onTap: () {
                Navigator.pop(context);
                _startReply(comment);
              },
            ),
            _buildOptionTile(
              icon: Icons.copy,
              title: tr(context, 'copy_text'),
              onTap: () {
                Navigator.pop(context);
                _copyCommentText(comment.content);
              },
            ),
            if (!isOwnComment) ...[
              _buildOptionTile(
                icon: Icons.report,
                title: tr(context, 'report_comment'),
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
    final controller = TextEditingController(text: comment.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'edit_comment')),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: tr(context, 'edit_comment_hint'),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty && newContent != comment.content) {
                final currentContext = context; // Capture context before async operation
                try {
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.post.id)
                      .collection('comments')
                      .doc(comment.id)
                      .update({
                    'content': newContent,
                    'editedAt': FieldValue.serverTimestamp(),
                    'isEdited': true,
                  });
                  
                  if (mounted && currentContext.mounted) {
                    Navigator.pop(currentContext);
                    _showSuccessSnackBar(tr(context, 'comment_updated'));
                    ref.invalidate(postCommentsProvider(widget.post.id));
                  }
                } catch (e) {
                  if (mounted && currentContext.mounted) {
                    Navigator.pop(currentContext);
                    _showErrorSnackBar(tr(context, 'failed_update_comment').replaceAll('{error}', '$e'));
                  }
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: Text(tr(context, 'save')),
          ),
        ],
      ),
    );
  }

  void _deleteComment(String commentId) async {
    final currentContext = context; // Capture context before async operation
    try {
      await ref.read(commentActionsProvider.notifier).deleteComment(commentId);
      HapticFeedback.mediumImpact();
      if (mounted && currentContext.mounted) {
        _showSuccessSnackBar(tr(currentContext, 'comment_deleted'));
      }
    } catch (e) {
      if (mounted && currentContext.mounted) {
        _showErrorSnackBar(tr(currentContext, 'failed_delete_comment').replaceAll('{error}', '$e'));
      }
    }
  }

  void _togglePinComment(String commentId) async {
    final currentContext = context; // Capture context before async operation
    try {
      await ref.read(commentActionsProvider.notifier).togglePinComment(commentId, widget.post.id);
      HapticFeedback.lightImpact();
      if (mounted && currentContext.mounted) {
        _showSuccessSnackBar(tr(currentContext, 'comment_pin_updated'));
      }
    } catch (e) {
      if (mounted && currentContext.mounted) {
        _showErrorSnackBar(tr(currentContext, 'failed_update_pin').replaceAll('{error}', '$e'));
      }
    }
  }

  void _copyCommentText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSuccessSnackBar(tr(context, 'comment_copied'));
  }

  void _reportComment(String commentId) {
    // Find the comment to get its details
    final allComments = ref.read(postCommentsProvider(widget.post.id)).value ?? [];
    final comment = allComments.firstWhere((c) => c.id == commentId);
    
    showDialog(
      context: context,
      builder: (context) => ReportContentDialog(
        contentId: commentId,
        contentType: 'comment',
        contentOwnerId: comment.userId,
        contentOwnerName: comment.userName,
        onReportSubmitted: (report) async {
          final currentContext = context; // Capture context before async operation
          try {
            // Submit comment report to Firebase
            await FirebaseFirestore.instance
                .collection('reports')
                .add({
              'reporterId': FirebaseAuth.instance.currentUser?.uid,
              'reporterName': FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous',
              'contentId': commentId,
              'contentType': 'comment',
              'contentOwnerId': comment.userId,
              'contentOwnerName': comment.userName,
              'reason': report.reason,
              'description': report.description,
              'reportedAt': FieldValue.serverTimestamp(),
              'status': 'pending',
              'postId': widget.post.id, // Reference to parent post
              'commentContent': comment.content,
            });

            if (mounted && currentContext.mounted) {
              _showSuccessSnackBar(tr(currentContext, 'report_submitted'));
            }
          } catch (e) {
            if (mounted && currentContext.mounted) {
              _showErrorSnackBar(tr(currentContext, 'failed_submit_report').replaceAll('{error}', '$e'));
            }
          }
        },
      ),
    );
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

}

