import 'package:logging/logging.dart';
import '../../models/translation/translated_meal.dart';
import '../../models/translation/translated_exercise.dart';
import '../../screens/search/workout_detail/models/workout_item.dart';
import 'translation_service_interface.dart';
import 'free_translation_service.dart';
import 'production_translation_service.dart';

final log = Logger('ApiTranslationService');

class ApiTranslationService {
  late final TranslationServiceInterface _translationService;

  ApiTranslationService({bool useProduction = false}) {
    if (useProduction) {
      final prodService = ProductionTranslationService();
      if (prodService.isAvailable) {
        _translationService = prodService;
        log.info('🚀 Using ${prodService.serviceName}');
      } else {
        _translationService = FreeTranslationService();
        log.info('⚠️ Google Cloud API not available, falling back to ${_translationService.serviceName}');
      }
    } else {
      _translationService = FreeTranslationService();
      log.info('🔧 Using ${_translationService.serviceName} (Development mode)');
    }
  }

  Future<TranslatedMeal> translateMeal(
    Map<String, dynamic> mealData,
    String targetLanguage,
  ) async {
    log.info('🍽️ Translating meal: ${mealData['titleKey']} to $targetLanguage');

    try {
      // Extract data from meal
      final id = mealData['id']?.toString() ?? '';
      final originalName = mealData['titleKey']?.toString() ?? '';
      final originalInstructions = List<String>.from(mealData['instructions'] ?? []);
      final originalIngredients = List<String>.from(mealData['ingredients'] ?? []);
      final originalMeasures = List<String>.from(mealData['measures'] ?? []);
      final originalCategory = mealData['category']?.toString();
      final originalArea = mealData['area']?.toString();

      // Filter out empty strings
      final validInstructions = originalInstructions.where((s) => s.trim().isNotEmpty).toList();
      final validIngredients = originalIngredients.where((s) => s.trim().isNotEmpty).toList();
      final validMeasures = originalMeasures.where((s) => s.trim().isNotEmpty).toList();

      // Translate all text fields
      final translatedName = await _translationService.translate(originalName, targetLanguage);

      // Translate instructions in batch
      final translatedInstructions = validInstructions.isNotEmpty
          ? await _translationService.translateBatch(validInstructions, targetLanguage)
          : <String>[];

      // Translate ingredients in batch
      final translatedIngredients = validIngredients.isNotEmpty
          ? await _translationService.translateBatch(validIngredients, targetLanguage)
          : <String>[];

      // Translate measures in batch (measurements like "1 cup", "2 tablespoons", etc.)
      final translatedMeasures = validMeasures.isNotEmpty
          ? await _translationService.translateBatch(validMeasures, targetLanguage)
          : <String>[];

      // Translate category and area
      String? translatedCategory;
      if (originalCategory != null && originalCategory.isNotEmpty) {
        translatedCategory = await _translationService.translate(originalCategory, targetLanguage);
      }

      String? translatedArea;
      if (originalArea != null && originalArea.isNotEmpty) {
        translatedArea = await _translationService.translate(originalArea, targetLanguage);
      }

      final translatedMeal = TranslatedMeal(
        id: id,
        originalLanguage: 'en',
        targetLanguage: targetLanguage,
        originalName: originalName,
        translatedName: translatedName,
        originalInstructions: originalInstructions,
        translatedInstructions: translatedInstructions,
        originalIngredients: originalIngredients,
        translatedIngredients: translatedIngredients,
        originalMeasures: originalMeasures,
        translatedMeasures: translatedMeasures,
        originalCategory: originalCategory,
        translatedCategory: translatedCategory,
        originalArea: originalArea,
        translatedArea: translatedArea,
        translatedAt: DateTime.now(),
        youtubeUrl: mealData['youtubeUrl']?.toString(),
        imagePath: mealData['imagePath']?.toString(),
        calories: mealData['calories']?.toString(),
        prepTime: mealData['prepTime']?.toString(),
        cookTime: mealData['cookTime']?.toString(),
        difficulty: mealData['difficulty']?.toString(),
        servings: mealData['servings'] as int?,
        isVegan: mealData['isVegan'] as bool?,
        nutritionFacts: mealData['nutritionFacts'] as Map<String, dynamic>?,
      );

      log.info('✅ Successfully translated meal: $originalName -> $translatedName');
      return translatedMeal;
    } catch (e, stackTrace) {
      log.severe('❌ Failed to translate meal: ${mealData['titleKey']}', e, stackTrace);
      rethrow;
    }
  }

  Future<TranslatedExercise> translateExercise(
    WorkoutItem exercise,
    String targetLanguage,
  ) async {
    log.info('💪 Translating exercise: ${exercise.title} to $targetLanguage');

    try {
      // Extract and filter data
      final originalInstructions = exercise.steps.isNotEmpty && exercise.steps.first.instructions.isNotEmpty
          ? exercise.steps.first.instructions.where((s) => s.trim().isNotEmpty).toList()
          : <String>[];

      final originalTips = exercise.tips.where((s) => s.trim().isNotEmpty).toList();
      final originalEquipment = exercise.equipment.where((s) => s.trim().isNotEmpty).toList();

      // Translate text fields
      final translatedName = await _translationService.translate(exercise.title, targetLanguage);
      final translatedDescription = await _translationService.translate(exercise.description, targetLanguage);

      // Translate instructions, tips, and equipment in batches
      final translatedInstructions = originalInstructions.isNotEmpty
          ? await _translationService.translateBatch(originalInstructions, targetLanguage)
          : <String>[];

      final translatedTips = originalTips.isNotEmpty
          ? await _translationService.translateBatch(originalTips, targetLanguage)
          : <String>[];

      final translatedEquipment = originalEquipment.isNotEmpty
          ? await _translationService.translateBatch(originalEquipment, targetLanguage)
          : <String>[];

      final translatedExercise = TranslatedExercise(
        id: exercise.title.toLowerCase().replaceAll(' ', '_'),
        originalLanguage: 'en',
        targetLanguage: targetLanguage,
        originalName: exercise.title,
        translatedName: translatedName,
        originalDescription: exercise.description,
        translatedDescription: translatedDescription,
        originalInstructions: originalInstructions,
        translatedInstructions: translatedInstructions,
        originalEquipment: exercise.equipment,
        translatedEquipment: translatedEquipment,
        originalTips: exercise.tips,
        translatedTips: translatedTips,
        translatedAt: DateTime.now(),
        gifUrl: exercise.image,
        duration: exercise.duration,
        difficulty: exercise.difficulty,
        caloriesBurn: exercise.caloriesBurn,
        rating: exercise.rating,
      );

      log.info('✅ Successfully translated exercise: ${exercise.title} -> $translatedName');
      return translatedExercise;
    } catch (e, stackTrace) {
      log.severe('❌ Failed to translate exercise: ${exercise.title}', e, stackTrace);
      rethrow;
    }
  }

  String get serviceName => _translationService.serviceName;
  bool get isAvailable => _translationService.isAvailable;
}