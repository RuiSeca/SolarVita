// lib/services/recipe_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class MealDBService {
  static const String baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  Future<Map<String, dynamic>> getMealById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/lookup.php?i=$id'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null && data['meals'].isNotEmpty) {
        return _formatMealData(data['meals'][0]);
      }
    }
    throw Exception('Failed to load meal');
  }

  Future<List<Map<String, dynamic>>> searchMeals(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/search.php?s=$query'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null) {
        return List<Map<String, dynamic>>.from(
          data['meals'].map((meal) => _formatMealData(meal)),
        );
      }
      return [];
    }
    throw Exception('Failed to search meals');
  }

  Future<List<Map<String, dynamic>>> getMealsByCategory(String category) async {
    final response =
        await http.get(Uri.parse('$baseUrl/filter.php?c=$category'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null) {
        List<Map<String, dynamic>> meals = [];
        for (var meal in data['meals']) {
          final detailedMeal = await getMealById(meal['idMeal']);
          meals.add(detailedMeal);
        }
        return meals;
      }
      return [];
    }
    throw Exception('Failed to load category meals');
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories.php'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['categories']);
    }
    throw Exception('Failed to load categories');
  }

  Map<String, dynamic> _formatMealData(Map<String, dynamic> meal) {
    // Extract ingredients and measurements
    List<Map<String, String>> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final ingredient = meal['strIngredient$i'];
      final measure = meal['strMeasure$i'];

      if (ingredient != null &&
          ingredient.trim().isNotEmpty &&
          measure != null &&
          measure.trim().isNotEmpty) {
        ingredients.add({
          'name': ingredient.trim(),
          'measure': measure.trim(),
        });
      }
    }

    // Format instructions into steps
    List<String> instructions = meal['strInstructions']
        .split(RegExp(r'\r\n|\n|\r'))
        .where((step) => step.trim().isNotEmpty)
        .map((step) => step.trim())
        .toList();

    // Calculate approximate calories (this is a rough estimation)
    int approximateCalories = _calculateApproximateCalories(ingredients);

    // Format to match your app's data structure
    return {
      'id': meal['idMeal'],
      'titleKey': meal['strMeal'],
      'category': meal['strCategory'],
      'area': meal['strArea'],
      'instructions': instructions,
      'ingredients': ingredients,
      'imagePath': meal['strMealThumb'],
      'calories': '$approximateCalories kcal',
      'prepTime': '30 min', // MealDB doesn't provide prep time
      'isVegan': _checkIfVegan(ingredients),
      'isFavorite': false,
      'nutritionFacts': {
        'calories': '$approximateCalories',
        'protein': '${approximateCalories ~/ 20}g', // Rough estimation
        'carbs': '${approximateCalories ~/ 15}g', // Rough estimation
        'fat': '${approximateCalories ~/ 30}g', // Rough estimation
      },
      'tags': meal['strTags']?.split(',') ?? [],
      'youtubeUrl': meal['strYoutube'],
    };
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

    return !ingredients.any((ingredient) => nonVeganIngredients.any(
        (nonVegan) => ingredient['name']!
            .toLowerCase()
            .contains(nonVegan.toLowerCase())));
  }

  int _calculateApproximateCalories(List<Map<String, String>> ingredients) {
    // This is a very rough estimation
    int totalCalories = 0;

    for (var ingredient in ingredients) {
      String measure = ingredient['measure']!.toLowerCase();
      String name = ingredient['name']!.toLowerCase();

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
}
