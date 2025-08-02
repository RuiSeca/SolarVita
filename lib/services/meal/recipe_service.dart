// lib/services/recipe_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../../config/mealdb_api_config.dart';
import 'nutrition_database.dart';

class MealDBService {
  static String get baseUrl => MealDBApiConfig.baseUrl;
  static const int timeoutSeconds =
      12; // Increased timeout for larger data loads
  static const int maxRetries = 3; // Increased for 429 errors

  // Single persistent HTTP client for connection reuse
  static final http.Client _client = http.Client();
  
  // Logging disabled for production
  static void _logDetailed(String message) {
    // Silent for production
  }
  static void _logRateLimit(String message) {}
  static void _logNutrition(String message) {
    // Silent for production
  }
  static void _logImportant(String message) {}

  // Enhanced rate limiting variables with circuit breaker
  static DateTime _lastRequestTime = DateTime.now();
  static int _minRequestInterval = 300; // More conservative 300ms to avoid rate limits
  static final List<Completer<void>> _requestQueue = [];
  static bool _isProcessingQueue = false;
  static int _consecutiveFailures = 0;
  static DateTime? _circuitBreakerOpenedAt;
  static const int _maxConsecutiveFailures = 3;
  static const Duration _circuitBreakerTimeout = Duration(seconds: 30); // Much faster recovery

