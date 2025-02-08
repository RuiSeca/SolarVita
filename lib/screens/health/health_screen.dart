import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

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
                  'Fitness Profile',
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
                image: AssetImage('assets/images/health/profile/profile.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'SolarVita Fitness',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Eco-friendly workouts',
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
          StatItem(title: 'Explore', subtitle: 'My Fitness', context: context),
          VerticalDivider(
              color: AppTheme.textColor(context).withValues(alpha: 51)),
          StatItem(title: '2', subtitle: 'Inspiring Users', context: context),
          VerticalDivider(
              color: AppTheme.textColor(context).withValues(alpha: 51)),
          StatItem(title: 'Achieve', subtitle: 'Challenges', context: context),
        ],
      ),
    );
  }

  Widget _buildMealsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Friendly Meals',
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
          'Track Progress',
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
          title: 'Completed Workouts',
          buttonText: 'explore',
        ),
        _buildTrackingItem(
          context,
          icon: Icons.bedtime,
          title: 'Sleep Pattern',
          buttonText: 'Record time',
        ),
        _buildTrackingItem(
          context,
          icon: Icons.favorite,
          title: 'Heart Rate',
          buttonText: 'Results',
        ),
        _buildTrackingItem(
          context,
          icon: Icons.eco,
          title: 'Eco-conscious Achievements',
          buttonText: 'Enter',
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
          const Text(
            'Meal Planning',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Discover sustainable meal options tailored to your fitness goals',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Explore Meals',
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
              title,
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
                buttonText,
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
          title,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.textColor(context).withValues(alpha: 153),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
