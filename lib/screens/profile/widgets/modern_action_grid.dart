import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../add_friend_screen.dart';
import '../supporters_list_screen.dart';
import '../friend_activity_feed_screen.dart';
import 'dart:ui';

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
            'Quick Actions',
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
                icon: Icons.fitness_center_outlined,
                title: 'Log Workout',
                subtitle: 'Track your fitness',
                gradient: [Colors.orange, Colors.deepOrange],
                onTap: () {
                  // Navigate to workout logging
                },
              ),
              _buildModernActionCard(
                context,
                icon: Icons.restaurant_outlined,
                title: 'Add Meal',
                subtitle: 'Log your nutrition',
                gradient: [Colors.green, Colors.teal],
                onTap: () {
                  // Navigate to meal logging
                },
              ),
              _buildModernActionCard(
                context,
                icon: Icons.person_add_outlined,
                title: 'Add Supporter',
                subtitle: 'Grow your network',
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
                title: 'View Supporters',
                subtitle: 'See your community',
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
                title: 'Activity Feed',
                subtitle: 'See updates',
                gradient: [Colors.pink, Colors.red],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FriendActivityFeedScreen(),
                    ),
                  );
                },
              ),
              _buildModernActionCard(
                context,
                icon: Icons.eco_outlined,
                title: 'Eco Impact',
                subtitle: 'View your progress',
                gradient: [AppColors.primary, Colors.lightGreen],
                onTap: () {
                  // Navigate to eco impact screen
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 16,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
