import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:solar_vitas/utils/translation_helper.dart';
import 'meal_plan_screen.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, 'fitness_profile'),
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildProfileSection(context),
                const SizedBox(height: 24),
                _buildStatsBar(context),
                const SizedBox(height: 24),
                _buildMealsSection(context),
                const SizedBox(height: 24),
                _buildProgressSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
              image: const DecorationImage(
                image: AssetImage(
                    'assets/images/health/health_profile/profile.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tr(context, 'solarvita_fitness'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            tr(context, 'eco_friendly_workouts'),
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 153),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StatItem(title: 'explore', subtitle: 'my_fitness', context: context),
          VerticalDivider(
              color: AppTheme.textColor(context).withValues(alpha: 51)),
          StatItem(title: '2', subtitle: 'inspiring_users', context: context),
          VerticalDivider(
              color: AppTheme.textColor(context).withValues(alpha: 51)),
          StatItem(title: 'achieve', subtitle: 'challenges', context: context),
        ],
      ),
    );
  }

  Widget _buildMealsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'friendly_meals'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildMealPlanningCard(context),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'track_progress'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildTrackingItem(
          context,
          icon: Icons.fitness_center,
          title: 'completed_workouts',
          buttonText: 'button_explore',
        ),
        _buildTrackingItem(
          context,
          icon: Icons.bedtime,
          title: 'sleep_pattern',
          buttonText: 'button_record_time',
        ),
        _buildTrackingItem(
          context,
          icon: Icons.favorite,
          title: 'heart_rate',
          buttonText: 'button_results',
        ),
        _buildTrackingItem(
          context,
          icon: Icons.eco,
          title: 'eco_conscious_achievements',
          buttonText: 'button_enter',
        ),
        _buildWaterIntakeItem(
          context,
          currentAmount: 0,
          totalAmount: 2000,
        ),
      ],
    );
  }

  Widget _buildMealPlanningCard(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: AssetImage('assets/images/health/meals/meal.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            tr(context, 'meal_planning'),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'meal_planning_description'),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MealPlanScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                tr(context, 'explore_meals'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String buttonText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textColor(context), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tr(context, title),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                tr(context, buttonText),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterIntakeItem(
    BuildContext context, {
    required int currentAmount,
    required int totalAmount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop,
                  color: AppTheme.textColor(context), size: 24),
              const SizedBox(width: 12),
              Text(
                '$currentAmount / $totalAmount ml',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    '+ 250ml',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: currentAmount / totalAmount,
              backgroundColor:
                  AppTheme.textColor(context).withValues(alpha: 51),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final BuildContext context;

  const StatItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          tr(context, title),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          tr(context, subtitle),
          style: TextStyle(
            color: AppTheme.textColor(context).withValues(alpha: 153),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
