import 'package:logging/logging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../screens/search/workout_detail/models/workout_item.dart';
import '../../screens/search/workout_detail/models/workout_step.dart';
import '../meal/recipe_service.dart';
import '../exercises/exercise_service.dart';
import '../translation/api_translation_service.dart';
import '../database/translation_database_service.dart';
import '../../models/translation/translated_meal.dart';
import '../../models/translation/translated_exercise.dart';
import '../../providers/riverpod/translation_progress_provider.dart';
import '../../utils/category_translation_helper.dart';

final log = Logger('UnifiedApiService');

class UnifiedApiService {
  final MealDBService _mealService;
  final ExerciseService _exerciseService;
  final ApiTranslationService _translationService;
  final TranslationDatabaseService _databaseService;
  final Ref? _ref;

  UnifiedApiService({
    bool useProductionTranslation = false,
    Ref? ref,
  }) : _mealService = MealDBService(),
        _exerciseService = ExerciseService(),
        _translationService = ApiTranslationService(useProduction: useProductionTranslation),
        _databaseService = TranslationDatabaseService(),
        _ref = ref;

  // MEAL OPERATIONS

  Future<List<Map<String, dynamic>>> getMealsByCategory(
    String category, {
    String? language,
    int page = 0,
    int limit = 8,
  }) async {
    final targetLanguage = language ?? 'en';

    if (targetLanguage == 'en') {
      // Return English data directly
      return await _mealService.getMealsByCategoryPaginated(category, page: page, limit: limit);
    }

    // Handle "All" category specially
    if (CategoryTranslationHelper.isAllCategory(category)) {
      return await _getMealsForAllCategory(targetLanguage, page: page, limit: limit);
    }

    try {
      // Check cache first
      final cachedMeals = await _getCachedMealsByCategory(category, targetLanguage, page, limit);

      // Check if we need to refresh (but serve cache while refreshing)
      final needsUpdate = await needsRefresh(targetLanguage);

      if (cachedMeals.isNotEmpty && !needsUpdate) {
        log.info('📱 Serving cached meals for category: $category ($targetLanguage)');
        return cachedMeals.map((meal) => _convertTranslatedMealToMap(meal)).toList();
      }

      // If we have cache but need update, serve cache and update in background
      if (cachedMeals.isNotEmpty && needsUpdate) {
        log.info('📱 Serving cached meals while refreshing in background: $category ($targetLanguage)');
        // Start background refresh (fire and forget)
        _refreshMealsInBackground(category, targetLanguage, page, limit);
        return cachedMeals.map((meal) => _convertTranslatedMealToMap(meal)).toList();
      }

      // Fetch from API and translate (first time or no cache)
      log.info('🌐 Fetching and translating meals for category: $category -> $targetLanguage');
      final englishMeals = await _mealService.getMealsByCategoryPaginated(category, page: page, limit: limit);

      if (englishMeals.isEmpty) {
        return [];
      }

      // Start progress tracking
      _ref?.read(translationProgressProvider.notifier).startProgress(
        language: targetLanguage,
        category: category,
        totalItems: englishMeals.length,
      );

      // Translate meals with progress tracking
      final translatedMeals = <TranslatedMeal>[];
      int translatedCount = 0;

      for (final mealData in englishMeals) {
        try {
          final translatedMeal = await _translationService.translateMeal(mealData, targetLanguage);
          translatedMeals.add(translatedMeal);
          translatedCount++;

          // Update progress
          _ref?.read(translationProgressProvider.notifier).updateProgress(translatedCount);
        } catch (e) {
          log.warning('Failed to translate meal ${mealData['titleKey']}: $e');
          // Continue with other meals
        }
      }

      // Batch save to database for better performance
      if (translatedMeals.isNotEmpty) {
        await _databaseService.saveMealsBatch(translatedMeals);
      }

      // Complete progress tracking
      _ref?.read(translationProgressProvider.notifier).completeProgress();

      // Update refresh tracking
      await _databaseService.updateRefreshTracking(
        targetLanguage,
        lastRefreshMeals: DateTime.now(),
      );

      log.info('✅ Translated and cached ${translatedMeals.length} meals');
      return translatedMeals.map((meal) => _convertTranslatedMealToMap(meal)).toList();

    } catch (e, stackTrace) {
      log.severe('❌ Failed to get translated meals for category: $category', e, stackTrace);

      // Report error to progress tracker
      _ref?.read(translationProgressProvider.notifier).errorProgress(
        'Translation failed. Falling back to ${targetLanguage == 'en' ? 'cached' : 'English'} content.',
      );

      // Fallback to cached data if available
      final cachedMeals = await _getCachedMealsByCategory(category, targetLanguage, page, limit);
      if (cachedMeals.isNotEmpty) {
        log.info('🔄 Falling back to cached meals');
        return cachedMeals.map((meal) => _convertTranslatedMealToMap(meal)).toList();
      }

      // Final fallback to English
      log.info('🔄 Falling back to English meals');
      return await _mealService.getMealsByCategoryPaginated(category, page: page, limit: limit);
    }
  }

