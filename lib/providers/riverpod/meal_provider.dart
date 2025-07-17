import 'dart:async';
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/recipe_service.dart';

part 'meal_provider.g.dart';

// Service provider
@riverpod
MealDBService mealService(Ref ref) {
  return MealDBService();
}

// Meal state class to hold the complete state
class MealState {
  final List<Map<String, dynamic>>? meals;
  final String? currentCategory;
  final String? currentQuery;
  final String? errorMessage;
  final String? errorDetails;
  final bool isLoading;

  const MealState({
    this.meals,
    this.currentCategory,
    this.currentQuery,
    this.errorMessage,
    this.errorDetails,
    this.isLoading = false,
  });

  MealState copyWith({
    List<Map<String, dynamic>>? meals,
    String? currentCategory,
    String? currentQuery,
    String? errorMessage,
    String? errorDetails,
    bool? isLoading,
  }) {
    return MealState(
      meals: meals ?? this.meals,
      currentCategory: currentCategory ?? this.currentCategory,
      currentQuery: currentQuery ?? this.currentQuery,
      errorMessage: errorMessage ?? this.errorMessage,
      errorDetails: errorDetails ?? this.errorDetails,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get hasError => errorMessage != null;
  bool get hasData => meals != null && meals!.isNotEmpty;
}

// Main meal provider using StateNotifier pattern
@Riverpod(keepAlive: true)
class MealNotifier extends _$MealNotifier {
  // Cache to store previously loaded data
  final Map<String, List<Map<String, dynamic>>> _cache = {};
  // Track most recently used queries/categories
  final List<String> _recentKeys = [];
  // Maximum number of searches to keep in cache
  static const int _maxCacheSize = 15; // Increased cache size for better performance

  @override
  MealState build() {
    // Preload popular categories in background for faster access
    _preloadPopularCategories();
    return const MealState();
  }

  // Preload popular categories in the background
  void _preloadPopularCategories() {
    Future.delayed(const Duration(milliseconds: 1000), () async {
      // Preload the most commonly accessed categories
      final popularCategories = ['chicken', 'beef', 'pasta', 'vegetarian', 'seafood'];
      for (String category in popularCategories) {
        try {
          final mealService = ref.read(mealServiceProvider);
          final meals = await mealService.getMealsByCategory(category);
          final cacheKey = 'category_$category';
          _cache[cacheKey] = meals; // Cache ALL meals from each category
          _updateRecentKeys(cacheKey);
        } catch (e) {
          // Ignore errors during preloading
        }
      }
    });
  }

  Future<void> loadMealsByCategory(String category) async {
    final normalizedCategory = category.trim().toLowerCase();
    final cacheKey = 'category_$normalizedCategory';

    // Prevent duplicate loading
    if (state.isLoading) {
      return;
    }

    // Check if we have this data in cache
    if (_cache.containsKey(cacheKey)) {
      state = state.copyWith(
        currentCategory: normalizedCategory,
        meals: _cache[cacheKey],
        isLoading: false,
        errorMessage: null,
        errorDetails: null,
      );
      _updateRecentKeys(cacheKey);
      return;
    }

    // Skip if we're already loaded for this category
    if (state.currentCategory == normalizedCategory && state.hasData) {
      return;
    }

    // Set loading state
    state = state.copyWith(
      isLoading: true,
      currentCategory: normalizedCategory,
      errorMessage: null,
      errorDetails: null,
    );

    try {
      final mealService = ref.read(mealServiceProvider);
      List<Map<String, dynamic>> meals;
      
      if (normalizedCategory == 'all') {
        meals = await mealService.getAllMeals();
      } else {
        meals = await mealService.getMealsByCategory(normalizedCategory);
      }

      if (meals.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No meals found',
          errorDetails: 'No meals available for this category.',
        );
        return;
      }

      // Update cache with new data
      _cache[cacheKey] = meals;
      _updateRecentKeys(cacheKey);
      _manageCache();

      state = state.copyWith(
        currentCategory: normalizedCategory,
        meals: meals,
        isLoading: false,
        errorMessage: null,
        errorDetails: null,
      );

    } catch (e) {
      String errorMessage;
      String errorDetails;

      if (e is SocketException) {
        errorMessage = 'Network error';
        errorDetails = 'Please check your internet connection and try again.';
      } else if (e is TimeoutException) {
        errorMessage = 'Connection timeout';
        errorDetails = 'The server is taking too long to respond. Please try again later.';
      } else {
        errorMessage = 'Unexpected error';
        errorDetails = 'Something went wrong while loading meals. Please try again.';
      }

      state = state.copyWith(
        isLoading: false,
        meals: null,
        errorMessage: errorMessage,
        errorDetails: errorDetails,
      );
    }
  }

  Future<void> searchMeals(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    final cacheKey = 'search_$normalizedQuery';

    if (normalizedQuery.isEmpty) {
      // Load default meals
      await loadMealsByCategory('all');
      return;
    }

    // Prevent duplicate loading
    if (state.isLoading) {
      return;
    }

    // Check if we have this search in cache
    if (_cache.containsKey(cacheKey)) {
      state = state.copyWith(
        currentQuery: normalizedQuery,
        meals: _cache[cacheKey],
        isLoading: false,
        errorMessage: null,
        errorDetails: null,
      );
      _updateRecentKeys(cacheKey);
      return;
    }

    // Set loading state
    state = state.copyWith(
      isLoading: true,
      currentQuery: normalizedQuery,
      errorMessage: null,
      errorDetails: null,
    );

    try {
      final mealService = ref.read(mealServiceProvider);
      final meals = await mealService.searchMeals(normalizedQuery);

      if (meals.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No meals found',
          errorDetails: 'Try a different search term.',
        );
        return;
      }

      // Update cache with new data
      _cache[cacheKey] = meals;
      _updateRecentKeys(cacheKey);
      _manageCache();

      state = state.copyWith(
        currentQuery: normalizedQuery,
        meals: meals,
        isLoading: false,
        errorMessage: null,
        errorDetails: null,
      );

    } catch (e) {
      String errorMessage;
      String errorDetails;

      if (e is SocketException) {
        errorMessage = 'Network error';
        errorDetails = 'Please check your internet connection and try again.';
      } else if (e is TimeoutException) {
        errorMessage = 'Connection timeout';
        errorDetails = 'The server is taking too long to respond. Please try again later.';
      } else {
        errorMessage = 'Unexpected error';
        errorDetails = 'Something went wrong while searching meals. Please try again.';
      }

      state = state.copyWith(
        isLoading: false,
        meals: null,
        errorMessage: errorMessage,
        errorDetails: errorDetails,
      );
    }
  }

