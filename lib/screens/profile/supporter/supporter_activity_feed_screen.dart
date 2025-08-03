import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import '../../../services/database/social_service.dart';
import '../../../models/social/social_activity.dart';
import '../../../utils/translation_helper.dart';

class SupporterActivityFeedScreen extends StatefulWidget {
  const SupporterActivityFeedScreen({super.key});

  @override
  State<SupporterActivityFeedScreen> createState() =>
      _SupporterActivityFeedScreenState();
}

class _SupporterActivityFeedScreenState
    extends State<SupporterActivityFeedScreen> {
  final SocialService _socialService = SocialService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        title: Text(
          tr(context, 'profile.supporters_activities'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<SocialActivity>>(
        stream: _socialService.getSupportersActivityFeed(limit: 20),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    tr(context, 'profile.error_loading_activities'),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final activities = snapshot.data ?? [];

          if (activities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timeline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    tr(context, 'profile.no_activities_yet'),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'profile.supporters_activities_help'),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Trigger rebuild to refresh stream
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _buildActivityCard(context, activity);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, SocialActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  backgroundImage: activity.userPhotoURL != null
                      ? CachedNetworkImageProvider(activity.userPhotoURL!)
                      : null,
                  child: activity.userPhotoURL == null
                      ? Icon(
                          Icons.person,
                          size: 20,
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
                        activity.userName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textColor(context),
                            ),
                      ),
                      Text(
                        _formatTimeAgo(context, activity.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _getActivityTypeIcon(activity.type),
              ],
            ),
            const SizedBox(height: 12),

            // Activity Content
            Text(
              activity.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              ),
            ),
            if (activity.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                activity.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
              ),
            ],

            // Metadata
            if (activity.metadata != null && activity.metadata!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildMetadata(context, activity.metadata!),
            ],

            // Privacy indicator
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getVisibilityIcon(activity.visibility),
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _getVisibilityText(context, activity.visibility),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getActivityTypeIcon(ActivityType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case ActivityType.workout:
        iconData = Icons.fitness_center;
        color = Colors.blue;
        break;
      case ActivityType.meal:
        iconData = Icons.restaurant;
        color = Colors.orange;
        break;
      case ActivityType.ecoAction:
        iconData = Icons.eco;
        color = Colors.green;
        break;
      case ActivityType.achievement:
        iconData = Icons.emoji_events;
        color = Colors.amber;
        break;
      case ActivityType.challenge:
        iconData = Icons.flag;
        color = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, size: 16, color: color),
    );
  }

  Widget _buildMetadata(BuildContext context, Map<String, dynamic> metadata) {
    final List<Widget> chips = [];

    metadata.forEach((key, value) {
      if (value != null) {
        chips.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$key: $value',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }
    });

    return Wrap(spacing: 8, runSpacing: 4, children: chips);
  }

  IconData _getVisibilityIcon(PostVisibility visibility) {
    switch (visibility) {
      case PostVisibility.supportersOnly:
        return Icons.people;
      case PostVisibility.community:
        return Icons.public;
      case PostVisibility.public:
        return Icons.language;
    }
  }

  String _getVisibilityText(BuildContext context, PostVisibility visibility) {
    switch (visibility) {
      case PostVisibility.supportersOnly:
        return tr(context, 'profile.supporters_only');
      case PostVisibility.community:
        return tr(context, 'profile.community');
      case PostVisibility.public:
        return tr(context, 'profile.public');
    }
  }

  String _formatTimeAgo(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}';
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
      return tr(context, 'just_now');
    }
  }
}
