import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/chat/chat_conversation.dart';
import '../../theme/app_theme.dart';

class ConversationListItem extends StatelessWidget {
  final ChatConversation conversation;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final hasUnread = unreadCount > 0;

    // Get other participant info
    final otherParticipantName = conversation.getOtherParticipantName(
      currentUserId,
    );
    final otherParticipantPhoto = conversation.getOtherParticipantPhoto(
      currentUserId,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: hasUnread ? AppTheme.cardColor(context) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: hasUnread
            ? Border.all(color: theme.primaryColor.withValues(alpha: 0.1))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              backgroundImage: otherParticipantPhoto != null
                  ? CachedNetworkImageProvider(otherParticipantPhoto)
                  : null,
              child: otherParticipantPhoto == null
                  ? Icon(Icons.person, size: 24, color: AppTheme.primaryColor)
                  : null,
            ),
            if (hasUnread)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.surfaceColor(context),
                      width: 2,
                    ),
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
        title: Text(
          otherParticipantName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
            color: AppTheme.textColor(context),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getLastMessagePreview(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: hasUnread
                    ? AppTheme.textColor(context)
                    : Colors.grey[600],
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              conversation.getLastMessageTimeAgo(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: hasUnread ? theme.primaryColor : Colors.grey[500],
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: hasUnread
            ? Icon(Icons.circle, color: theme.primaryColor, size: 8)
            : Icon(Icons.chevron_right, color: Colors.grey[400], size: 16),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }

  String _getLastMessagePreview() {
    if (conversation.lastMessage.isEmpty) {
      return 'No messages yet';
    }

    // Handle different message types
    if (conversation.lastMessage.startsWith('{"messageType":')) {
      // This is likely a JSON message for activity share
      return '📊 Shared an activity';
    }

    // Regular text message
    return conversation.lastMessage;
  }
}
