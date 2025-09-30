import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import '../api/unified_api_service.dart';
import '../database/translation_database_service.dart';

final log = Logger('TranslationRefreshManager');

class TranslationRefreshManager {
  static const String _lastRefreshKey = 'last_translation_refresh';
  static const String _refreshIntervalKey = 'translation_refresh_interval_days';
  static const int _defaultRefreshIntervalDays = 7;

  final UnifiedApiService _apiService;
  final TranslationDatabaseService _databaseService;
  Timer? _refreshTimer;

  TranslationRefreshManager({
    bool useProductionTranslation = false,
  }) : _apiService = UnifiedApiService(useProductionTranslation: useProductionTranslation),
        _databaseService = TranslationDatabaseService();

  /// Initialize the refresh manager and start automatic refresh cycle
  Future<void> initialize() async {
    log.info('🔄 Initializing Translation Refresh Manager');

    try {
      // Check if immediate refresh is needed
      await _checkAndRefreshIfNeeded();

      // Start periodic refresh timer
      _startPeriodicRefresh();

      log.info('✅ Translation Refresh Manager initialized successfully');
    } catch (e, stackTrace) {
      log.severe('❌ Failed to initialize Translation Refresh Manager', e, stackTrace);
      rethrow;
    }
  }

  /// Check if refresh is needed and perform it if necessary
  Future<bool> _checkAndRefreshIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRefreshTimestamp = prefs.getInt(_lastRefreshKey);
      final refreshIntervalDays = prefs.getInt(_refreshIntervalKey) ?? _defaultRefreshIntervalDays;

      if (lastRefreshTimestamp == null) {
        log.info('🆕 First time refresh needed');
        return await _performRefresh();
      }

      final lastRefreshDate = DateTime.fromMillisecondsSinceEpoch(lastRefreshTimestamp);
      final daysSinceRefresh = DateTime.now().difference(lastRefreshDate).inDays;

      if (daysSinceRefresh >= refreshIntervalDays) {
        log.info('⏰ Refresh needed: $daysSinceRefresh days since last refresh');
        return await _performRefresh();
      }

