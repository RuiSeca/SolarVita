import 'package:flutter/material.dart';
import '../../models/exercise/exercise_log.dart';
import '../../services/exercises/exercise_tracking_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';

class ExerciseMealInsights extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>>? todaysMeals;
  
  const ExerciseMealInsights({
    super.key,
    this.todaysMeals,
  });

  @override
  State<ExerciseMealInsights> createState() => _ExerciseMealInsightsState();
}

class _ExerciseMealInsightsState extends State<ExerciseMealInsights> {
  final ExerciseTrackingService _trackingService = ExerciseTrackingService();
  bool _isLoading = true;
  List<InsightRecommendation> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadDataAndGenerateInsights();
  }

  Future<void> _loadDataAndGenerateInsights() async {
    setState(() => _isLoading = true);
    
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // Get today's exercise logs
      final allLogs = await _trackingService.getAllLogs();
      final todaysLogs = allLogs.where((log) {
        return log.date.isAfter(startOfDay) && log.date.isBefore(endOfDay);
      }).toList();
      
      // Generate intelligent recommendations
      final recommendations = await _generateRecommendations(todaysLogs, widget.todaysMeals);
      
      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<List<InsightRecommendation>> _generateRecommendations(
    List<ExerciseLog> exerciseLogs,
    Map<String, List<Map<String, dynamic>>>? meals,
  ) async {
    final recommendations = <InsightRecommendation>[];
    
    // Calculate current nutrition from meals
    final currentNutrition = _calculateCurrentNutrition(meals);
    
    // Calculate exercise demands
    final exerciseDemands = _calculateExerciseDemands(exerciseLogs);
    
    // Generate different types of recommendations
    recommendations.addAll(_generateProteinRecommendations(currentNutrition, exerciseDemands));
    recommendations.addAll(_generateHydrationRecommendations(exerciseDemands));
    recommendations.addAll(_generateTimingRecommendations(exerciseLogs, meals));
    recommendations.addAll(_generateRecoveryRecommendations(exerciseLogs));
    
    // Sort by priority and return top 3
    recommendations.sort((a, b) => b.priority.compareTo(a.priority));
    return recommendations.take(3).toList();
  }

  Map<String, double> _calculateCurrentNutrition(Map<String, List<Map<String, dynamic>>>? meals) {
    if (meals == null) return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    
    double calories = 0, protein = 0, carbs = 0, fat = 0;
    
    for (final mealList in meals.values) {
      for (final meal in mealList) {
        if (meal['isSuggested'] != true && meal['nutritionFacts'] != null) {
          final nutrition = meal['nutritionFacts'];
          calories += _parseNutrition(nutrition['calories']);
          protein += _parseNutrition(nutrition['protein']);
          carbs += _parseNutrition(nutrition['carbs']);
          fat += _parseNutrition(nutrition['fat']);
        }
      }
    }
    
    return {'calories': calories, 'protein': protein, 'carbs': carbs, 'fat': fat};
  }

  double _parseNutrition(String? value) {
    if (value == null) return 0;
    return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  }

  Map<String, dynamic> _calculateExerciseDemands(List<ExerciseLog> logs) {
    if (logs.isEmpty) {
      return {
        'caloriesBurned': 0.0,
        'proteinNeeded': 0.0,
        'intensity': 'none',
        'primaryType': 'none',
        'totalSets': 0,
        'totalVolume': 0.0,
      };
    }
    
    double totalVolume = 0;
    int totalSets = 0;
    final exerciseTypes = <String, int>{};
    
    for (final log in logs) {
      totalSets += log.sets.length;
      totalVolume += log.sets.fold(0.0, (sum, set) => sum + (set.weight * set.reps));
      
      final type = _categorizeExercise(log.exerciseName);
      exerciseTypes[type] = (exerciseTypes[type] ?? 0) + 1;
    }
    
    // Calculate calories burned (using our improved formula)
    final estimatedTimeMinutes = totalSets * 2.5;
    final baseCalories = estimatedTimeMinutes * 4;
    final volumeBonus = totalVolume * 0.01;
    final caloriesBurned = (baseCalories + volumeBonus).clamp(0, 800);
    
    // Determine intensity
    String intensity = 'light';
    if (totalSets >= 20 || totalVolume >= 3000) {
      intensity = 'intense';
    } else if (totalSets >= 12 || totalVolume >= 1500) {
      intensity = 'moderate';
    }
    
    // Find primary exercise type
    String primaryType = 'general';
    int maxCount = 0;
    exerciseTypes.forEach((type, count) {
      if (count > maxCount) {
        maxCount = count;
        primaryType = type;
      }
    });
    
    // Calculate protein needs (higher for strength training)
    double proteinMultiplier = primaryType == 'strength' ? 1.8 : 1.2; // g per kg body weight
    double estimatedBodyWeight = 70; // Default assumption
    double proteinNeeded = estimatedBodyWeight * proteinMultiplier;
    
    return {
      'caloriesBurned': caloriesBurned,
      'proteinNeeded': proteinNeeded,
      'intensity': intensity,
      'primaryType': primaryType,
      'totalSets': totalSets,
      'totalVolume': totalVolume,
    };
  }

  String _categorizeExercise(String exerciseName) {
    final name = exerciseName.toLowerCase();
    
    if (name.contains('bench') || name.contains('press') || name.contains('squat') || name.contains('deadlift')) {
      return 'strength';
    } else if (name.contains('run') || name.contains('bike') || name.contains('cardio')) {
      return 'cardio';
    } else if (name.contains('yoga') || name.contains('stretch')) {
      return 'flexibility';
    }
    return 'general';
  }

  List<InsightRecommendation> _generateProteinRecommendations(
    Map<String, double> nutrition, 
    Map<String, dynamic> demands,
  ) {
    final recommendations = <InsightRecommendation>[];
    final currentProtein = nutrition['protein'] ?? 0;
    final neededProtein = demands['proteinNeeded'] ?? 0;
    final primaryType = demands['primaryType'];
    
    if (primaryType == 'strength' && currentProtein < neededProtein * 0.7) {
      recommendations.add(InsightRecommendation(
        type: InsightType.nutrition,
        title: tr(context, 'protein_boost_needed'),
        description: tr(context, 'strength_training_protein_message')
            .replaceAll('{current}', currentProtein.toStringAsFixed(0))
            .replaceAll('{target}', neededProtein.toStringAsFixed(0)),
        actionText: tr(context, 'add_protein_rich_meal'),
        icon: Icons.fitness_center,
        color: Colors.orange,
        priority: 90,
      ));
    } else if (currentProtein < neededProtein * 0.5) {
      recommendations.add(InsightRecommendation(
        type: InsightType.nutrition,
        title: tr(context, 'protein_gap_detected'),
        description: tr(context, 'general_protein_message'),
        actionText: tr(context, 'explore_protein_meals'),
        icon: Icons.restaurant,
        color: Colors.green,
        priority: 70,
      ));
    }
    
    return recommendations;
  }

  List<InsightRecommendation> _generateHydrationRecommendations(Map<String, dynamic> demands) {
    final recommendations = <InsightRecommendation>[];
    final caloriesBurned = demands['caloriesBurned'] ?? 0;
    final intensity = demands['intensity'];
    
    if (intensity == 'intense' || caloriesBurned > 300) {
      recommendations.add(InsightRecommendation(
        type: InsightType.hydration,
        title: tr(context, 'hydration_boost_needed'),
        description: tr(context, 'intense_workout_hydration_message')
            .replaceAll('{calories}', caloriesBurned.toStringAsFixed(0)),
        actionText: tr(context, 'increase_water_intake'),
        icon: Icons.water_drop,
        color: Colors.blue,
        priority: 80,
      ));
    }
    
    return recommendations;
  }

  List<InsightRecommendation> _generateTimingRecommendations(
    List<ExerciseLog> logs,
    Map<String, List<Map<String, dynamic>>>? meals,
  ) {
    final recommendations = <InsightRecommendation>[];
    
    if (logs.isNotEmpty && meals != null) {
      final lastWorkoutTime = logs.map((log) => log.date).reduce((a, b) => a.isAfter(b) ? a : b);
      final now = DateTime.now();
      final timeSinceWorkout = now.difference(lastWorkoutTime).inMinutes;
      
      // Post-workout nutrition window (30-60 minutes)
      if (timeSinceWorkout <= 60) {
        final hasPostWorkoutMeal = meals.values.any((mealList) => 
          mealList.any((meal) => 
            meal['timestamp'] != null &&
            DateTime.parse(meal['timestamp']).isAfter(lastWorkoutTime)
          )
        );
        
        if (!hasPostWorkoutMeal) {
          recommendations.add(InsightRecommendation(
            type: InsightType.timing,
            title: tr(context, 'post_workout_window'),
            description: tr(context, 'post_workout_nutrition_message'),
            actionText: tr(context, 'plan_recovery_meal'),
            icon: Icons.schedule,
            color: Colors.amber,
            priority: 85,
          ));
        }
      }
    }
    
    return recommendations;
  }

  List<InsightRecommendation> _generateRecoveryRecommendations(List<ExerciseLog> logs) {
    final recommendations = <InsightRecommendation>[];
    
    if (logs.isNotEmpty) {
      final totalSets = logs.fold(0, (sum, log) => sum + log.sets.length);
      
      if (totalSets >= 25) {
        recommendations.add(InsightRecommendation(
          type: InsightType.recovery,
          title: tr(context, 'recovery_focus_needed'),
          description: tr(context, 'high_volume_recovery_message')
              .replaceAll('{sets}', totalSets.toString()),
          actionText: tr(context, 'plan_rest_day'),
          icon: Icons.bed,
          color: Colors.purple,
          priority: 75,
        ));
      }
    }
    
    return recommendations;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_recommendations.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
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
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                tr(context, 'smart_nutrition_insights'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._recommendations.map((rec) => _buildRecommendationCard(rec)),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(InsightRecommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: recommendation.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: recommendation.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: recommendation.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              recommendation.icon,
              color: recommendation.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.title,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation.description,
                  style: TextStyle(
                    color: AppTheme.textColor(context).withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  recommendation.actionText,
                  style: TextStyle(
                    color: recommendation.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.eco,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'all_balanced'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            tr(context, 'great_nutrition_balance'),
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

enum InsightType { nutrition, hydration, timing, recovery }

class InsightRecommendation {
  final InsightType type;
  final String title;
  final String description;
  final String actionText;
  final IconData icon;
  final Color color;
  final int priority;

  InsightRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.actionText,
    required this.icon,
    required this.color,
    required this.priority,
  });
}