  // Method to manually reset rate limiting (useful for search)
  static void resetRateLimiting() {
    _circuitBreakerOpenedAt = null;
    _consecutiveFailures = 0;
    _minRequestInterval = 300;
    
    // Clear any pending requests safely
    for (final completer in _requestQueue) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Rate limiting reset'));
      }
    }
    _requestQueue.clear();
    _isProcessingQueue = false;
    
    _logImportant('🔄 Rate limiting manually reset');
  }

  // Enhanced rate limiting method with circuit breaker
  static Future<void> _waitForRateLimit() async {
    // Check circuit breaker
    if (_circuitBreakerOpenedAt != null) {
      final timeSinceOpened = DateTime.now().difference(_circuitBreakerOpenedAt!);
      if (timeSinceOpened < _circuitBreakerTimeout) {
        throw Exception('API circuit breaker is open. Please wait ${(_circuitBreakerTimeout - timeSinceOpened).inMinutes} more minutes.');
      } else {
        // Reset circuit breaker
        _circuitBreakerOpenedAt = null;
        _consecutiveFailures = 0;
        _minRequestInterval = 300; // Reset to base interval
        _logRateLimit('Circuit breaker reset - API requests resumed');
      }
    }

    final completer = Completer<void>();
    _requestQueue.add(completer);

    if (!_isProcessingQueue) {
      _processRequestQueue();
    }

    return completer.future;
  }

  // Process the request queue with rate limiting
  static Future<void> _processRequestQueue() async {
    _isProcessingQueue = true;

    while (_requestQueue.isNotEmpty) {
      final completer = _requestQueue.removeAt(0);

      final timeSinceLastRequest = DateTime.now()
          .difference(_lastRequestTime)
          .inMilliseconds;
      if (timeSinceLastRequest < _minRequestInterval) {
        await Future.delayed(
          Duration(milliseconds: _minRequestInterval - timeSinceLastRequest),
        );
      }

      _lastRequestTime = DateTime.now();
      completer.complete();
    }

    _isProcessingQueue = false;
  }

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

  // Enhanced test method that also analyzes ingredient coverage
  Future<void> runIngredientAnalysis() async {
    try {
      // Running comprehensive ingredient analysis
      
      // Test API connection first
      final isConnected = await testApiConnection();
      if (!isConnected) {
        return;
      }
      
      // Run ingredient coverage analysis
      await analyzeIngredientCoverage();
      
      // Also print current missing ingredients from actual meal processing
      if (_missingIngredients.isNotEmpty) {
        // Missing ingredients would be printed here if logging was enabled
        // final sortedMissing = _missingIngredients.toList()..sort();
      }
      
    } catch (e) {
      // Error running ingredient analysis
    }
  }

  Future<http.Response> _makeRequest(String url, {int retryCount = 0}) async {
    // Wait for rate limit before making request
    await _waitForRateLimit();

    try {
      _logRateLimit('Making API request (attempt ${retryCount + 1})');
      
      final response = await _client
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'SolarVita/1.0',
              'Accept': 'application/json',
              'Connection': 'keep-alive', // Enable connection reuse
            },
          )
          .timeout(Duration(seconds: timeoutSeconds));

      // Handle 429 (Too Many Requests) with enhanced backoff
      if (response.statusCode == 429) {
        _consecutiveFailures++;
        _logRateLimit('Rate limit hit (429) - consecutive failures: $_consecutiveFailures');
        
        // Open circuit breaker if too many consecutive failures
        if (_consecutiveFailures >= _maxConsecutiveFailures) {
          _circuitBreakerOpenedAt = DateTime.now();
          
          // Clear request queue to prevent buildup
          for (final completer in _requestQueue) {
            if (!completer.isCompleted) {
              completer.completeError(Exception('Circuit breaker opened - clearing queue'));
            }
          }
          _requestQueue.clear();
          _isProcessingQueue = false;
          
          _logImportant('⚠️ Circuit breaker opened - API requests paused for ${_circuitBreakerTimeout.inSeconds} seconds');
          throw Exception('API temporarily unavailable due to rate limiting. Retrying in ${_circuitBreakerTimeout.inSeconds} seconds...');
        }
        
        if (retryCount < maxRetries) {
          // Increase minimum interval for future requests (exponential backoff)
          _minRequestInterval = (_minRequestInterval * 1.5).round().clamp(300, 2000);
          _logRateLimit('Increased request interval to ${_minRequestInterval}ms');
          
          final backoffDelay = Duration(
            milliseconds: 2000 * (1 << retryCount), // 2s, 4s, 8s
          );
          _logRateLimit('Backing off for ${backoffDelay.inSeconds} seconds');
          await Future.delayed(backoffDelay);
          return _makeRequest(url, retryCount: retryCount + 1);
        }
        throw Exception('Rate limit exceeded after $maxRetries attempts. Circuit breaker may activate soon.');
      }

      // Success - reset failure counter and gradually reduce interval
      if (response.statusCode == 200) {
        _consecutiveFailures = 0;
        if (_minRequestInterval > 500) {
          _minRequestInterval = (_minRequestInterval * 0.95).round().clamp(300, 2000);
          _logRateLimit('Reduced request interval to ${_minRequestInterval}ms');
        }
      }

      return response;
    } on SocketException catch (e) {
      if (retryCount < maxRetries) {
        await Future.delayed(
          Duration(milliseconds: 500 * (retryCount + 1)),
        ); // Reduced retry delay
        return _makeRequest(url, retryCount: retryCount + 1);
      }
      throw Exception(
        'Network error: ${e.message}. Please check your internet connection or try using a VPN if you\'re on a restricted network.',
      );
    } on TimeoutException {
      if (retryCount < maxRetries) {
        await Future.delayed(
          Duration(milliseconds: 500 * (retryCount + 1)),
        ); // Reduced retry delay
        return _makeRequest(url, retryCount: retryCount + 1);
      }
      throw Exception(
        'Request timeout. Please check your internet connection.',
      );
    } catch (e) {
      if (retryCount < maxRetries) {
        await Future.delayed(
          Duration(milliseconds: 500 * (retryCount + 1)),
        ); // Reduced retry delay
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

  // New paginated search method
  Future<List<Map<String, dynamic>>> searchMealsPaginated(
    String query, {
    int page = 0, 
    int limit = 8,
  }) async {
    final response = await _makeRequest('$baseUrl/search.php?s=$query');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['meals'] != null) {
        final mealList = data['meals'] as List;
        
        // Calculate pagination
        final startIndex = page * limit;
        final endIndex = math.min(startIndex + limit, mealList.length);
        
        if (startIndex >= mealList.length) {
          return []; // No more meals
        }
        
        // Get only the requested page of meals
        final paginatedMeals = mealList.sublist(startIndex, endIndex);
        
        _logDetailed('Search page $page: meals ${startIndex + 1}-$endIndex of ${mealList.length} for query: "$query"');
        
        final meals = <Map<String, dynamic>>[];
        
        // Process search results with faster loading since they already have more data
        for (int i = 0; i < paginatedMeals.length; i++) {
          final meal = paginatedMeals[i];
          try {
            final formattedMeal = await _formatMealData(meal);
            meals.add(formattedMeal);
            _logDetailed('Loaded search result: ${formattedMeal['titleKey']}');
            
            // Minimal delay for search since data is already detailed
            if (i < paginatedMeals.length - 1) {
              await Future.delayed(Duration(milliseconds: 200));
            }
          } catch (e) {
            _logDetailed('Failed to format search result: $e');
            if (i < paginatedMeals.length - 1) {
              await Future.delayed(Duration(milliseconds: 300));
            }
          }
        }
        
        _logDetailed('Search page $page loaded: ${meals.length}/${paginatedMeals.length} results');
        return meals;
      }
      return [];
    }
    throw Exception('Failed to search meals: Status ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> searchMeals(String query) async {
    final response = await _makeRequest('$baseUrl/search.php?s=$query');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null) {
        final mealList = data['meals'] as List;
        final meals = <Map<String, dynamic>>[];
        
        // Process search results - already have detailed data from search endpoint
        for (var meal in mealList) {
          try {
            final formattedMeal = await _formatMealData(meal);
            meals.add(formattedMeal);
          } catch (e) {
            // Continue with other meals
          }
        }
        
        // Print missing ingredients summary after processing search results
        _printMissingIngredientsSummary();
        
        return meals;
      }
      return [];
    }
    throw Exception('Failed to search meals: Status ${response.statusCode}');
  }

  // New paginated method for efficient loading
  Future<List<Map<String, dynamic>>> getMealsByCategoryPaginated(
    String category, {
    int page = 0,
    int limit = 8,
  }) async {
    _logDetailed('Fetching meals for category: "$category" (page $page, limit $limit)');
    final response = await _makeRequest('$baseUrl/filter.php?c=$category');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['meals'] != null) {
        final mealList = data['meals'] as List;
        
        // Calculate pagination
        final startIndex = page * limit;
        final endIndex = math.min(startIndex + limit, mealList.length);
        
        if (startIndex >= mealList.length) {
          return []; // No more meals
        }
        
        // Get only the requested page of meals
        final paginatedMeals = mealList.sublist(startIndex, endIndex);
        
        _logDetailed('Loading page $page: meals ${startIndex + 1}-$endIndex of ${mealList.length} in category: $category');
        
        List<Map<String, dynamic>> detailedMeals = [];
        
        // Process meals with optimized delays
        for (int i = 0; i < paginatedMeals.length; i++) {
          final meal = paginatedMeals[i];
          final mealId = meal['idMeal'];
          if (mealId != null) {
            try {
              _logDetailed('Loading meal ${i + 1}/${paginatedMeals.length}: $mealId');
              
              final detailedMeal = await getMealById(mealId);
              _logDetailed('Loaded: ${detailedMeal['titleKey']} (Category: ${detailedMeal['category']})');
              
              // Validate that the meal belongs to the expected category
              final mealCategory = detailedMeal['category']?.toString() ?? '';
              if (mealCategory.toLowerCase() != category.toLowerCase()) {
                _logDetailed('⚠️ Category mismatch: Expected "$category" but got "$mealCategory" for meal "${detailedMeal['titleKey']}"');
              }
              
              detailedMeals.add(detailedMeal);
              
              // Minimal delay between meals for speed
              if (i < paginatedMeals.length - 1) {
                await Future.delayed(Duration(milliseconds: 25));
              }
              
            } catch (e) {
              _logDetailed('Failed to load meal ID $mealId: $e');
              // Minimal delay after errors
              if (i < paginatedMeals.length - 1) {
                await Future.delayed(Duration(milliseconds: 50));
              }
            }
          }
        }
        
        _logDetailed('Page $page loaded: ${detailedMeals.length}/${paginatedMeals.length} meals');
        return detailedMeals;
      }
      return [];
    }
    throw Exception('Failed to load category meals: Status ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getMealsByCategory(String category) async {
    final response = await _makeRequest('$baseUrl/filter.php?c=$category');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['meals'] != null) {
        final mealList = data['meals'] as List;

        // Fetch detailed data for all meals to ensure accuracy
        List<Map<String, dynamic>> detailedMeals = [];
        
        // Fetching detailed data for meals in category
        
        // Drastically reduce meals and increase delays to prevent rate limiting
        final maxMeals = math.min(mealList.length, 3); // Max 3 meals per category to avoid rate limits
        final limitedMealList = mealList.take(maxMeals).toList();
        
        // Processing limited meals to respect API limits
        
        // Process meals sequentially with very large delays to prevent rate limiting
        for (int i = 0; i < limitedMealList.length; i++) {
          final meal = limitedMealList[i];
          final mealId = meal['idMeal'];
          if (mealId != null) {
            try {
              // Processing meal
              
              // Fetch complete meal data with real nutrition from API
              final detailedMeal = await getMealById(mealId);
              // Loaded meal data
              detailedMeals.add(detailedMeal);
              
              // Reasonable delay between each meal to prevent rate limiting
              if (i < limitedMealList.length - 1) { // Don't delay after the last meal
                // Waiting between meals
                await Future.delayed(Duration(milliseconds: 1000)); // 1 second delay
              }
              
            } catch (e) {
              // Failed to load detailed data  
              // Add moderate delay after failures to cool down API
              if (i < limitedMealList.length - 1) {
                // Extra cooldown after error
                await Future.delayed(Duration(milliseconds: 2000)); // 2 second delay after error
              }
            }
          }
        }
        
        // Successfully loaded meals with real API data
        
        // Print missing ingredients summary after processing meals
        _printMissingIngredientsSummary();
        
        return detailedMeals;
      }

      // If data['meals'] is null, the category might not exist or be empty
      return [];
    }

    throw Exception(
      'Failed to load category meals: Status ${response.statusCode}',
    );
  }

  // Method to get full meal details for background loading
  Future<List<Map<String, dynamic>>> getMealsByCategoryDetailed(
    String category,
  ) async {
    final response = await _makeRequest('$baseUrl/filter.php?c=$category');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['meals'] != null) {
        List<Map<String, dynamic>> meals = [];
        final mealList = data['meals'] as List;

        // Process meals in smaller batches for background loading
        const batchSize = 3; // Smaller batches for background processing

        for (int i = 0; i < mealList.length; i += batchSize) {
          final batch = mealList.skip(i).take(batchSize).toList();

          // Process batch sequentially to respect rate limits
          for (var meal in batch) {
            try {
              final mealData = await getMealById(meal['idMeal']);
              meals.add(mealData);
            } catch (e) {
              // Continue with next meal instead of giving up
            }
          }

          // Longer delay between batches for background loading
          if (i + batchSize < mealList.length) {
            await Future.delayed(Duration(milliseconds: 200));
          }
        }

        return meals;
      }

      return [];
    }

    throw Exception(
      'Failed to load detailed category meals: Status ${response.statusCode}',
    );
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _makeRequest('$baseUrl/categories.php');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['categories']);
      }
      throw Exception(
        'Failed to load categories: Status ${response.statusCode}',
      );
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
      throw Exception(
        'Failed to load latest meals: Status ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Failed to load latest meals: $e');
    }
  }

  /// Get all meals by fetching from multiple categories (for "All" tab)
  Future<List<Map<String, dynamic>>> getAllMeals({int limit = 50}) async {
    try {
      List<Map<String, dynamic>> allMeals = [];

      // Get meals from all major categories for variety
      final allCategories = [
        'Chicken',
        'Beef',
        'Seafood',
        'Pasta',
        'Vegetarian',
        'Pork',
        'Lamb',
        'Dessert',
        'Breakfast',
        'Side',
        'Starter',
        'Vegan',
        'Goat',
        'Miscellaneous',
      ];

      // Process categories sequentially to avoid overwhelming the API
      const batchSize = 2; // Reduced batch size
      for (int i = 0; i < allCategories.length; i += batchSize) {
        if (allMeals.length >= limit) break;

        final categoryBatch = allCategories.skip(i).take(batchSize).toList();
        // Processing category batch

        // Process categories sequentially instead of parallel to reduce load
        final results = <List<Map<String, dynamic>>>[];
        for (final category in categoryBatch) {
          try {
            final categoryMeals = await getMealsByCategory(category);
            // Take only first 2 meals from each category to reduce API load
            final limitedMeals = categoryMeals.take(2).toList();
            results.add(limitedMeals);
            // Got meals from category
            
            // Add delay between categories
            if (category != categoryBatch.last) {
              await Future.delayed(Duration(milliseconds: 1000)); // 1 second delay between categories
            }
          } catch (e) {
            // Failed to get meals from category
            results.add(<Map<String, dynamic>>[]);
            // Moderate delay after errors
            await Future.delayed(Duration(milliseconds: 1500));
          }
        }

        // Combine all results
        for (var categoryMeals in results) {
          for (var meal in categoryMeals) {
            if (allMeals.length >= limit) break;
            // Avoid duplicates - check both id and idMeal fields
            final mealId = meal['id']?.toString() ?? meal['idMeal']?.toString();

            bool hasDuplicate(Map<String, dynamic> existing) =>
                existing['id']?.toString() == mealId ||
                existing['idMeal']?.toString() == mealId;

            if (mealId != null && !allMeals.any(hasDuplicate)) {
              allMeals.add(meal);
            }
          }
          if (allMeals.length >= limit) break;
        }
      }

      // Shuffle the meals to provide variety
      allMeals.shuffle();
      
      // Print missing ingredients summary after processing all meals
      _printMissingIngredientsSummary();
      
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
              final meal = await _formatMealData(data['meals'][0]);
              // Avoid duplicates
              if (!randomMeals.any(
                (existing) =>
                    existing['id']?.toString() == meal['id']?.toString(),
              )) {
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

  Future<Map<String, dynamic>> _formatMealData(Map<String, dynamic> meal, {String? expectedCategory}) async {
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

    // Extract actual nutrition data from API response or calculate as fallback
    final nutritionData = await _getNutritionData(meal);

    // Validate category if expected category is provided
    final mealCategory = meal['strCategory']?.toString() ?? '';
    if (expectedCategory != null && mealCategory.toLowerCase() != expectedCategory.toLowerCase()) {
      _logDetailed('⚠️ Category mismatch: Expected "$expectedCategory" but meal "${meal['strMeal']}" is in "$mealCategory"');
    }

    // Format to match your app's data structure
    final formattedMeal = {
      'id': meal['idMeal'],
      'titleKey': meal['strMeal'],
      'category': meal['strCategory'],
      'area': meal['strArea'],
      'instructions': instructions,
      'ingredients': ingredients
          .map((ing) => ing['name']!)
          .toList(), // Convert to List<String>
      'measures': ingredients
          .map((ing) => ing['measure']!)
          .toList(), // Convert to List<String>
      'imagePath': meal['strMealThumb'],
      'calories': '${nutritionData['caloriesPerServing']} kcal per serving',
      'prepTime': '30 min', // MealDB doesn't provide prep time
      'servings': _estimateServings(ingredients), // Estimated serving size
      'difficulty': _estimateDifficulty(instructions, ingredients),
      'cookTime': _estimateCookTime(instructions, meal['strCategory']),
      'isVegan': _checkIfVegan(ingredients),
      'isFavorite': false,
      'nutritionFacts': nutritionData,
      'tags': meal['strTags']?.split(',') ?? [],
      'youtubeUrl': meal['strYoutube'],
    };
    return formattedMeal;
  }

  // Get nutrition data from premium API or extract from meal response
  Future<Map<String, dynamic>> _getNutritionData(Map<String, dynamic> meal) async {
    final mealName = meal['strMeal'] ?? 'Unknown';
    
    // Debug: Check ALL available fields in the API response to see what premium provides
    _logNutrition('🔍 ALL available fields for $mealName:');
    // Field logging disabled for production
    
    // First, check if nutrition data is already in the meal response (premium API might include it)
    if (meal.containsKey('strCalories') && meal['strCalories'] != null && meal['strCalories'].toString().isNotEmpty) {
      _logNutrition('✓ Found direct nutrition data in meal response for: $mealName');
      // Extract nutrition data directly from meal response if available
      return {
        'calories': meal['strCalories']?.toString() ?? '0',
        'protein': meal['strProtein']?.toString() ?? '0g',
        'carbs': meal['strCarbohydrates']?.toString() ?? '0g', 
        'fat': meal['strFat']?.toString() ?? '0g',
        'fiber': meal['strFiber']?.toString() ?? '0g',
        'sugar': meal['strSugar']?.toString() ?? '0g',
        'sodium': meal['strSodium']?.toString() ?? '0mg',
      };
    }

    // Enhanced ingredient-based nutrition calculation
    _logNutrition('⚠️ TheMealDB does not provide nutrition data - calculating from ingredients for: $mealName');
    final ingredients = <Map<String, String>>[];
    for (int i = 1; i <= 20; i++) {
      final ingredient = meal['strIngredient$i'];
      final measure = meal['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients.add({
          'name': ingredient.toString().trim(),
          'measure': measure?.toString().trim() ?? '',
        });
      }
    }

    if (ingredients.isEmpty) {
      _logNutrition('❌ No ingredients found for: $mealName - using category-based defaults');
      return _getCategoryBasedNutrition(meal['strCategory']?.toString() ?? '', mealName);
    }

    // Calculate nutrition from ingredients using enhanced database
    final calculatedNutrition = _calculateEnhancedNutritionFromIngredients(ingredients);
    final totalCalories = calculatedNutrition['calories'] as int;
    
    _logNutrition('Calculated nutrition for $mealName: $totalCalories cal from ${ingredients.length} ingredients');
    
    // Print summary every 50 ingredients to track progress
    if (_totalIngredientsProcessed % 50 == 0) {
      _printMissingIngredientsSummary();
    }

    // Get estimated servings for per-serving calculations
    final estimatedServings = _estimateServings(ingredients).clamp(1, 12); // Ensure at least 1 serving
    
    // Calculate per-serving values
    final caloriesPerServing = (totalCalories / estimatedServings).round();
    final proteinPerServing = (calculatedNutrition['protein'] / estimatedServings).round();
    final carbsPerServing = (calculatedNutrition['carbs'] / estimatedServings).round();
    final fatPerServing = (calculatedNutrition['fat'] / estimatedServings).round();

    return {
      // Per-meal (whole recipe) values
      'calories': '${calculatedNutrition['calories']}',
      'protein': '${calculatedNutrition['protein']}g',
      'carbs': '${calculatedNutrition['carbs']}g',
      'fat': '${calculatedNutrition['fat']}g',
      
      // Per-serving values
      'caloriesPerServing': '$caloriesPerServing',
      'proteinPerServing': '${proteinPerServing}g',
      'carbsPerServing': '${carbsPerServing}g',
      'fatPerServing': '${fatPerServing}g',
      
      // Additional data
      'servings': estimatedServings,
      'ingredientBreakdown': calculatedNutrition['ingredientBreakdown'],
      'totalIngredients': calculatedNutrition['totalIngredients'],
      'foundIngredients': calculatedNutrition['foundIngredients'],
    };
  }

  // Enhanced ingredient nutrition database
  Map<String, Map<String, double>> _getIngredientNutritionDatabase() {
    return NutritionDatabase.getDatabase();
  }


  // Get category-based nutrition defaults
  Map<String, dynamic> _getCategoryBasedNutrition(String category, String mealName) {
    final categoryLower = category.toLowerCase();
    final random = mealName.hashCode % 50; // Small variation
    
    switch (categoryLower) {
      case 'beef':
        return {
          'calories': 400 + random,
          'protein': 35 + (random / 10).round(),
          'carbs': 15 + (random / 5).round(), 
          'fat': 25 + (random / 5).round(),
        };
      case 'chicken':
        return {
          'calories': 350 + random,
          'protein': 40 + (random / 10).round(),
          'carbs': 10 + (random / 5).round(),
          'fat': 15 + (random / 5).round(),
        };
      case 'seafood':
        return {
          'calories': 250 + random,
          'protein': 30 + (random / 10).round(),
          'carbs': 5 + (random / 10).round(),
          'fat': 8 + (random / 8).round(),
        };
      case 'vegetarian':
      case 'vegan':
        return {
          'calories': 280 + random,
          'protein': 15 + (random / 10).round(),
          'carbs': 45 + (random / 3).round(),
          'fat': 8 + (random / 6).round(),
        };
      case 'pasta':
        return {
          'calories': 320 + random,
          'protein': 12 + (random / 10).round(),
          'carbs': 55 + (random / 3).round(),
          'fat': 6 + (random / 8).round(),
        };
      case 'dessert':
        return {
          'calories': 450 + random,
          'protein': 6 + (random / 15).round(),
          'carbs': 65 + (random / 2).round(),
          'fat': 18 + (random / 4).round(),
        };
      case 'breakfast':
        return {
          'calories': 300 + random,
          'protein': 18 + (random / 8).round(),
          'carbs': 35 + (random / 4).round(),
          'fat': 12 + (random / 6).round(),
        };
      default:
        return {
          'calories': 320 + random,
          'protein': 20 + (random / 8).round(),
          'carbs': 30 + (random / 4).round(),
          'fat': 12 + (random / 6).round(),
        };
    }
  }

  // Static set to track missing ingredients across all meals
  static final Set<String> _missingIngredients = {};
  static int _totalIngredientsProcessed = 0;
  static int _missingIngredientsCount = 0;

  // Enhanced nutrition calculation from ingredients with detailed breakdown
  Map<String, dynamic> _calculateEnhancedNutritionFromIngredients(List<Map<String, String>> ingredients) {
    final nutritionDb = _getIngredientNutritionDatabase();
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    List<Map<String, dynamic>> ingredientBreakdown = [];
    
    for (final ingredient in ingredients) {
      final name = ingredient['name']!.toLowerCase();
      final measure = ingredient['measure'] ?? '';
      _totalIngredientsProcessed++;
      
      // Find matching ingredient in database
      String? matchedKey;
      for (final key in nutritionDb.keys) {
        if (name.contains(key) || key.contains(name.split(' ').first)) {
          matchedKey = key;
          break;
        }
      }
      
      if (matchedKey != null) {
        final nutrition = nutritionDb[matchedKey]!;
        final quantity = _parseQuantityFromMeasure(measure);
        final gramsEquivalent = _convertToGrams(quantity, measure, name);
        
        // Calculate nutrition for this ingredient
        final factor = gramsEquivalent / 100; // nutrition DB is per 100g
        final ingredientCalories = nutrition['calories']! * factor;
        final ingredientProtein = nutrition['protein']! * factor;
        final ingredientCarbs = nutrition['carbs']! * factor;
        final ingredientFat = nutrition['fat']! * factor;
        
        totalCalories += ingredientCalories;
        totalProtein += ingredientProtein;
        totalCarbs += ingredientCarbs;
        totalFat += ingredientFat;
        
        // Add to breakdown
        ingredientBreakdown.add({
          'name': ingredient['name']!, // Original case name
          'measure': measure,
          'grams': gramsEquivalent.round(),
          'calories': ingredientCalories.round(),
          'protein': ingredientProtein.round(),
          'carbs': ingredientCarbs.round(),
          'fat': ingredientFat.round(),
          'caloriesPer100g': nutrition['calories']!.round(),
        });
        
        _logNutrition('  📝 $name (${gramsEquivalent.round()}g): ${ingredientCalories.round()} cal');
      } else {
        // Track missing ingredient
        _missingIngredients.add(name);
        _missingIngredientsCount++;
        
        // Default values for unknown ingredients
        final defaultCalories = 50;
        final defaultProtein = 2;
        final defaultCarbs = 8;
        final defaultFat = 1;
        
        totalCalories += defaultCalories;
        totalProtein += defaultProtein;
        totalCarbs += defaultCarbs;
        totalFat += defaultFat;
        
        // Add to breakdown with default values
        ingredientBreakdown.add({
          'name': ingredient['name']!, // Original case name
          'measure': measure,
          'grams': 50, // Estimated
          'calories': defaultCalories,
          'protein': defaultProtein,
          'carbs': defaultCarbs,
          'fat': defaultFat,
          'caloriesPer100g': 100, // Default estimate
          'isMissing': true,
        });
      }
    }
    
    // Log actual calculated values before capping
    _logNutrition('📊 Raw calculation: ${totalCalories.round()} cal, ${totalProtein.round()}g protein, ${totalCarbs.round()}g carbs, ${totalFat.round()}g fat');
    
    // Apply reasonable caps to prevent unrealistic values - much higher for whole meals
    final cappedCalories = totalCalories.round().clamp(50, 20000); // Accommodate whole meals with many ingredients
    final cappedProtein = totalProtein.round().clamp(1, 120);
    final cappedCarbs = totalCarbs.round().clamp(5, 300);
    final cappedFat = totalFat.round().clamp(1, 100);
    
    _logNutrition('🎯 Final values: $cappedCalories cal, ${cappedProtein}g protein, ${cappedCarbs}g carbs, ${cappedFat}g fat');
    
    return {
      'calories': cappedCalories,
      'protein': cappedProtein,
      'carbs': cappedCarbs,
      'fat': cappedFat,
      'ingredientBreakdown': ingredientBreakdown,
      'totalIngredients': ingredients.length,
      'foundIngredients': ingredients.length - _missingIngredientsCount,
    };
  }

  // Parse quantity from measure string
  double _parseQuantityFromMeasure(String measure) {
    final regex = RegExp(r'(\d+(?:\.\d+)?)');
    final match = regex.firstMatch(measure);
    return match != null ? double.parse(match.group(1)!) : 1.0;
  }

  // Convert various measurements to grams
  double _convertToGrams(double quantity, String measure, String ingredientName) {
    final measureLower = measure.toLowerCase();
    
    // Handle volume measurements
    if (measureLower.contains('cup')) {
      // Different ingredients have different densities
      if (ingredientName.contains('flour')) return quantity * 125;
      if (ingredientName.contains('sugar')) return quantity * 200;
      if (ingredientName.contains('rice')) return quantity * 185;
      if (ingredientName.contains('milk')) return quantity * 240;
      if (ingredientName.contains('oil')) return quantity * 220;
      return quantity * 150; // Default cup to grams
    }
    
    if (measureLower.contains('tbsp') || measureLower.contains('tablespoon')) {
      // Different densities for different ingredients in tablespoons
      if (ingredientName.contains('oil') || ingredientName.contains('butter')) {
        return quantity * 14; // 1 tbsp oil/butter ≈ 14g
      }
      if (ingredientName.contains('sugar') || ingredientName.contains('flour')) {
        return quantity * 12; // 1 tbsp sugar/flour ≈ 12g
      }
      return quantity * 15; // 1 tablespoon ≈ 15g for most ingredients
    }
    
    if (measureLower.contains('tsp') || measureLower.contains('teaspoon')) {
      return quantity * 5; // 1 teaspoon ≈ 5g for most ingredients
    }
    
    // Handle weight measurements
    if (measureLower.contains('kg') || measureLower.contains('kilogram')) {
      return quantity * 1000;
    }
    
    if (measureLower.contains('lb') || measureLower.contains('pound')) {
      return quantity * 453.592;
    }
    
    if (measureLower.contains('oz') || measureLower.contains('ounce')) {
      return quantity * 28.3495;
    }
    
    if (measureLower.contains('g') && !measureLower.contains('kg')) {
      return quantity; // Already in grams
    }
    
    // Handle milliliter measurements with proper liquid densities
    if (measureLower.contains('ml') || measureLower.contains('milliliter')) {
      // Proper liquid densities (ml to grams)
      if (ingredientName.contains('milk')) return quantity * 1.03; // Milk density ~1.03 g/ml
      if (ingredientName.contains('cream') || ingredientName.contains('heavy cream')) return quantity * 0.985; // Heavy cream ~0.985 g/ml
      if (ingredientName.contains('double cream')) return quantity * 0.985; // Double cream ~0.985 g/ml
      if (ingredientName.contains('oil') || ingredientName.contains('olive oil')) return quantity * 0.92; // Oil ~0.92 g/ml
      if (ingredientName.contains('water') || ingredientName.contains('broth') || ingredientName.contains('stock')) return quantity * 1.0; // Water-based ~1.0 g/ml
      if (ingredientName.contains('wine') || ingredientName.contains('beer')) return quantity * 0.99; // Alcohol ~0.99 g/ml
      if (ingredientName.contains('honey') || ingredientName.contains('syrup')) return quantity * 1.4; // Honey/syrup ~1.4 g/ml
      return quantity * 1.0; // Default liquid density
    }
    
    // Handle specific measurements and counts
    if (measureLower.contains('clove') && ingredientName.contains('garlic')) {
      return quantity * 3; // 1 clove ≈ 3g
    }
    
    if (measureLower.contains('large')) {
      if (ingredientName.contains('onion')) return quantity * 150;
      if (ingredientName.contains('potato')) return quantity * 200;
      if (ingredientName.contains('egg')) return quantity * 60;
      if (ingredientName.contains('carrot')) return quantity * 80;
      return quantity * 100; // Default for large items
    }
    
    if (measureLower.contains('medium')) {
      if (ingredientName.contains('onion')) return quantity * 110;
      if (ingredientName.contains('potato')) return quantity * 150;
      if (ingredientName.contains('carrot')) return quantity * 60;
      return quantity * 80; // Default for medium items
    }
    
    if (measureLower.contains('small')) {
      if (ingredientName.contains('onion')) return quantity * 70;
      if (ingredientName.contains('potato')) return quantity * 100;
      return quantity * 50; // Default for small items
    }
    
    // Handle specific measurements like "24 Skinned" for prawns
    if (measureLower.contains('skinned') && ingredientName.contains('prawn')) {
      return quantity * 4; // 24 prawns ≈ 96g (4g each)
    }
    
    // Handle individual items
    if (ingredientName.contains('tomato') && !measureLower.contains('g') && !measureLower.contains('cup')) {
      return quantity * 120; // 1 tomato ≈ 120g
    }
    
    // Handle "handful" measurements
    if (measureLower.contains('handful')) {
      return quantity * 10; // 1 handful ≈ 10g for herbs/greens
    }
    
    // Handle "leaves" measurements
    if (measureLower.contains('leaves')) {
      return quantity * 2; // Leaves are very light
    }
    
    // Handle "garnish" - minimal amount
    if (measureLower.contains('garnish') || measureLower.contains('serve')) {
      return quantity * 5; // Garnish ≈ 5g
    }
    
    // Default fallback
    return quantity * 50; // Conservative estimate for unknown measurements
  }

  // Missing ingredients summary (logging disabled)
  static void _printMissingIngredientsSummary() {
    // Silent tracking - no output for production
  }

  // Public method to manually trigger missing ingredients report
  static void printMissingIngredientsReport() {
    _printMissingIngredientsSummary();
  }

  // Method to reset missing ingredients tracking
  static void resetMissingIngredientsTracking() {
    _missingIngredients.clear();
    _totalIngredientsProcessed = 0;
    _missingIngredientsCount = 0;
    // Missing ingredients tracking reset
  }

  // Fetch all available ingredients from TheMealDB API
  Future<List<String>> getAllAvailableIngredients() async {
    try {
      // Fetching ingredients from TheMealDB API
      final response = await _makeRequest('$baseUrl/list.php?i=list');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          final ingredients = <String>[];
          for (var ingredient in data['meals']) {
            final ingredientName = ingredient['strIngredient']?.toString();
            if (ingredientName != null && ingredientName.isNotEmpty) {
              ingredients.add(ingredientName.toLowerCase());
            }
          }
          
          // Found ingredients in TheMealDB API
          
          return ingredients;
        }
      }
      
      // Failed to fetch ingredients
      return [];
    } catch (e) {
      // Error fetching ingredients
      return [];
    }
  }

  // Compare our database with TheMealDB's full ingredient list (silent analysis)
  Future<void> analyzeIngredientCoverage() async {
    try {
      final allApiIngredients = await getAllAvailableIngredients();
      final ourIngredients = NutritionDatabase.getAllIngredients().toSet();
      
      // Find ingredients we have that match API ingredients
      final matchingIngredients = <String>[];
      final missingFromOurDb = <String>[];
      
      for (final apiIngredient in allApiIngredients) {
        bool found = false;
        for (final ourIngredient in ourIngredients) {
          if (apiIngredient.contains(ourIngredient) || 
              ourIngredient.contains(apiIngredient) ||
              apiIngredient == ourIngredient) {
            matchingIngredients.add(apiIngredient);
            found = true;
            break;
          }
        }
        if (!found) {
          missingFromOurDb.add(apiIngredient);
        }
      }
      
      // Silent analysis complete - no output for production
      
    } catch (e) {
      // Error analyzing coverage - silent
    }
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
      'honey',
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



  int _estimateServings(List<Map<String, String>> ingredients) {
    // Estimate servings based on quantity of main ingredients
    int estimatedServings = 4; // Default serving size

    for (var ingredient in ingredients) {
      String measure = (ingredient['measure'] ?? '').toLowerCase();
      String name = (ingredient['name'] ?? '').toLowerCase();

      // Extract numeric value from measure
      double quantity =
          double.tryParse(
            RegExp(r'[\d.]+').firstMatch(measure)?.group(0) ?? '0',
          ) ??
          0;

      // Adjust servings based on main protein or bulk ingredients
      if (name.contains('chicken') ||
          name.contains('beef') ||
          name.contains('fish')) {
        if (measure.contains('lb') && quantity >= 1) {
          estimatedServings = (quantity * 4)
              .round(); // ~4 servings per lb of protein
        } else if (measure.contains('kg') && quantity >= 0.5) {
          estimatedServings = (quantity * 8).round(); // ~8 servings per kg
        }
      } else if (name.contains('rice') || name.contains('pasta')) {
        if (measure.contains('cup') && quantity >= 1) {
          estimatedServings = (quantity * 2)
              .round(); // ~2 servings per cup of grain
        }
      }
    }

    return estimatedServings.clamp(1, 12); // Reasonable range: 1-12 servings
  }

  String _estimateDifficulty(
    List<String> instructions,
    List<Map<String, String>> ingredients,
  ) {
    int difficultyScore = 0;

    // Base difficulty on ingredient count
    if (ingredients.length > 15) {
      difficultyScore += 2;
    } else if (ingredients.length > 10) {
      difficultyScore += 1;
    }

    // Check instructions for complexity indicators
    String allInstructions = instructions.join(' ').toLowerCase();

    if (allInstructions.contains('marinate') ||
        allInstructions.contains('overnight')) {
      difficultyScore += 2;
    }
    if (allInstructions.contains('fold') ||
        allInstructions.contains('whisk') ||
        allInstructions.contains('cream')) {
      difficultyScore += 1;
    }
    if (allInstructions.contains('fry') ||
        allInstructions.contains('sauté') ||
        allInstructions.contains('simmer')) {
      difficultyScore += 1;
    }
    if (allInstructions.contains('bake') || allInstructions.contains('roast')) {
      difficultyScore += 1;
    }
    if (allInstructions.contains('blend') ||
        allInstructions.contains('processor')) {
      difficultyScore += 1;
    }

    // Number of steps
    if (instructions.length > 10) {
      difficultyScore += 2;
    } else if (instructions.length > 6) {
      difficultyScore += 1;
    }

    if (difficultyScore <= 2) {
      return 'Easy';
    } else if (difficultyScore <= 5) {
      return 'Medium';
    } else {
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
          if (allInstructions.contains('slow cook') ||
              allInstructions.contains('braise')) {
            totalMinutes = 120;
          } else if (allInstructions.contains('bake') ||
              allInstructions.contains('roast')) {
            totalMinutes = 45;
          }
      }
    }

    return '$totalMinutes min';
  }
}
