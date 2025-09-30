import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logging/logging.dart';
import '../../screens/search/workout_detail/models/workout_item.dart';
import '../api/unified_api_service.dart';
import '../database/translation_database_service.dart';
import '../error_handling/translation_error_handler.dart';

final log = Logger('OfflineTranslationService');

class OfflineTranslationService {
  final UnifiedApiService _apiService;
  final TranslationDatabaseService _databaseService;
  final Connectivity _connectivity = Connectivity();

  OfflineTranslationService({bool useProduction = false})
      : _apiService = UnifiedApiService(useProductionTranslation: useProduction),
        _databaseService = TranslationDatabaseService();

  /// Get meals with offline fallback
  Future<List<Map<String, dynamic>>> getMealsByCategory(
    String category, {
    String? language,
    int page = 0,
    int limit = 8,
  }) async {
    return await TranslationErrorHandler.executeWithCacheFallback(
      // Primary (online) operation
      () async {
        final isOnline = await _checkConnectivity();
        if (!isOnline) {
          throw NetworkException('No internet connection');
        }
        return await _apiService.getMealsByCategory(
          category,
          language: language,
          page: page,
          limit: limit,
        );
      },
      // Cache (offline) operation
      () async {
        if (language == null || language == 'en') {
          return null; // No cache for English content
        }

        final cachedMeals = await _getCachedMealsByCategory(category, language, page, limit);
        if (cachedMeals.isNotEmpty) {
          return cachedMeals.map((meal) => _convertCachedMealToMap(meal)).toList();
        }
        return null;
      },
      'getMealsByCategory($category, $language)',
      ultimateFallback: <Map<String, dynamic>>[],
    );
  }

  /// Get meal by ID with offline fallback
  Future<Map<String, dynamic>?> getMealById(String id, {String? language}) async {
    return await TranslationErrorHandler.executeWithCacheFallback(
      // Primary (online) operation
      () async {
        final isOnline = await _checkConnectivity();
        if (!isOnline) {
          throw NetworkException('No internet connection');
        }
        return await _apiService.getMealById(id, language: language);
      },
      // Cache (offline) operation
      () async {
        if (language == null || language == 'en') {
          return null;
        }

        final cachedMeal = await _databaseService.getMeal(id, language);
        return cachedMeal != null ? _convertCachedMealToMap(cachedMeal) : null;
      },
      'getMealById($id, $language)',
    );
  }

  /// Search meals with offline fallback
  Future<List<Map<String, dynamic>>> searchMeals(String query, {String? language}) async {
    return await TranslationErrorHandler.executeWithCacheFallback(
      // Primary (online) operation
      () async {
        final isOnline = await _checkConnectivity();
        if (!isOnline) {
          throw NetworkException('No internet connection');
        }
        return await _apiService.searchMeals(query, language: language);
      },
      // Cache (offline) operation
      () async {
        if (language == null || language == 'en') {
          return null;
        }

        final cachedMeals = await _searchCachedMeals(query, language);
        return cachedMeals.map((meal) => _convertCachedMealToMap(meal)).toList();
      },
      'searchMeals($query, $language)',
      ultimateFallback: <Map<String, dynamic>>[],
    );
  }

  /// Get exercises with offline fallback
  Future<List<WorkoutItem>> getExercisesByTarget(String target, {String? language}) async {
    return await TranslationErrorHandler.executeWithCacheFallback(
      // Primary (online) operation
      () async {
        final isOnline = await _checkConnectivity();
        if (!isOnline) {
          throw NetworkException('No internet connection');
        }
        return await _apiService.getExercisesByTarget(target, language: language);
      },
      // Cache (offline) operation
      () async {
        if (language == null || language == 'en') {
          return null;
        }

        final cachedExercises = await _getCachedExercisesByTarget(target, language);
        return cachedExercises.map((exercise) => _convertCachedExerciseToWorkoutItem(exercise)).toList();
      },
      'getExercisesByTarget($target, $language)',
      ultimateFallback: <WorkoutItem>[],
    );
  }

  /// Check internet connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isConnected = !connectivityResult.contains(ConnectivityResult.none);

