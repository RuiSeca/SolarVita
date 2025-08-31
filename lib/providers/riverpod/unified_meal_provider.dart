import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:logger/logger.dart';
import '../../services/chat/data_sync_service.dart';

final logger = Logger();

/// State class to hold unified meal data from both local meal plans and profile
class UnifiedMealState {
  final Map<String, List<Map<String, dynamic>>>? todaysMeals;
  final Map<int, Map<String, List<Map<String, dynamic>>>>? weeklyMeals;
  final bool isLoading;
  final String? error;
  final DateTime lastSynced;

  static final DateTime _defaultDateTime = DateTime(2000);

  UnifiedMealState({
    this.todaysMeals,
    this.weeklyMeals,
    this.isLoading = false,
    this.error,
    DateTime? lastSynced,
  }) : lastSynced = lastSynced ?? _defaultDateTime;

  UnifiedMealState copyWith({
    Map<String, List<Map<String, dynamic>>>? todaysMeals,
    Map<int, Map<String, List<Map<String, dynamic>>>>? weeklyMeals,
    bool? isLoading,
    String? error,
    DateTime? lastSynced,
  }) {
    return UnifiedMealState(
      todaysMeals: todaysMeals ?? this.todaysMeals,
      weeklyMeals: weeklyMeals ?? this.weeklyMeals,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastSynced: lastSynced ?? this.lastSynced,
    );
  }

  bool get hasData => todaysMeals != null && todaysMeals!.isNotEmpty;
  bool get hasError => error != null;
}

/// Unified meal provider that combines meal plan data with profile meal data
class UnifiedMealNotifier extends StateNotifier<UnifiedMealState> {
  UnifiedMealNotifier() : super(UnifiedMealState()) {
    loadMealData();
  }

