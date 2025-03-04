// lib/services/fat_secret_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_analysis.dart';
import '../config/fat_secret_api_config.dart';
import 'package:logger/logger.dart';
import 'food_recognition_service.dart';

class FatSecretService {
  final Logger _logger = Logger();
  final FoodRecognitionService _recognitionService = FoodRecognitionService();

  // Token management
  String? _accessToken;
  DateTime? _tokenExpiry;

  // Constructor validates API credentials
  FatSecretService() {
    if (!FatSecretApiConfig.isConfigured()) {
      _logger.w(
          'FatSecret API is not properly configured. Set FATSECRET_API_KEY and FATSECRET_API_SECRET in .env file.');
    }
  }

  // Get OAuth2 token with multiple attempts using different methods
  Future<String> _getAccessToken() async {
    // Return cached token if it's still valid
    final now = DateTime.now();
    if (_accessToken != null &&
        _tokenExpiry != null &&
        _tokenExpiry!.isAfter(now)) {
      return _accessToken!;
    }

    _logger.d('Attempting to get FatSecret access token...');
    FatSecretApiConfig.logKeyInfo();
    FatSecretApiConfig.debugOAuthRequest();

    try {
      // Try multiple approaches to get a token

      // Attempt 1: Standard OAuth with Authorization header
      _logger.d('Attempt 1: Standard OAuth with Authorization header');
      var response = await http.post(
        Uri.parse(FatSecretApiConfig.oauthUrl),
        headers: FatSecretApiConfig.oauthHeaders,
        body: FatSecretApiConfig.oauthBody,
      );

      _logger.d('OAuth response status (1): ${response.statusCode}');
      _logger.d('OAuth response body (1): ${response.body}');

      // If successful, process the token
      if (response.statusCode == 200 && _processTokenResponse(response, now)) {
        return _accessToken!;
      }

      // Attempt 2: OAuth with credentials in body
      _logger.d('Attempt 2: OAuth with credentials in body');
      response = await http.post(
        Uri.parse(FatSecretApiConfig.oauthUrl),
        headers: FatSecretApiConfig.altOauthHeaders,
        body: FatSecretApiConfig.altOauthBody,
      );

      _logger.d('OAuth response status (2): ${response.statusCode}');
      _logger.d('OAuth response body (2): ${response.body}');

      // If successful, process the token
      if (response.statusCode == 200 && _processTokenResponse(response, now)) {
        return _accessToken!;
      }

      // Attempt 3: OAuth with redirect URI
      _logger.d('Attempt 3: OAuth with redirect URI');
      response = await http.post(
        Uri.parse(FatSecretApiConfig.oauthUrl),
        headers: FatSecretApiConfig.oauthHeaders,
        body: FatSecretApiConfig.altOauthBodyWithRedirect,
      );

      _logger.d('OAuth response status (3): ${response.statusCode}');
      _logger.d('OAuth response body (3): ${response.body}');

      // If successful, process the token
      if (response.statusCode == 200 && _processTokenResponse(response, now)) {
        return _accessToken!;
      }

      // If all attempts fail, throw an exception with details
      _logger.e('All token acquisition attempts failed');
      throw Exception(
          'Failed to get FatSecret access token after multiple attempts. Last status: ${response.statusCode}, Last response: ${response.body}');
    } catch (e) {
      _logger.e('OAuth authentication error', e);
      throw Exception('Authentication error: ${e.toString()}');
    }
  }

  // Helper to process token response
  bool _processTokenResponse(http.Response response, DateTime now) {
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];

        if (_accessToken == null || _accessToken!.isEmpty) {
          _logger
              .e('Received empty access token from response: ${response.body}');
          return false;
        }

        int expiresIn = data['expires_in'] ?? 86400; // Default 24 hours
        _tokenExpiry =
            now.add(Duration(seconds: expiresIn - 300)); // 5-minute buffer

