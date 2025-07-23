import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../providers/riverpod/chat_provider.dart';
import 'chat_search_screen.dart';

class ConversationInfoScreen extends ConsumerWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoURL;

  const ConversationInfoScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoURL,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final chatActions = ref.read(chatActionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        title: Text(
          'Conversation Info',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.textColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // User Info Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    backgroundImage: otherUserPhotoURL != null
                        ? CachedNetworkImageProvider(otherUserPhotoURL!)
                        : null,
                    child: otherUserPhotoURL == null
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: AppTheme.primaryColor,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    otherUserName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your supporter',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Actions Section
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildActionTile(
                    context,
                    icon: Icons.search,
                    title: 'Search in conversation',
                    subtitle: 'Find messages in this chat',
                    onTap: () {
                      Navigator.pop(context);
                      _showSearchDialog(context);
                    },
                  ),
                  
                  _buildActionTile(
                    context,
                    icon: Icons.notifications_off,
                    title: 'Mute notifications',
                    subtitle: 'Stop receiving notifications for this chat',
                    onTap: () {
                      _showMuteDialog(context);
                    },
                  ),
                  
                  _buildActionTile(
                    context,
                    icon: Icons.photo_library,
                    title: 'Media & Files',
                    subtitle: 'View shared photos and files',
                    onTap: () {
                      _showMediaGallery(context);
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Danger Zone
                  Text(
                    'Danger Zone',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.red[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildActionTile(
                    context,
                    icon: Icons.delete_forever,
                    title: 'Delete conversation',
                    subtitle: 'This action cannot be undone',
                    textColor: Colors.red[600],
                    onTap: () {
                      _showDeleteDialog(context, chatActions);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: textColor ?? AppTheme.textColor(context),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: textColor ?? AppTheme.textColor(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        
        return AlertDialog(
          title: const Text('Search in conversation'),
          content: TextField(
            decoration: const InputDecoration(
              hintText: 'Enter search term...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              searchQuery = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (searchQuery.isNotEmpty) {
                  // Navigate to search screen with pre-filled query
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatSearchScreen(),
                    ),
                  );
                }
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _showMuteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mute notifications'),
          content: const Text('How long would you like to mute notifications for this conversation?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications muted for 1 hour'),
                  ),
                );
              },
              child: const Text('1 hour'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications muted for 1 day'),
                  ),
                );
              },
              child: const Text('1 day'),
            ),
          ],
        );
      },
    );
  }

  void _showMediaGallery(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Media gallery coming soon!'),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ChatActions chatActions) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Conversation'),
          content: const Text(
            'Are you sure you want to delete this conversation? This action cannot be undone and all messages will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close info screen
                Navigator.pop(context); // Close chat screen
                
                final success = await chatActions.deleteConversation(conversationId);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Conversation deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red[600]),
              ),
            ),
          ],
        );
      },
    );
  }
}