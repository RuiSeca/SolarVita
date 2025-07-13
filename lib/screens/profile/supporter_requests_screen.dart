import 'package:flutter/material.dart';
import '../../models/supporter.dart';
import '../../services/social_service.dart';
import '../../theme/app_theme.dart';
import 'friend_profile_screen.dart';

class SupporterRequestsScreen extends StatefulWidget {
  const SupporterRequestsScreen({super.key});

  @override
  State<SupporterRequestsScreen> createState() => _SupporterRequestsScreenState();
}

class _SupporterRequestsScreenState extends State<SupporterRequestsScreen> {
  final SocialService _socialService = SocialService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: const Text('Supporter Requests'),
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<SupporterRequest>>(
        stream: _socialService.getPendingSupporterRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.hintColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading supporter requests',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            );
          }

          final friendRequests = snapshot.data ?? [];

          if (friendRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: theme.hintColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending supporter requests',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Supporter requests will appear here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: friendRequests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = friendRequests[index];
              return _buildSupporterRequestCard(request);
            },
          );
        },
      ),
    );
  }

  Widget _buildSupporterRequestCard(SupporterRequest request) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withAlpha(51),
          width: 1,
        ),
      ),
      child: Builder(
        builder: (context) {
          // Use data directly from supporter_request object
          final displayName = request.requesterName ?? 'Unknown User';
          final username = request.requesterUsername;
          final photoURL = request.requesterPhotoURL;

          return Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _viewUserProfile(request),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: theme.primaryColor.withAlpha(51),
                          backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                          child: photoURL == null
                              ? Text(
                                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      displayName,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: theme.hintColor,
                                  ),
                                ],
                              ),
                              if (username != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '@$username',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                'Sent ${_getTimeAgo(request.createdAt)} • Tap to view profile',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  SizedBox(
                    width: 80,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () => _acceptRequest(request.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 80,
                    height: 32,
                    child: OutlinedButton(
                      onPressed: () => _rejectRequest(request.id),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: BorderSide(color: theme.hintColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Decline',
                        style: TextStyle(
                          color: theme.hintColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _acceptRequest(String supporterRequestId) async {
    try {
      await _socialService.acceptSupporterRequest(supporterRequestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supporter request accepted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(String supporterRequestId) async {
    try {
      await _socialService.rejectSupporterRequest(supporterRequestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supporter request declined'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewUserProfile(SupporterRequest request) {
    // Create a Supporter object from the request data
    final supporter = Supporter(
      userId: request.requesterId,
      displayName: request.requesterName ?? 'Unknown User',
      username: request.requesterUsername,
      photoURL: request.requesterPhotoURL,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupporterProfileScreen(supporter: supporter),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}