// lib/screens/profile/widgets/enhanced_profile_header.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/user/user_profile.dart';
import '../../../theme/app_theme.dart';

class EnhancedProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final bool isCurrentUser;
  final VoidCallback? onAvatarTap;

  const EnhancedProfileHeader({
    super.key,
    required this.profile,
    required this.isCurrentUser,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Avatar
          GestureDetector(
            onTap: onAvatarTap,
            child: Hero(
              tag: 'profile_avatar_${profile.uid}',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withAlpha(51),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child:
                      profile.photoURL != null && profile.photoURL!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: profile.photoURL!,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                          placeholder: (context, url) => Container(
                            color: AppTheme.textFieldBackground(context),
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: AppTheme.textColor(context).withAlpha(128),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.textFieldBackground(context),
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: AppTheme.textColor(context).withAlpha(128),
                            ),
                          ),
                        )
                      : Container(
                          color: Theme.of(context).primaryColor.withAlpha(26),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Display Name and Verification
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  profile.displayName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (profile.isVerified) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.verified,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ],
          ),

          // Username
          if (profile.username != null && profile.username!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '@${profile.username}',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          // Bio
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.textColor(context).withAlpha(26),
                ),
              ),
              child: Text(
                profile.bio!,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: AppTheme.textColor(context).withAlpha(204),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          // Interests
          if (profile.interests.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: profile.interests
                  .take(5)
                  .map(
                    (interest) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withAlpha(77),
                        ),
                      ),
                      child: Text(
                        interest,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (profile.interests.length > 5) ...[
              const SizedBox(height: 8),
              Text(
                '+${profile.interests.length - 5} more',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textColor(context).withAlpha(153),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],

          // Activity Status
          if (!isCurrentUser && profile.lastActive != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getActivityColor(profile.lastActive!).withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getActivityColor(profile.lastActive!),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getActivityText(profile.lastActive!),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getActivityColor(profile.lastActive!),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getActivityColor(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 5) {
      return Colors.green;
    } else if (difference.inHours < 1) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  String _getActivityText(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 5) {
      return 'Active now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
