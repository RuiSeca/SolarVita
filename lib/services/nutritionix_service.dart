// lib/services/nutritionix_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_analysis.dart';
import '../config/nutritionix_api_config.dart';
import 'package:logger/logger.dart';
import 'food_recognition_service.dart';

// Enhanced data models for multi-ingredient analysis
class MultiIngredientAnalysis {
  final File image;
  final List<IngredientAnalysis> ingredients;
  final CombinedNutrition combinedNutrition;
  final List<String> failedIngredients;
  final double detectionAccuracy;
  final String primaryFood; // Main dish name for compatibility

  MultiIngredientAnalysis({
    required this.image,
    required this.ingredients,
    required this.combinedNutrition,
    required this.failedIngredients,
    required this.detectionAccuracy,
    required this.primaryFood,
  });

  // Convert to legacy FoodAnalysis for backward compatibility
  FoodAnalysis toLegacyFoodAnalysis() {
    return FoodAnalysis(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      foodName: primaryFood,
      calories: combinedNutrition.totalCalories,
      protein: combinedNutrition.totalProtein,
      carbs: combinedNutrition.totalCarbs,
      fat: combinedNutrition.totalFat,
      ingredients: ingredients.map((i) => i.name).toList(),
      healthRating: _calculateOverallHealthRating(),
      servingSize: 'combined serving',
      image: image,
    );
  }

  int _calculateOverallHealthRating() {
    if (ingredients.isEmpty) return 0;
    final avgRating = ingredients
            .map((i) => i.nutritionData.healthRating)
            .reduce((a, b) => a + b) /
        ingredients.length;
    return avgRating.round();
  }
}

class IngredientAnalysis {
  final String name;
  final FoodAnalysis nutritionData;
  final PortionEstimate estimatedPortion;
  final double confidence;

  IngredientAnalysis({
    required this.name,
    required this.nutritionData,
    required this.estimatedPortion,
    required this.confidence,
  });
}

class PortionEstimate {
  final double amount;
  final String unit;
  final String description;

  PortionEstimate({
    required this.amount,
    required this.unit,
    required this.description,
  });
}

class CombinedNutrition {
  final int totalCalories;
  final int totalProtein;
  final int totalCarbs;
  final int totalFat;
  final int ingredientCount;

  CombinedNutrition({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.ingredientCount,
  });
}

class NutritionixService {
  final Logger _logger = Logger();
  final FoodRecognitionService _recognitionService = FoodRecognitionService();

  // Constructor validates API credentials
  NutritionixService() {
    if (!NutritionixApiConfig.isConfigured()) {
      _logger.w(
          'Nutritionix API is not properly configured. Set NUTRITIONIX_APP_ID and NUTRITIONIX_APP_KEY in .env file.');
    }
  }

  // Enhanced analyze food from image - now returns MultiIngredientAnalysis
  Future<MultiIngredientAnalysis> analyzeFoodImageAdvanced(File image) async {
    try {
      // Step 1: Use vision API to identify food in the image
      final List<String> identifiedFoods =
          await _recognitionService.identifyFoodInImage(image);

      if (identifiedFoods.isEmpty) {
        throw Exception('No food detected in the image');
      }

      _logger.d('Identified foods: $identifiedFoods');

      // Step 2: Get nutrition data for each ingredient
      List<IngredientAnalysis> ingredientAnalyses = [];
      List<String> failedIngredients = [];

      for (String foodName in identifiedFoods) {
        try {
          final FoodAnalysis? nutritionData =
              await getNaturalNutrients(foodName);

          if (nutritionData != null) {
            ingredientAnalyses.add(IngredientAnalysis(
              name: foodName,
              nutritionData: nutritionData,
              estimatedPortion: _estimateStandardPortion(foodName),
              confidence: _calculateConfidence(foodName),
            ));
          }
        } catch (e) {
          _logger.w('Failed to get data for $foodName: ${e.toString()}');
          failedIngredients.add(foodName);
        }
      }

      // If no ingredients were successfully analyzed, throw an error
      if (ingredientAnalyses.isEmpty) {
        throw Exception('No nutritional data found for any identified food');
      }

      // Step 3: Calculate combined nutrition
      final combinedNutrition = _calculateCombinedNutrition(ingredientAnalyses);

      // Step 4: Determine primary food name
      final primaryFood =
          _determinePrimaryFood(identifiedFoods, ingredientAnalyses);

      return MultiIngredientAnalysis(
        image: image,
        ingredients: ingredientAnalyses,
        combinedNutrition: combinedNutrition,
        failedIngredients: failedIngredients,
        detectionAccuracy:
            _calculateOverallAccuracy(ingredientAnalyses, failedIngredients),
        primaryFood: primaryFood,
      );
    } catch (e) {
      _logger.e('Error analyzing multiple ingredients', e);
      rethrow;
    }
  }

