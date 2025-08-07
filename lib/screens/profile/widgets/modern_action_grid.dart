import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../theme/app_theme.dart';
import '../screens/add_friend_screen.dart';
import '../supporter/supporters_list_screen.dart';
import '../supporter/supporter_activity_feed_screen.dart';
import '../screens/eco_impact_screen.dart';
import '../../stats/monthly_stats_screen.dart';
import '../debug_menu_screen.dart';
import 'dart:ui';
import '../../../utils/translation_helper.dart';

class ModernActionGrid extends StatelessWidget {
  const ModernActionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'quick_actions'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildModernActionCard(
                context,
                icon: Icons.bar_chart_outlined,
                title: tr(context, 'monthly_stats'),
                subtitle: tr(context, 'view_progress_calendar'),
                gradient: [Colors.cyan, Colors.blue],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MonthlyStatsScreen(),
                    ),
                  );
                },
              ),
              _buildModernActionCard(
                context,
                icon: Icons.restaurant_outlined,
                title: tr(context, 'add_meal'),
                subtitle: tr(context, 'log_your_nutrition'),
                gradient: [Colors.green, Colors.teal],
                onTap: () {
                  // Navigate to meal logging
                },
              ),
              _buildModernActionCard(
                context,
                icon: Icons.person_add_outlined,
                title: tr(context, 'add_supporter'),
                subtitle: tr(context, 'grow_your_network'),
                gradient: [Colors.blue, Colors.indigo],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddSupporterScreen(),
                    ),
                  );
                },
              ),
              _buildModernActionCard(
                context,
                icon: Icons.groups_outlined,
                title: tr(context, 'view_supporters'),
                subtitle: tr(context, 'see_your_community'),
                gradient: [Colors.purple, Colors.deepPurple],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SupportersListScreen(),
                    ),
                  );
                },
              ),
              _buildModernActionCard(
                context,
                icon: Icons.timeline_outlined,
                title: tr(context, 'activity_feed'),
                subtitle: tr(context, 'see_updates'),
                gradient: [Colors.pink, Colors.red],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SupporterActivityFeedScreen(),
                    ),
                  );
                },
              ),
              _buildModernActionCard(
                context,
                icon: Icons.eco_outlined,
                title: tr(context, 'eco_impact'),
                subtitle: tr(context, 'view_your_progress'),
                gradient: [AppColors.primary, Colors.lightGreen],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EcoImpactScreen(),
                    ),
                  );
                },
              ),
              // Debug card - only show in debug mode
              if (kDebugMode)
                _buildModernActionCard(
                  context,
                  icon: Icons.bug_report_outlined,
                  title: 'Debug Menu',
                  subtitle: 'Developer tools',
                  gradient: [Colors.grey.shade600, Colors.grey.shade800],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DebugMenuScreen(),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.3),
              spreadRadius: 0,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gradient[0].withValues(alpha: 0.8),
                    gradient[1].withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white, size: 20),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