  // Update the list of recently used keys
  void _updateRecentKeys(String key) {
    _recentKeys.remove(key);
    _recentKeys.insert(0, key);
    if (_recentKeys.length > _maxCacheSize) {
      _recentKeys.removeLast();
    }
  }

  // Manage the cache size by removing least recently used items
  void _manageCache() {
    if (_cache.length <= _maxCacheSize) return;

    final keysToKeep = Set<String>.from(_recentKeys);
    _cache.removeWhere((key, _) => !keysToKeep.contains(key));
  }

  void clearMeals() {
    state = const MealState();
  }

  void retryCurrentSearch() {
    if (state.currentQuery != null) {
      searchMeals(state.currentQuery!);
    } else if (state.currentCategory != null) {
      loadMealsByCategory(state.currentCategory!);
    }
  }

  void clearError() {
    if (state.hasError) {
      state = state.copyWith(
        errorMessage: null,
        errorDetails: null,
      );
    }
  }

  // Update favorite status of a specific meal
  void updateMealFavoriteStatus(String mealId, bool isFavorite) {
    if (state.meals == null) return;

    final updatedMeals = state.meals!.map((meal) {
      if (meal['id'] == mealId) {
        return {
          ...meal,
          'isFavorite': isFavorite,
        };
      }
      return meal;
    }).toList();

    // Update current state
    state = state.copyWith(meals: updatedMeals);

    // Update cache as well
    for (final entry in _cache.entries) {
      final updatedCachedMeals = entry.value.map((meal) {
        if (meal['id'] == mealId) {
          return {
            ...meal,
            'isFavorite': isFavorite,
          };
        }
        return meal;
      }).toList();
      _cache[entry.key] = updatedCachedMeals;
    }
  }

  // Get cache info for debugging
  Map<String, int> getCacheInfo() {
    return {
      'cacheSize': _cache.length,
      'recentKeysCount': _recentKeys.length,
    };
  }
}

// Convenience providers for common meal data
@riverpod
List<Map<String, dynamic>> meals(Ref ref) {
  final mealState = ref.watch(mealNotifierProvider);
  return mealState.meals ?? [];
}

@riverpod
bool isMealsLoading(Ref ref) {
  final mealState = ref.watch(mealNotifierProvider);
  return mealState.isLoading;
}

@riverpod
bool hasMealsError(Ref ref) {
  final mealState = ref.watch(mealNotifierProvider);
  return mealState.hasError;
}

@riverpod
String? mealsErrorMessage(Ref ref) {
  final mealState = ref.watch(mealNotifierProvider);
  return mealState.errorMessage;
}

@riverpod
String? mealsErrorDetails(Ref ref) {
  final mealState = ref.watch(mealNotifierProvider);
  return mealState.errorDetails;
}

@riverpod
String? currentMealCategory(Ref ref) {
  final mealState = ref.watch(mealNotifierProvider);
  return mealState.currentCategory;
}

@riverpod
String? currentMealQuery(Ref ref) {
  final mealState = ref.watch(mealNotifierProvider);
  return mealState.currentQuery;
}

@riverpod
bool hasMealsData(Ref ref) {
  final mealState = ref.watch(mealNotifierProvider);
  return mealState.hasData;
}