  // Legacy method - maintains backward compatibility
  Future<FoodAnalysis> analyzeFoodImage(File image) async {
    try {
      final multiAnalysis = await analyzeFoodImageAdvanced(image);
      return multiAnalysis.toLegacyFoodAnalysis();
    } catch (e) {
      _logger.e('Error analyzing food', e);
      rethrow;
    }
  }

  // Estimate standard portion sizes
  PortionEstimate _estimateStandardPortion(String foodName) {
    final foodLower = foodName.toLowerCase();

    // Standard portion sizes database
    final Map<String, PortionEstimate> standardPortions = {
      // Grains & Starches
      'rice':
          PortionEstimate(amount: 150, unit: 'g', description: '1 cup cooked'),
      'pasta':
          PortionEstimate(amount: 125, unit: 'g', description: '1 cup cooked'),
      'bread': PortionEstimate(amount: 30, unit: 'g', description: '1 slice'),
      'quinoa':
          PortionEstimate(amount: 185, unit: 'g', description: '1 cup cooked'),
      'oats':
          PortionEstimate(amount: 40, unit: 'g', description: '1/2 cup dry'),
      'cereal': PortionEstimate(amount: 30, unit: 'g', description: '1 cup'),

      // Proteins
      'chicken': PortionEstimate(
          amount: 100, unit: 'g', description: '1 palm-sized piece'),
      'beef':
          PortionEstimate(amount: 85, unit: 'g', description: '3 oz serving'),
      'fish': PortionEstimate(amount: 100, unit: 'g', description: '1 fillet'),
      'salmon':
          PortionEstimate(amount: 100, unit: 'g', description: '1 fillet'),
      'tuna':
          PortionEstimate(amount: 85, unit: 'g', description: '3 oz serving'),
      'egg': PortionEstimate(amount: 50, unit: 'g', description: '1 large egg'),
      'tofu': PortionEstimate(amount: 85, unit: 'g', description: '3 oz cube'),
      'beans': PortionEstimate(amount: 130, unit: 'g', description: '1/2 cup'),
      'lentils': PortionEstimate(
          amount: 100, unit: 'g', description: '1/2 cup cooked'),

      // Vegetables
      'broccoli':
          PortionEstimate(amount: 80, unit: 'g', description: '1/2 cup'),
      'spinach':
          PortionEstimate(amount: 30, unit: 'g', description: '1 cup raw'),
      'carrot': PortionEstimate(
          amount: 60, unit: 'g', description: '1 medium carrot'),
      'tomato': PortionEstimate(
          amount: 150, unit: 'g', description: '1 medium tomato'),
      'onion': PortionEstimate(
          amount: 110, unit: 'g', description: '1 medium onion'),
      'potato': PortionEstimate(
          amount: 150, unit: 'g', description: '1 medium potato'),
      'lettuce':
          PortionEstimate(amount: 85, unit: 'g', description: '1 cup shredded'),
      'cucumber': PortionEstimate(
          amount: 100, unit: 'g', description: '1/2 cup sliced'),

      // Fruits
      'apple': PortionEstimate(
          amount: 150, unit: 'g', description: '1 medium apple'),
      'banana': PortionEstimate(
          amount: 120, unit: 'g', description: '1 medium banana'),
      'orange': PortionEstimate(
          amount: 130, unit: 'g', description: '1 medium orange'),
      'strawberry':
          PortionEstimate(amount: 150, unit: 'g', description: '1 cup'),
      'blueberry':
          PortionEstimate(amount: 145, unit: 'g', description: '1 cup'),
      'grape': PortionEstimate(amount: 150, unit: 'g', description: '1 cup'),
      'avocado':
          PortionEstimate(amount: 150, unit: 'g', description: '1/2 avocado'),

      // Dairy
      'milk': PortionEstimate(amount: 240, unit: 'ml', description: '1 cup'),
      'yogurt': PortionEstimate(amount: 170, unit: 'g', description: '3/4 cup'),
      'cheese':
          PortionEstimate(amount: 30, unit: 'g', description: '1 oz slice'),

      // Nuts & Seeds
      'nuts':
          PortionEstimate(amount: 30, unit: 'g', description: '1 oz handful'),
      'almonds':
          PortionEstimate(amount: 30, unit: 'g', description: '23 almonds'),
      'peanuts': PortionEstimate(amount: 30, unit: 'g', description: '1 oz'),

      // Oils & Fats
      'oil': PortionEstimate(amount: 15, unit: 'ml', description: '1 tbsp'),
      'butter': PortionEstimate(amount: 14, unit: 'g', description: '1 tbsp'),
    };

    // Try to find an exact or partial match
    for (String key in standardPortions.keys) {
      if (foodLower.contains(key) || key.contains(foodLower)) {
        return standardPortions[key]!;
      }
    }

    // Category-based estimation for unmatched foods
    if (_isVegetable(foodLower)) {
      return PortionEstimate(amount: 80, unit: 'g', description: '1/2 cup');
    } else if (_isFruit(foodLower)) {
      return PortionEstimate(
          amount: 150, unit: 'g', description: '1 medium piece');
    } else if (_isProtein(foodLower)) {
      return PortionEstimate(
          amount: 100, unit: 'g', description: '1 palm-sized serving');
    } else if (_isGrain(foodLower)) {
      return PortionEstimate(
          amount: 125, unit: 'g', description: '1/2 cup cooked');
    }

    // Default portion
    return PortionEstimate(
        amount: 100, unit: 'g', description: 'standard serving');
  }