  static const String _weeklyMealDataKey = 'weeklyMealData';

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }

  /// Load meal data from local storage
  Future<void> loadMealData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load weekly meal data from SharedPreferences (same as meal plan screen)
      final savedWeeklyData = prefs.getString(_weeklyMealDataKey);
      Map<int, Map<String, List<Map<String, dynamic>>>> weeklyMeals = {};
      
      if (savedWeeklyData != null) {
        logger.d('Raw saved data found: ${savedWeeklyData.substring(0, math.min(200, savedWeeklyData.length))}...');
        final decodedData = json.decode(savedWeeklyData) as Map<String, dynamic>;
        logger.d('Decoded data keys: ${decodedData.keys}');
        
        decodedData.forEach((String key, dynamic value) {
          final dayIndex = int.parse(key);
          weeklyMeals[dayIndex] = {};
          logger.d('Processing day $dayIndex ($key)');
          
          if (value is Map<String, dynamic>) {
            value.forEach((mealTime, meals) {
              if (meals is List) {
                final mealList = meals
                    .map((meal) => Map<String, dynamic>.from(meal as Map))
                    .toList();
                weeklyMeals[dayIndex]![mealTime] = mealList;
                logger.d('  $mealTime: ${mealList.length} meals');
                
                // Debug first meal
                if (mealList.isNotEmpty) {
                  final firstMeal = mealList.first;
                  logger.d('    - ${firstMeal['titleKey'] ?? firstMeal['name'] ?? 'Unnamed'} (suggested: ${firstMeal['isSuggested']})');
                }
              }
            });
          }
        });
        logger.d('Final weekly meals keys: ${weeklyMeals.keys}');
      } else {
        logger.d('No saved meal data found in SharedPreferences');
      }
      
      // Get today's meals
      final today = DateTime.now();
      final todayIndex = today.weekday - 1;
      logger.d('Today is ${today.weekday} (${_getDayName(today.weekday)}), index: $todayIndex');
      
      final todaysMeals = weeklyMeals[todayIndex] ?? {
        'breakfast': <Map<String, dynamic>>[],
        'lunch': <Map<String, dynamic>>[],
        'dinner': <Map<String, dynamic>>[],
        'snacks': <Map<String, dynamic>>[],
      };
      
      logger.d('Today\'s meals summary:');
      int totalMeals = 0;
      int realMeals = 0;
      todaysMeals.forEach((mealTime, meals) {
        final realMealCount = meals.where((m) => m['isSuggested'] != true).length;
        totalMeals += meals.length;
        realMeals += realMealCount;
        logger.d('  $mealTime: ${meals.length} total, $realMealCount real');
      });
      logger.d('Grand total: $totalMeals meals ($realMeals real)');
      
      state = state.copyWith(
        todaysMeals: todaysMeals,
        weeklyMeals: weeklyMeals,
        isLoading: false,
        lastSynced: DateTime.now(),
      );
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load meal data: $e',
      );
      logger.e('Error loading unified meal data: $e');
    }
  }

  /// Refresh data from local storage and sync with Firebase
  Future<void> refreshMealData() async {
    await loadMealData();
    await syncMealsToFirebase();
  }

  /// Sync current meal data to Firebase
  Future<void> syncMealsToFirebase() async {
    try {
      if (state.todaysMeals != null && state.todaysMeals!.isNotEmpty) {
        // Filter out suggested meals and empty meal lists
        final realMealsOnly = <String, List<Map<String, dynamic>>>{};
        bool hasRealMeals = false;
        
        state.todaysMeals!.forEach((mealTime, meals) {
          final realMeals = meals
              .where((meal) => meal['isSuggested'] != true)
              .toList();
          realMealsOnly[mealTime] = realMeals;
          if (realMeals.isNotEmpty) hasRealMeals = true;
        });
        
        if (hasRealMeals) {
          await DataSyncService().syncDailyMeals(realMealsOnly);
          logger.d('Successfully synced unified meal data to Firebase');
        }
      }
    } catch (e) {
      logger.e('Error syncing unified meal data to Firebase: $e');
    }
  }

  /// Get meals for a specific day
  Map<String, List<Map<String, dynamic>>>? getMealsForDay(int dayIndex) {
    return state.weeklyMeals?[dayIndex];
  }

  /// Get all meals flattened into a single list (for profile display)
  List<Map<String, dynamic>> getAllMealsAsList() {
    if (state.todaysMeals == null) return [];
    
    final allMeals = <Map<String, dynamic>>[];
    state.todaysMeals!.forEach((mealTime, meals) {
      for (final meal in meals) {
        if (meal['isSuggested'] != true) {
          // Add meal time info for display
          final mealWithTime = Map<String, dynamic>.from(meal);
          mealWithTime['mealTime'] = mealTime;
          allMeals.add(mealWithTime);
        }
      }
    });
    
    return allMeals;
  }

  /// Calculate nutrition totals for today
  Map<String, double> getTodaysNutrition() {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    if (state.todaysMeals != null) {
      for (final meals in state.todaysMeals!.values) {
        for (final meal in meals) {
          if (meal['isSuggested'] == true) continue; // Skip suggested meals
          
          if (meal['nutritionFacts'] != null) {
            totalCalories += double.tryParse(
              meal['nutritionFacts']['calories']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0',
            ) ?? 0;
            totalProtein += double.tryParse(
              meal['nutritionFacts']['protein']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0',
            ) ?? 0;
            totalCarbs += double.tryParse(
              meal['nutritionFacts']['carbs']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0',
            ) ?? 0;
            totalFat += double.tryParse(
              meal['nutritionFacts']['fat']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0',
            ) ?? 0;
          }
        }
      }
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }

  /// Get meal count for today (excluding suggested meals)
  int getTodaysMealCount() {
    if (state.todaysMeals == null) {
      logger.d('getTodaysMealCount: todaysMeals is null');
      return 0;
    }
    
    int count = 0;
    state.todaysMeals!.forEach((mealTime, meals) {
      final realMealCount = meals.where((meal) => meal['isSuggested'] != true).length;
      count += realMealCount;
      logger.d('getTodaysMealCount: $mealTime has $realMealCount real meals');
    });
    
    logger.d('getTodaysMealCount: Total count = $count');
    return count;
  }
}

/// Provider for unified meal data
final unifiedMealProvider = StateNotifierProvider<UnifiedMealNotifier, UnifiedMealState>((ref) {
  return UnifiedMealNotifier();
});

/// Convenience providers
final todaysMealsProvider = Provider<Map<String, List<Map<String, dynamic>>>>((ref) {
  final mealState = ref.watch(unifiedMealProvider);
  return mealState.todaysMeals ?? {};
});

final todaysMealsListProvider = Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(unifiedMealProvider); // Ensure dependency on state changes
  final notifier = ref.watch(unifiedMealProvider.notifier);
  return notifier.getAllMealsAsList();
});

final todaysNutritionProvider = Provider<Map<String, double>>((ref) {
  ref.watch(unifiedMealProvider); // Ensure dependency on state changes
  final notifier = ref.watch(unifiedMealProvider.notifier);
  return notifier.getTodaysNutrition();
});

final todaysMealCountProvider = Provider<int>((ref) {
  ref.watch(unifiedMealProvider); // Ensure dependency on state changes
  final notifier = ref.watch(unifiedMealProvider.notifier);
  return notifier.getTodaysMealCount();
});

final mealDataLoadingProvider = Provider<bool>((ref) {
  final mealState = ref.watch(unifiedMealProvider);
  return mealState.isLoading;
});

final mealDataErrorProvider = Provider<String?>((ref) {
  final mealState = ref.watch(unifiedMealProvider);
  return mealState.error;
});