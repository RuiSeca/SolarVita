
/// Model for flexible nutrition calculations
class FlexibleNutritionCalculator {
  final double totalWeight; // Total weight in grams
  final Map<String, double> totalNutrients; // Total nutrients for whole meal
  final int servings; // Number of servings
  
  FlexibleNutritionCalculator({
    required this.totalWeight,
    required this.totalNutrients,
    required this.servings,
  });

  /// Weight per serving in grams
  double get weightPerServing => totalWeight / servings;

  /// Calculate nutrition per 100g
  Map<String, double> get nutritionPer100g {
    final Map<String, double> per100g = {};
    totalNutrients.forEach((key, value) {
      per100g[key] = (value / totalWeight) * 100;
    });
    return per100g;
  }

  /// Calculate nutrition per serving
  Map<String, double> get nutritionPerServing {
    final Map<String, double> perServing = {};
    totalNutrients.forEach((key, value) {
      perServing[key] = value / servings;
    });
    return perServing;
  }

  /// Calculate nutrition for specific grams input
  Map<String, double> nutritionForGrams(double grams) {
    final Map<String, double> forGrams = {};
    final per100g = nutritionPer100g;
    per100g.forEach((key, value) {
      forGrams[key] = value * (grams / 100);
    });
    return forGrams;
  }

  /// Calculate serving fraction for given grams
  double servingFractionForGrams(double grams) {
    return grams / weightPerServing;
  }

  /// Calculate grams for given serving count
  double gramsForServings(double servingCount) {
    return servingCount * weightPerServing;
  }

  /// Round to 1 decimal place for display
  static double roundToOneDecimal(double value) {
    return (value * 10).round() / 10;
  }

  /// Format nutrition value for display
  static String formatNutritionValue(double value, String unit) {
    final rounded = roundToOneDecimal(value);
    if (unit == 'kcal' || unit == 'cal') {
      return '${rounded.round()} $unit';
    }
    return '$rounded$unit';
  }
}

/// Nutrition display modes
enum NutritionDisplayMode {
  wholeMeal,
  per100g,
  perServing,
  customGrams,
}

/// Nutrition calculation result
class NutritionCalculationResult {
  final NutritionDisplayMode mode;
  final Map<String, double> nutrition;
  final double? grams;
  final double? servingFraction;
  final String description;

  NutritionCalculationResult({
    required this.mode,
    required this.nutrition,
    this.grams,
    this.servingFraction,
    required this.description,
  });
}