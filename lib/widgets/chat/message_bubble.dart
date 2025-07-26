import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/chat_message.dart';
import '../../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final bool showAvatar;
  final String? otherUserPhotoURL;
  final String? otherUserName;
  final String? currentUserPhotoURL;
  final String? currentUserName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.showAvatar = true,
    this.otherUserPhotoURL,
    this.otherUserName,
    this.currentUserPhotoURL,
    this.currentUserName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser && showAvatar) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: isCurrentUser 
                    ? CrossAxisAlignment.end 
                    : CrossAxisAlignment.start,
                children: [
                  _buildMessageBubble(context, theme),
                  const SizedBox(height: 2),
                  _buildMessageInfo(theme),
                ],
              ),
            ),
          ),
          
          if (isCurrentUser && showAvatar) ...[
            const SizedBox(width: 8),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    // Use the actual sender avatar from the message data, fallback to passed values for legacy messages
    String? photoURL = message.senderAvatarUrl;
    
    // Fallback to static values if message doesn't have avatar data
    if (photoURL == null || photoURL.isEmpty) {
      photoURL = isCurrentUser ? currentUserPhotoURL : otherUserPhotoURL;
    }
    
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      backgroundImage: photoURL != null && photoURL.isNotEmpty
          ? CachedNetworkImageProvider(photoURL)
          : null,
      child: photoURL == null || photoURL.isEmpty
          ? Icon(
              Icons.person,
              size: 16,
              color: AppTheme.primaryColor,
            )
          : null,
    );
  }

  Widget _buildMessageBubble(BuildContext context, ThemeData theme) {
    switch (message.messageType) {
      case MessageType.activityShare:
        return _buildActivityShareBubble(context, theme);
      case MessageType.image:
        return _buildImageBubble(context, theme);
      default:
        return _buildTextBubble(context, theme);
    }
  }

  Widget _buildTextBubble(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? theme.primaryColor 
            : AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomLeft: isCurrentUser ? const Radius.circular(20) : const Radius.circular(4),
          bottomRight: isCurrentUser ? const Radius.circular(4) : const Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isCurrentUser 
              ? Colors.white 
              : AppTheme.textColor(context),
        ),
      ),
    );
  }

  Widget _buildActivityShareBubble(BuildContext context, ThemeData theme) {
    final metadata = message.metadata;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? theme.primaryColor.withValues(alpha: 0.9)
            : AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomLeft: isCurrentUser ? const Radius.circular(20) : const Radius.circular(4),
          bottomRight: isCurrentUser ? const Radius.circular(4) : const Radius.circular(20),
        ),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.share,
                size: 16,
                color: isCurrentUser 
                    ? Colors.white 
                    : theme.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Shared Activity',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isCurrentUser 
                      ? Colors.white.withValues(alpha: 0.8)
                      : theme.textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentUser 
                  ? Colors.white.withValues(alpha: 0.1)
                  : theme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metadata?['activityTitle'] ?? 'Activity',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isCurrentUser 
                        ? Colors.white 
                        : AppTheme.textColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (metadata?['activityType'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _getActivityTypeText(metadata!['activityType']),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isCurrentUser 
                          ? Colors.white.withValues(alpha: 0.8)
                          : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBubble(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomLeft: isCurrentUser ? const Radius.circular(20) : const Radius.circular(4),
          bottomRight: isCurrentUser ? const Radius.circular(4) : const Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomLeft: isCurrentUser ? const Radius.circular(20) : const Radius.circular(4),
          bottomRight: isCurrentUser ? const Radius.circular(4) : const Radius.circular(20),
        ),
        child: CachedNetworkImage(
          imageUrl: message.content,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 200,
            height: 200,
            color: AppTheme.cardColor(context),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 200,
            height: 200,
            color: AppTheme.cardColor(context),
            child: const Center(
              child: Icon(Icons.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInfo(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.getFormattedTime(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 4),
            Icon(
              message.isRead ? Icons.done_all : Icons.done,
              size: 12,
              color: message.isRead ? theme.primaryColor : Colors.grey[600],
            ),
          ],
        ],
      ),
    );
  }

  String _getActivityTypeText(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'workout':
        return '💪 Workout Activity';
      case 'meal':
        return '🥗 Meal Activity';
      case 'eco':
        return '🌱 Eco Activity';
      case 'achievement':
        return '🏆 Achievement';
      default:
        return '📊 Activity';
    }
  }
}