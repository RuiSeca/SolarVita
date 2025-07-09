// lib/services/nutritionix_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_analysis.dart';
import '../config/nutritionix_api_config.dart';
import 'package:logger/logger.dart';
import 'food_recognition_service.dart';

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

  // Analyze food from image
  Future<FoodAnalysis> analyzeFoodImage(File image) async {
    try {
      // Step 1: Use vision API to identify food in the image
      final List<String> identifiedFoods =
          await _recognitionService.identifyFoodInImage(image);

      if (identifiedFoods.isEmpty) {
        throw Exception('No food detected in the image');
      }

      _logger.d('Identified foods: $identifiedFoods');

      // Step 2: Search Nutritionix for the top food item
      FoodAnalysis? foundFood;
      Exception? lastError;

      for (String foodName in identifiedFoods) {
        try {
          final FoodAnalysis? nutritionData =
              await getNaturalNutrients(foodName);

          if (nutritionData != null) {
            foundFood = nutritionData;
            break;
          }
        } catch (e) {
          lastError = Exception(
              'No nutritional data found for identified food: $foodName');
          _logger.w('Failed to get data for $foodName: ${e.toString()}');
          continue; // Try next food
        }
      }

      if (foundFood == null) {
        throw lastError ??
            Exception('No nutritional data found for any identified food');
      }

      // Step 3: Create a complete food analysis with the image
      return FoodAnalysis(
        id: foundFood.id,
        foodName: foundFood.foodName,
        calories: foundFood.calories,
        protein: foundFood.protein,
        carbs: foundFood.carbs,
        fat: foundFood.fat,
        ingredients: foundFood.ingredients,
        healthRating: foundFood.healthRating,
        servingSize: foundFood.servingSize,
        image: image,
      );
    } catch (e) {
      _logger.e('Error analyzing food', e);
      rethrow;
    }
  }

  // Search for food using instant search
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

  // Get natural nutrients (detailed nutrition info using natural language)
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

  // Helper method to parse instant search results
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

  // Helper method to parse natural nutrients response
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

  // Health rating algorithm (same as before)
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

  // Debug helper
  void debugApiCredentials() {
    NutritionixApiConfig.logKeyInfo();
  }
}
