import 'package:logging/logging.dart';
import '../../screens/search/workout_detail/models/workout_item.dart';
import '../meal/recipe_service.dart';
import '../exercises/exercise_service.dart';
import '../translation/api_translation_service.dart';
import '../database/translation_database_service.dart';
import '../../models/translation/translated_meal.dart';
import '../../models/translation/translated_exercise.dart';

final log = Logger('UnifiedApiService');

class UnifiedApiService {
  final MealDBService _mealService;
  final ExerciseService _exerciseService;
  final ApiTranslationService _translationService;
  final TranslationDatabaseService _databaseService;

  UnifiedApiService({
    bool useProductionTranslation = false,
  }) : _mealService = MealDBService(),
        _exerciseService = ExerciseService(),
        _translationService = ApiTranslationService(useProduction: useProductionTranslation),
        _databaseService = TranslationDatabaseService();

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

    try {
      // Check cache first
      final cachedMeals = await _getCachedMealsByCategory(category, targetLanguage, page, limit);
      if (cachedMeals.isNotEmpty) {
        log.info('📱 Serving cached meals for category: $category ($targetLanguage)');
        return cachedMeals.map((meal) => _convertTranslatedMealToMap(meal)).toList();
      }

      // Fetch from API and translate
      log.info('🌐 Fetching and translating meals for category: $category -> $targetLanguage');
      final englishMeals = await _mealService.getMealsByCategoryPaginated(category, page: page, limit: limit);

      if (englishMeals.isEmpty) {
        return [];
      }

      // Translate and cache
      final translatedMeals = <TranslatedMeal>[];
      for (final mealData in englishMeals) {
        try {
          final translatedMeal = await _translationService.translateMeal(mealData, targetLanguage);
          translatedMeals.add(translatedMeal);
          await _databaseService.saveMeal(translatedMeal);
        } catch (e) {
          log.warning('Failed to translate meal ${mealData['titleKey']}: $e');
          // Continue with other meals
        }
      }

      // Update refresh tracking
      await _databaseService.updateRefreshTracking(
        targetLanguage,
        lastRefreshMeals: DateTime.now(),
      );

      log.info('✅ Translated and cached ${translatedMeals.length} meals');
      return translatedMeals.map((meal) => _convertTranslatedMealToMap(meal)).toList();

    } catch (e, stackTrace) {
      log.severe('❌ Failed to get translated meals for category: $category', e, stackTrace);

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

      // Translate and cache
      final translatedExercises = <TranslatedExercise>[];
      for (final exercise in englishExercises) {
        try {
          final translatedExercise = await _translationService.translateExercise(exercise, targetLanguage);
          translatedExercises.add(translatedExercise);
          await _databaseService.saveExercise(translatedExercise);
        } catch (e) {
          log.warning('Failed to translate exercise ${exercise.title}: $e');
          // Continue with other exercises
        }
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

  // HELPER METHODS

  Future<List<TranslatedMeal>> _getCachedMealsByCategory(
    String category,
    String language,
    int page,
    int limit,
  ) async {
    final allCachedMeals = await _databaseService.getMealsForLanguage(language);

    // Filter by category if specified
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

    return categoryMeals.sublist(startIndex, endIndex);
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
        // You might want to create a more sophisticated conversion here
        // For now, using the translated instructions as a single step
      ],
      equipment: exercise.translatedEquipment,
      caloriesBurn: exercise.caloriesBurn ?? '100-150',
      tips: exercise.translatedTips,
    );
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