  Future<Map<String, dynamic>?> getMealById(String id, {String? language}) async {
    final targetLanguage = language ?? 'en';

    if (targetLanguage == 'en') {
      return await _mealService.getMealById(id);
    }

    try {
      // Check cache first
      final cachedMeal = await _databaseService.getMeal(id, targetLanguage);
      if (cachedMeal != null) {
        log.fine('📱 Serving cached meal: ${cachedMeal.translatedName}');
        return _convertTranslatedMealToMap(cachedMeal);
      }

      // Fetch and translate
      final Map<String, dynamic> englishMeal;
      try {
        englishMeal = await _mealService.getMealById(id);
      } catch (e) {
        log.warning('Meal not found: $id', e);
        return null;
      }

      final translatedMeal = await _translationService.translateMeal(englishMeal, targetLanguage);
      await _databaseService.saveMeal(translatedMeal);

      log.info('✅ Translated meal: ${englishMeal['titleKey']} -> ${translatedMeal.translatedName}');
      return _convertTranslatedMealToMap(translatedMeal);

    } catch (e) {
      log.warning('Failed to get translated meal $id: $e');
      // Fallback to cached or English
      final cachedMeal = await _databaseService.getMeal(id, targetLanguage);
      if (cachedMeal != null) {
        return _convertTranslatedMealToMap(cachedMeal);
      }
      return await _mealService.getMealById(id);
    }
  }

  Future<List<Map<String, dynamic>>> searchMeals(String query, {String? language}) async {
    final targetLanguage = language ?? 'en';

    if (targetLanguage == 'en') {
      return await _mealService.searchMeals(query);
    }

    try {
      // For search, we fetch fresh data and translate on demand
      final englishMeals = await _mealService.searchMeals(query);

      if (englishMeals.isEmpty) {
        return [];
      }

      // Translate search results
      final translatedMeals = <Map<String, dynamic>>[];
      for (final mealData in englishMeals) {
        try {
          // Check cache first for each meal
          final mealId = mealData['id']?.toString() ?? '';
          final cachedMeal = await _databaseService.getMeal(mealId, targetLanguage);

          if (cachedMeal != null) {
            translatedMeals.add(_convertTranslatedMealToMap(cachedMeal));
          } else {
            // Translate and cache
            final translatedMeal = await _translationService.translateMeal(mealData, targetLanguage);
            await _databaseService.saveMeal(translatedMeal);
            translatedMeals.add(_convertTranslatedMealToMap(translatedMeal));
          }
        } catch (e) {
          log.warning('Failed to translate search result ${mealData['titleKey']}: $e');
          // Include original on translation failure
          translatedMeals.add(mealData);
        }
      }

      return translatedMeals;

    } catch (e) {
      log.warning('Failed to search translated meals: $e');
      return await _mealService.searchMeals(query);
    }
  }

  // EXERCISE OPERATIONS

