import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod/firebase_chat_provider.dart';
import '../../providers/riverpod/offline_cache_provider.dart';
import '../../providers/riverpod/auth_provider.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../theme/app_theme.dart';
import '../../services/chat_notification_service.dart';
import 'conversation_info_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoURL;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoURL,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // Mark conversation as read when entering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationReadTrackerProvider.notifier)
          .markConversationAsViewed(widget.conversationId);
      
      // Set current conversation for notification service
      ChatNotificationService().setCurrentChatConversation(widget.conversationId);
    });
  }

  @override
  void dispose() {
    // Clear current conversation when leaving chat
    ChatNotificationService().setCurrentChatConversation(null);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    if (_scrollController.hasClients) {
      if (animate) {
        _scrollController.animateTo(
          0.0, // With reverse: true, 0.0 is the bottom (newest messages)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(0.0); // With reverse: true, 0.0 is the bottom
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final messagesAsync = ref.watch(conversationMessagesProvider(widget.conversationId));
    final isOnline = ref.watch(connectivityStatusProvider);
    final pendingSyncCount = ref.watch(pendingSyncItemsCountProvider);
    final chatActions = ref.read(chatActionsProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.textColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              backgroundImage: widget.otherUserPhotoURL != null
                  ? NetworkImage(widget.otherUserPhotoURL!)
                  : null,
              child: widget.otherUserPhotoURL == null
                  ? Icon(
                      Icons.person,
                      size: 16,
                      color: AppTheme.primaryColor,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.textColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isOnline)
                    Text(
                      'Offline',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Connection status indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 6,
              backgroundColor: isOnline ? Colors.green : Colors.orange,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: AppTheme.textColor(context),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConversationInfoScreen(
                    conversationId: widget.conversationId,
                    otherUserId: widget.otherUserId,
                    otherUserName: widget.otherUserName,
                    otherUserPhotoURL: widget.otherUserPhotoURL,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline indicator
          if (!isOnline) 
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.orange.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.cloud_off, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    'You\'re offline',
                    style: TextStyle(color: Colors.orange[700], fontSize: 12),
                  ),
                  const Spacer(),
                  pendingSyncCount.when(
                    data: (count) => count > 0 
                        ? Text(
                            '$count pending',
                            style: TextStyle(color: Colors.orange[700], fontSize: 12),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

          // Messages List
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                // Scroll to bottom when new messages arrive or screen loads
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length,
                  reverse: true, // Show oldest messages first (reverse the descending order)
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message.senderId == currentUser?.uid;
                    
                    // Show avatar for the first message from each sender (accounting for reverse order)
                    final showAvatar = index == messages.length - 1 ||
                        messages[index + 1].senderId != message.senderId;

                    return MessageBubble(
                      message: message,
                      isCurrentUser: isCurrentUser,
                      showAvatar: showAvatar,
                      otherUserPhotoURL: widget.otherUserPhotoURL,
                      otherUserName: widget.otherUserName,
                      currentUserPhotoURL: currentUser?.photoURL,
                      currentUserName: currentUser?.displayName,
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading messages',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Message Input
          _buildMessageInput(chatActions),
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to ${widget.otherUserName}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(ChatActions chatActions) {
    final theme = Theme.of(context);
    final chatState = ref.watch(chatActionsProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Add attachment button
            IconButton(
              icon: Icon(
                Icons.add,
                color: theme.primaryColor,
              ),
              onPressed: () {
                _showAttachmentOptions(context);
              },
            ),
            
            // Message input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.textFieldBackground(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(chatActions),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Send button
            Container(
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: chatState.maybeWhen(
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  orElse: () => const Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
                ),
                onPressed: chatState.maybeWhen(
                  loading: () => null,
                  orElse: () => () => _sendMessage(chatActions),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(ChatActions chatActions) async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    
    try {
      await chatActions.sendTextMessage(
        conversationId: widget.conversationId,
        content: content,
      );
      _scrollToBottom();
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Share Content',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              _buildAttachmentOption(
                context,
                icon: Icons.camera_alt,
                title: 'Camera',
                subtitle: 'Take a photo',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon(context, 'Camera feature');
                },
              ),
              
              _buildAttachmentOption(
                context,
                icon: Icons.photo_library,
                title: 'Gallery',
                subtitle: 'Choose from gallery',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon(context, 'Gallery feature');
                },
              ),
              
              _buildAttachmentOption(
                context,
                icon: Icons.fitness_center,
                title: 'Share Activity',
                subtitle: 'Share your recent workout or eco activity',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon(context, 'Activity sharing');
                },
              ),
              
              _buildAttachmentOption(
                context,
                icon: Icons.location_on,
                title: 'Location',
                subtitle: 'Share your location',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon(context, 'Location sharing');
                },
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).primaryColor,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}