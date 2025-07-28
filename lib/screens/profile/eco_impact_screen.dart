import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/riverpod/eco_provider.dart';
import '../../providers/riverpod/meal_provider.dart';
import '../../providers/riverpod/health_data_provider.dart';
import '../../providers/riverpod/location_provider.dart';
import '../../models/eco_metrics.dart';
import '../../models/carbon_activity.dart';
import '../../models/health_data.dart';
import '../../services/eco_service.dart';
import '../../widgets/optimized_map_factory.dart';
import 'transportation_details_screen.dart';
import 'meals_details_screen.dart';
import 'package:geolocator/geolocator.dart';

class EcoImpactScreen extends ConsumerStatefulWidget {
  const EcoImpactScreen({super.key});

  @override
  ConsumerState<EcoImpactScreen> createState() => _EcoImpactScreenState();
}

class _EcoImpactScreenState extends ConsumerState<EcoImpactScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _mealsKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToMealsSection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MealsDetailsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final ecoMetricsAsync = ref.watch(userEcoMetricsProvider);
        final recentActivitiesAsync = ref.watch(recentEcoActivitiesProvider);
        final carbonLast30DaysAsync = ref.watch(carbonSavedLast30DaysProvider);
        final mealsState = ref.watch(mealNotifierProvider);

        return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(
          'Eco Impact',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppTheme.textColor(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.textColor(context)),
            onPressed: () {
              ref.invalidate(userEcoMetricsProvider);
              ref.invalidate(recentEcoActivitiesProvider);
              ref.invalidate(carbonSavedLast30DaysProvider);
            },
          ),
        ],
      ),
      body: ecoMetricsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading eco data: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userEcoMetricsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (ecoMetrics) => SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main eco stats card
              _buildEcoStatsCard(ecoMetrics),
              const SizedBox(height: 24),
              
              // Individual impact sections
              _buildImpactSection(
                context,
                title: 'Plastic Reduction',
                icon: Icons.water_drop,
                color: Colors.blue,
                value: '${ecoMetrics.plasticBottlesSaved}',
                unit: 'Bottles Saved',
                description: 'By choosing eco-friendly options, you\'ve helped reduce plastic waste equivalent to ${ecoMetrics.plasticBottlesSaved} plastic bottles.',
              ),
              const SizedBox(height: 16),
              
              _buildImpactSection(
                context,
                title: 'Carbon Footprint',
                icon: Icons.co2,
                color: Colors.green,
                value: ecoMetrics.totalCarbonSaved.toStringAsFixed(1),
                unit: 'kg CO₂ Saved',
                description: 'Your sustainable lifestyle choices have prevented ${ecoMetrics.totalCarbonSaved.toStringAsFixed(1)}kg of CO₂ from entering the atmosphere.',
              ),
              const SizedBox(height: 16),
              
              _buildSustainableMealsCard(context, ref, ecoMetrics, mealsState),
              const SizedBox(height: 16),
              
              _buildTransportationCard(context, ref, ecoMetrics),
              const SizedBox(height: 16),
              
              _buildImpactSection(
                context,
                title: 'Current Streak',
                icon: Icons.local_fire_department,
                color: Colors.red,
                value: '${ecoMetrics.currentStreak}',
                unit: 'Days',
                description: 'You\'ve been consistently eco-friendly for ${ecoMetrics.currentStreak} days! Keep it up!',
              ),
              const SizedBox(height: 16),
              
              _buildImpactSection(
                context,
                title: 'Overall Eco Score',
                icon: Icons.stars,
                color: Colors.amber,
                value: '${ecoMetrics.ecoScore}',
                unit: 'Points',
                description: 'Your combined eco-friendly actions have earned you ${ecoMetrics.ecoScore} sustainability points. Keep up the great work!',
              ),
              const SizedBox(height: 24),

              // Today's Meals section with eco advice
              Container(
                key: _mealsKey,
                child: _buildTodaysMealsSection(context, ref, mealsState),
              ),
              const SizedBox(height: 24),


              // Recent activities section
              _buildRecentActivitiesSection(context, ref, recentActivitiesAsync),
              const SizedBox(height: 24),

              // Last 30 days summary
              _buildLast30DaysSummary(context, carbonLast30DaysAsync),
              const SizedBox(height: 32),
              
              // Tips section
              _buildTipsSection(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddActivityDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Log Activity'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
        );
      },
    );
  }

  Widget _buildEcoStatsCard(EcoMetrics ecoMetrics) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.primary.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.eco,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Eco Impact',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEcoStatItem(
                  icon: Icons.water_drop,
                  value: '${ecoMetrics.plasticBottlesSaved}',
                  label: 'Bottles Saved',
                  color: Colors.blue.shade300,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEcoStatItem(
                  icon: Icons.co2,
                  value: '${ecoMetrics.totalCarbonSaved.toStringAsFixed(1)}kg',
                  label: 'Carbon Saved',
                  color: Colors.green.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildEcoStatItem(
                  icon: Icons.local_fire_department,
                  value: '${ecoMetrics.currentStreak}',
                  label: 'Day Streak',
                  color: Colors.red.shade300,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEcoStatItem(
                  icon: Icons.stars,
                  value: '${ecoMetrics.ecoScore}',
                  label: 'Eco Score',
                  color: Colors.yellow.shade300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEcoStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImpactSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String value,
    required String unit,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.textFieldBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: TextStyle(
                        color: AppTheme.textColor(context).withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: AppTheme.textColor(context).withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Eco Tips',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...const [
            '🌱 Choose plant-based meals to reduce carbon footprint',
            '♻️ Use reusable water bottles and containers',
            '🚶‍♀️ Walk or bike for short distances instead of driving',
            '💡 Turn off lights and electronics when not in use',
            '🌿 Support local and organic food producers',
          ].map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  tip,
                  style: TextStyle(
                    color: AppTheme.textColor(context).withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // Recent activities section
  Widget _buildRecentActivitiesSection(BuildContext context, WidgetRef ref, AsyncValue<List<EcoActivity>> recentActivitiesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activities',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        recentActivitiesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error loading activities: $error'),
          data: (activities) {
            if (activities.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.textFieldBackground(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.eco, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'No eco activities yet',
                        style: TextStyle(color: AppTheme.textColor(context)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start logging your eco-friendly actions!',
                        style: TextStyle(color: AppTheme.textColor(context).withAlpha(153)),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: activities.take(5).map((activity) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.textFieldBackground(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        activity.icon,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.displayName,
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${activity.carbonSaved.toStringAsFixed(1)} kg CO₂ saved',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDate(activity.date),
                      style: TextStyle(
                        color: AppTheme.textColor(context).withAlpha(153),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  // Last 30 days summary
  Widget _buildLast30DaysSummary(BuildContext context, AsyncValue<double> carbonLast30DaysAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withAlpha(26),
            Colors.blue.withAlpha(26),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Last 30 Days Impact',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          carbonLast30DaysAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text('Error: $error'),
            data: (carbonSaved) => Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Carbon Saved:',
                      style: TextStyle(color: AppTheme.textColor(context)),
                    ),
                    Text(
                      '${carbonSaved.toStringAsFixed(1)} kg CO₂',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Equivalent bottles:',
                      style: TextStyle(color: AppTheme.textColor(context)),
                    ),
                    Text(
                      '${EcoMetrics.carbonToBottles(carbonSaved)} bottles',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add activity dialog
  void _showAddActivityDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Log Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 20),
            _buildQuickActivityButton(
              context,
              ref,
              'Used Reusable Bottle',
              Icons.water_drop,
              Colors.blue,
              () async {
                final actions = ref.read(ecoActivityActionsProvider);
                await actions.logConsumptionActivity('reusableBottle');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Activity logged successfully!')),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            _buildQuickActivityButton(
              context,
              ref,
              'Walked/Biked Instead',
              Icons.directions_walk,
              Colors.green,
              () async {
                final actions = ref.read(ecoActivityActionsProvider);
                await actions.logTransportActivity('walking');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Activity logged successfully!')),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            _buildQuickActivityButton(
              context,
              ref,
              'Recycled Items',
              Icons.recycling,
              Colors.orange,
              () async {
                final actions = ref.read(ecoActivityActionsProvider);
                final ecoActivity = EcoActivity(
                  id: '',
                  userId: ref.read(ecoServiceProvider).currentUserId!,
                  type: EcoActivityType.waste,
                  activity: 'recycling',
                  carbonSaved: 0.5,
                  date: DateTime.now(),
                );
                await actions.addActivity(ecoActivity);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Activity logged successfully!')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActivityButton(BuildContext context, WidgetRef ref, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.add, color: color),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  // Enhanced Sustainable Meals card with today's meals preview and navigation
  Widget _buildSustainableMealsCard(BuildContext context, WidgetRef ref, EcoMetrics ecoMetrics, MealState mealsState) {
    // Calculate today's meal stats
    final todaysMeals = mealsState.meals?.take(5).toList() ?? [];
    double todaysCarbonPotential = 0.0;
    int todaysSustainableMeals = 0;

    for (final meal in todaysMeals) {
      final category = _inferMealCategory(meal);
      final calories = _extractCalories(meal);
      final carbonSaved = EcoService.calculateMealCarbonSaved(category, calories: calories);
      
      if (carbonSaved > 0) {
        todaysCarbonPotential += carbonSaved;
        todaysSustainableMeals++;
      }
    }

    return GestureDetector(
      onTap: () => _scrollToMealsSection(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.textFieldBackground(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.textColor(context).withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            // Header row with main stats
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.restaurant,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sustainable Meals',
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            ecoMetrics.mealCarbonSaved.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'kg CO₂ from Meals',
                            style: TextStyle(
                              color: AppTheme.textColor(context).withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.textColor(context).withValues(alpha: 0.5),
                  size: 16,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Today's meals preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.today,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Today\'s Meals',
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (todaysMeals.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: todaysSustainableMeals > todaysMeals.length / 2 
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$todaysSustainableMeals/${todaysMeals.length} sustainable',
                            style: TextStyle(
                              color: todaysSustainableMeals > todaysMeals.length / 2 
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  if (todaysMeals.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'No meals logged today - start tracking to see your eco impact!',
                      style: TextStyle(
                        color: AppTheme.textColor(context).withValues(alpha: 0.6),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    
                    // Show first 3 meals as preview
                    ...todaysMeals.take(3).map((meal) {
                      final category = _inferMealCategory(meal);
                      final mealName = meal['strMeal'] ?? meal['food_name'] ?? 'Unknown Meal';
                      final carbonSaved = EcoService.calculateMealCarbonSaved(category, calories: _extractCalories(meal));
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              _getCategoryIcon(category),
                              color: _getCategoryColor(category),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                mealName.length > 25 ? '${mealName.substring(0, 25)}...' : mealName,
                                style: TextStyle(
                                  color: AppTheme.textColor(context),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (carbonSaved > 0)
                              Text(
                                '${carbonSaved.toStringAsFixed(1)}kg',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    
                    if (todaysMeals.length > 3) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+${todaysMeals.length - 3} more meals',
                        style: TextStyle(
                          color: AppTheme.textColor(context).withValues(alpha: 0.6),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    
                    if (todaysCarbonPotential > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.eco, color: Colors.green, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '${todaysCarbonPotential.toStringAsFixed(1)}kg CO₂ potential today',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Description
            Text(
              'Your mindful meal choices have reduced your carbon footprint by ${ecoMetrics.mealCarbonSaved.toStringAsFixed(1)}kg through sustainable eating. Tap to see today\'s meal analysis.',
              style: TextStyle(
                color: AppTheme.textColor(context).withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Today's Meals section with eco advice
  Widget _buildTodaysMealsSection(BuildContext context, WidgetRef ref, MealState mealsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Meals & Eco Impact',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildMealsList(context, ref, mealsState),
      ],
    );
  }

  Widget _buildMealsList(BuildContext context, WidgetRef ref, MealState mealsState) {
    // If no meals data or loading, show placeholder
    if (mealsState.isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.textFieldBackground(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (mealsState.meals == null || mealsState.meals!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.textFieldBackground(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.restaurant_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'No meals logged today',
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
              const SizedBox(height: 4),
              Text(
                'Start logging meals to see your eco impact!',
                style: TextStyle(color: AppTheme.textColor(context).withAlpha(153)),
              ),
            ],
          ),
        ),
      );
    }

    // Show sample of recent meals with eco analysis
    final sampleMeals = mealsState.meals!.take(5).toList();
    
    return Column(
      children: [
        // Today's meal eco summary
        _buildMealEcoSummary(context, ref, sampleMeals),
        const SizedBox(height: 16),
        
        // Individual meal cards with eco advice
        ...sampleMeals.map((meal) => _buildMealEcoCard(context, ref, meal)),
        
        // Button to generate eco activities from meals
        const SizedBox(height: 12),
        _buildGenerateEcoActivitiesButton(context, ref, sampleMeals),
      ],
    );
  }

  Widget _buildMealEcoSummary(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> meals) {
    double totalCarbonPotential = 0.0;
    int sustainableMeals = 0;

    for (final meal in meals) {
      final category = _inferMealCategory(meal);
      final calories = _extractCalories(meal);
      final carbonSaved = EcoService.calculateMealCarbonSaved(category, calories: calories);
      
      if (carbonSaved > 0) {
        totalCarbonPotential += carbonSaved;
        sustainableMeals++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withAlpha(26),
            Colors.blue.withAlpha(26),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Meal Impact',
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$sustainableMeals/${meals.length} sustainable choices',
                  style: TextStyle(color: AppTheme.textColor(context)),
                ),
                Text(
                  '${totalCarbonPotential.toStringAsFixed(2)} kg CO₂ potential savings',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            sustainableMeals > meals.length / 2 ? Icons.eco : Icons.info_outline,
            color: sustainableMeals > meals.length / 2 ? Colors.green : Colors.orange,
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildMealEcoCard(BuildContext context, WidgetRef ref, Map<String, dynamic> meal) {
    final mealName = meal['strMeal'] ?? meal['food_name'] ?? 'Unknown Meal';
    final category = _inferMealCategory(meal);
    final calories = _extractCalories(meal);
    
    final carbonSaved = EcoService.calculateMealCarbonSaved(category, calories: calories);
    final sustainabilityTip = ref.read(mealSustainabilityTipProvider(category));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.textFieldBackground(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: carbonSaved > 0 ? Colors.green.withAlpha(51) : Colors.orange.withAlpha(51),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getCategoryIcon(category),
                color: _getCategoryColor(category),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mealName,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (carbonSaved > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${carbonSaved.toStringAsFixed(1)}kg CO₂ saved',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${category.toUpperCase()} • ${calories ?? 'Unknown'} cal',
            style: TextStyle(
              color: AppTheme.textColor(context).withAlpha(153),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sustainabilityTip,
            style: TextStyle(
              color: AppTheme.textColor(context).withAlpha(204),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateEcoActivitiesButton(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> meals) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _generateEcoActivitiesFromMeals(context, ref, meals),
        icon: const Icon(Icons.eco),
        label: const Text('Generate Eco Activities from Today\'s Meals'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // Helper methods for meal analysis
  String _inferMealCategory(Map<String, dynamic> meal) {
    final mealName = (meal['strMeal'] ?? meal['food_name'] ?? '').toString().toLowerCase();
    final category = meal['strCategory']?.toString().toLowerCase() ?? '';
    
    // Use actual category if available
    if (category.isNotEmpty) {
      // Map your existing categories
      switch (category) {
        case 'beef': return 'beef';
        case 'chicken': return 'chicken';
        case 'pork': return 'pork';
        case 'lamb': return 'lamb';
        case 'goat': return 'goat';
        case 'seafood': return 'seafood';
        case 'vegan': return 'vegan';
        case 'vegetarian': return 'vegetarian';
        case 'pasta': return 'pasta';
        case 'dessert': return 'dessert';
        case 'breakfast': return 'breakfast';
        case 'side': return 'side';
        case 'starter': return 'starter';
        default: return 'miscellaneous';
      }
    }
    
    // Fallback to name-based inference
    if (mealName.contains('beef') || mealName.contains('steak')) return 'beef';
    if (mealName.contains('chicken') || mealName.contains('poultry')) return 'chicken';
    if (mealName.contains('pork') || mealName.contains('bacon')) return 'pork';
    if (mealName.contains('fish') || mealName.contains('salmon')) return 'seafood';
    if (mealName.contains('pasta') || mealName.contains('spaghetti')) return 'pasta';
    if (mealName.contains('vegan')) return 'vegan';
    if (mealName.contains('vegetarian')) return 'vegetarian';
    
    return 'miscellaneous';
  }

  int? _extractCalories(Map<String, dynamic> meal) {
    // Try different calorie field names
    final calorieFields = ['calories', 'nf_calories', 'strCalories', 'kcal'];
    for (final field in calorieFields) {
      final value = meal[field];
      if (value != null) {
        if (value is int) return value;
        if (value is double) return value.round();
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
    }
    return null;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'vegan': return Icons.eco;
      case 'vegetarian': return Icons.nature;
      case 'chicken': return Icons.egg;
      case 'beef': 
      case 'lamb':
      case 'goat': return Icons.agriculture;
      case 'seafood': return Icons.phishing;
      case 'pasta': return Icons.ramen_dining;
      case 'dessert': return Icons.cake;
      case 'breakfast': return Icons.free_breakfast;
      default: return Icons.restaurant;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'vegan': return Colors.green;
      case 'vegetarian': return Colors.lightGreen;
      case 'chicken': return Colors.orange;
      case 'seafood': return Colors.blue;
      case 'pasta': return Colors.amber;
      case 'beef':
      case 'lamb':
      case 'goat': return Colors.red;
      default: return Colors.grey;
    }
  }

  // Generate eco activities from meals
  Future<void> _generateEcoActivitiesFromMeals(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> meals) async {
    final ecoActions = ref.read(ecoActivityActionsProvider);
    int activitiesCreated = 0;
    
    for (final meal in meals) {
      final category = _inferMealCategory(meal);
      final mealName = meal['strMeal'] ?? meal['food_name'] ?? 'Unknown Meal';
      final calories = _extractCalories(meal);
      
      try {
        final activityId = await ecoActions.onMealLogged(
          mealCategory: category,
          mealName: mealName,
          calories: calories,
          isCustomMeal: false,
        );
        
        if (activityId != null) {
          activitiesCreated++;
        }
      } catch (e) {
        // Continue with other meals even if one fails
      }
    }
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generated $activitiesCreated eco activities from your meals!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildTransportationCard(BuildContext context, WidgetRef ref, EcoMetrics ecoMetrics) {
    final healthData = ref.watch(healthDataNotifierProvider);
    final steps = ref.watch(dailyStepsProvider);
    final activeMinutes = ref.watch(activeMinutesProvider);
    final currentPosition = ref.watch(currentPositionNotifierProvider);
    
    // Generate sample eco routes when position is available
    currentPosition.whenData((position) {
      if (position != null) {
        // Create a sample destination for route calculation
        final sampleDestination = Position(
          latitude: position.latitude + 0.01, // ~1km north
          longitude: position.longitude + 0.005, // ~0.5km east
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        
        // Update eco routes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(ecoRoutesNotifierProvider.notifier).updateRoutes(position, sampleDestination);
        });
      }
    });
    
    return GestureDetector(
      onTap: () => _scrollToTransportationSection(context),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_walk, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  const Text(
                    'Active Transportation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              
              // Health data integration
              healthData.when(
                data: (data) => _buildTransportationHealthStats(data, steps, activeMinutes),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const Text('Health data unavailable'),
              ),
              
              const SizedBox(height: 16),
              
              // Transportation carbon impact preview
              _buildTransportationCarbonPreview(steps, activeMinutes),
              
              const SizedBox(height: 12),
              
              // Optimized Google Maps integration
              OptimizedMapFactory.createMap(
                height: 120,
                showRoutes: false, // Disable for preview to save memory
                enableInteraction: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransportationHealthStats(HealthData healthData, int steps, int activeMinutes) {
    // Calculate estimated walking distance from steps (average step = 0.8m)
    final walkingKm = (steps * 0.0008).toStringAsFixed(1);
    
    return Row(
      children: [
        Expanded(
          child: _buildTransportStatCard(
            'Steps Today',
            '$steps',
            Icons.directions_walk,
            Colors.blue[600]!,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTransportStatCard(
            'Distance',
            '$walkingKm km',
            Icons.straighten,
            Colors.green[600]!,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTransportStatCard(
            'Active Min',
            '$activeMinutes',
            Icons.timer,
            Colors.orange[600]!,
          ),
        ),
      ],
    );
  }

  Widget _buildTransportStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransportationCarbonPreview(int steps, int activeMinutes) {
    // Calculate estimated carbon saved from walking vs driving
    final walkingKm = steps * 0.0008;
    final carbonSaved = walkingKm * 0.21; // 0.21 kg CO₂ saved per km vs car
    final bottlesSaved = (carbonSaved / 0.2).round(); // 0.2 kg CO₂ per bottle
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.eco, color: Colors.green[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Impact',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${carbonSaved.toStringAsFixed(2)} kg CO₂ saved',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green[700],
                  ),
                ),
                if (bottlesSaved > 0)
                  Text(
                    '≈ $bottlesSaved bottles prevented',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _scrollToTransportationSection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransportationDetailsScreen(),
      ),
    );
  }

}