import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';

class ModernAchievementsSection extends ConsumerWidget {
  const ModernAchievementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr(context, 'story_highlights'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // View all achievements
                },
                child: Text(
                  tr(context, 'view_all'),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildStoryHighlight(
                  context,
                  icon: Icons.fitness_center,
                  label: tr(context, 'workouts'),
                  color: Colors.orange,
                  hasNew: true,
                ),
                _buildStoryHighlight(
                  context,
                  icon: Icons.eco,
                  label: tr(context, 'eco_goals'),
                  color: AppColors.primary,
                  hasNew: false,
                ),
                _buildStoryHighlight(
                  context,
                  icon: Icons.restaurant,
                  label: tr(context, 'nutrition'),
                  color: Colors.green,
                  hasNew: true,
                ),
                _buildStoryHighlight(
                  context,
                  icon: Icons.emoji_events,
                  label: tr(context, 'achievements'),
                  color: Colors.amber,
                  hasNew: false,
                ),
                _buildStoryHighlight(
                  context,
                  icon: Icons.groups,
                  label: tr(context, 'community'),
                  color: Colors.blue,
                  hasNew: true,
                ),
                _buildStoryHighlight(
                  context,
                  icon: Icons.trending_up,
                  label: tr(context, 'progress'),
                  color: Colors.purple,
                  hasNew: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryHighlight(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool hasNew,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasNew
                      ? LinearGradient(
                          colors: [
                            AppColors.primary,
                            color,
                          ],
                        )
                      : null,
                  color: hasNew ? null : Colors.grey.withAlpha(77),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(77),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(hasNew ? 3 : 0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withAlpha(204),
                        color,
                      ],
                    ),
                    border: hasNew
                        ? Border.all(
                            color: AppTheme.surfaceColor(context),
                            width: 2,
                          )
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              if (hasNew)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.surfaceColor(context),
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}