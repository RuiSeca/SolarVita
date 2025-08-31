import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/riverpod/unified_meal_provider.dart';
import '../../../providers/riverpod/eco_provider.dart';
import '../../../services/database/eco_service.dart';
import '../../../models/eco/eco_metrics.dart';
import '../../health/meals/meal_plan_screen.dart';

class MealsDetailsScreen extends ConsumerStatefulWidget {
  const MealsDetailsScreen({super.key});

  @override
  ConsumerState<MealsDetailsScreen> createState() => _MealsDetailsScreenState();
}

class _MealsDetailsScreenState extends ConsumerState<MealsDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final unifiedMealState = ref.watch(unifiedMealProvider);
    final ecoMetrics = ref.watch(userEcoMetricsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(
          'Meals & Sustainability',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textColor(context)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.textColor(context)),
            onPressed: () {
              ref.read(unifiedMealProvider.notifier).refreshMealData();
              ref.invalidate(userEcoMetricsProvider);
            },
          ),
        ],
      ),
      body: ecoMetrics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading data: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userEcoMetricsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (metrics) => unifiedMealState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : unifiedMealState.hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading meal data: ${unifiedMealState.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(unifiedMealProvider.notifier).refreshMealData(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero section with today's meal overview
                        _buildHeroSection(context, ref, metrics, unifiedMealState),
                        const SizedBox(height: 24),

                        // Today's meals detailed list
                        _buildTodaysMealsSection(context, ref, unifiedMealState),
                        const SizedBox(height: 24),

                        // Sustainability analysis
                        _buildSustainabilityAnalysis(context, ref, unifiedMealState, metrics),
                        const SizedBox(height: 24),

                        // Meal categories breakdown
                        _buildMealCategoriesSection(context, ref, unifiedMealState),
                        const SizedBox(height: 24),

                        // Weekly meal trends
                        _buildWeeklyTrendsSection(context, ref, metrics),
                        const SizedBox(height: 24),

                        // Nutrition vs sustainability balance
                        _buildNutritionSustainabilitySection(context, ref, unifiedMealState),
                        const SizedBox(height: 24),

                        // Achievements and goals
                        _buildMealAchievementsSection(context, ref, metrics, unifiedMealState),
                        const SizedBox(height: 24),

                        // Sustainable eating tips
                        _buildSustainableEatingTips(context),
                        const SizedBox(height: 24),

                        // Action buttons
                        _buildActionButtonsSection(context, ref, unifiedMealState),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    WidgetRef ref,
    EcoMetrics metrics,
    UnifiedMealState mealState,
  ) {
    final todaysMeals = ref.read(unifiedMealProvider.notifier).getAllMealsAsList();
    final nutrition = ref.read(unifiedMealProvider.notifier).getTodaysNutrition();
    
    double todaysCarbonSaved = 0.0;
    int sustainableMeals = 0;
    int totalCalories = nutrition['calories']?.round() ?? 0;

    for (final meal in todaysMeals) {
      final category = _inferMealCategory(meal);
      final calories = _extractCalories(meal) ?? 0;

      final carbonSaved = EcoService.calculateMealCarbonSaved(
        category,
        calories: calories,
      );
      if (carbonSaved > 0) {
        todaysCarbonSaved += carbonSaved;
        sustainableMeals++;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.8),
            Colors.green.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text(
                'Today\'s Meals',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildHeroStatCard(
                  '${todaysMeals.length}',
                  'Meals Logged',
                  Icons.restaurant_menu,
                  Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHeroStatCard(
                  '$sustainableMeals',
                  'Sustainable',
                  Icons.eco,
                  Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildHeroStatCard(
                  '${todaysCarbonSaved.toStringAsFixed(1)} kg',
                  'CO₂ Saved',
                  Icons.co2,
                  Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHeroStatCard(
                  '$totalCalories',
                  'Total Calories',
                  Icons.local_fire_department,
                  Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysMealsSection(
    BuildContext context,
    WidgetRef ref,
    UnifiedMealState mealState,
  ) {
    final todaysMeals = ref.read(unifiedMealProvider.notifier).getAllMealsAsList();
    if (todaysMeals.isEmpty) {
      return _buildEmptyMealsCard(context);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.textFieldBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Meals',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ...todaysMeals.map(
            (meal) => _buildDetailedMealCard(context, ref, meal),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMealsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.textFieldBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.restaurant_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No meals logged today',
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging your meals to track your eco impact!',
              style: TextStyle(
                color: AppTheme.textColor(context).withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedMealCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> meal,
  ) {
    final mealName = meal['titleKey'] ?? meal['name'] ?? meal['strMeal'] ?? meal['food_name'] ?? 'Unknown Meal';
    final category = _inferMealCategory(meal);
    final calories = _extractCalories(meal);
    final carbonSaved = EcoService.calculateMealCarbonSaved(
      category,
      calories: calories,
    );
    final sustainabilityTip = ref.read(mealSustainabilityTipProvider(category));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: carbonSaved > 0
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: carbonSaved > 0
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealName,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${category.toUpperCase()} • ${calories ?? 'Unknown'} cal',
                      style: TextStyle(
                        color: AppTheme.textColor(
                          context,
                        ).withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (carbonSaved > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${carbonSaved.toStringAsFixed(1)}kg CO₂',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Sustainability analysis
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.textFieldBackground(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      carbonSaved > 0 ? Icons.eco : Icons.info_outline,
                      color: carbonSaved > 0 ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sustainability Impact',
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  sustainabilityTip,
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

  Widget _buildSustainabilityAnalysis(
    BuildContext context,
    WidgetRef ref,
    UnifiedMealState mealState,
    EcoMetrics metrics,
  ) {
    final todaysMeals = ref.read(unifiedMealProvider.notifier).getAllMealsAsList();
    final categoryBreakdown = <String, int>{};
    double totalCarbonSaved = 0.0;

    for (final meal in todaysMeals) {
      final category = _inferMealCategory(meal);
      categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + 1;

      final calories = _extractCalories(meal);
      final carbonSaved = EcoService.calculateMealCarbonSaved(
        category,
        calories: calories,
      );
      totalCarbonSaved += carbonSaved;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.1),
            Colors.teal.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.green[700], size: 24),
              const SizedBox(width: 12),
              Text(
                'Sustainability Analysis',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Your meal choices today have made a positive environmental impact:',
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildAnalysisCard(
                  context,
                  '🌱',
                  '${totalCarbonSaved.toStringAsFixed(1)} kg',
                  'CO₂ Saved Today',
                  Colors.green[600]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalysisCard(
                  context,
                  '♻️',
                  '${EcoMetrics.carbonToBottles(totalCarbonSaved)}',
                  'Bottles Prevented',
                  Colors.blue[600]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildAnalysisCard(
                  context,
                  '🥗',
                  '${(categoryBreakdown['vegan'] ?? 0) + (categoryBreakdown['vegetarian'] ?? 0)}',
                  'Plant-Based Meals',
                  Colors.green[700]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalysisCard(
                  context,
                  '📊',
                  '${metrics.ecoScore}',
                  'Eco Score Points',
                  Colors.amber[600]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(
    BuildContext context,
    String emoji,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textColor(context).withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMealCategoriesSection(
    BuildContext context,
    WidgetRef ref,
    UnifiedMealState mealState,
  ) {
    final todaysMeals = ref.read(unifiedMealProvider.notifier).getAllMealsAsList();
    final categoryBreakdown = <String, Map<String, dynamic>>{};

    for (final meal in todaysMeals) {
      final category = _inferMealCategory(meal);
      if (!categoryBreakdown.containsKey(category)) {
        categoryBreakdown[category] = {
          'count': 0,
          'carbonSaved': 0.0,
          'calories': 0,
        };
      }

      categoryBreakdown[category]!['count'] += 1;

      final calories = _extractCalories(meal) ?? 0;
      categoryBreakdown[category]!['calories'] += calories;

      final carbonSaved = EcoService.calculateMealCarbonSaved(
        category,
        calories: calories,
      );
      categoryBreakdown[category]!['carbonSaved'] += carbonSaved;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.textFieldBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meal Categories Breakdown',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (categoryBreakdown.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No meal data available for analysis',
                  style: TextStyle(
                    color: AppTheme.textColor(context).withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ] else ...[
            ...categoryBreakdown.entries.map((entry) {
              final category = entry.key;
              final data = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getCategoryColor(category).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      color: _getCategoryColor(category),
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.toUpperCase(),
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${data['count']} meals • ${data['calories']} cal • ${(data['carbonSaved'] as double).toStringAsFixed(1)}kg CO₂',
                            style: TextStyle(
                              color: AppTheme.textColor(
                                context,
                              ).withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendsSection(
    BuildContext context,
    WidgetRef ref,
    EcoMetrics metrics,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.textFieldBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.purple[600], size: 24),
              const SizedBox(width: 12),
              Text(
                'Weekly Trends',
                style: TextStyle(
                  color: AppTheme.textColor(context),
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
                child: _buildTrendCard(
                  context,
                  'Meal CO₂ Saved',
                  '${metrics.mealCarbonSaved.toStringAsFixed(1)} kg',
                  Icons.eco,
                  Colors.green[600]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrendCard(
                  context,
                  'Sustainable Meals',
                  '${(metrics.mealCarbonSaved * 3).round()}', // Estimated count
                  Icons.restaurant,
                  Colors.orange[600]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildTrendCard(
                  context,
                  'Current Streak',
                  '${metrics.currentStreak} days',
                  Icons.local_fire_department,
                  Colors.red[600]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrendCard(
                  context,
                  'Best Week',
                  '12.3 kg', // Mock data
                  Icons.star,
                  Colors.amber[600]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textColor(context).withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSustainabilitySection(
    BuildContext context,
    WidgetRef ref,
    UnifiedMealState mealState,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.balance, color: Colors.blue[700], size: 24),
              const SizedBox(width: 12),
              Text(
                'Nutrition vs Sustainability',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Balancing nutritional needs with environmental impact:',
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),

          // Balance indicators
          _buildBalanceIndicator(
            'Protein Sources',
            0.7,
            Colors.red,
            'Consider more plant-based proteins',
          ),
          const SizedBox(height: 12),
          _buildBalanceIndicator(
            'Vegetable Intake',
            0.9,
            Colors.green,
            'Excellent plant diversity!',
          ),
          const SizedBox(height: 12),
          _buildBalanceIndicator(
            'Processed Foods',
            0.3,
            Colors.orange,
            'Great job minimizing processed foods',
          ),
          const SizedBox(height: 12),
          _buildBalanceIndicator(
            'Local/Seasonal',
            0.6,
            Colors.blue,
            'Try incorporating more seasonal ingredients',
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceIndicator(
    String label,
    double value,
    Color color,
    String tip,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 6,
        ),
        const SizedBox(height: 4),
        Text(
          tip,
          style: TextStyle(
            color: AppTheme.textColor(context).withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMealAchievementsSection(
    BuildContext context,
    WidgetRef ref,
    EcoMetrics metrics,
    UnifiedMealState mealState,
  ) {
    final todaysMeals = ref.read(unifiedMealProvider.notifier).getAllMealsAsList();
    final achievements = _calculateMealAchievements(metrics, mealState, todaysMeals);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.1),
            Colors.orange.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber[700], size: 24),
              const SizedBox(width: 12),
              Text(
                'Meal Achievements',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (achievements.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Keep logging sustainable meals to unlock achievements!',
                      style: TextStyle(
                        color: AppTheme.textColor(
                          context,
                        ).withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...achievements.map(
              (achievement) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        achievement['emoji'] as String,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement['title'] as String,
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            achievement['description'] as String,
                            style: TextStyle(
                              color: AppTheme.textColor(
                                context,
                              ).withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSustainableEatingTips(BuildContext context) {
    final tips = [
      {
        'icon': Icons.eco,
        'title': 'Choose Plant-Based Options',
        'description':
            'Plant-based meals typically have 50-90% lower carbon footprint than meat-based meals.',
        'color': Colors.green,
      },
      {
        'icon': Icons.location_on,
        'title': 'Eat Local & Seasonal',
        'description':
            'Local produce reduces transportation emissions and supports your community.',
        'color': Colors.blue,
      },
      {
        'icon': Icons.recycling,
        'title': 'Minimize Food Waste',
        'description':
            'Plan portions carefully and use leftovers creatively to reduce waste.',
        'color': Colors.orange,
      },
      {
        'icon': Icons.water_drop,
        'title': 'Consider Water Footprint',
        'description':
            'Some foods require significantly more water to produce than others.',
        'color': Colors.cyan,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.textFieldBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber[600], size: 24),
              const SizedBox(width: 12),
              Text(
                'Sustainable Eating Tips',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...tips.map(
            (tip) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (tip['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (tip['color'] as Color).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    tip['icon'] as IconData,
                    color: tip['color'] as Color,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip['title'] as String,
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tip['description'] as String,
                          style: TextStyle(
                            color: AppTheme.textColor(
                              context,
                            ).withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsSection(
    BuildContext context,
    WidgetRef ref,
    UnifiedMealState mealState,
  ) {
    final todaysMeals = ref.read(unifiedMealProvider.notifier).getAllMealsAsList();

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: todaysMeals.isNotEmpty
                ? () =>
                      _generateEcoActivitiesFromMeals(context, ref, todaysMeals)
                : null,
            icon: const Icon(Icons.eco),
            label: const Text('Generate Eco Activities from Meals'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MealPlanScreen(),
                ),
              ).then((_) {
                // Refresh meal data when coming back from meal plan
                ref.read(unifiedMealProvider.notifier).refreshMealData();
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Log New Meal'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods
  String _inferMealCategory(Map<String, dynamic> meal) {
    final mealName = (meal['strMeal'] ?? meal['food_name'] ?? '')
        .toString()
        .toLowerCase();
    final category = meal['strCategory']?.toString().toLowerCase() ?? '';

    if (category.isNotEmpty) {
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

  List<Map<String, dynamic>> _calculateMealAchievements(
    EcoMetrics metrics,
    UnifiedMealState mealState,
    List<Map<String, dynamic>> todaysMeals,
  ) {
    final achievements = <Map<String, dynamic>>[];

    if (metrics.mealCarbonSaved >= 1.0) {
      achievements.add({
        'emoji': '🌱',
        'title': 'Eco Eater',
        'description':
            'Saved ${metrics.mealCarbonSaved.toStringAsFixed(1)}kg CO₂ through sustainable meal choices!',
      });
    }

    final plantBasedMeals = todaysMeals.where((meal) {
      final category = _inferMealCategory(meal);
      return category == 'vegan' || category == 'vegetarian';
    }).length;

    if (plantBasedMeals >= 2) {
      achievements.add({
        'emoji': '🥗',
        'title': 'Plant Power',
        'description': 'Had $plantBasedMeals plant-based meals today!',
      });
    }

    if (metrics.currentStreak >= 7) {
      achievements.add({
        'emoji': '🔥',
        'title': 'Sustainability Streak',
        'description':
            'Maintained sustainable eating for ${metrics.currentStreak} days!',
      });
    }

    if (todaysMeals.length >= 5) {
      achievements.add({
        'emoji': '📝',
        'title': 'Tracking Champion',
        'description':
            'Logged ${todaysMeals.length} meals today - great tracking!',
      });
    }

    return achievements;
  }

  Future<void> _generateEcoActivitiesFromMeals(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> meals,
  ) async {
    final ecoActions = ref.read(ecoActivityActionsProvider);
    int activitiesCreated = 0;

    for (final meal in meals) {
      final category = _inferMealCategory(meal);
      final mealName = meal['titleKey'] ?? meal['name'] ?? meal['strMeal'] ?? meal['food_name'] ?? 'Unknown Meal';
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
}
