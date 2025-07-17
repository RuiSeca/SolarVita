// lib/services/recipe_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/mealdb_api_config.dart';

class MealDBService {
  static String get baseUrl => MealDBApiConfig.baseUrl;
  static const int timeoutSeconds = 12; // Increased timeout for larger data loads
  static const int maxRetries = 2; // Keep retries low for responsiveness
  
  // Single persistent HTTP client for connection reuse
  static final http.Client _client = http.Client();
  
  // Test method to verify API connection
  Future<bool> testApiConnection() async {
    try {
      final response = await _makeRequest('$baseUrl/latest.php');
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<http.Response> _makeRequest(String url, {int retryCount = 0}) async {
    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'SolarVita/1.0',
          'Accept': 'application/json',
          'Connection': 'keep-alive', // Enable connection reuse
        },
      ).timeout(Duration(seconds: timeoutSeconds));
      return response;
    } on SocketException catch (e) {
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1))); // Reduced retry delay
        return _makeRequest(url, retryCount: retryCount + 1);
      }
      throw Exception('Network error: ${e.message}. Please check your internet connection or try using a VPN if you\'re on a restricted network.');
    } on TimeoutException {
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1))); // Reduced retry delay
        return _makeRequest(url, retryCount: retryCount + 1);
      }
      throw Exception('Request timeout. Please check your internet connection.');
    } catch (e) {
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1))); // Reduced retry delay
        return _makeRequest(url, retryCount: retryCount + 1);
      }
      throw Exception('Request failed: $e');
    }
  }

  Future<Map<String, dynamic>> getMealById(String id) async {
    final response = await _makeRequest('$baseUrl/lookup.php?i=$id');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null && data['meals'].isNotEmpty) {
        return _formatMealData(data['meals'][0]);
      }
    }
    throw Exception('Failed to load meal: Status ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> searchMeals(String query) async {
    final response = await _makeRequest('$baseUrl/search.php?s=$query');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null) {
        return List<Map<String, dynamic>>.from(
          data['meals'].map((meal) => _formatMealData(meal)),
        );
      }
      return [];
    }
    throw Exception('Failed to search meals: Status ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getMealsByCategory(String category) async {
    final response = await _makeRequest('$baseUrl/filter.php?c=$category');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null) {
        List<Map<String, dynamic>> meals = [];
        final mealList = data['meals'] as List; // Get ALL meals, no artificial limit
        
        // Process meals in batches for better performance while loading all
        const batchSize = 10;
        for (int i = 0; i < mealList.length; i += batchSize) {
          final batch = mealList.skip(i).take(batchSize).toList();
          
          // Use parallel requests for each batch
          final futures = batch.map((meal) async {
            try {
              return await getMealById(meal['idMeal']);
            } catch (e) {
              return null; // Return null for failed requests
            }
          }).toList();
          
          final results = await Future.wait(futures);
          
          // Filter out null results and add to meals list
          for (var meal in results) {
            if (meal != null) {
              meals.add(meal);
            }
          }
        }
        
        return meals;
      }
      return [];
    }
    throw Exception('Failed to load category meals: Status ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _makeRequest('$baseUrl/categories.php');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['categories']);
      }
      throw Exception(
          'Failed to load categories: Status ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  /// Get latest meals (V2 Premium feature)
  Future<List<Map<String, dynamic>>> getLatestMeals() async {
    try {
      final response = await _makeRequest('$baseUrl/latest.php');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          return List<Map<String, dynamic>>.from(
            data['meals'].map((meal) => _formatMealData(meal)),
          );
        }
        return [];
      }
      throw Exception('Failed to load latest meals: Status ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to load latest meals: $e');
    }
  }

  /// Get all meals by fetching from multiple categories (for "All" tab)
  Future<List<Map<String, dynamic>>> getAllMeals({int limit = 200}) async {
    try {
      List<Map<String, dynamic>> allMeals = [];
      
      // Get meals from all major categories for variety
      final allCategories = [
        'Chicken', 'Beef', 'Seafood', 'Pasta', 'Vegetarian', 'Pork',
        'Lamb', 'Dessert', 'Breakfast', 'Side', 'Starter', 'Vegan',
        'Goat', 'Miscellaneous'
      ];
      
      // Process categories in smaller batches to avoid overwhelming the API
      const batchSize = 4;
      for (int i = 0; i < allCategories.length; i += batchSize) {
        if (allMeals.length >= limit) break;
        
        final categoryBatch = allCategories.skip(i).take(batchSize).toList();
        
        final futures = categoryBatch.map((category) async {
          try {
            final categoryMeals = await getMealsByCategory(category);
            return categoryMeals; // Return ALL meals from each category
          } catch (e) {
            return <Map<String, dynamic>>[];
          }
        }).toList();
        
        final results = await Future.wait(futures);
        
        // Combine all results
        for (var categoryMeals in results) {
          for (var meal in categoryMeals) {
            if (allMeals.length >= limit) break;
            // Avoid duplicates
            if (!allMeals.any((existing) => existing['id']?.toString() == meal['id']?.toString())) {
              allMeals.add(meal);
            }
          }
          if (allMeals.length >= limit) break;
        }
      }
      
      // Shuffle the meals to provide variety
      allMeals.shuffle();
      return allMeals;
      
    } catch (e) {
      throw Exception('Failed to load all meals: $e');
    }
  }

  /// Get random meals for variety
  Future<List<Map<String, dynamic>>> getRandomMeals({int count = 10}) async {
    try {
      List<Map<String, dynamic>> randomMeals = [];
      
      for (int i = 0; i < count; i++) {
        try {
          final response = await _makeRequest('$baseUrl/random.php');
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['meals'] != null && data['meals'].isNotEmpty) {
              final meal = _formatMealData(data['meals'][0]);
              // Avoid duplicates
              if (!randomMeals.any((existing) => existing['id']?.toString() == meal['id']?.toString())) {
                randomMeals.add(meal);
              }
            }
          }
        } catch (e) {
          // Failed to get random meal, continuing with next attempt
          continue;
        }
      }
      
      return randomMeals;
    } catch (e) {
      throw Exception('Failed to load random meals: $e');
    }
  }

  Map<String, dynamic> _formatMealData(Map<String, dynamic> meal) {
    
    // Extract ingredients and measurements
    List<Map<String, String>> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final ingredient = meal['strIngredient$i'];
      final measure = meal['strMeasure$i'];

      if (ingredient != null &&
          ingredient.toString().trim().isNotEmpty &&
          measure != null &&
          measure.toString().trim().isNotEmpty) {
        ingredients.add({
          'name': ingredient.toString().trim(),
          'measure': measure.toString().trim(),
        });
      }
    }

    // Format instructions into steps
    List<String> instructions = (meal['strInstructions']?.toString() ?? '')
        .split(RegExp(r'\r\n|\n|\r'))
        .where((step) => step.trim().isNotEmpty)
        .map((step) => step.trim())
        .toList();

    // Calculate approximate calories (this is a rough estimation)
    int approximateCalories = _calculateApproximateCalories(ingredients);

    // Format to match your app's data structure
    final formattedMeal = {
      'id': meal['idMeal'],
      'titleKey': meal['strMeal'],
      'category': meal['strCategory'],
      'area': meal['strArea'],
      'instructions': instructions,
      'ingredients': ingredients.map((ing) => ing['name']!).toList(), // Convert to List<String>
      'measures': ingredients.map((ing) => ing['measure']!).toList(), // Convert to List<String>
      'imagePath': meal['strMealThumb'],
      'calories': '$approximateCalories kcal',
      'prepTime': '30 min', // MealDB doesn't provide prep time
      'servings': _estimateServings(ingredients), // Estimated serving size
      'difficulty': _estimateDifficulty(instructions, ingredients),
      'cookTime': _estimateCookTime(instructions, meal['strCategory']),
      'isVegan': _checkIfVegan(ingredients),
      'isFavorite': false,
      'nutritionFacts': {
        'calories': '$approximateCalories',
        'caloriesPerServing': '${(approximateCalories / _estimateServings(ingredients)).round()}',
        'protein': '${approximateCalories ~/ 20}g', // Rough estimation
        'proteinPerServing': '${(approximateCalories ~/ 20 / _estimateServings(ingredients)).round()}g',
        'carbs': '${approximateCalories ~/ 15}g', // Rough estimation
        'carbsPerServing': '${(approximateCalories ~/ 15 / _estimateServings(ingredients)).round()}g',
        'fat': '${approximateCalories ~/ 30}g', // Rough estimation
        'fatPerServing': '${(approximateCalories ~/ 30 / _estimateServings(ingredients)).round()}g',
      },
      'tags': meal['strTags']?.split(',') ?? [],
      'youtubeUrl': meal['strYoutube'],
    };
    return formattedMeal;
  }

  bool _checkIfVegan(List<Map<String, String>> ingredients) {
    final nonVeganIngredients = [
      'chicken',
      'beef',
      'meat',
      'fish',
      'pork',
      'lamb',
      'egg',
      'milk',
      'cream',
      'cheese',
      'butter',
      'yogurt',
      'honey'
    ];

    for (var ingredient in ingredients) {
      final ingredientName = ingredient['name']?.toLowerCase() ?? '';
      for (var nonVegan in nonVeganIngredients) {
        if (ingredientName.contains(nonVegan)) {
          return false;
        }
      }
    }
    return true;
  }

  int _calculateApproximateCalories(List<Map<String, String>> ingredients) {
    // This is a very rough estimation
    int totalCalories = 0;

    for (var ingredient in ingredients) {
      String measure = (ingredient['measure'] ?? '').toLowerCase();
      String name = (ingredient['name'] ?? '').toLowerCase();

      // Extract numeric value from measure
      double quantity = double.tryParse(
              RegExp(r'[\d.]+').firstMatch(measure)?.group(0) ?? '0') ??
          0;

      // Very rough calorie estimations per unit
      if (measure.contains('g')) {
        if (name.contains('meat') || name.contains('cheese')) {
          totalCalories += (quantity * 2).round();
        } else if (name.contains('oil') || name.contains('butter')) {
          totalCalories += (quantity * 9).round();
        } else {
          totalCalories += (quantity * 1.5).round();
        }
      } else if (measure.contains('cup')) {
        totalCalories += (quantity * 200).round();
      } else if (measure.contains('tbsp')) {
        totalCalories += (quantity * 45).round();
      } else if (measure.contains('tsp')) {
        totalCalories += (quantity * 15).round();
      }
    }

    return totalCalories;
  }

  int _estimateServings(List<Map<String, String>> ingredients) {
    // Estimate servings based on quantity of main ingredients
    int estimatedServings = 4; // Default serving size
    
    for (var ingredient in ingredients) {
      String measure = (ingredient['measure'] ?? '').toLowerCase();
      String name = (ingredient['name'] ?? '').toLowerCase();
      
      // Extract numeric value from measure
      double quantity = double.tryParse(
          RegExp(r'[\d.]+').firstMatch(measure)?.group(0) ?? '0') ?? 0;
      
      // Adjust servings based on main protein or bulk ingredients
      if (name.contains('chicken') || name.contains('beef') || name.contains('fish')) {
        if (measure.contains('lb') && quantity >= 1) {
          estimatedServings = (quantity * 4).round(); // ~4 servings per lb of protein
        } else if (measure.contains('kg') && quantity >= 0.5) {
          estimatedServings = (quantity * 8).round(); // ~8 servings per kg
        }
      } else if (name.contains('rice') || name.contains('pasta')) {
        if (measure.contains('cup') && quantity >= 1) {
          estimatedServings = (quantity * 2).round(); // ~2 servings per cup of grain
        }
      }
    }
    
    return estimatedServings.clamp(1, 12); // Reasonable range: 1-12 servings
  }

  String _estimateDifficulty(List<String> instructions, List<Map<String, String>> ingredients) {
    int difficultyScore = 0;
    
    // Base difficulty on ingredient count
    if (ingredients.length > 15) {
      difficultyScore += 2;
    }
    else if (ingredients.length > 10) {
      difficultyScore += 1;
    }
    
    // Check instructions for complexity indicators
    String allInstructions = instructions.join(' ').toLowerCase();
    
    if (allInstructions.contains('marinate') || allInstructions.contains('overnight')) {
      difficultyScore += 2;
    }
    if (allInstructions.contains('fold') || allInstructions.contains('whisk') || allInstructions.contains('cream')) {
      difficultyScore += 1;
    }
    if (allInstructions.contains('fry') || allInstructions.contains('sauté') || allInstructions.contains('simmer')) {
      difficultyScore += 1;
    }
    if (allInstructions.contains('bake') || allInstructions.contains('roast')) {
      difficultyScore += 1;
    }
    if (allInstructions.contains('blend') || allInstructions.contains('processor')) {
      difficultyScore += 1;
    }
    
    // Number of steps
    if (instructions.length > 10) {
      difficultyScore += 2;
    }
    else if (instructions.length > 6) {
      difficultyScore += 1;
    }
    
    if (difficultyScore <= 2) {
      return 'Easy';
    }
    else if (difficultyScore <= 5) {
      return 'Medium';
    }
    else {
      return 'Hard';
    }
  }

  String _estimateCookTime(List<String> instructions, String? category) {
    String allInstructions = instructions.join(' ').toLowerCase();
    int totalMinutes = 30; // Default
    
    // Look for time indicators in instructions
    RegExp timePattern = RegExp(r'(\d+)\s*(minute|min|hour|hr)');
    Iterable<RegExpMatch> matches = timePattern.allMatches(allInstructions);
    
    int foundTime = 0;
    for (RegExpMatch match in matches) {
      int time = int.tryParse(match.group(1) ?? '0') ?? 0;
      String unit = match.group(2) ?? '';
      
      if (unit.startsWith('hour') || unit.startsWith('hr')) {
        time *= 60; // Convert hours to minutes
      }
      foundTime += time;
    }
    
    if (foundTime > 0) {
      totalMinutes = foundTime;
    } else {
      // Estimate based on category and cooking methods
      switch (category?.toLowerCase()) {
        case 'breakfast':
          totalMinutes = 15;
          break;
        case 'dessert':
          totalMinutes = allInstructions.contains('bake') ? 45 : 20;
          break;
        case 'beef':
        case 'lamb':
          totalMinutes = 60;
          break;
        case 'chicken':
          totalMinutes = 35;
          break;
        case 'seafood':
          totalMinutes = 20;
          break;
        case 'pasta':
          totalMinutes = 25;
          break;
        default:
          if (allInstructions.contains('slow cook') || allInstructions.contains('braise')) {
            totalMinutes = 120;
          } else if (allInstructions.contains('bake') || allInstructions.contains('roast')) {
            totalMinutes = 45;
          }
      }
    }
    
    return '$totalMinutes min';
  }
}
