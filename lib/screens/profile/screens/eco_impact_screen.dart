import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/riverpod/eco_provider.dart';
import '../../../providers/riverpod/meal_provider.dart';
import '../../../providers/riverpod/health_data_provider.dart';
import '../../../models/eco/eco_metrics.dart';
import '../../../models/eco/carbon_activity.dart';
import '../../../models/health/health_data.dart';
import '../../../services/database/eco_service.dart';
import '../../../widgets/common/optimized_map_factory.dart';
import '../supporter/transportation_details_screen.dart';

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


  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final ecoMetricsAsync = ref.watch(userEcoMetricsProvider);
        final carbonLast30DaysAsync = ref.watch(carbonSavedLast30DaysProvider);
        final mealsState = ref.watch(mealNotifierProvider);

        return Scaffold(
          backgroundColor: AppTheme.surfaceColor(context),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userEcoMetricsProvider);
              ref.invalidate(todaysActivitiesProvider);
              ref.invalidate(recentEcoActivitiesProvider);
              ref.invalidate(carbonSavedLast30DaysProvider);
              // Add a small delay to show the refresh indicator
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: true,
                snap: false,
                backgroundColor: AppTheme.surfaceColor(context),
                elevation: 0,
                iconTheme: IconThemeData(color: AppTheme.textColor(context)),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Eco Impact',
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(left: 72, bottom: 16), // More space for back arrow
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green.withValues(alpha: 0.1),
                          Colors.blue.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(72, 16, 16, 16), // Left padding for back arrow
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 32), // Reduced space since title has proper padding
                            Text(
                              'Track your environmental impact',
                              style: TextStyle(
                                color: AppTheme.textColor(context).withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.eco,
                                  size: 16,
                                  color: Colors.green.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Every action counts',
                                  style: TextStyle(
                                    color: Colors.green.withValues(alpha: 0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
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
              ),
              ecoMetricsAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: Center(
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
                ),
                data: (ecoMetrics) => SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Today's Impact - Clear daily focus
                      _buildTodaysImpactCard(context, ref),
                      const SizedBox(height: 16),

                      // Today's Activities Breakdown
                      _buildTodaysActivitiesSection(context, ref),
                      const SizedBox(height: 24),

                      // Achievements & All-Time Stats
                      _buildAchievementsSection(context, ecoMetrics),
                      const SizedBox(height: 24),

                      // Detailed Daily Sections
                      _buildDetailedDailySection(context, ref, mealsState),
                      const SizedBox(height: 24),

                      // Progress Tracking
                      _buildProgressSection(context, ref, carbonLast30DaysAsync),
                      const SizedBox(height: 32),

                      // Eco Tips & Actions
                      _buildActionsAndTipsSection(context),
                      const SizedBox(height: 100), // Extra space for FAB
                    ]),
                  ),
                ),
              ),
            ],
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
              Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
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
          ].map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                tip,
                style: TextStyle(
                  color: AppTheme.textColor(context).withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Recent activities section
  Widget _buildRecentActivitiesSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<EcoActivity>> recentActivitiesAsync,
  ) {
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
                        style: TextStyle(
                          color: AppTheme.textColor(context).withAlpha(153),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: activities
                  .take(5)
                  .map(
                    (activity) => Container(
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
                              color: Theme.of(
                                context,
                              ).primaryColor.withAlpha(26),
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
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  // Last 30 days summary
  Widget _buildLast30DaysSummary(
    BuildContext context,
    AsyncValue<double> carbonLast30DaysAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.withAlpha(26), Colors.blue.withAlpha(26)],
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
                    const SnackBar(
                      content: Text('Activity logged successfully!'),
                    ),
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
                    const SnackBar(
                      content: Text('Activity logged successfully!'),
                    ),
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
                // Use real calculation based on user's historical recycling patterns
                final userMetrics = ref.read(userEcoMetricsProvider).value;
                final avgRecyclingCarbonSaved = userMetrics != null 
                    ? (userMetrics.totalCarbonSaved / (userMetrics.currentStreak > 0 ? userMetrics.currentStreak : 1)) * 0.1 // 10% comes from recycling typically
                    : 0.3; // Default fallback if no historical data
                
                final ecoActivity = EcoActivity(
                  id: '',
                  userId: ref.read(ecoServiceProvider).currentUserId!,
                  type: EcoActivityType.waste,
                  activity: 'recycling',
                  carbonSaved: avgRecyclingCarbonSaved,
                  date: DateTime.now(),
                );
                await actions.addActivity(ecoActivity);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Activity logged successfully!'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActivityButton(
    BuildContext context,
    WidgetRef ref,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
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


  // Today's Meals section with eco advice
  Widget _buildTodaysMealsSection(
    BuildContext context,
    WidgetRef ref,
    MealState mealsState,
  ) {
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

  Widget _buildMealsList(
    BuildContext context,
    WidgetRef ref,
    MealState mealsState,
  ) {
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
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(153),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show today's meals with eco analysis, or recent meals if none today
    final today = DateTime.now();
    final todaysMeals = mealsState.meals!.where((meal) {
      if (meal['timestamp'] != null) {
        try {
          final mealDate = DateTime.parse(meal['timestamp'].toString());
          return mealDate.year == today.year && 
                 mealDate.month == today.month && 
                 mealDate.day == today.day;
        } catch (e) {
          return false;
        }
      }
      return false;
    }).toList();
    
    // Use today's meals if available, otherwise show recent meals
    final mealsToShow = todaysMeals.isNotEmpty ? todaysMeals : mealsState.meals!.take(5).toList();

    return Column(
      children: [
        // Today's meal eco summary
        _buildMealEcoSummary(context, ref, mealsToShow),
        const SizedBox(height: 16),

        // Individual meal cards with eco advice
        ...mealsToShow.map((meal) => _buildMealEcoCard(context, ref, meal)),

        // Button to generate eco activities from meals
        const SizedBox(height: 12),
        _buildGenerateEcoActivitiesButton(context, ref, mealsToShow),
      ],
    );
  }

  Widget _buildMealEcoSummary(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> meals,
  ) {
    double totalCarbonPotential = 0.0;
    int sustainableMeals = 0;

    for (final meal in meals) {
      final category = _inferMealCategory(meal);
      final calories = _extractCalories(meal);
      final carbonSaved = EcoService.calculateMealCarbonSaved(
        category,
        calories: calories,
      );

      if (carbonSaved > 0) {
        totalCarbonPotential += carbonSaved;
        sustainableMeals++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.withAlpha(26), Colors.blue.withAlpha(26)],
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
            sustainableMeals > meals.length / 2
                ? Icons.eco
                : Icons.info_outline,
            color: sustainableMeals > meals.length / 2
                ? Colors.green
                : Colors.orange,
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildMealEcoCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> meal,
  ) {
    final mealName = meal['strMeal'] ?? meal['food_name'] ?? 'Unknown Meal';
    final category = _inferMealCategory(meal);
    final calories = _extractCalories(meal);

    final carbonSaved = EcoService.calculateMealCarbonSaved(
      category,
      calories: calories,
    );
    final sustainabilityTip = ref.read(mealSustainabilityTipProvider(category));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.textFieldBackground(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: carbonSaved > 0
              ? Colors.green.withAlpha(51)
              : Colors.orange.withAlpha(51),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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

  Widget _buildGenerateEcoActivitiesButton(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> meals,
  ) {
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
    final mealName = (meal['strMeal'] ?? meal['food_name'] ?? '')
        .toString()
        .toLowerCase();
    final category = meal['strCategory']?.toString().toLowerCase() ?? '';

    // Use actual category if available
    if (category.isNotEmpty) {
      // Map your existing categories
      switch (category) {
        case 'beef':
          return 'beef';
        case 'chicken':
          return 'chicken';
        case 'pork':
          return 'pork';
        case 'lamb':
          return 'lamb';
        case 'goat':
          return 'goat';
        case 'seafood':
          return 'seafood';
        case 'vegan':
          return 'vegan';
        case 'vegetarian':
          return 'vegetarian';
        case 'pasta':
          return 'pasta';
        case 'dessert':
          return 'dessert';
        case 'breakfast':
          return 'breakfast';
        case 'side':
          return 'side';
        case 'starter':
          return 'starter';
        default:
          return 'miscellaneous';
      }
    }

    // Fallback to name-based inference
    if (mealName.contains('beef') || mealName.contains('steak')) return 'beef';
    if (mealName.contains('chicken') || mealName.contains('poultry')) {
      return 'chicken';
    }
    if (mealName.contains('pork') || mealName.contains('bacon')) return 'pork';
    if (mealName.contains('fish') || mealName.contains('salmon')) {
      return 'seafood';
    }
    if (mealName.contains('pasta') || mealName.contains('spaghetti')) {
      return 'pasta';
    }
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
      case 'vegan':
        return Icons.eco;
      case 'vegetarian':
        return Icons.nature;
      case 'chicken':
        return Icons.egg;
      case 'beef':
      case 'lamb':
      case 'goat':
        return Icons.agriculture;
      case 'seafood':
        return Icons.phishing;
      case 'pasta':
        return Icons.ramen_dining;
      case 'dessert':
        return Icons.cake;
      case 'breakfast':
        return Icons.free_breakfast;
      default:
        return Icons.restaurant;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'vegan':
        return Colors.green;
      case 'vegetarian':
        return Colors.lightGreen;
      case 'chicken':
        return Colors.orange;
      case 'seafood':
        return Colors.blue;
      case 'pasta':
        return Colors.amber;
      case 'beef':
      case 'lamb':
      case 'goat':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Generate eco activities from meals
  Future<void> _generateEcoActivitiesFromMeals(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> meals,
  ) async {
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
          content: Text(
            'Generated $activitiesCreated eco activities from your meals!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildTransportationCard(
    BuildContext context,
    WidgetRef ref,
    EcoMetrics ecoMetrics,
  ) {
    final healthData = ref.watch(healthDataNotifierProvider);
    final steps = ref.watch(dailyStepsProvider);
    final activeMinutes = ref.watch(activeMinutesProvider);

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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Health data integration
              healthData.when(
                data: (data) =>
                    _buildTransportationHealthStats(data, steps, activeMinutes),
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

  Widget _buildTransportationHealthStats(
    HealthData healthData,
    int steps,
    int activeMinutes,
  ) {
    // Calculate walking distance from steps using average step length
    // Default to 0.8m (average human step length)
    const userStepLength = 0.0008; // meters per step
    final walkingKm = (steps * userStepLength).toStringAsFixed(1);

    return Row(
      children: [
        Expanded(
          child: _buildTransportStatCard(
            'Steps Today',
            '$steps',
            Icons.directions_walk,
            Colors.blue[600] ?? Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTransportStatCard(
            'Distance',
            '$walkingKm km',
            Icons.straighten,
            Colors.green[600] ?? Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTransportStatCard(
            'Active Min',
            '$activeMinutes',
            Icons.timer,
            Colors.orange[600] ?? Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildTransportStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransportationCarbonPreview(int steps, int activeMinutes) {
    // Use real user data for carbon calculations
    final userMetrics = ref.read(userEcoMetricsProvider).value;
    final userStepLength = 0.0008; // Default step length - could be made user-specific
    final walkingKm = steps * userStepLength;
    
    // Calculate carbon saved based on user's actual transportation patterns
    final avgCarbonPerKm = userMetrics != null && userMetrics.transportCarbonSaved > 0
        ? userMetrics.transportCarbonSaved / (userMetrics.currentStreak > 0 ? userMetrics.currentStreak : 1)
        : 0.21; // Default kg CO₂ saved per km vs car
    
    final carbonSaved = walkingKm * avgCarbonPerKm;
    final bottlesSaved = EcoMetrics.carbonToBottles(carbonSaved);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50] ?? Colors.green.shade50, Colors.green[100] ?? Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200] ?? Colors.green),
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
                  style: TextStyle(fontSize: 13, color: Colors.green[700]),
                ),
                if (bottlesSaved > 0)
                  Text(
                    '≈ $bottlesSaved bottles prevented',
                    style: TextStyle(fontSize: 11, color: Colors.green[600]),
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

  Widget _buildTodaysImpactCard(BuildContext context, WidgetRef ref) {
    final todaysCarbon = ref.watch(todaysCarbonSavedProvider);
    final todaysBottles = ref.watch(todaysBottlesSavedProvider);
    final todaysActivityCount = ref.watch(todaysActivityCountProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
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
              Icon(Icons.today, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'Today\'s Impact',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: todaysCarbon.when(
                  data: (carbon) => _buildTodaysStat(
                    icon: Icons.co2,
                    value: '${carbon.toStringAsFixed(1)}kg',
                    label: 'CO₂ Saved',
                    color: Colors.white,
                  ),
                  loading: () => _buildTodaysStatLoading(),
                  error: (_, __) => _buildTodaysStatError(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: todaysBottles.when(
                  data: (bottles) => _buildTodaysStat(
                    icon: Icons.water_drop,
                    value: '$bottles',
                    label: 'Bottles Equivalent',
                    color: Colors.white,
                  ),
                  loading: () => _buildTodaysStatLoading(),
                  error: (_, __) => _buildTodaysStatError(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: todaysActivityCount.when(
                  data: (count) => _buildTodaysStat(
                    icon: Icons.eco,
                    value: '$count',
                    label: 'Eco Actions',
                    color: Colors.white,
                  ),
                  loading: () => _buildTodaysStatLoading(),
                  error: (_, __) => _buildTodaysStatError(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.9),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTodaysStatLoading() {
    return Column(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text('Loading...', style: TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }

  Widget _buildTodaysStatError() {
    return Column(
      children: [
        Icon(Icons.error_outline, color: Colors.white, size: 16),
        const SizedBox(height: 4),
        Text('--', style: TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildTodaysActivitiesSection(BuildContext context, WidgetRef ref) {
    final todaysActivitiesByType = ref.watch(todaysActivitiesByTypeProvider);
    final todaysCarbonByType = ref.watch(todaysCarbonByTypeProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Activities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 12),
            todaysActivitiesByType.when(
              data: (activitiesByType) {
                if (activitiesByType.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.eco,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No eco activities today yet',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start with a meal or walk!',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return todaysCarbonByType.when(
                  data: (carbonByType) => Column(
                    children: activitiesByType.entries.map((entry) {
                      final type = entry.key;
                      final activities = entry.value;
                      final carbon = carbonByType[type] ?? 0.0;
                      
                      return _buildActivityTypeCard(type, activities.length, carbon);
                    }).toList(),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => Text('Error loading carbon data'),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => Text('Error loading activities'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTypeCard(EcoActivityType type, int count, double carbon) {
    IconData icon;
    Color color;
    String title;
    
    switch (type) {
      case EcoActivityType.food:
        icon = Icons.restaurant;
        color = Colors.green;
        title = 'Food';
        break;
      case EcoActivityType.transport:
        icon = Icons.directions_walk;
        color = Colors.blue;
        title = 'Transport';
        break;
      case EcoActivityType.energy:
        icon = Icons.energy_savings_leaf;
        color = Colors.orange;
        title = 'Energy';
        break;
      case EcoActivityType.waste:
        icon = Icons.recycling;
        color = Colors.purple;
        title = 'Waste';
        break;
      case EcoActivityType.consumption:
        icon = Icons.water_drop;
        color = Colors.blue;
        title = 'Consumption';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '$count activities',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${carbon.toStringAsFixed(1)}kg CO₂',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context, EcoMetrics ecoMetrics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stars, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Achievements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAchievementCard(
                    icon: Icons.local_fire_department,
                    value: '${ecoMetrics.currentStreak}',
                    label: 'Day Streak',
                    color: Colors.red,
                    subtitle: 'Keep it up!',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAchievementCard(
                    icon: Icons.stars,
                    value: '${ecoMetrics.ecoScore}',
                    label: 'Eco Points',
                    color: Colors.amber,
                    subtitle: 'Total earned',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAchievementCard(
                    icon: Icons.co2,
                    value: '${ecoMetrics.totalCarbonSaved.toStringAsFixed(1)}kg',
                    label: 'Total CO₂ Saved',
                    color: Colors.green,
                    subtitle: 'All time',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAchievementCard(
                    icon: Icons.water_drop,
                    value: '${ecoMetrics.plasticBottlesSaved}',
                    label: 'Bottles Saved',
                    color: Colors.blue,
                    subtitle: 'Plastic reduction',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedDailySection(BuildContext context, WidgetRef ref, MealState mealsState) {
    return Column(
      children: [
        Container(
          key: _mealsKey,
          child: _buildTodaysMealsSection(context, ref, mealsState),
        ),
        const SizedBox(height: 16),
        _buildTransportationCard(context, ref, ref.read(userEcoMetricsProvider).value!),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context, WidgetRef ref, AsyncValue<double> carbonLast30DaysAsync) {
    final recentActivitiesAsync = ref.watch(recentEcoActivitiesProvider);
    
    return Column(
      children: [
        _buildLast30DaysSummary(context, carbonLast30DaysAsync),
        const SizedBox(height: 16),
        _buildRecentActivitiesSection(context, ref, recentActivitiesAsync),
      ],
    );
  }

  Widget _buildActionsAndTipsSection(BuildContext context) {
    return _buildTipsSection(context);
  }
}