      if (!isConnected) {
        log.info('📱 Device is offline');
      }

      return isConnected;
    } catch (e) {
      log.warning('Failed to check connectivity: $e');
      return false; // Assume offline if check fails
    }
  }

  /// Get cached meals by category with filtering
  Future<List<dynamic>> _getCachedMealsByCategory(
    String category,
    String language,
    int page,
    int limit,
  ) async {
    try {
      final allCachedMeals = await _databaseService.getMealsForLanguage(language);

      // Filter by category
      final categoryMeals = category.toLowerCase() == 'all'
          ? allCachedMeals
          : allCachedMeals.where((meal) =>
              meal.translatedCategory?.toLowerCase() == category.toLowerCase() ||
              meal.originalCategory?.toLowerCase() == category.toLowerCase()).toList();

      // Apply pagination
      final startIndex = page * limit;
      final endIndex = (startIndex + limit).clamp(0, categoryMeals.length);

      if (startIndex >= categoryMeals.length) {
        return [];
      }

      final result = categoryMeals.sublist(startIndex, endIndex);
      log.info('📱 Found ${result.length} cached meals for category: $category ($language)');
      return result;
    } catch (e) {
      log.warning('Failed to get cached meals: $e');
      return [];
    }
  }

  /// Search in cached meals
  Future<List<dynamic>> _searchCachedMeals(String query, String language) async {
    try {
      final allCachedMeals = await _databaseService.getMealsForLanguage(language);
      final queryLower = query.toLowerCase();

      final matchingMeals = allCachedMeals.where((meal) {
        final nameMatch = meal.translatedName.toLowerCase().contains(queryLower) ||
            meal.originalName.toLowerCase().contains(queryLower);
        final categoryMatch = (meal.translatedCategory?.toLowerCase().contains(queryLower) ?? false) ||
            (meal.originalCategory?.toLowerCase().contains(queryLower) ?? false);
        final areaMatch = (meal.translatedArea?.toLowerCase().contains(queryLower) ?? false) ||
            (meal.originalArea?.toLowerCase().contains(queryLower) ?? false);
        final ingredientMatch = meal.translatedIngredients.any((ingredient) =>
            ingredient.toLowerCase().contains(queryLower)) ||
            meal.originalIngredients.any((ingredient) =>
                ingredient.toLowerCase().contains(queryLower));

        return nameMatch || categoryMatch || areaMatch || ingredientMatch;
      }).toList();

      log.info('📱 Found ${matchingMeals.length} cached meals for query: "$query" ($language)');
      return matchingMeals;
    } catch (e) {
      log.warning('Failed to search cached meals: $e');
      return [];
    }
  }

  /// Get cached exercises by target
  Future<List<dynamic>> _getCachedExercisesByTarget(String target, String language) async {
    try {
      final allCachedExercises = await _databaseService.getExercisesForLanguage(language);
      final targetLower = target.toLowerCase();

      final matchingExercises = allCachedExercises.where((exercise) {
        final nameMatch = exercise.translatedName.toLowerCase().contains(targetLower) ||
            exercise.originalName.toLowerCase().contains(targetLower);
        final targetMatch = (exercise.translatedTarget?.toLowerCase().contains(targetLower) ?? false) ||
            (exercise.originalTarget?.toLowerCase().contains(targetLower) ?? false);
        final bodyPartMatch = (exercise.translatedBodyPart?.toLowerCase().contains(targetLower) ?? false) ||
            (exercise.originalBodyPart?.toLowerCase().contains(targetLower) ?? false);

        return nameMatch || targetMatch || bodyPartMatch;
      }).toList();

      log.info('📱 Found ${matchingExercises.length} cached exercises for target: $target ($language)');
      return matchingExercises;
    } catch (e) {
      log.warning('Failed to get cached exercises: $e');
      return [];
    }
  }

  /// Convert cached meal to API format
  Map<String, dynamic> _convertCachedMealToMap(dynamic meal) {
    return {
      'id': meal.id,
      'titleKey': meal.translatedName,
      'category': meal.translatedCategory ?? meal.originalCategory,
      'area': meal.translatedArea ?? meal.originalArea,
      'instructions': meal.translatedInstructions,
      'ingredients': meal.translatedIngredients,
      'imagePath': meal.imagePath,
      'calories': meal.calories,
      'prepTime': meal.prepTime,
      'cookTime': meal.cookTime,
      'difficulty': meal.difficulty,
      'servings': meal.servings,
      'isVegan': meal.isVegan,
      'nutritionFacts': meal.nutritionFacts,
      'youtubeUrl': meal.youtubeUrl,
      'isTranslated': true,
      'isFromCache': true,
      'translatedAt': meal.translatedAt.toIso8601String(),
    };
  }

  /// Convert cached exercise to WorkoutItem
  WorkoutItem _convertCachedExerciseToWorkoutItem(dynamic exercise) {
    return WorkoutItem(
      title: exercise.translatedName,
      image: exercise.gifUrl ?? '',
      duration: exercise.duration ?? '45 seconds',
      difficulty: exercise.difficulty ?? 'Medium',
      description: exercise.translatedDescription,
      rating: exercise.rating ?? 4.5,
      steps: [], // You might want to create proper steps from instructions
      equipment: exercise.translatedEquipment,
      caloriesBurn: exercise.caloriesBurn ?? '100-150',
      tips: exercise.translatedTips,
    );
  }

  /// Get offline status information
  Future<Map<String, dynamic>> getOfflineStatus() async {
    try {
      final isOnline = await _checkConnectivity();
      final translationCounts = await _databaseService.getTranslationCounts();

      // Check availability for each language
      final languages = ['es', 'pt', 'fr', 'de', 'it', 'ru', 'ja', 'zh', 'hi', 'ko'];
      final languageStatus = <String, bool>{};

      for (final language in languages) {
        languageStatus[language] = await _databaseService.hasTranslationsForLanguage(language);
      }

      return {
        'isOnline': isOnline,
        'totalTranslations': translationCounts['total'],
        'mealTranslations': translationCounts['meals'],
        'exerciseTranslations': translationCounts['exercises'],
        'languageAvailability': languageStatus,
        'offlineCapable': translationCounts['total']! > 0,
      };
    } catch (e) {
      log.warning('Failed to get offline status: $e');
      return {
        'isOnline': false,
        'totalTranslations': 0,
        'mealTranslations': 0,
        'exerciseTranslations': 0,
        'languageAvailability': <String, bool>{},
        'offlineCapable': false,
      };
    }
  }

  /// Prefetch essential content for offline use
  Future<void> prefetchForOffline({
    List<String>? languages,
    List<String>? mealCategories,
    List<String>? exerciseTargets,
  }) async {
    final targetLanguages = languages ?? ['es', 'pt', 'fr', 'de'];
    final categories = mealCategories ?? ['Chicken', 'Vegetarian', 'Pasta'];
    final targets = exerciseTargets ?? ['abs', 'chest', 'legs'];

    log.info('🔄 Starting offline prefetch for ${targetLanguages.length} languages');

    try {
      for (final language in targetLanguages) {
        if (language == 'en') continue; // Skip English

        log.info('📦 Prefetching content for: $language');

        // Prefetch meals
        for (final category in categories) {
          try {
            await getMealsByCategory(category, language: language, limit: 10);
            await Future.delayed(const Duration(milliseconds: 500)); // Rate limiting
          } catch (e) {
            log.warning('Failed to prefetch meals for $category ($language): $e');
          }
        }

        // Prefetch exercises
        for (final target in targets) {
          try {
            await getExercisesByTarget(target, language: language);
            await Future.delayed(const Duration(milliseconds: 500)); // Rate limiting
          } catch (e) {
            log.warning('Failed to prefetch exercises for $target ($language): $e');
          }
        }

        // Longer delay between languages
        await Future.delayed(const Duration(seconds: 1));
      }

      log.info('✅ Offline prefetch completed');
    } catch (e) {
      log.severe('❌ Offline prefetch failed: $e');
    }
  }

  /// Cleanup resources
  Future<void> dispose() async {
    await _apiService.dispose();
    await _databaseService.close();
  }
}