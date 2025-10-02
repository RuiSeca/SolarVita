import 'dart:async';
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/meal/recipe_service.dart';
import '../../services/api/unified_api_service.dart';
import '../riverpod/language_provider.dart';

part 'meal_provider.g.dart';

// Logging control - set to false to reduce verbosity
class _MealProviderLogging {
  static const bool _enableCacheLogging = false;
  
  static void logCache(String message) {
    if (_enableCacheLogging) {
      // Using debug print to avoid avoid_print lint warning
      assert(() {
        // ignore: avoid_print
        print(message);
        return true;
      }());
    }
  }
  
}

// Service providers
@riverpod
MealDBService mealService(Ref ref) {
  return MealDBService();
}

// Manual provider for UnifiedApiService (not using @riverpod to avoid build_runner dependency)
final unifiedApiServiceProvider = Provider<UnifiedApiService>((ref) {
  return UnifiedApiService(useProductionTranslation: false, ref: ref);
});

// Language-aware meal providers that automatically update when language changes
final mealsByCategoryLanguageAwareProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, category) async {
  final unifiedService = ref.read(unifiedApiServiceProvider);
  final currentLanguage = ref.watch(currentLanguageProvider); // Watch for language changes!

  return await unifiedService.getMealsByCategory(category, language: currentLanguage.code);
});

final searchMealsLanguageAwareProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  final unifiedService = ref.read(unifiedApiServiceProvider);
  final currentLanguage = ref.watch(currentLanguageProvider); // Watch for language changes!

  if (query.isEmpty) return [];
  return await unifiedService.searchMeals(query, language: currentLanguage.code);
});

// Language change detector - triggers meal refresh when language changes
final languageChangeMealRefreshProvider = Provider<String>((ref) {
  final currentLanguage = ref.watch(currentLanguageProvider);

  // This provider rebuilds when language changes, triggering refresh in screens that watch it
  return currentLanguage.code;
});

// Meal state class to hold the complete state with pagination
class MealState {
  final List<Map<String, dynamic>>? meals;
  final String? currentCategory;
  final String? currentQuery;
  final String? errorMessage;
  final String? errorDetails;
  final bool isLoading;
  final bool isLoadingDetails;
  final bool isLoadingMore;
  final int currentPage;
  final bool hasMoreData;

  const MealState({
    this.meals,
    this.currentCategory,
    this.currentQuery,
    this.errorMessage,
    this.errorDetails,
    this.isLoading = false,
    this.isLoadingDetails = false,
    this.isLoadingMore = false,
    this.currentPage = 0,
    this.hasMoreData = true,
  });

  MealState copyWith({
    List<Map<String, dynamic>>? meals,
    String? currentCategory,
    String? currentQuery,
    String? errorMessage,
    String? errorDetails,
    bool? isLoading,
    bool? isLoadingDetails,
    bool? isLoadingMore,
    int? currentPage,
    bool? hasMoreData,
  }) {
    return MealState(
      meals: meals ?? this.meals,
      currentCategory: currentCategory ?? this.currentCategory,
      currentQuery: currentQuery ?? this.currentQuery,
      errorMessage: errorMessage ?? this.errorMessage,
      errorDetails: errorDetails ?? this.errorDetails,
      isLoading: isLoading ?? this.isLoading,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
    );
  }

  bool get hasError => errorMessage != null;
  bool get hasData => meals != null && meals!.isNotEmpty;
}

// Cache entry with timestamp for expiration
class CacheEntry {
  final List<Map<String, dynamic>> meals;
  final DateTime timestamp;
  
  CacheEntry(this.meals, this.timestamp);
  
  bool get isExpired => DateTime.now().difference(timestamp) > const Duration(minutes: 30);
}