  Future<List<WorkoutItem>> getExercisesByTarget(String target, {String? language}) async {
    final targetLanguage = language ?? 'en';

    if (targetLanguage == 'en') {
      return await _exerciseService.getExercisesByTarget(target);
    }

    try {
      // Check cache first
      final cachedExercises = await _getCachedExercisesByTarget(target, targetLanguage);
      if (cachedExercises.isNotEmpty) {
        log.info('📱 Serving cached exercises for target: $target ($targetLanguage)');
        return cachedExercises.map((exercise) => _convertTranslatedExerciseToWorkoutItem(exercise)).toList();
      }

      // Fetch from API and translate
      log.info('🌐 Fetching and translating exercises for target: $target -> $targetLanguage');
      final englishExercises = await _exerciseService.getExercisesByTarget(target);

      if (englishExercises.isEmpty) {
        return [];
      }

      // Translate exercises in parallel for better performance
      final translationFutures = englishExercises.map((exercise) async {
        try {
          return await _translationService.translateExercise(exercise, targetLanguage);
        } catch (e) {
          log.warning('Failed to translate exercise ${exercise.title}: $e');
          return null;
        }
      }).toList();

      final translationResults = await Future.wait(translationFutures);
      final translatedExercises = translationResults.whereType<TranslatedExercise>().toList();

      // Batch save to database for better performance
      if (translatedExercises.isNotEmpty) {
        await _databaseService.saveExercisesBatch(translatedExercises);
      }

      // Update refresh tracking
      await _databaseService.updateRefreshTracking(
        targetLanguage,
        lastRefreshExercises: DateTime.now(),
      );

      log.info('✅ Translated and cached ${translatedExercises.length} exercises');
      return translatedExercises.map((exercise) => _convertTranslatedExerciseToWorkoutItem(exercise)).toList();

    } catch (e, stackTrace) {
      log.severe('❌ Failed to get translated exercises for target: $target', e, stackTrace);

      // Fallback to cached data
      final cachedExercises = await _getCachedExercisesByTarget(target, targetLanguage);
      if (cachedExercises.isNotEmpty) {
        log.info('🔄 Falling back to cached exercises');
        return cachedExercises.map((exercise) => _convertTranslatedExerciseToWorkoutItem(exercise)).toList();
      }

      // Final fallback to English
      log.info('🔄 Falling back to English exercises');
      return await _exerciseService.getExercisesByTarget(target);
    }
  }

  // SPECIAL CATEGORY HANDLING

