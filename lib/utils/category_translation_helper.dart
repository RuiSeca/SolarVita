import 'package:flutter/material.dart';
import 'translation_helper.dart';

class CategoryTranslationHelper {
  /// Translates a meal category name to the current app language
  static String translateCategory(BuildContext context, String categoryName) {
    final normalizedCategory = categoryName.toLowerCase().trim();

    // Map API category names to translation keys
    try {
      switch (normalizedCategory) {
        case 'all':
          return tr(context, 'all');
        case 'beef':
          return tr(context, 'beef');
        case 'chicken':
          return tr(context, 'chicken');
        case 'dessert':
          return tr(context, 'dessert');
        case 'lamb':
          return tr(context, 'lamb');
        case 'miscellaneous':
          return tr(context, 'miscellaneous');
        case 'pasta':
          return tr(context, 'pasta');
        case 'pork':
          return tr(context, 'pork');
        case 'seafood':
          return tr(context, 'seafood');
        case 'side':
          return tr(context, 'side');
        case 'starter':
          return tr(context, 'starter');
        case 'vegan':
          return tr(context, 'vegan');
        case 'vegetarian':
          return tr(context, 'vegetarian');
        case 'breakfast':
          return tr(context, 'breakfast');
        case 'goat':
          return tr(context, 'goat');
        default:
          // Return the original name if no translation is found
          return categoryName;
      }
    } catch (e) {
      // Fallback to original name if translation fails
      return categoryName;
    }
  }

  /// Gets the API category name from a translated category name
  /// This is useful when we need to make API calls with the original English names
  static String getApiCategoryName(String translatedCategory) {
    // This would need a reverse mapping, but for simplicity,
    // we can store the original API name alongside the translated name
    // For now, we'll handle this in the calling code by storing both
    return translatedCategory;
  }

  /// Gets all available categories with their translations
  static List<Map<String, String>> getAllCategoriesWithTranslations(BuildContext context) {
    final categories = [
      'All',
      'Beef',
      'Chicken',
      'Dessert',
      'Lamb',
      'Miscellaneous',
      'Pasta',
      'Pork',
      'Seafood',
      'Side',
      'Starter',
      'Vegan',
      'Vegetarian',
      'Breakfast',
      'Goat',
    ];

    return categories.map((category) => {
      'original': category,
      'translated': translateCategory(context, category),
      'apiName': category, // Keep original for API calls
    }).toList();
  }

  /// Checks if a category represents "all" meals
  static bool isAllCategory(String categoryName) {
    return categoryName.toLowerCase().trim() == 'all';
  }
}