// Main meal provider using StateNotifier pattern
@Riverpod(keepAlive: true)
class MealNotifier extends _$MealNotifier {
  // Simplified cache for pagination
  final Map<String, CacheEntry> _cache = {};
  final List<String> _recentKeys = [];
  static const int _maxCacheSize = 10; // Reduced cache size for pagination

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
      final popularCategories = [
        'chicken',
        'beef',
        'pasta',
        'vegetarian',
        'seafood',
      ];
      for (String category in popularCategories) {
        try {
          final unifiedService = ref.read(unifiedApiServiceProvider);
          final currentLanguage = ref.read(currentLanguageProvider);
          final meals = await unifiedService.getMealsByCategory(category, language: currentLanguage.code);
          final cacheKey = 'category_$category';
          _cache[cacheKey] = CacheEntry(meals, DateTime.now()); // Cache ALL meals from each category
          _updateRecentKeys(cacheKey);
        } catch (e) {
          // Ignore errors during preloading
        }
      }
    });
  }

  Future<void> loadMealsByCategory(String category, {bool loadMore = false}) async {
    // Normalize category for comparison but keep original case for API
    final normalizedCategoryForComparison = category.trim().toLowerCase();
    final apiCategory = category.trim(); // Keep original case for API

    // Prevent duplicate loading
    if (state.isLoading || (loadMore && state.isLoadingMore)) {
      return;
    }

    // If loading more but no more data available
    if (loadMore && !state.hasMoreData) {
      return;
    }

    // If switching categories, reset pagination
    if (!loadMore || state.currentCategory != normalizedCategoryForComparison) {
      state = state.copyWith(
        isLoading: true,
        currentCategory: normalizedCategoryForComparison,
        currentPage: 0,
        meals: [],
        hasMoreData: true,
        errorMessage: null,
        errorDetails: null,
      );
    } else {
      // Loading more data for same category
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final unifiedService = ref.read(unifiedApiServiceProvider);
      final currentLanguage = ref.read(currentLanguageProvider);
      final currentPage = loadMore ? state.currentPage + 1 : 0;

      List<Map<String, dynamic>> newMeals;

      if (normalizedCategoryForComparison == 'all') {
        // For 'all' category, we'll need to implement a different approach
        // For now, fallback to original method for 'all'
        final mealService = ref.read(mealServiceProvider);
        newMeals = await mealService.getAllMeals();
      } else {
        // Use unified service with automatic translation
        final pageLimit = currentPage == 0 ? 8 : 8; // First page loads 8 meals for better UX
        newMeals = await unifiedService.getMealsByCategory(
          apiCategory, // Use original case for API
          language: currentLanguage.code,
          page: currentPage,
          limit: pageLimit,
        );
      }

      // Check if we got fewer meals than requested (indicating no more data)
      final expectedLimit = 8;
      final hasMoreData = newMeals.length >= expectedLimit;

      final currentMeals = loadMore ? (state.meals ?? []) : <Map<String, dynamic>>[];
      final updatedMeals = <Map<String, dynamic>>[...currentMeals, ...newMeals];

      state = state.copyWith(
        currentCategory: normalizedCategoryForComparison,
        meals: updatedMeals,
        currentPage: currentPage,
        hasMoreData: hasMoreData,
        isLoading: false,
        isLoadingMore: false,
        errorMessage: null,
        errorDetails: null,
      );

      _MealProviderLogging.logCache('📊 Loaded page $currentPage: ${newMeals.length} meals for $normalizedCategoryForComparison. Total: ${updatedMeals.length}');

    } catch (e) {
      String errorMessage;
      String errorDetails;

      if (e is SocketException) {
        errorMessage = 'Network error';
        errorDetails = 'Please check your internet connection and try again.';
      } else if (e is TimeoutException) {
        errorMessage = 'Connection timeout';
        errorDetails =
            'The server is taking too long to respond. Please try again later.';
      } else if (e.toString().contains('circuit breaker') || e.toString().contains('rate limit')) {
        errorMessage = 'API rate limit reached';
        errorDetails = 'Too many requests. API will recover automatically in 30 seconds.';
        
        // Reset rate limiting to help recovery
        MealDBService.resetRateLimiting();
      } else {
        errorMessage = 'Unexpected error';
        errorDetails = 'Something went wrong while loading meals. Please try again.';
      }

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: errorMessage,
        errorDetails: errorDetails,
      );
    }
  }


  Future<void> searchMeals(String query, {bool loadMore = false}) async {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      // Load default meals
      await loadMealsByCategory('all');
      return;
    }

    // Prevent duplicate loading
    if (state.isLoading || (loadMore && state.isLoadingMore)) {
      return;
    }

    // If loading more but no more data available
    if (loadMore && !state.hasMoreData) {
      return;
    }

    // If new search, reset pagination
    if (!loadMore || state.currentQuery != normalizedQuery) {
      state = state.copyWith(
        isLoading: true,
        currentQuery: normalizedQuery,
        currentCategory: null, // Clear category when searching
        currentPage: 0,
        meals: [],
        hasMoreData: true,
        errorMessage: null,
        errorDetails: null,
      );
    } else {
      // Loading more search results
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final unifiedService = ref.read(unifiedApiServiceProvider);
      final currentLanguage = ref.read(currentLanguageProvider);
      final currentPage = loadMore ? state.currentPage + 1 : 0;

      // Use unified service search with automatic translation
      final newMeals = await unifiedService.searchMeals(
        normalizedQuery,
        language: currentLanguage.code,
      );

      // Check if we got fewer meals than requested (indicating no more data)
      // For search, if we get fewer than requested OR got empty results, no more relevant data
      final hasMoreData = newMeals.length >= 8 && newMeals.isNotEmpty;

      final currentMeals = loadMore ? (state.meals ?? []) : <Map<String, dynamic>>[];
      final updatedMeals = <Map<String, dynamic>>[...currentMeals, ...newMeals];

      if (updatedMeals.isEmpty && !loadMore) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No meals found',
          errorDetails: 'Try a different search term.',
        );
        return;
      }

      state = state.copyWith(
        currentQuery: normalizedQuery,
        meals: updatedMeals,
        currentPage: currentPage,
        hasMoreData: hasMoreData,
        isLoading: false,
        isLoadingMore: false,
        errorMessage: null,
        errorDetails: null,
      );

      _MealProviderLogging.logCache('🔍 Search page $currentPage: ${newMeals.length} results for "$normalizedQuery". Total: ${updatedMeals.length}');

    } catch (e) {
      String errorMessage;
      String errorDetails;

      if (e is SocketException) {
        errorMessage = 'Network error';
        errorDetails = 'Please check your internet connection and try again.';
      } else if (e is TimeoutException) {
        errorMessage = 'Connection timeout';
        errorDetails =
            'The server is taking too long to respond. Please try again later.';
      } else if (e.toString().contains('circuit breaker') || e.toString().contains('rate limit')) {
        errorMessage = 'API rate limit reached';
        errorDetails = 'Too many requests. API will recover automatically in 30 seconds.';
        
        // Reset rate limiting to help recovery
        MealDBService.resetRateLimiting();
      } else {
        errorMessage = 'Unexpected error';
        errorDetails = 'Something went wrong while searching meals. Please try again.';
      }

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
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


  // Load more meals (pagination)
  Future<void> loadMoreMeals() async {
    if (state.currentCategory != null) {
      await loadMealsByCategory(state.currentCategory!, loadMore: true);
    } else if (state.currentQuery != null) {
      await searchMeals(state.currentQuery!, loadMore: true);
    }
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
      state = state.copyWith(errorMessage: null, errorDetails: null);
    }
  }

  // Update favorite status of a specific meal
  void updateMealFavoriteStatus(String mealId, bool isFavorite) {
    if (state.meals == null) return;

    final updatedMeals = state.meals!.map((meal) {
      if (meal['id'] == mealId) {
        return {...meal, 'isFavorite': isFavorite};
      }
      return meal;
    }).toList();

    // Update current state
    state = state.copyWith(meals: updatedMeals);
    
    // Update cache with new data
    final cacheKey = _getCurrentCacheKey();
    if (cacheKey != null) {
      _cache[cacheKey] = CacheEntry(updatedMeals, DateTime.now());
    }
  }

  // Update complete meal data with detailed information from API
  void updateMealData(String mealId, Map<String, dynamic> detailedMealData) {
    if (state.meals == null) return;

    final updatedMeals = state.meals!.map((meal) {
      if (meal['id'] == mealId || meal['idMeal'] == mealId) {
        // Preserve the favorite status from the current meal
        final currentFavoriteStatus = meal['isFavorite'] ?? false;
        return {...detailedMealData, 'isFavorite': currentFavoriteStatus};
      }
      return meal;
    }).toList();

    // Update current state
    state = state.copyWith(meals: updatedMeals);

    // Update cache with detailed meal data
    final cacheKey = _getCurrentCacheKey();
    if (cacheKey != null) {
      _cache[cacheKey] = CacheEntry(updatedMeals, DateTime.now());
    }
  }

  // Helper method to get current cache key
  String? _getCurrentCacheKey() {
    if (state.currentQuery != null) {
      return 'search:${state.currentQuery}';
    } else if (state.currentCategory != null) {
      return 'category:${state.currentCategory}';
    }
    return null;
  }

  // Get cache info for debugging
  Map<String, int> getCacheInfo() {
    return {'cacheSize': _cache.length, 'recentKeysCount': _recentKeys.length};
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

@riverpod
bool isMealsLoadingDetails(Ref ref) {
  final mealState = ref.watch(mealNotifierProvider);
  return mealState.isLoadingDetails;
}

@riverpod
bool isLoadingMoreMeals(Ref ref) {
  final mealState = ref.watch(mealNotifierProvider);
  return mealState.isLoadingMore;
}

@riverpod
bool hasMoreMealsData(Ref ref) {
  final mealState = ref.watch(mealNotifierProvider);
  return mealState.hasMoreData;
}

@riverpod
int currentMealPage(Ref ref) {
  final mealState = ref.watch(mealNotifierProvider);
  return mealState.currentPage;
}