      log.info('✅ No refresh needed: $daysSinceRefresh days since last refresh (interval: $refreshIntervalDays days)');
      return false;
    } catch (e) {
      log.warning('Failed to check refresh status: $e');
      return false;
    }
  }

  /// Perform the actual refresh for supported languages
  Future<bool> _performRefresh() async {
    log.info('🔄 Starting translation refresh process');

    try {
      final supportedLanguages = ['es', 'pt', 'fr', 'de', 'it', 'ru', 'ja', 'zh', 'hi', 'ko'];
      int successfulRefreshes = 0;
      int totalLanguages = supportedLanguages.length;

      for (final language in supportedLanguages) {
        try {
          log.info('🌍 Refreshing translations for: $language');

          // Check if this specific language needs refresh
          final needsRefresh = await _apiService.needsRefresh(language);
          if (!needsRefresh) {
            log.info('⏭️ Skipping $language - recent translations available');
            successfulRefreshes++;
            continue;
          }

          // Refresh meals for popular categories
          final mealCategories = ['Chicken', 'Beef', 'Vegetarian', 'Pasta', 'Dessert'];
          int mealCount = 0;

          for (final category in mealCategories) {
            try {
              final meals = await _apiService.getMealsByCategory(
                category,
                language: language,
                page: 0,
                limit: 5, // Limit to 5 meals per category to control API usage
              );
              mealCount += meals.length;

              // Small delay between categories to be gentle on APIs
              await Future.delayed(const Duration(milliseconds: 500));
            } catch (e) {
              log.warning('Failed to refresh meals for category $category ($language): $e');
            }
          }

          // Refresh exercises for popular targets
          final exerciseTargets = ['abs', 'chest', 'legs', 'arms', 'back'];
          int exerciseCount = 0;

          for (final target in exerciseTargets) {
            try {
              final exercises = await _apiService.getExercisesByTarget(
                target,
                language: language,
              );
              exerciseCount += exercises.length;

              // Small delay between targets
              await Future.delayed(const Duration(milliseconds: 500));
            } catch (e) {
              log.warning('Failed to refresh exercises for target $target ($language): $e');
            }
          }

          // Update refresh tracking for this language
          await _databaseService.updateRefreshTracking(
            language,
            lastRefreshMeals: DateTime.now(),
            lastRefreshExercises: DateTime.now(),
            mealCount: mealCount,
            exerciseCount: exerciseCount,
          );

          successfulRefreshes++;
          log.info('✅ Successfully refreshed $language: $mealCount meals, $exerciseCount exercises');

          // Longer delay between languages to avoid overwhelming APIs
          if (language != supportedLanguages.last) {
            await Future.delayed(const Duration(seconds: 2));
          }

        } catch (e) {
          log.warning('Failed to refresh language $language: $e');
          // Continue with other languages
        }
      }

      // Update global refresh timestamp if we had some success
      if (successfulRefreshes > 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_lastRefreshKey, DateTime.now().millisecondsSinceEpoch);

        log.info('🎉 Refresh completed: $successfulRefreshes/$totalLanguages languages updated');
        return true;
      } else {
        log.warning('⚠️ Refresh failed for all languages');
        return false;
      }

    } catch (e, stackTrace) {
      log.severe('❌ Translation refresh failed', e, stackTrace);
      return false;
    }
  }

  /// Start the periodic refresh timer
  void _startPeriodicRefresh() {
    // Check every 6 hours if refresh is needed
    const checkInterval = Duration(hours: 6);

    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(checkInterval, (timer) async {
      log.fine('🔍 Periodic refresh check');
      await _checkAndRefreshIfNeeded();
    });

    log.info('⏲️ Periodic refresh timer started (checking every ${checkInterval.inHours} hours)');
  }

  /// Manually trigger a refresh
  Future<bool> forceRefresh({List<String>? languages}) async {
    log.info('🔧 Manual refresh triggered');

    try {
      if (languages != null && languages.isNotEmpty) {
        // Refresh specific languages only
        for (final language in languages) {
          await _databaseService.clearTranslationsForLanguage(language);
        }
      } else {
        // Clear all cached translations to force complete refresh
        final supportedLanguages = ['es', 'pt', 'fr', 'de', 'it', 'ru', 'ja', 'zh', 'hi', 'ko'];
        for (final language in supportedLanguages) {
          await _databaseService.clearTranslationsForLanguage(language);
        }
      }

      // Reset refresh timestamp to force immediate refresh
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastRefreshKey);

      return await _performRefresh();
    } catch (e, stackTrace) {
      log.severe('❌ Manual refresh failed', e, stackTrace);
      return false;
    }
  }

  /// Set custom refresh interval (in days)
  Future<void> setRefreshInterval(int days) async {
    if (days < 1 || days > 30) {
      throw ArgumentError('Refresh interval must be between 1 and 30 days');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_refreshIntervalKey, days);
      log.info('⚙️ Refresh interval set to $days days');
    } catch (e) {
      log.severe('Failed to set refresh interval: $e');
      rethrow;
    }
  }

  /// Get current refresh interval
  Future<int> getRefreshInterval() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_refreshIntervalKey) ?? _defaultRefreshIntervalDays;
    } catch (e) {
      log.warning('Failed to get refresh interval: $e');
      return _defaultRefreshIntervalDays;
    }
  }

  /// Get last refresh date
  Future<DateTime?> getLastRefreshDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastRefreshKey);
      return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
    } catch (e) {
      log.warning('Failed to get last refresh date: $e');
      return null;
    }
  }

  /// Get refresh status for all languages
  Future<Map<String, Map<String, dynamic>>> getRefreshStatus() async {
    final supportedLanguages = ['es', 'pt', 'fr', 'de', 'it', 'ru', 'ja', 'zh', 'hi', 'ko'];
    final status = <String, Map<String, dynamic>>{};

    for (final language in supportedLanguages) {
      try {
        final tracking = await _databaseService.getRefreshTracking(language);
        final hasTranslations = await _databaseService.hasTranslationsForLanguage(language);

        status[language] = {
          'hasTranslations': hasTranslations,
          'lastRefresh': tracking?['lastRefreshMeals'] != null
              ? DateTime.fromMillisecondsSinceEpoch(tracking!['lastRefreshMeals'] as int)
              : null,
          'mealCount': tracking?['mealCount'] ?? 0,
          'exerciseCount': tracking?['exerciseCount'] ?? 0,
          'needsRefresh': await _apiService.needsRefresh(language),
        };
      } catch (e) {
        log.warning('Failed to get refresh status for $language: $e');
        status[language] = {
          'hasTranslations': false,
          'lastRefresh': null,
          'mealCount': 0,
          'exerciseCount': 0,
          'needsRefresh': true,
        };
      }
    }

    return status;
  }

  /// Clean up old translations (older than specified days)
  Future<void> cleanupOldTranslations({int daysOld = 60}) async {
    try {
      await _databaseService.clearOldTranslations(daysOld: daysOld);
      log.info('🧹 Cleaned up translations older than $daysOld days');
    } catch (e) {
      log.severe('Failed to cleanup old translations: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    await _apiService.dispose();
    log.info('🔒 Translation Refresh Manager disposed');
  }
}