  Future<List<Map<String, dynamic>>> _getMealsForAllCategory(
    String targetLanguage, {
    int page = 0,
    int limit = 8,
  }) async {
    try {
      // For "All" category, ONLY show cached translated meals (no new downloads)
      final allCachedMeals = await _databaseService.getMealsForLanguage(targetLanguage);

      // Log cache status for debugging
      log.info('🔍 Cached meals found for "$targetLanguage": ${allCachedMeals.length} meals');

      if (allCachedMeals.isNotEmpty) {
        // Remove duplicates by meal ID (same meal can be in multiple categories)
        final uniqueMeals = <String, TranslatedMeal>{};
        for (final meal in allCachedMeals) {
          if (!uniqueMeals.containsKey(meal.id)) {
            uniqueMeals[meal.id] = meal;
          }
        }

        final deduplicatedMeals = uniqueMeals.values.toList();
        log.info('📱 After deduplication: ${deduplicatedMeals.length} unique meals (was ${allCachedMeals.length})');

        // Apply pagination to deduplicated data
        final startIndex = page * limit;
        final endIndex = (startIndex + limit).clamp(0, deduplicatedMeals.length);

        if (startIndex < deduplicatedMeals.length) {
          final paginatedCachedMeals = deduplicatedMeals.sublist(startIndex, endIndex);
          log.info('📱 Serving cached "All" meals: ${paginatedCachedMeals.length} unique meals ($targetLanguage)');

          return paginatedCachedMeals.map((meal) => _convertTranslatedMealToMap(meal)).toList();
        }
      }

      // No cached translations - fallback to English "All" category without duplicates
      log.info('💡 No cached translations for "All" category. Showing English fallback without duplicates.');

      final englishMeals = await _mealService.getMealsByCategoryPaginated('All', page: page, limit: limit * 3); // Get more to account for deduplication

      // Remove duplicates from English meals by ID
      final uniqueEnglishMeals = <String, Map<String, dynamic>>{};
      for (final meal in englishMeals) {
        final mealId = meal['id']?.toString() ?? meal['titleKey']?.toString() ?? '';
        if (mealId.isNotEmpty && !uniqueEnglishMeals.containsKey(mealId)) {
          uniqueEnglishMeals[mealId] = meal;
        }
      }

      final deduplicatedEnglishMeals = uniqueEnglishMeals.values.toList();
      log.info('📱 English fallback: ${deduplicatedEnglishMeals.length} unique meals (was ${englishMeals.length})');

      // Apply pagination to deduplicated English meals
      final startIndex = page * limit;
      final endIndex = (startIndex + limit).clamp(0, deduplicatedEnglishMeals.length);

      if (startIndex < deduplicatedEnglishMeals.length) {
        final paginatedEnglishMeals = deduplicatedEnglishMeals.sublist(startIndex, endIndex);
        return paginatedEnglishMeals;
      }

      return [];

    } catch (e, stackTrace) {
      log.severe('❌ Failed to get translated "All" category meals', e, stackTrace);

      // Report error to progress tracker
      _ref?.read(translationProgressProvider.notifier).errorProgress(
        'Translation failed. Falling back to English content.',
      );

      // Fallback to English "All" category with deduplication
      try {
        final englishMeals = await _mealService.getMealsByCategoryPaginated('All', page: page, limit: limit * 3); // Get more to account for deduplication

        // Remove duplicates from English meals by ID
        final uniqueEnglishMeals = <String, Map<String, dynamic>>{};
        for (final meal in englishMeals) {
          final mealId = meal['id']?.toString() ?? meal['titleKey']?.toString() ?? '';
          if (mealId.isNotEmpty && !uniqueEnglishMeals.containsKey(mealId)) {
            uniqueEnglishMeals[mealId] = meal;
          }
        }

        final deduplicatedEnglishMeals = uniqueEnglishMeals.values.toList();
        log.info('📱 Error fallback: ${deduplicatedEnglishMeals.length} unique English meals (was ${englishMeals.length})');

        // Apply pagination to deduplicated English meals
        final startIndex = page * limit;
        final endIndex = (startIndex + limit).clamp(0, deduplicatedEnglishMeals.length);

        if (startIndex < deduplicatedEnglishMeals.length) {
          final paginatedEnglishMeals = deduplicatedEnglishMeals.sublist(startIndex, endIndex);
          return paginatedEnglishMeals;
        }

        return [];
      } catch (fallbackError) {
        log.severe('❌ Even English fallback failed', fallbackError);
        return [];
      }
    }
  }


  // HELPER METHODS

  Future<List<TranslatedMeal>> _getCachedMealsByCategory(
    String category,
    String language,
    int page,
    int limit,
  ) async {
    final allCachedMeals = await _databaseService.getMealsForLanguage(language);

    // Log cache details for debugging
    log.info('🔍 _getCachedMealsByCategory: category="$category", cached=${allCachedMeals.length}, page=$page, limit=$limit');

    // Filter by category if specified
    final categoryMeals = category.toLowerCase() == 'all'
        ? allCachedMeals
        : allCachedMeals.where((meal) =>
            meal.translatedCategory?.toLowerCase() == category.toLowerCase() ||
            meal.originalCategory?.toLowerCase() == category.toLowerCase()).toList();

    log.info('🔍 After filtering: ${categoryMeals.length} meals for category "$category"');

    // Apply pagination
    final startIndex = page * limit;
    final endIndex = (startIndex + limit).clamp(0, categoryMeals.length);

    if (startIndex >= categoryMeals.length) {
      log.info('🔍 No meals for page $page (startIndex=$startIndex >= ${categoryMeals.length})');
      return [];
    }

    final result = categoryMeals.sublist(startIndex, endIndex);
    log.info('🔍 Returning ${result.length} cached meals for category "$category"');
    return result;
  }

  Future<List<TranslatedExercise>> _getCachedExercisesByTarget(String target, String language) async {
    final allCachedExercises = await _databaseService.getExercisesForLanguage(language);

    // Filter by target muscle group - this is simplified, you might want more sophisticated matching
    return allCachedExercises.where((exercise) =>
        exercise.translatedTarget?.toLowerCase().contains(target.toLowerCase()) == true ||
        exercise.originalTarget?.toLowerCase().contains(target.toLowerCase()) == true ||
        exercise.translatedName.toLowerCase().contains(target.toLowerCase()) ||
        exercise.originalName.toLowerCase().contains(target.toLowerCase())).toList();
  }

