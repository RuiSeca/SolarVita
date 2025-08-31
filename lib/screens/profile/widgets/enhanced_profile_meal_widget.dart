import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:math' as math;
import '../../../utils/translation_helper.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/riverpod/unified_meal_provider.dart';
import '../screens/meals_details_screen.dart';
import '../../health/meals/meal_plan_screen.dart';
import '../../health/meals/meal_detail_screen.dart';
import 'package:logger/logger.dart';

/// Enhanced profile meal widget that shows actual meals from the meal plan
class EnhancedProfileMealWidget extends ConsumerWidget {
  const EnhancedProfileMealWidget({super.key});
  
  static final Logger _logger = Logger();

  void _navigateToMealDetail(BuildContext context, Map<String, dynamic> meal) {
    // Extract meal data and navigate to detail screen
    final nutritionFacts = meal['nutritionFacts'] != null
        ? Map<String, dynamic>.from(meal['nutritionFacts'])
        : {'calories': '0', 'protein': '0g', 'carbs': '0g', 'fat': '0g'};

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealDetailScreen(
          mealId: meal['id']?.toString() ?? '',
          mealTitle: meal['titleKey'] ?? meal['name'] ?? 'Meal',
          imagePath: meal['imagePath'] ?? meal['image'],
          calories: meal['calories']?.toString() ?? nutritionFacts['calories']?.toString() ?? '0',
          nutritionFacts: nutritionFacts,
          ingredients: List<String>.from(meal['ingredients'] ?? []),
          measures: List<String>.from(meal['measures'] ?? []),
          instructions: List<String>.from(meal['instructions'] ?? []),
          area: meal['area'] ?? '',
          category: meal['category'] ?? '',
          isVegan: meal['isVegan'] ?? false,
          isFavorite: false, // We can enhance this later
          onFavoriteToggle: null, // We can enhance this later
        ),
      ),
    );
  }

  Widget _buildMealPreview(Map<String, List<Map<String, dynamic>>> todaysMeals) {
    // Filter out empty and suggested-only meal times
    final activeMealTimes = <String>[];
    todaysMeals.forEach((mealTime, meals) {
      final realMeals = meals.where((meal) => meal['isSuggested'] != true).toList();
      if (realMeals.isNotEmpty) {
        activeMealTimes.add(mealTime);
      }
    });

    if (activeMealTimes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show each meal time separately
        ...activeMealTimes.take(2).map((mealTime) => _buildMealTimeSection(mealTime, todaysMeals[mealTime]!)),
        
        // Show "more meal times" indicator if there are more than 2
        if (activeMealTimes.length > 2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.more_horiz, size: 14, color: Colors.green[600]),
                const SizedBox(width: 4),
                Text(
                  '${activeMealTimes.length - 2} more meal time${activeMealTimes.length > 3 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMealTimeSection(String mealTime, List<Map<String, dynamic>> meals) {
    final realMeals = meals.where((meal) => meal['isSuggested'] != true).toList();
    if (realMeals.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal time header with count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getMealTimeIcon(mealTime),
                  size: 12,
                  color: Colors.green[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${_getMealTimeDisplayName(mealTime)} (${realMeals.length})',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          
          // Horizontal scrollable meal images for this meal time
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: math.min(realMeals.length, 3), // Show max 3 meals per time
              itemBuilder: (context, index) {
                final meal = realMeals[index];
                final mealWithTime = Map<String, dynamic>.from(meal);
                mealWithTime['mealTime'] = mealTime;
                
                return Container(
                  width: 50,
                  margin: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      _navigateToMealDetail(context, mealWithTime);
                    },
                    child: Stack(
                      children: [
                        _buildCompactMealImage(mealWithTime),
                        // Meal name overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(6),
                                bottomRight: Radius.circular(6),
                              ),
                            ),
                            child: Text(
                              meal['titleKey'] ?? meal['name'] ?? 'Meal',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMealTimeIcon(String mealTime) {
    switch (mealTime.toLowerCase()) {
      case 'breakfast':
        return Icons.wb_sunny;
      case 'lunch':
        return Icons.wb_sunny_outlined;
      case 'dinner':
        return Icons.nights_stay;
      case 'snacks':
        return Icons.cookie;
      default:
        return Icons.restaurant_menu;
    }
  }

  Widget _buildCompactMealImage(Map<String, dynamic> meal) {
    final imagePath = meal['imagePath'] ?? meal['image'];
    final mealName = meal['titleKey'] ?? meal['name'] ?? 'Meal';
    
    if (imagePath == null || imagePath.isEmpty) {
      return _buildCompactFallbackMealImage(mealName);
    }

    final isLocalFile = imagePath.startsWith('/') || imagePath.startsWith('file://');
    
    if (isLocalFile) {
      final file = File(imagePath.replaceFirst('file://', ''));
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            file,
            height: 50,
            width: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildCompactFallbackMealImage(mealName),
          ),
        );
      }
    }

    // Network image
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        imagePath,
        height: 50,
        width: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildCompactFallbackMealImage(mealName),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactFallbackMealImage(String mealName) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.3),
            Colors.green.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          mealName.isNotEmpty ? mealName[0].toUpperCase() : 'M',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
      ),
    );
  }



  String _getMealTimeDisplayName(String mealTime) {
    switch (mealTime.toLowerCase()) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snacks':
        return 'Snacks';
      default:
        return mealTime;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealState = ref.watch(unifiedMealProvider);
    final todaysMeals = ref.watch(todaysMealsProvider);
    final nutrition = ref.watch(todaysNutritionProvider);
    final mealCount = ref.watch(todaysMealCountProvider);

    // Debug logging
    _logger.d('EnhancedProfileMealWidget - mealCount: $mealCount');
    _logger.d('EnhancedProfileMealWidget - todaysMeals keys: ${todaysMeals.keys}');
    todaysMeals.forEach((mealTime, meals) {
      _logger.d('EnhancedProfileMealWidget - $mealTime: ${meals.length} meals');
      for (final meal in meals) {
        _logger.d('  - ${meal['titleKey'] ?? meal['name']} (suggested: ${meal['isSuggested']})');
      }
    });

    if (mealState.isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(context, 'todays_meals'),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          if (mealCount > 0) ...[
                            Text(
                              '$mealCount meals • ${nutrition['calories']?.toInt() ?? 0} cal',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green[600],
                              ),
                            ),
                          ] else ...[
                            Text(
                              tr(context, 'no_meals_planned_today'),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MealsDetailsScreen(),
                          ),
                        ).then((_) {
                          // Refresh meal data when coming back
                          ref.read(unifiedMealProvider.notifier).refreshMealData();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.green[600],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Meal preview section or action button
                if (mealCount > 0) ...[
                  const SizedBox(height: 12),
                  _buildMealPreview(todaysMeals),
                ] else ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MealPlanScreen(),
                        ),
                      ).then((_) {
                        ref.read(unifiedMealProvider.notifier).refreshMealData();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline, color: Colors.green[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Log New Meal',
                            style: TextStyle(
                              color: Colors.green[600], 
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
      ),
    );
  }
}