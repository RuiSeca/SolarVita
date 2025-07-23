// lib/services/food_recognition_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../config/vision_api_config.dart';

class FoodRecognitionService {
  final Logger _logger = Logger();
  bool _isConfigured = false;

  // Constructor validates API key
  FoodRecognitionService() {
    _isConfigured = VisionApiConfig.isConfigured();
    if (!_isConfigured) {
      _logger.w('Google Vision API is not properly configured. Food recognition will not work.');
    }
  }

  // Identify food in an image using Google Vision API
  Future<List<String>> identifyFoodInImage(File imageFile) async {
    if (!_isConfigured) {
      _logger.w('Vision API not configured, returning generic food items');
      return ['Food Item', 'Unknown Food'];
    }
    
    // Read file as bytes
    final List<int> imageBytes = await imageFile.readAsBytes();

    // Encode image as base64
    final String base64Image = base64Encode(imageBytes);

    // Prepare request body
    final Map<String, dynamic> requestBody = {
      'requests': [
        {
          'image': {
            'content': base64Image,
          },
          'features': [
            {
              'type': 'LABEL_DETECTION',
              'maxResults': 15,
            },
            {
              'type': 'WEB_DETECTION',
              'maxResults': 15,
            }
          ],
        }
      ]
    };

    // Send request to Google Vision API
    final response = await http.post(
      Uri.parse(VisionApiConfig.apiUrl),
      headers: VisionApiConfig.headers,
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      // Extract labels from response
      final List<dynamic> labels =
          jsonResponse['responses'][0]['labelAnnotations'] ?? [];

      // Extract web entities from response
      final List<dynamic> webEntities =
          jsonResponse['responses'][0]['webDetection']?['webEntities'] ?? [];

      // Collect food-related labels and entities
      final Set<String> foodItems = {};

      // Process label annotations
      for (var label in labels) {
        String description = label['description'] ?? '';
        double score = label['score'] ?? 0.0;

        // Filter for food-related labels with good confidence
        if (score > 0.7 && _isFoodRelated(description)) {
          foodItems.add(description);
        }
      }

      // Process web entities
      for (var entity in webEntities) {
        String description = entity['description'] ?? '';
        double score = entity['score'] ?? 0.0;

        // Filter for food-related entities with good confidence
        if (score > 0.7 && _isFoodRelated(description)) {
          foodItems.add(description);
        }
      }


      if (foodItems.isEmpty) {
        throw Exception('No food detected in the image');
      }

      return foodItems.toList();
    } else {
      throw Exception('Failed to analyze image: ${response.statusCode}');
    }
  }

  // Helper method to determine if a label is food-related
  bool _isFoodRelated(String label) {
    // Convert to lowercase for case-insensitive matching
    final lowerLabel = label.toLowerCase();

    // List of common food categories and terms
    final List<String> foodKeywords = [
      'food',
      'dish',
      'meal',
      'cuisine',
      'breakfast',
      'lunch',
      'dinner',
      'snack',
      'dessert',
      'fruit',
      'vegetable',
      'meat',
      'fish',
      'seafood',
      'bread',
      'pasta',
      'rice',
      'noodle',
      'soup',
      'salad',
      'sandwich',
      'protein',
      'carb',
      'fat',
      'egg',
      'dairy',
      'cheese',
      'milk',
      'yogurt',
      'chicken',
      'beef',
      'pork',
      'lamb',
      'steak',
      'burger',
      'pizza',
      'ingredient',
      'recipe',
      'drink',
      'beverage',
      'cocktail',
      'smoothie',
      'juice',
      'coffee',
      'tea',
      'chocolate',
      'candy',
      'sweet',
      'savory'
    ];

    // Check if the label contains any food-related keywords
    for (var keyword in foodKeywords) {
      if (lowerLabel.contains(keyword)) {
        return true;
      }
    }

    // Additional check for specific types of foods
    final List<String> specificFoods = [
      'apple',
      'banana',
      'orange',
      'grape',
      'strawberry',
      'blueberry',
      'avocado',
      'tomato',
      'potato',
      'carrot',
      'broccoli',
      'lettuce',
      'spinach',
      'onion',
      'garlic',
      'rice',
      'wheat',
      'oat',
      'corn',
      'bean',
      'lentil',
      'chickpea',
      'tofu',
      'tempeh',
      'seitan',
      'steak',
      'chop',
      'filet',
      'rib',
      'roast',
      'ground'
    ];

    for (var food in specificFoods) {
      if (lowerLabel == food ||
          lowerLabel.startsWith('$food ') ||
          lowerLabel.endsWith(' $food')) {
        return true;
      }
    }

    return false;
  }
}