  // Helper methods for food categorization
  bool _isVegetable(String food) {
    final vegetables = [
      'vegetable',
      'green',
      'leaf',
      'salad',
      'cabbage',
      'pepper',
      'mushroom'
    ];
    return vegetables.any((veg) => food.toLowerCase().contains(veg));
  }

  bool _isFruit(String food) {
    final fruits = [
      'fruit',
      'berry',
      'citrus',
      'melon',
      'peach',
      'pear',
      'plum'
    ];
    return fruits.any((fruit) => food.toLowerCase().contains(fruit));
  }

  bool _isProtein(String food) {
    final proteins = [
      'meat',
      'protein',
      'fish',
      'poultry',
      'seafood',
      'turkey',
      'pork'
    ];
    return proteins.any((protein) => food.toLowerCase().contains(protein));
  }

  bool _isGrain(String food) {
    final grains = ['grain', 'wheat', 'corn', 'barley', 'rye', 'noodle'];
    return grains.any((grain) => food.toLowerCase().contains(grain));
  }

  // Calculate confidence based on food recognition accuracy
  double _calculateConfidence(String foodName) {
    final foodLower = foodName.toLowerCase();

    // High confidence foods (very specific)
    final highConfidenceFoods = [
      'apple',
      'banana',
      'orange',
      'chicken breast',
      'salmon',
      'broccoli',
      'rice',
      'bread',
      'egg',
      'avocado',
      'tomato',
      'carrot'
    ];

    // Medium confidence foods (somewhat specific)
    final mediumConfidenceFoods = [
      'meat',
      'fish',
      'vegetable',
      'fruit',
      'pasta',
      'cheese',
      'nuts'
    ];

    // Low confidence foods (very generic)
    final lowConfidenceFoods = [
      'food',
      'dish',
      'meal',
      'snack',
      'ingredient',
      'item'
    ];

    if (highConfidenceFoods.any((food) => foodLower.contains(food.toString()))) {
      return 0.9;
    } else if (mediumConfidenceFoods.any((food) => foodLower.contains(food.toString()))) {
      return 0.7;
    } else if (lowConfidenceFoods.any((food) => foodLower.contains(food.toString()))) {
      return 0.3;
    }

    // Check for specificity indicators
    if (foodLower.split(' ').length > 2) {
      return 0.8; // More descriptive = higher confidence
    } else if (foodLower.split(' ').length == 2) {
      return 0.6;
    }

    return 0.5; // Default confidence
  }

