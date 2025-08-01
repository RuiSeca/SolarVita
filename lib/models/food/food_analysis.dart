// lib/models/food_analysis.dart
import 'dart:io';

class FoodAnalysis {
  final String id;
  final String foodName;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final List<String> ingredients;
  final int healthRating;
  final String servingSize;
  final File? image;

  FoodAnalysis({
    required this.id,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.ingredients,
    required this.healthRating,
    required this.servingSize,
    this.image,
  });

  // Factory constructor to create a FoodAnalysis from JSON
  factory FoodAnalysis.fromJson(Map<String, dynamic> json) {
    return FoodAnalysis(
      id: json['id'] ?? '0',
      foodName: json['food_name'] ?? 'Unknown Food',
      calories: json['calories'] ?? 0,
      protein: json['protein'] ?? 0,
      carbs: json['carbs'] ?? 0,
      fat: json['fat'] ?? 0,
      ingredients:
          (json['ingredients'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      healthRating: json['health_rating'] ?? 0,
      servingSize: json['serving_size'] ?? 'serving',
      image: null, // Image will be added separately
    );
  }

  // Convert FoodAnalysis to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'food_name': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'ingredients': ingredients,
      'health_rating': healthRating,
      'serving_size': servingSize,
    };
  }
}
