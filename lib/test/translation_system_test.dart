// Test and demonstration file for the translation system
//
// This file provides comprehensive testing and examples for the
// API translation layer implementation.

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../services/api/unified_api_service.dart';
import '../services/database/translation_database_service.dart';
import '../services/refresh/translation_refresh_manager.dart';
import '../services/offline/offline_translation_service.dart';

final log = Logger('TranslationSystemTest');

class TranslationSystemTest {
  late final UnifiedApiService _unifiedService;
  late final TranslationDatabaseService _databaseService;
  late final TranslationRefreshManager _refreshManager;
  late final OfflineTranslationService _offlineService;

  /// Initialize the translation system for testing
  Future<void> initialize({bool useProduction = false}) async {
    log.info('🧪 Initializing Translation System Test');

    try {
      _unifiedService = UnifiedApiService(useProductionTranslation: useProduction);
      _databaseService = TranslationDatabaseService();
      _refreshManager = TranslationRefreshManager(useProductionTranslation: useProduction);
      _offlineService = OfflineTranslationService(useProduction: useProduction);

      await _refreshManager.initialize();

      log.info('✅ Translation System Test initialized successfully');
    } catch (e) {
      log.severe('❌ Failed to initialize test system', e);
      rethrow;
    }
  }

  /// Test meal translation functionality
  Future<void> testMealTranslation() async {
    log.info('🍽️ Testing meal translation functionality');

    try {
      // Test 1: Get meals in different languages
      final languages = ['es', 'fr', 'pt'];
      final category = 'Chicken';

      for (final language in languages) {
        log.info('Testing meals in $language');

        final meals = await _unifiedService.getMealsByCategory(
          category,
          language: language,
          limit: 3,
        );

        log.info('✅ Retrieved ${meals.length} meals in $language');

        if (meals.isNotEmpty) {
          final firstMeal = meals.first;
          log.info('Sample meal: ${firstMeal['titleKey']} (${firstMeal['category']})');

          // Test meal detail
          final mealDetail = await _unifiedService.getMealById(
            firstMeal['id']?.toString() ?? '',
            language: language,
          );

          if (mealDetail != null) {
            log.info('✅ Retrieved meal details in $language');
            _logMealDetails(mealDetail, language);
          }
        }

        // Small delay between language tests
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      log.severe('❌ Meal translation test failed', e);
    }
  }

  /// Test exercise translation functionality
  Future<void> testExerciseTranslation() async {
    log.info('💪 Testing exercise translation functionality');

    try {
      final languages = ['es', 'fr', 'pt'];
      final target = 'abs';

      for (final language in languages) {
        log.info('Testing exercises in $language');

        final exercises = await _unifiedService.getExercisesByTarget(
          target,
          language: language,
        );

        log.info('✅ Retrieved ${exercises.length} exercises in $language');

        if (exercises.isNotEmpty) {
          final firstExercise = exercises.first;
          log.info('Sample exercise: ${firstExercise.title} (${firstExercise.difficulty})');
          _logExerciseDetails(firstExercise, language);
        }

        // Small delay between language tests
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      log.severe('❌ Exercise translation test failed', e);
    }
  }

  /// Test search functionality
  Future<void> testSearchTranslation() async {
    log.info('🔍 Testing search translation functionality');

    try {
      final queries = ['chicken', 'pasta', 'salad'];
      final languages = ['es', 'fr'];

      for (final language in languages) {
        for (final query in queries) {
          log.info('Testing search: "$query" in $language');

          final results = await _unifiedService.searchMeals(
            query,
            language: language,
          );

          log.info('✅ Search "$query" returned ${results.length} results in $language');

          if (results.isNotEmpty) {
            final firstResult = results.first;
            log.info('First result: ${firstResult['titleKey']}');
          }

          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      log.severe('❌ Search translation test failed', e);
    }
  }

  /// Test offline functionality
  Future<void> testOfflineCapability() async {
    log.info('📱 Testing offline capability');

    try {
      // Get offline status
      final offlineStatus = await _offlineService.getOfflineStatus();
      log.info('Offline status: $offlineStatus');

      // Test offline meals
      if (offlineStatus['offlineCapable'] == true) {
        final cachedMeals = await _offlineService.getMealsByCategory(
          'Chicken',
          language: 'es',
        );
        log.info('✅ Retrieved ${cachedMeals.length} meals from cache');

        // Test offline exercises
        final cachedExercises = await _offlineService.getExercisesByTarget(
          'abs',
          language: 'es',
        );
        log.info('✅ Retrieved ${cachedExercises.length} exercises from cache');

        // Test offline search
        final searchResults = await _offlineService.searchMeals(
          'pollo', // Spanish for chicken
          language: 'es',
        );
        log.info('✅ Found ${searchResults.length} meals in offline search');
      } else {
        log.info('⚠️ No offline content available yet');
      }
    } catch (e) {
      log.severe('❌ Offline capability test failed', e);
    }
  }

  /// Test database operations
  Future<void> testDatabaseOperations() async {
    log.info('🗄️ Testing database operations');

    try {
      // Get translation counts
      final counts = await _databaseService.getTranslationCounts();
      log.info('Translation counts: $counts');

      // Check languages with translations
      final languages = ['es', 'fr', 'pt', 'de', 'it'];
      for (final language in languages) {
        final hasTranslations = await _databaseService.hasTranslationsForLanguage(language);
        final refreshTracking = await _databaseService.getRefreshTracking(language);

        log.info('Language $language: translations=$hasTranslations, tracking=$refreshTracking');
      }

      log.info('✅ Database operations test completed');
    } catch (e) {
      log.severe('❌ Database operations test failed', e);
    }
  }

  /// Test error handling
  Future<void> testErrorHandling() async {
    log.info('⚠️ Testing error handling');

    try {
      // Test with invalid meal ID
      final invalidMeal = await _unifiedService.getMealById(
        'invalid_meal_id_12345',
        language: 'es',
      );
      log.info('Invalid meal result: $invalidMeal');

      // Test with invalid exercise target
      final invalidExercises = await _unifiedService.getExercisesByTarget(
        'invalid_target_12345',
        language: 'es',
      );
      log.info('Invalid exercises result: ${invalidExercises.length} exercises');

      // Test with empty search query
      final emptySearch = await _unifiedService.searchMeals('', language: 'es');
      log.info('Empty search result: ${emptySearch.length} meals');

      log.info('✅ Error handling test completed');
    } catch (e) {
      log.info('✅ Caught expected error: $e');
    }
  }

  /// Test refresh manager
  Future<void> testRefreshManager() async {
    log.info('🔄 Testing refresh manager');

    try {
      // Get refresh status
      final refreshStatus = await _refreshManager.getRefreshStatus();
      log.info('Refresh status for all languages:');

      refreshStatus.forEach((language, status) {
        log.info('  $language: ${status['hasTranslations'] ? '✅' : '❌'} '
               '(${status['mealCount']} meals, ${status['exerciseCount']} exercises) '
               '${status['needsRefresh'] ? '[needs refresh]' : '[up to date]'}');
      });

      // Get refresh interval and last refresh
      final interval = await _refreshManager.getRefreshInterval();
      final lastRefresh = await _refreshManager.getLastRefreshDate();

      log.info('Refresh interval: $interval days');
      log.info('Last refresh: ${lastRefresh?.toIso8601String() ?? 'Never'}');

      log.info('✅ Refresh manager test completed');
    } catch (e) {
      log.severe('❌ Refresh manager test failed', e);
    }
  }

  /// Run comprehensive translation system test
  Future<void> runComprehensiveTest() async {
    log.info('🚀 Starting comprehensive translation system test');

    try {
      await initialize();

      await testDatabaseOperations();
      await testMealTranslation();
      await testExerciseTranslation();
      await testSearchTranslation();
      await testOfflineCapability();
      await testErrorHandling();
      await testRefreshManager();

      log.info('🎉 Comprehensive test completed successfully!');

      // Print summary
      await _printTestSummary();

    } catch (e) {
      log.severe('💥 Comprehensive test failed', e);
    }
  }

  /// Print test summary
  Future<void> _printTestSummary() async {
    log.info('📊 Test Summary:');

    try {
      final counts = await _databaseService.getTranslationCounts();
      final refreshStatus = await _refreshManager.getRefreshStatus();
      final offlineStatus = await _offlineService.getOfflineStatus();

      log.info('  📈 Cached translations: ${counts['total']}');
      log.info('    - Meals: ${counts['meals']}');
      log.info('    - Exercises: ${counts['exercises']}');

      log.info('  🌍 Language support:');
      refreshStatus.forEach((language, status) {
        final hasData = status['hasTranslations'] as bool;
        log.info('    - $language: ${hasData ? '✅' : '❌'}');
      });

      log.info('  📱 Offline capability: ${offlineStatus['offlineCapable'] ? '✅' : '❌'}');
      log.info('  🌐 Online status: ${offlineStatus['isOnline'] ? '✅' : '❌'}');

      final serviceName = _unifiedService.translationServiceName;
      log.info('  🔧 Translation service: $serviceName');

    } catch (e) {
      log.warning('Failed to generate summary: $e');
    }
  }

  /// Utility method to log meal details
  void _logMealDetails(Map<String, dynamic> meal, String language) {
    log.fine('Meal details ($language):');
    log.fine('  Name: ${meal['titleKey']}');
    log.fine('  Category: ${meal['category']}');
    log.fine('  Area: ${meal['area']}');
    log.fine('  Instructions: ${meal['instructions']?.length ?? 0} steps');
    log.fine('  Ingredients: ${meal['ingredients']?.length ?? 0} items');
    log.fine('  Is translated: ${meal['isTranslated'] ?? false}');
  }

  /// Utility method to log exercise details
  void _logExerciseDetails(dynamic exercise, String language) {
    log.fine('Exercise details ($language):');
    log.fine('  Name: ${exercise.title}');
    log.fine('  Description: ${exercise.description.substring(0, exercise.description.length.clamp(0, 100))}...');
    log.fine('  Duration: ${exercise.duration}');
    log.fine('  Difficulty: ${exercise.difficulty}');
    log.fine('  Equipment: ${exercise.equipment.join(', ')}');
    log.fine('  Tips: ${exercise.tips.length} tips');
  }

  /// Cleanup resources
  Future<void> dispose() async {
    await _refreshManager.dispose();
    await _offlineService.dispose();
    await _databaseService.close();
  }
}

/// Demo widget showing the translation system in action
class TranslationSystemDemo extends StatefulWidget {
  const TranslationSystemDemo({super.key});

  @override
  State<TranslationSystemDemo> createState() => _TranslationSystemDemoState();
}

class _TranslationSystemDemoState extends State<TranslationSystemDemo> {
  final _tester = TranslationSystemTest();
  bool _isRunning = false;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    // Setup logging to capture test output
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      setState(() {
        _logs.add('${record.level.name}: ${record.message}');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translation System Demo'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? null : _runTest,
                  child: _isRunning
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Running...'),
                          ],
                        )
                      : const Text('Run Test'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _logs.clear();
                    });
                  },
                  child: const Text('Clear Logs'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  Color textColor = Colors.black;

                  if (log.contains('ERROR') || log.contains('SEVERE')) {
                    textColor = Colors.red;
                  } else if (log.contains('WARNING')) {
                    textColor = Colors.orange;
                  } else if (log.contains('INFO') && log.contains('✅')) {
                    textColor = Colors.green;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.0),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: textColor,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runTest() async {
    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    try {
      await _tester.runComprehensiveTest();
    } catch (e) {
      log.severe('Test failed: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  void dispose() {
    _tester.dispose();
    super.dispose();
  }
}