  Map<String, dynamic> _convertTranslatedMealToMap(TranslatedMeal meal) {
    final ingredients = meal.translatedIngredients;
    final measures = meal.translatedMeasures ?? meal.originalMeasures ?? [];

    // Ensure measures array matches ingredients array length
    final synchronizedMeasures = List<String>.generate(
      ingredients.length,
      (index) => index < measures.length ? measures[index] : '1 serving',
    );

    return {
      'id': meal.id,
      'titleKey': meal.translatedName,
      'category': meal.translatedCategory ?? meal.originalCategory,
      'area': meal.translatedArea ?? meal.originalArea,
      'instructions': meal.translatedInstructions,
      'ingredients': ingredients,
      'measures': synchronizedMeasures, // Synchronized measures array
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
      'translatedAt': meal.translatedAt.toIso8601String(),
    };
  }

  WorkoutItem _convertTranslatedExerciseToWorkoutItem(TranslatedExercise exercise) {
    return WorkoutItem(
      title: exercise.translatedName,
      image: exercise.gifUrl ?? '',
      duration: exercise.duration ?? '45 seconds',
      difficulty: exercise.difficulty ?? 'Medium',
      description: exercise.translatedDescription,
      rating: exercise.rating ?? 4.5,
      steps: [
        WorkoutStep(
          title: exercise.translatedName,
          duration: exercise.duration ?? '45 seconds',
          description: exercise.translatedDescription,
          instructions: exercise.translatedInstructions,
          gifUrl: exercise.gifUrl ?? '',
          isCompleted: false,
        ),
      ],
      equipment: exercise.translatedEquipment,
      caloriesBurn: exercise.caloriesBurn ?? '100-150',
      tips: exercise.translatedTips,
    );
  }

  // BACKGROUND REFRESH METHODS

  void _refreshMealsInBackground(String category, String language, int page, int limit) {
    // Run in background without blocking UI
    Future(() async {
      try {
        log.info('🔄 Background refresh started for meals: $category ($language)');
        final englishMeals = await _mealService.getMealsByCategoryPaginated(category, page: page, limit: limit);

        if (englishMeals.isNotEmpty) {
          // Translate meals in parallel
          final translationFutures = englishMeals.map((mealData) async {
            try {
              return await _translationService.translateMeal(mealData, language);
            } catch (e) {
              log.warning('Background translation failed for meal ${mealData['titleKey']}: $e');
              return null;
            }
          }).toList();

          final translationResults = await Future.wait(translationFutures);
          final translatedMeals = translationResults.whereType<TranslatedMeal>().toList();

          if (translatedMeals.isNotEmpty) {
            await _databaseService.saveMealsBatch(translatedMeals);
            await _databaseService.updateRefreshTracking(language, lastRefreshMeals: DateTime.now());
            log.info('✅ Background refresh completed: ${translatedMeals.length} meals updated');
          }
        }
      } catch (e) {
        log.warning('Background refresh failed: $e');
      }
    });
  }

  // UTILITY METHODS

  Future<bool> needsRefresh(String language, {int daysSinceLastRefresh = 7}) async {
    final tracking = await _databaseService.getRefreshTracking(language);
    if (tracking == null) {
      return true; // First time, needs refresh
    }

    final lastRefresh = tracking['lastRefreshMeals'] as int?;
    if (lastRefresh == null) {
      return true;
    }

    final lastRefreshDate = DateTime.fromMillisecondsSinceEpoch(lastRefresh);
    final daysSince = DateTime.now().difference(lastRefreshDate).inDays;

    return daysSince >= daysSinceLastRefresh;
  }

  Future<Map<String, int>> getTranslationStats() async {
    return await _databaseService.getTranslationCounts();
  }

  String get translationServiceName => _translationService.serviceName;

  Future<void> clearCacheForLanguage(String language) async {
    await _databaseService.clearTranslationsForLanguage(language);
  }

  Future<void> dispose() async {
    await _databaseService.close();
  }
}