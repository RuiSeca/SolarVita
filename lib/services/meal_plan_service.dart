import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MealPlanService {
  static final MealPlanService _instance = MealPlanService._internal();
  factory MealPlanService() => _instance;
  MealPlanService._internal();

  static const String _weeklyMealDataKey = 'weeklyMealData';

  /// Get custom meal names for a specific day and meal type
  Future<String?> getMealNameForNotification(String mealType, {DateTime? targetDate}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mealDataString = prefs.getString(_weeklyMealDataKey);
      
      if (mealDataString == null) return null;
      
      final Map<String, dynamic> weeklyData = jsonDecode(mealDataString);
      
      // Get the current week offset (default to 0 for current week)
      final now = targetDate ?? DateTime.now();
      final weekOffset = _getWeekOffset(now);
      final weekData = weeklyData[weekOffset.toString()];
      
      if (weekData == null) return null;
      
      // Get current day index (0 = Monday, 6 = Sunday)
      final dayIndex = now.weekday - 1;
      final dayData = weekData[dayIndex.toString()];
      
      if (dayData == null) return null;
      
      // Get meals for the specific meal type
      final meals = dayData[mealType] as List<dynamic>?;
      
      if (meals == null || meals.isEmpty) return null;
      
      // Return the first meal's name (or combine multiple if needed)
      final meal = meals.first as Map<String, dynamic>;
      return meal['name'] as String?;
      
    } catch (e) {
      return null;
    }
  }

  /// Get all custom meal names for today
  Future<Map<String, String>> getTodaysMealNames() async {
    final result = <String, String>{};
    final mealTypes = ['breakfast', 'lunch', 'dinner', 'snacks'];
    
    for (final mealType in mealTypes) {
      final mealName = await getMealNameForNotification(mealType);
      if (mealName != null) {
        result[mealType] = mealName;
      }
    }
    
    return result;
  }

  /// Get custom meal names for the entire week
  Future<Map<String, Map<String, String>>> getWeeklyMealNames() async {
    final result = <String, Map<String, String>>{};
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final mealTypes = ['breakfast', 'lunch', 'dinner', 'snacks'];
    
    for (int i = 0; i < days.length; i++) {
      final targetDate = DateTime.now().add(Duration(days: i - DateTime.now().weekday + 1));
      final dayMeals = <String, String>{};
      
      for (final mealType in mealTypes) {
        final mealName = await getMealNameForNotification(mealType, targetDate: targetDate);
        if (mealName != null) {
          dayMeals[mealType] = mealName;
        }
      }
      
      if (dayMeals.isNotEmpty) {
        result[days[i]] = dayMeals;
      }
    }
    
    return result;
  }

  /// Check if user has any meal plans set up
  Future<bool> hasMealPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mealDataString = prefs.getString(_weeklyMealDataKey);
      
      if (mealDataString == null) return false;
      
      final Map<String, dynamic> weeklyData = jsonDecode(mealDataString);
      return weeklyData.isNotEmpty;
      
    } catch (e) {
      return false;
    }
  }

  /// Update meal plan notification integration
  Future<void> updateMealPlanNotifications() async {
    try {
      // This would be called when meal plans are updated
      // to refresh notifications with new meal names
      await hasMealPlans();
      
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get week offset for meal data storage
  int _getWeekOffset(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final targetStartOfWeek = date.subtract(Duration(days: date.weekday - 1));
    
    return targetStartOfWeek.difference(startOfWeek).inDays ~/ 7;
  }

  /// Listen for meal plan changes (to be called when meal plan is updated)
  void onMealPlanUpdated() {
    updateMealPlanNotifications();
  }
}