import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../screens/search/workout_detail/models/workout_item.dart';
import '../../services/api/unified_api_service.dart';
import '../../services/refresh/translation_refresh_manager.dart';
import '../../services/offline/offline_translation_service.dart';
import '../riverpod/language_provider.dart';

// Provider for the unified API service
final unifiedApiServiceProvider = Provider<UnifiedApiService>((ref) {
  // Determine if we should use production translation service
  // You can make this configurable via environment variables or settings
  const useProduction = String.fromEnvironment('USE_PRODUCTION_TRANSLATION') == 'true';

  return UnifiedApiService(useProductionTranslation: useProduction);
});

// Provider for the refresh manager
final translationRefreshManagerProvider = Provider<TranslationRefreshManager>((ref) {
  const useProduction = String.fromEnvironment('USE_PRODUCTION_TRANSLATION') == 'true';

  final manager = TranslationRefreshManager(useProductionTranslation: useProduction);

  // Initialize the manager when first created
  manager.initialize().catchError((error) {
    // Handle initialization errors gracefully
    // Log error in debug mode only
    if (error is Exception) {
      // Error will be logged by the service itself
    }
  });

  // Dispose when no longer needed
  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
});

// Provider for offline translation service
final offlineTranslationServiceProvider = Provider<OfflineTranslationService>((ref) {
  const useProduction = String.fromEnvironment('USE_PRODUCTION_TRANSLATION') == 'true';

  final service = OfflineTranslationService(useProduction: useProduction);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// Provider for meals by category with automatic translation
final mealsByCategoryProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, category) async {
  final apiService = ref.watch(unifiedApiServiceProvider);
  final currentLanguage = ref.watch(currentLanguageProvider);

  return await apiService.getMealsByCategory(
    category,
    language: currentLanguage.code,
    page: 0,
    limit: 8,
  );
});

// Provider for meal by ID with automatic translation
final mealByIdProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  final apiService = ref.watch(unifiedApiServiceProvider);
  final currentLanguage = ref.watch(currentLanguageProvider);

  return await apiService.getMealById(id, language: currentLanguage.code);
});

// Provider for meal search with automatic translation
final searchMealsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  final apiService = ref.watch(unifiedApiServiceProvider);
  final currentLanguage = ref.watch(currentLanguageProvider);

  return await apiService.searchMeals(query, language: currentLanguage.code);
});

// Provider for exercises by target with automatic translation
final exercisesByTargetProvider = FutureProvider.family<List<WorkoutItem>, String>((ref, target) async {
  final apiService = ref.watch(unifiedApiServiceProvider);
  final currentLanguage = ref.watch(currentLanguageProvider);

  return await apiService.getExercisesByTarget(target, language: currentLanguage.code);
});

// Provider for translation statistics
final translationStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final apiService = ref.watch(unifiedApiServiceProvider);
  return await apiService.getTranslationStats();
});

// Provider for refresh status
final refreshStatusProvider = FutureProvider<Map<String, Map<String, dynamic>>>((ref) async {
  final refreshManager = ref.watch(translationRefreshManagerProvider);
  return await refreshManager.getRefreshStatus();
});

// Provider to check if refresh is needed for current language
final needsRefreshProvider = FutureProvider<bool>((ref) async {
  final apiService = ref.watch(unifiedApiServiceProvider);
  final currentLanguage = ref.watch(currentLanguageProvider);

  if (currentLanguage.code == 'en') {
    return false; // English doesn't need translation refresh
  }

  return await apiService.needsRefresh(currentLanguage.code);
});

// Provider for translation service name
final translationServiceNameProvider = Provider<String>((ref) {
  final apiService = ref.watch(unifiedApiServiceProvider);
  return apiService.translationServiceName;
});

// Utility providers for common meal categories
final chickenMealsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(mealsByCategoryProvider('Chicken').future);
});

final vegetarianMealsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(mealsByCategoryProvider('Vegetarian').future);
});

final dessertMealsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(mealsByCategoryProvider('Dessert').future);
});

// Utility providers for common exercise targets
final absExercisesProvider = FutureProvider<List<WorkoutItem>>((ref) async {
  return ref.watch(exercisesByTargetProvider('abs').future);
});

final chestExercisesProvider = FutureProvider<List<WorkoutItem>>((ref) async {
  return ref.watch(exercisesByTargetProvider('chest').future);
});

final legExercisesProvider = FutureProvider<List<WorkoutItem>>((ref) async {
  return ref.watch(exercisesByTargetProvider('legs').future);
});

// Provider for offline status
final offlineStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final offlineService = ref.watch(offlineTranslationServiceProvider);
  return await offlineService.getOfflineStatus();
});