  // Combine nutrition from all ingredients
  CombinedNutrition _calculateCombinedNutrition(
      List<IngredientAnalysis> ingredients) {
    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var ingredient in ingredients) {
      final nutrition = ingredient.nutritionData;
      final portionMultiplier = ingredient.estimatedPortion.amount /
          100; // Assuming nutrition is per 100g

      totalCalories += (nutrition.calories * portionMultiplier).round();
      totalProtein += nutrition.protein * portionMultiplier;
      totalCarbs += nutrition.carbs * portionMultiplier;
      totalFat += nutrition.fat * portionMultiplier;
    }

    return CombinedNutrition(
      totalCalories: totalCalories,
      totalProtein: totalProtein.round(),
      totalCarbs: totalCarbs.round(),
      totalFat: totalFat.round(),
      ingredientCount: ingredients.length,
    );
  }

  // Determine the primary food name for the meal
  String _determinePrimaryFood(
      List<String> allFoods, List<IngredientAnalysis> successful) {
    if (successful.isEmpty) {
      return allFoods.isNotEmpty ? allFoods.first : 'Mixed Meal';
    }

    // If only one ingredient, use it
    if (successful.length == 1) {
      return successful.first.name;
    }

    // Find the ingredient with highest calories (likely the main dish)
    final mainIngredient = successful.reduce(
        (a, b) => a.nutritionData.calories > b.nutritionData.calories ? a : b);

    // Create a descriptive name
    if (successful.length <= 3) {
      return successful.map((i) => i.name).join(', ');
    } else {
      return '${mainIngredient.name} + ${successful.length - 1} more ingredients';
    }
  }

  // Calculate overall detection accuracy
  double _calculateOverallAccuracy(
      List<IngredientAnalysis> successful, List<String> failed) {
    final total = successful.length + failed.length;
    if (total == 0) return 0.0;

    // Weight by confidence scores
    double weightedSuccess =
        successful.fold(0.0, (sum, ingredient) => sum + ingredient.confidence);
    double totalPossible = (successful.length + failed.length).toDouble();

    return weightedSuccess / totalPossible;
  }

  // Search for food using instant search (existing method - unchanged)
  Future<List<FoodAnalysis>> searchFood(String query) async {
    try {
      _logger.d('Searching for food: $query');

      final uri = Uri.parse('${NutritionixApiConfig.baseUrl}/search/instant');

      final response = await http.get(
        uri.replace(queryParameters: {'query': query}),
        headers: NutritionixApiConfig.headers,
      );

      _logger.d('Search response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.d('Search response structure: ${data.keys.toList()}');

        List<FoodAnalysis> results = [];

        // Process common foods
        if (data['common'] != null) {
          for (var food in data['common']) {
            results.add(_parseInstantSearchFood(food, isCommon: true));
          }
        }

        // Process branded foods
        if (data['branded'] != null) {
          for (var food in data['branded']) {
            results.add(_parseInstantSearchFood(food, isCommon: false));
          }
        }

        _logger.d('Found ${results.length} food results for query: $query');
        return results;
      } else {
        _logger.e(
            'Failed to search foods: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to search foods: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error searching foods', e);
      throw Exception('Error searching for food data: ${e.toString()}');
    }
  }

  // Get natural nutrients (existing method - unchanged)
  Future<FoodAnalysis?> getNaturalNutrients(String query) async {
    try {
      _logger.d('Getting natural nutrients for: $query');

      final uri =
          Uri.parse('${NutritionixApiConfig.baseUrl}/natural/nutrients');

      final requestBody = {
        'query': query,
        'timezone': 'US/Eastern',
      };

      final response = await http.post(
        uri,
        headers: NutritionixApiConfig.headers,
        body: json.encode(requestBody),
      );

      _logger.d('Natural nutrients response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['foods'] != null && data['foods'].isNotEmpty) {
          final foodData = data['foods'][0]; // Take the first result
          return _parseNaturalNutrientsFood(foodData);
        } else {
          _logger.w('No nutrition data found for: $query');
          return null;
        }
      } else {
        _logger.e(
            'Failed to get natural nutrients: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to get nutrition data: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error getting natural nutrients', e);
      throw Exception('Error retrieving nutrition data: ${e.toString()}');
    }
  }

  // Helper method to parse instant search results (existing method - unchanged)
  FoodAnalysis _parseInstantSearchFood(Map<String, dynamic> foodData,
      {required bool isCommon}) {
    try {
      final String foodId = foodData['nix_item_id'] ??
          foodData['food_name'] ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final String foodName = foodData['food_name'] ?? 'Unknown Food';
      final String brandName = foodData['brand_name'] ?? '';

      final displayName =
          brandName.isNotEmpty ? '$brandName $foodName' : foodName;

      // For instant search, we don't get detailed nutrition info
      // This would need a follow-up call to natural/nutrients
      return FoodAnalysis(
        id: foodId,
        foodName: displayName,
        calories: 0, // Will be filled when getting detailed data
        protein: 0,
        carbs: 0,
        fat: 0,
        ingredients: [],
        healthRating: 0,
        servingSize: 'serving',
      );
    } catch (e) {
      _logger.e('Error parsing instant search food data', e);
      throw Exception('Error parsing food data: ${e.toString()}');
    }
  }

  // Helper method to parse natural nutrients response (existing method - unchanged)
  FoodAnalysis _parseNaturalNutrientsFood(Map<String, dynamic> foodData) {
    try {
      final String foodId = foodData['nix_item_id'] ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final String foodName = foodData['food_name'] ?? 'Unknown Food';
      final String brandName = foodData['brand_name'] ?? '';

      final displayName =
          brandName.isNotEmpty ? '$brandName $foodName' : foodName;

      // Extract nutritional data
      final int calories = (foodData['nf_calories'] ?? 0).round();
      final double protein = (foodData['nf_protein'] ?? 0).toDouble();
      final double carbs = (foodData['nf_total_carbohydrate'] ?? 0).toDouble();
      final double fat = (foodData['nf_total_fat'] ?? 0).toDouble();

      // Extract serving information
      final double servingQty = (foodData['serving_qty'] ?? 1).toDouble();
      final String servingUnit = foodData['serving_unit'] ?? 'serving';
      final String servingSize = '$servingQty $servingUnit';

      // Try to extract ingredients if available
      List<String> ingredients = [];
      if (foodData['ingredients'] != null) {
        ingredients = List<String>.from(foodData['ingredients']);
      }

      // Calculate health rating
      final int healthRating =
          _calculateHealthRating(calories, protein, carbs, fat);

      return FoodAnalysis(
        id: foodId,
        foodName: displayName,
        calories: calories,
        protein: protein.round(),
        carbs: carbs.round(),
        fat: fat.round(),
        ingredients: ingredients,
        healthRating: healthRating,
        servingSize: servingSize,
      );
    } catch (e) {
      _logger.e('Error parsing natural nutrients food data', e);
      throw Exception('Error parsing nutrition data: ${e.toString()}');
    }
  }

  // Health rating algorithm (existing method - unchanged)
  int _calculateHealthRating(
      int calories, double protein, double carbs, double fat) {
    if (calories <= 0) {
      return 0;
    }

    // Calculate percentages of macronutrients
    final totalGrams = protein + carbs + fat;
    if (totalGrams <= 0) {
      return 0;
    }

    final proteinPercentage = protein / totalGrams * 100;
    final carbsPercentage = carbs / totalGrams * 100;
    final fatPercentage = fat / totalGrams * 100;

    int rating = 0;

    // High protein foods (>25%) get a bonus
    if (proteinPercentage > 25) {
      rating += 2;
    } else if (proteinPercentage > 15) {
      rating += 1;
    }

    // Balanced macros are good
    if (proteinPercentage > 20 && carbsPercentage > 20 && fatPercentage > 20) {
      rating += 1;
    }

    // Penalize for very high fat
    if (fatPercentage > 60) {
      rating -= 1;
    }

    // Adjust for calories
    if (calories < 300) {
      rating += 1;
    } else if (calories > 600) {
      rating -= 1;
    }

    return rating.clamp(0, 5);
  }

  // Debug helper (existing method - unchanged)
  void debugApiCredentials() {
    NutritionixApiConfig.logKeyInfo();
  }
}