        _logger.d(
            'Successfully obtained access token (length: ${_accessToken!.length})');
        return true;
      } catch (e) {
        _logger.e('Error processing token response: $e');
        return false;
      }
    }
    return false;
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

      // Step 2: Search FatSecret for the top food item
      // Try first identified food, if no results, try second one, etc.
      FoodAnalysis? foundFood;
      Exception? lastError;

      for (String foodName in identifiedFoods) {
        try {
          final List<FoodAnalysis> searchResults = await searchFood(foodName);

          if (searchResults.isNotEmpty) {
            // Step 3: Get detailed nutritional information for the first result
            foundFood = await getFoodDetails(searchResults.first.id);
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

      // Step 4: Create a complete food analysis with the image
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
      rethrow; // Re-throw the exception to be handled by the UI
    }
  }

  // Search for food by name
  Future<List<FoodAnalysis>> searchFood(String query) async {
    try {
      final token = await _getAccessToken();
      _logger.d('Searching for food: $query');

      // URL encode the query
      final encodedQuery = Uri.encodeComponent(query);

      // Prepare API parameters - using GET parameters as recommended
      final uri = Uri.parse(
          '${FatSecretApiConfig.baseUrl}?method=foods.search&search_expression=$encodedQuery&format=json');

      _logger.d('Search request URL: $uri');

      final response = await http.get(
        uri,
        headers: FatSecretApiConfig.getAuthenticatedHeaders(token),
      );

      _logger.d('Search response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        _logger.d('Search response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.d('Search response structure: ${data.keys.toList()}');

        // Check if foods exist in response
        if (!data.containsKey('foods') || data['foods'] == null) {
          _logger.w('No foods found in response for query: $query');
          return [];
        }

        // Handle "no results" response
        if (data['foods'].containsKey('total_results') &&
            (data['foods']['total_results'] == 0 ||
                data['foods']['total_results'] == '0')) {
          _logger.w('Zero total_results returned for query: $query');
          return [];
        }

        final foodsData = data['foods']['food'];

        if (foodsData is List) {
          // Multiple results
          _logger.d('Found ${foodsData.length} food results for query: $query');
          return foodsData.map((foodData) => _parseFoodData(foodData)).toList();
        } else if (foodsData != null) {
          // Single result
          _logger.d('Found single food result for query: $query');
          return [_parseFoodData(foodsData)];
        }

        return [];
      } else {
        _logger.e(
            'Failed to search foods: ${response.statusCode}, ${response.body}');
        throw Exception(
            'Failed to search foods: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      _logger.e('Error searching foods', e);
      throw Exception('Error searching for food data: ${e.toString()}');
    }
  }

  // Get detailed food information by ID
  Future<FoodAnalysis> getFoodDetails(String foodId) async {
    try {
      final token = await _getAccessToken();

      final uri = Uri.parse(
          '${FatSecretApiConfig.baseUrl}?method=food.get&food_id=$foodId&format=json');

      final response = await http.get(
        uri,
        headers: FatSecretApiConfig.getAuthenticatedHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!data.containsKey('food')) {
          throw Exception('Invalid response from API - missing food data');
        }
        return _parseDetailedFoodData(data['food']);
      } else {
        _logger.e(
            'Failed to get food details: ${response.statusCode}, ${response.body}');
        throw Exception(
            'Failed to get food details: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      _logger.e('Error getting food details', e);
      throw Exception('Error retrieving food details: ${e.toString()}');
    }
  }

  // Helper method to parse basic food data
  FoodAnalysis _parseFoodData(Map<String, dynamic> foodData) {
    try {
      // Extract the food ID
      final String foodId = foodData['food_id'] ?? '0';

      // Extract food name
      final String foodName = foodData['food_name'] ?? 'Unknown Food';

      // Try to extract calories
      int calories = 0;
      String description = foodData['food_description'] ?? '';

      // FatSecret typically includes calories in the description like "Calories: 200 kcal"
      final RegExp calorieRegex = RegExp(r'Calories:\s*(\d+)');
      final calorieMatch = calorieRegex.firstMatch(description);
      if (calorieMatch != null && calorieMatch.groupCount >= 1) {
        calories = int.tryParse(calorieMatch.group(1) ?? '0') ?? 0;
      }

      // For simple search results, we only get basic info
      // For detailed nutritional data, we'll need to make a separate request
      return FoodAnalysis(
        id: foodId,
        foodName: foodName,
        calories: calories,
        protein: 0,
        carbs: 0,
        fat: 0,
        ingredients: [],
        healthRating: 0,
        servingSize: 'serving',
      );
    } catch (e) {
      _logger.e('Error parsing food data', e);
      throw Exception('Error parsing food data: ${e.toString()}');
    }
  }

  // Helper method to parse detailed food data
  FoodAnalysis _parseDetailedFoodData(Map<String, dynamic> foodData) {
    try {
      // Extract basic info
      final String foodId = foodData['food_id'] ?? '0';
      final String foodName = foodData['food_name'] ?? 'Unknown Food';
      List<String> ingredients = [];

      // Try to extract ingredients if available
      if (foodData.containsKey('food_ingredients') &&
          foodData['food_ingredients'] != null) {
        ingredients = foodData['food_ingredients']
            .toString()
            .split(',')
            .map<String>((ingredient) => ingredient.trim())
            .toList();
      }

      // Extract servings information
      var servings = foodData['servings']['serving'];

      // Use the first serving for nutritional data
      final serving = servings is List ? servings[0] : servings;

      // Extract serving size
      final String servingSize = serving['serving_description'] ?? 'serving';

      // Extract nutritional data
      final int calories = int.tryParse(serving['calories'] ?? '0') ?? 0;
      final double protein = double.tryParse(serving['protein'] ?? '0') ?? 0;
      final double carbs = double.tryParse(serving['carbohydrate'] ?? '0') ?? 0;
      final double fat = double.tryParse(serving['fat'] ?? '0') ?? 0;

      // Calculate a health rating based on macronutrient balance
      final int healthRating =
          _calculateHealthRating(calories, protein, carbs, fat);

      return FoodAnalysis(
        id: foodId,
        foodName: foodName,
        calories: calories,
        protein: protein.toInt(),
        carbs: carbs.toInt(),
        fat: fat.toInt(),
        ingredients: ingredients,
        healthRating: healthRating,
        servingSize: servingSize,
      );
    } catch (e) {
      _logger.e('Error parsing detailed food data', e);
      throw Exception('Error parsing detailed food data: ${e.toString()}');
    }
  }

  // Health rating algorithm
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

    // Very basic formula - would be more sophisticated in a real app
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

    // Penalize for very high fat (except for healthy fat sources, which we can't detect)
    if (fatPercentage > 60) {
      rating -= 1;
    }

    // Adjust for calories
    if (calories < 300) {
      rating += 1;
    } else if (calories > 600) {
      rating -= 1;
    }

    // Clamp to valid range
    return rating.clamp(0, 5);
  }

  // Debug helper to check API key info
  void debugApiCredentials() {
    FatSecretApiConfig.logKeyInfo();
  }
}

// Helper to avoid null-safety error with min
class Math {
  static int min(int a, int b) => (a < b) ? a : b;
}
