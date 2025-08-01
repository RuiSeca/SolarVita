import 'package:flutter/foundation.dart';
import '../../models/food/food_analysis.dart';
import '../database/eco_service.dart';

/// Service to automatically generate eco activities from meal logging
class MealEcoIntegrationService {
  static final MealEcoIntegrationService _instance =
      MealEcoIntegrationService._internal();
  factory MealEcoIntegrationService() => _instance;
  MealEcoIntegrationService._internal();

  final EcoService _ecoService = EcoService();

  /// Auto-generate eco activity when a meal is logged
  /// This should be called from meal logging workflows
  Future<String?> onMealLogged({
    required String mealCategory,
    String? mealName,
    int? calories,
    bool isCustomMeal = false,
    bool autoGenerate = true,
  }) async {
    if (!autoGenerate) return null;

    try {
      // Calculate potential carbon savings
      final carbonSaved = EcoService.calculateMealCarbonSaved(
        mealCategory,
        calories: calories,
        isCustomMeal: isCustomMeal,
      );

      // Only create eco activity if there are meaningful savings
      if (carbonSaved > 0.1) {
        // Minimum threshold of 100g CO₂
        final activityId = await _ecoService.logMealActivity(
          mealCategory,
          calories: calories,
          isCustomMeal: isCustomMeal,
          mealName: mealName,
          notes: 'Auto-generated from meal logging',
        );

        debugPrint(
          '✅ Eco activity created for meal: $mealName (${carbonSaved.toStringAsFixed(2)}kg CO₂ saved)',
        );
        return activityId;
      } else {
        debugPrint(
          'ℹ️ No eco activity created for $mealCategory meal (insufficient carbon savings)',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Failed to create eco activity for meal: $e');
      return null;
    }
  }

  /// Process meal from food analysis (from image recognition)
  Future<String?> onFoodAnalysisLogged(FoodAnalysis foodAnalysis) async {
    try {
      // Determine meal category from food analysis
      final mealCategory = _categorizeFoodAnalysis(foodAnalysis);

      return await onMealLogged(
        mealCategory: mealCategory,
        mealName: foodAnalysis.foodName,
        calories: foodAnalysis.calories,
        isCustomMeal: false,
      );
    } catch (e) {
      debugPrint('❌ Failed to process food analysis for eco activity: $e');
      return null;
    }
  }

  /// Categorize food analysis into meal categories
  String _categorizeFoodAnalysis(FoodAnalysis foodAnalysis) {
    final foodName = foodAnalysis.foodName.toLowerCase();
    final ingredients = foodAnalysis.ingredients
        .map((i) => i.toLowerCase())
        .toList();

    // Check for meat types
    if (_containsAny(foodName, ingredients, [
      'beef',
      'steak',
      'hamburger',
      'ground beef',
    ])) {
      return 'beef';
    }
    if (_containsAny(foodName, ingredients, [
      'chicken',
      'poultry',
      'wing',
      'breast',
    ])) {
      return 'chicken';
    }
    if (_containsAny(foodName, ingredients, [
      'pork',
      'bacon',
      'ham',
      'sausage',
    ])) {
      return 'pork';
    }
    if (_containsAny(foodName, ingredients, ['lamb', 'mutton'])) {
      return 'lamb';
    }
    if (_containsAny(foodName, ingredients, [
      'fish',
      'salmon',
      'tuna',
      'shrimp',
      'crab',
      'lobster',
    ])) {
      return 'seafood';
    }

    // Check for vegetarian/vegan
    if (_isVeganMeal(foodName, ingredients)) {
      return 'vegan';
    }
    if (_isVegetarianMeal(foodName, ingredients)) {
      return 'vegetarian';
    }

    // Check for specific meal types
    if (_containsAny(foodName, ingredients, [
      'pasta',
      'spaghetti',
      'noodle',
      'macaroni',
    ])) {
      return 'pasta';
    }
    if (_containsAny(foodName, ingredients, [
      'dessert',
      'cake',
      'cookie',
      'ice cream',
      'chocolate',
    ])) {
      return 'dessert';
    }
    if (_containsAny(foodName, ingredients, [
      'breakfast',
      'cereal',
      'pancake',
      'waffle',
      'toast',
    ])) {
      return 'breakfast';
    }

    // Default to miscellaneous
    return 'miscellaneous';
  }

  /// Check if food contains any of the specified terms
  bool _containsAny(
    String foodName,
    List<String> ingredients,
    List<String> terms,
  ) {
    for (String term in terms) {
      if (foodName.contains(term) ||
          ingredients.any((ingredient) => ingredient.contains(term))) {
        return true;
      }
    }
    return false;
  }

  /// Check if meal is vegan
  bool _isVeganMeal(String foodName, List<String> ingredients) {
    final veganIndicators = [
      'vegan',
      'plant based',
      'tofu',
      'tempeh',
      'seitan',
    ];
    final nonVeganIndicators = [
      'meat',
      'chicken',
      'beef',
      'pork',
      'fish',
      'dairy',
      'cheese',
      'milk',
      'egg',
      'butter',
    ];

    // If explicitly marked as vegan
    if (_containsAny(foodName, ingredients, veganIndicators)) {
      return true;
    }

    // If contains non-vegan ingredients
    if (_containsAny(foodName, ingredients, nonVeganIndicators)) {
      return false;
    }

    // Check if it's primarily plant-based
    final plantIndicators = [
      'vegetable',
      'fruit',
      'grain',
      'bean',
      'lentil',
      'quinoa',
      'rice',
      'salad',
    ];
    return _containsAny(foodName, ingredients, plantIndicators);
  }

  /// Check if meal is vegetarian (but not vegan)
  bool _isVegetarianMeal(String foodName, List<String> ingredients) {
    final vegetarianIndicators = ['vegetarian', 'cheese', 'milk', 'egg'];
    final meatIndicators = [
      'meat',
      'chicken',
      'beef',
      'pork',
      'fish',
      'seafood',
    ];

    // If contains meat, not vegetarian
    if (_containsAny(foodName, ingredients, meatIndicators)) {
      return false;
    }

    // If explicitly vegetarian or contains dairy/eggs
    return _containsAny(foodName, ingredients, vegetarianIndicators);
  }

  /// Get carbon savings potential for a meal category
  double getCarbonSavingsPotential(String mealCategory, {int? calories}) {
    return EcoService.calculateMealCarbonSaved(
      mealCategory,
      calories: calories,
      isCustomMeal: calories != null,
    );
  }

  /// Get sustainability tips for meal categories
  String getSustainabilityTip(String mealCategory) {
    switch (mealCategory.toLowerCase()) {
      case 'beef':
      case 'lamb':
      case 'goat':
        return 'Consider choosing chicken, fish, or plant-based alternatives to reduce your carbon footprint!';
      case 'pork':
        return 'Great choice! Pork has a lower carbon footprint than beef. Try chicken or fish next time for even more savings!';
      case 'chicken':
        return 'Good choice! Chicken has a much lower carbon footprint than red meat.';
      case 'seafood':
        return 'Excellent! Seafood is generally a sustainable protein choice.';
      case 'vegan':
        return 'Amazing! Vegan meals have the lowest carbon footprint. You\'re making a real difference!';
      case 'vegetarian':
        return 'Great choice! Vegetarian meals significantly reduce your environmental impact.';
      case 'pasta':
        return 'Nice! Pasta-based meals are typically lower in carbon emissions.';
      default:
        return 'Every sustainable meal choice makes a difference for our planet!';
    }
  }
}
