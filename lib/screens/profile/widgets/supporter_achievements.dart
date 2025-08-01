import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../../../models/user/privacy_settings.dart';
import '../../../services/database/supporter_profile_service.dart';

class SupporterAchievements extends ConsumerWidget {
  final String supporterId;
  final PrivacySettings privacySettings;
  final List<Achievement>? achievements;

  const SupporterAchievements({
    super.key,
    required this.supporterId,
    required this.privacySettings,
    this.achievements,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                tr(context, 'achievements'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
              const Spacer(),
              if (!privacySettings.showAchievements)
                Icon(Icons.lock_outline, color: Colors.grey[500], size: 20),
            ],
          ),
          const SizedBox(height: 16),
          _buildAchievementsContent(context),
        ],
      ),
    );
  }

  Widget _buildAchievementsContent(BuildContext context) {
    if (!privacySettings.showAchievements) {
      return _buildPrivateAchievements(context);
    }

    // Show actual achievements
    final achievementsList = achievements ?? _getDefaultAchievements(context);

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: achievementsList.length,
        itemBuilder: (context, index) {
          final achievement = achievementsList[index];
          return _buildAchievementBadge(context, achievement);
        },
      ),
    );
  }

  Widget _buildPrivateAchievements(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, color: Colors.grey[500], size: 32),
            const SizedBox(height: 8),
            Text(
              tr(context, 'achievements_shared_privately'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr(context, 'supporter_keeps_achievements_private'),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementBadge(BuildContext context, Achievement achievement) {
    final iconData = _getIconFromName(achievement.iconName);
    final color = _getColorFromName(achievement.colorName);

    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: achievement.isUnlocked
                  ? LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                    )
                  : LinearGradient(
                      colors: [
                        Colors.grey.withValues(alpha: 0.3),
                        Colors.grey.withValues(alpha: 0.1),
                      ],
                    ),
              shape: BoxShape.circle,
              border: Border.all(
                color: achievement.isUnlocked
                    ? color.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: achievement.isUnlocked
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              iconData,
              color: achievement.isUnlocked ? Colors.white : Colors.grey[500],
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: achievement.isUnlocked
                  ? AppTheme.textColor(context)
                  : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (achievement.isUnlocked && achievement.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              achievement.subtitle!,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  List<Achievement> _getDefaultAchievements(BuildContext context) {
    // Default achievements - would come from Firebase in real implementation
    return [
      Achievement(
        id: '1',
        title: tr(context, 'first_steps'),
        subtitle: tr(context, 'started_journey'),
        iconName: 'directions_walk',
        colorName: 'blue',
        isUnlocked: true,
      ),
      Achievement(
        id: '2',
        title: tr(context, 'eco_warrior'),
        subtitle: tr(context, 'green_choices'),
        iconName: 'eco',
        colorName: 'green',
        isUnlocked: true,
      ),
      Achievement(
        id: '3',
        title: tr(context, 'streak_master'),
        subtitle: tr(context, '7_day_streak'),
        iconName: 'local_fire_department',
        colorName: 'orange',
        isUnlocked: true,
      ),
      Achievement(
        id: '4',
        title: tr(context, 'goal_crusher'),
        subtitle: tr(context, 'perfect_week'),
        iconName: 'emoji_events',
        colorName: 'amber',
        isUnlocked: false,
      ),
      Achievement(
        id: '5',
        title: tr(context, 'social_butterfly'),
        subtitle: tr(context, '10_supporters'),
        iconName: 'people',
        colorName: 'purple',
        isUnlocked: false,
      ),
    ];
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'directions_walk':
        return Icons.directions_walk;
      case 'eco':
        return Icons.eco;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'people':
        return Icons.people;
      default:
        return Icons.emoji_events;
    }
  }

  Color _getColorFromName(String colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'amber':
        return Colors.amber;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
}
