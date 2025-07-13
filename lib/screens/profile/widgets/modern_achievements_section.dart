import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ModernAchievementsSection extends StatelessWidget {
  const ModernAchievementsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Story Highlights',
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
                  'View All',
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
                  label: 'Workouts',
                  color: Colors.orange,
                  hasNew: true,
                ),
                _buildStoryHighlight(
                  context,
                  icon: Icons.eco,
                  label: 'Eco Goals',
                  color: AppColors.primary,
                  hasNew: false,
                ),
                _buildStoryHighlight(
                  context,
                  icon: Icons.restaurant,
                  label: 'Nutrition',
                  color: Colors.green,
                  hasNew: true,
                ),
                _buildStoryHighlight(
                  context,
                  icon: Icons.emoji_events,
                  label: 'Achievements',
                  color: Colors.amber,
                  hasNew: false,
                ),
                _buildStoryHighlight(
                  context,
                  icon: Icons.groups,
                  label: 'Community',
                  color: Colors.blue,
                  hasNew: true,
                ),
                _buildStoryHighlight(
                  context,
                  icon: Icons.trending_up,
                  label: 'Progress',
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
                  color: hasNew ? null : Colors.grey.withValues(alpha: 0.3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
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
                        color.withValues(alpha: 0.8),
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