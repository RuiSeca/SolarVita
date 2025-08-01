import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/user/supporter.dart';
import '../../../providers/riverpod/user_profile_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import 'supporter_profile_screen.dart';

part 'supporter_requests_screen.g.dart';

// Provider for supporter requests stream
@riverpod
Stream<List<SupporterRequest>> supporterRequestsList(Ref ref) {
  final socialService = ref.watch(socialServiceProvider);
  return socialService.getPendingSupporterRequests();
}

class SupporterRequestsScreen extends ConsumerStatefulWidget {
  const SupporterRequestsScreen({super.key});

  @override
  ConsumerState<SupporterRequestsScreen> createState() =>
      _SupporterRequestsScreenState();
}

class _SupporterRequestsScreenState
    extends ConsumerState<SupporterRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requestsAsync = ref.watch(supporterRequestsListProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(tr(context, 'supporter_requests')),
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: theme.hintColor),
                  const SizedBox(height: 16),
                  Text(
                    tr(context, 'no_pending_supporter_requests'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'supporter_requests_will_appear'),
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
            itemCount: requests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildSupporterRequestCard(request);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.hintColor),
              const SizedBox(height: 16),
              Text(
                tr(context, 'error_loading_supporter_requests'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
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
        border: Border.all(color: theme.dividerColor.withAlpha(51), width: 1),
      ),
      child: Builder(
        builder: (context) {
          // Use data directly from supporter_request object
          final displayName =
              request.requesterName ?? tr(context, 'unknown_user');
          final username = request.requesterUsername;
          final photoURL = request.requesterPhotoURL;

          return Column(
            children: [
              // Header with profile info and action buttons
              Row(
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
                              backgroundImage: photoURL != null
                                  ? CachedNetworkImageProvider(photoURL)
                                  : null,
                              child: photoURL == null
                                  ? Text(
                                      displayName.isNotEmpty
                                          ? displayName[0].toUpperCase()
                                          : '?',
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
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
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
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    tr(context, 'sent_time_ago').replaceAll(
                                      '{timeAgo}',
                                      _getTimeAgo(context, request.createdAt),
                                    ),
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
                          child: Text(
                            tr(context, 'accept'),
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
                            tr(context, 'decline'),
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
              ),
              // Message section (if provided)
              if (request.message != null && request.message!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.primaryColor.withAlpha(51),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.message_outlined,
                            size: 14,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tr(context, 'message_label'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        request.message!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textColor(context),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _acceptRequest(String supporterRequestId) async {
    try {
      final socialService = ref.read(socialServiceProvider);
      await socialService.acceptSupporterRequest(supporterRequestId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'supporter_request_accepted')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                context,
                'error_accepting_request',
              ).replaceAll('{error}', e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(String supporterRequestId) async {
    try {
      final socialService = ref.read(socialServiceProvider);
      await socialService.rejectSupporterRequest(supporterRequestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'supporter_request_declined')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                context,
                'error_declining_request',
              ).replaceAll('{error}', e.toString()),
            ),
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
      displayName: request.requesterName ?? tr(context, 'unknown_user'),
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

  String _getTimeAgo(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return tr(
        context,
        'w_ago',
      ).replaceAll('{weeks}', (difference.inDays / 7).floor().toString());
    } else if (difference.inDays > 0) {
      return tr(
        context,
        'd_ago',
      ).replaceAll('{days}', difference.inDays.toString());
    } else if (difference.inHours > 0) {
      return tr(
        context,
        'h_ago',
      ).replaceAll('{hours}', difference.inHours.toString());
    } else if (difference.inMinutes > 0) {
      return tr(
        context,
        'm_ago',
      ).replaceAll('{minutes}', difference.inMinutes.toString());
    } else {
      return tr(context, 'now');
    }
  }
}
