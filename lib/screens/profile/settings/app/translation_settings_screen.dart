import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/translation_helper.dart';
import '../../../../widgets/common/lottie_loading_widget.dart';
import '../../../../providers/riverpod/language_provider.dart';
import '../../../../providers/riverpod/meal_provider.dart';
import '../../../../services/database/translation_database_service.dart';
import '../../../../providers/riverpod/translation_progress_provider.dart';
import '../../../../models/languages/language.dart';

class TranslationSettingsScreen extends ConsumerStatefulWidget {
  const TranslationSettingsScreen({super.key});

  @override
  ConsumerState<TranslationSettingsScreen> createState() => _TranslationSettingsScreenState();
}

class _TranslationSettingsScreenState extends ConsumerState<TranslationSettingsScreen> {
  static const String _autoDownloadKey = 'auto_download_translations';

  bool _autoDownload = true;
  Map<String, Map<String, dynamic>> _languageStats = {};
  bool _isLoading = true;
  final Set<String> _downloadingLanguages = {};

  @override
  void initState() {
    super.initState();
    _loadAutoDownloadPreference();
    _loadTranslationStats();
  }

  Future<void> _loadTranslationStats() async {
    setState(() => _isLoading = true);

    try {
      final dbService = TranslationDatabaseService();
      final supportedLanguages = ref.read(supportedLanguagesProvider);
      final stats = <String, Map<String, dynamic>>{};

      for (final language in supportedLanguages) {
        if (language.code == 'en') continue; // Skip English as it's source language

        final counts = await dbService.getTranslationCountsForLanguage(language.code);
        final totalMeals = counts['meals'] ?? 0;
        final totalExercises = counts['exercises'] ?? 0;
        final isDownloaded = totalMeals > 0 || totalExercises > 0;

        // Estimate storage size (rough calculation)
        final estimatedSize = ((totalMeals * 2) + (totalExercises * 1.5)).round(); // KB estimate

        stats[language.code] = {
          'meals': totalMeals,
          'exercises': totalExercises,
          'isDownloaded': isDownloaded,
          'sizeKB': estimatedSize,
          'sizeDisplay': _formatSize(estimatedSize),
        };
      }

      if (mounted) {
        setState(() {
          _languageStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAutoDownloadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoDownloadValue = prefs.getBool(_autoDownloadKey) ?? true; // Default to true

      if (mounted) {
        setState(() {
          _autoDownload = autoDownloadValue;
        });
      }
    } catch (e) {
      // If loading fails, keep the default value (true)
    }
  }

  Future<void> _saveAutoDownloadPreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoDownloadKey, value);
    } catch (e) {
      // If saving fails, show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_saving_preference')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatSize(int sizeKB) {
    if (sizeKB < 1024) {
      return '${sizeKB}KB';
    } else {
      final sizeMB = (sizeKB / 1024).toStringAsFixed(1);
      return '${sizeMB}MB';
    }
  }

  Future<void> _downloadLanguage(String languageCode) async {
    // Prevent multiple downloads of the same language
    if (_downloadingLanguages.contains(languageCode)) {
      return;
    }

    _downloadingLanguages.add(languageCode);

    try {
      final unifiedService = ref.read(unifiedApiServiceProvider);
      final progressNotifier = ref.read(translationProgressProvider.notifier);

      // Initialize progress with separate meal and exercise counts
      final categories = ['Chicken', 'Beef', 'Pasta', 'Vegetarian', 'Seafood'];
      final exerciseTargets = ['pectorals', 'biceps', 'abs', 'quads'];
      final totalMeals = categories.length;
      final totalExercises = exerciseTargets.length;
      final totalItems = totalMeals + totalExercises;

      progressNotifier.startProgress(
        language: languageCode,
        category: 'Downloading',
        totalItems: totalItems,
        totalMeals: totalMeals,
        totalExercises: totalExercises,
      );

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardColor(context),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LottieLoadingWidget(),
                const SizedBox(height: 16),
                Text(
                  tr(context, 'downloading_translations'),
                  style: TextStyle(color: AppTheme.textColor(context)),
                ),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, child) {
                    final progress = ref.watch(translationProgressProvider);
                    if (progress.isActive) {
                      return Column(
                        children: [
                          // Overall progress
                          LinearProgressIndicator(
                            value: progress.progress,
                            backgroundColor: AppTheme.textColor(context).withAlpha(51),
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(progress.progress * 100).toInt()}% (${progress.translatedItems}/${progress.totalItems})',
                            style: TextStyle(
                              color: AppTheme.textColor(context).withAlpha(179),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Separate progress for meals and exercises
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.restaurant,
                                          size: 14,
                                          color: progress.currentPhase == 'meals'
                                              ? AppTheme.primaryColor
                                              : AppTheme.textColor(context).withAlpha(128),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          tr(context, 'meals'),
                                          style: TextStyle(
                                            color: progress.currentPhase == 'meals'
                                                ? AppTheme.primaryColor
                                                : AppTheme.textColor(context).withAlpha(128),
                                            fontSize: 11,
                                            fontWeight: progress.currentPhase == 'meals'
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: progress.mealProgress,
                                      backgroundColor: AppTheme.textColor(context).withAlpha(26),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        progress.currentPhase == 'meals'
                                            ? AppTheme.primaryColor
                                            : AppTheme.primaryColor.withAlpha(128),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${progress.completedMeals}/${progress.totalMeals}',
                                      style: TextStyle(
                                        color: AppTheme.textColor(context).withAlpha(128),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.fitness_center,
                                          size: 14,
                                          color: progress.currentPhase == 'exercises'
                                              ? AppTheme.primaryColor
                                              : AppTheme.textColor(context).withAlpha(128),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          tr(context, 'exercises'),
                                          style: TextStyle(
                                            color: progress.currentPhase == 'exercises'
                                                ? AppTheme.primaryColor
                                                : AppTheme.textColor(context).withAlpha(128),
                                            fontSize: 11,
                                            fontWeight: progress.currentPhase == 'exercises'
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: progress.exerciseProgress,
                                      backgroundColor: AppTheme.textColor(context).withAlpha(26),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        progress.currentPhase == 'exercises'
                                            ? AppTheme.primaryColor
                                            : AppTheme.primaryColor.withAlpha(128),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${progress.completedExercises}/${progress.totalExercises}',
                                      style: TextStyle(
                                        color: AppTheme.textColor(context).withAlpha(128),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        );
      }

      int completedMeals = 0;
      int completedExercises = 0;

      // Download meal categories
      for (final category in categories) {
        try {
          await unifiedService.getMealsByCategory(category, language: languageCode, page: 0, limit: 8);
          completedMeals++;
          progressNotifier.updateMealProgress(completedMeals);

          // Small delay to show progress
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          // Continue with other categories if one fails
          completedMeals++;
          progressNotifier.updateMealProgress(completedMeals);
        }
      }

      // Download exercise targets
      for (final target in exerciseTargets) {
        try {
          await unifiedService.getExercisesByTarget(target, language: languageCode);
          completedExercises++;
          progressNotifier.updateExerciseProgress(completedExercises);

          // Small delay to show progress
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          // Continue with other targets if one fails
          completedExercises++;
          progressNotifier.updateExerciseProgress(completedExercises);
        }
      }

      // Complete progress
      progressNotifier.completeProgress();

      // Small delay to show completion
      await Future.delayed(const Duration(milliseconds: 500));

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'language_downloaded_successfully')),
            backgroundColor: Colors.green,
          ),
        );

        // Reset progress
        progressNotifier.resetProgress();

        // Reload stats
        _loadTranslationStats();
      }
    } catch (e) {
      // Reset progress on error
      ref.read(translationProgressProvider.notifier).errorProgress('Download failed: $e');

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr(context, 'download_failed')}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );

        // Reset progress after error
        Future.delayed(const Duration(seconds: 2), () {
          ref.read(translationProgressProvider.notifier).resetProgress();
        });
      }
    } finally {
      // Always remove from downloading set
      _downloadingLanguages.remove(languageCode);
    }
  }

  Future<void> _deleteLanguageTranslations(String languageCode) async {
    try {
      final dbService = TranslationDatabaseService();
      await dbService.clearTranslationsForLanguage(languageCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'language_deleted_successfully')),
            backgroundColor: Colors.orange,
          ),
        );

        _loadTranslationStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'delete_failed')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadAllLanguages() async {
    final supportedLanguages = ref.read(supportedLanguagesProvider);
    final languagesToDownload = supportedLanguages
        .where((lang) => lang.code != 'en' && !(_languageStats[lang.code]?['isDownloaded'] ?? false))
        .toList();

    if (languagesToDownload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'all_languages_already_downloaded')),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    for (final language in languagesToDownload) {
      await _downloadLanguage(language.code);
    }
  }

  Future<void> _clearAllTranslations() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          tr(context, 'clear_all_translations'),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        content: Text(
          tr(context, 'clear_all_translations_confirmation'),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr(context, 'clear')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final dbService = TranslationDatabaseService();
        final supportedLanguages = ref.read(supportedLanguagesProvider);

        for (final language in supportedLanguages) {
          if (language.code != 'en') {
            await dbService.clearTranslationsForLanguage(language.code);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(context, 'all_translations_cleared')),
              backgroundColor: Colors.orange,
            ),
          );

          _loadTranslationStats();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(context, 'clear_failed')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final supportedLanguages = ref.watch(supportedLanguagesProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        title: Text(
          tr(context, 'translation_settings'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: LottieLoadingWidget())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Auto-download setting
                  _buildSectionHeader(tr(context, 'download_behavior')),
                  _buildAutoDownloadTile(),

                  const SizedBox(height: 24),

                  // Storage overview
                  _buildSectionHeader(tr(context, 'storage_usage')),
                  _buildStorageOverview(),

                  const SizedBox(height: 24),

                  // Language packages
                  _buildSectionHeader(tr(context, 'language_packages')),
                  ...supportedLanguages
                      .where((lang) => lang.code != 'en')
                      .map((language) => _buildLanguagePackageTile(language)),

                  const SizedBox(height: 24),

                  // Bulk actions
                  _buildSectionHeader(tr(context, 'bulk_actions')),
                  _buildBulkActions(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.textColor(context),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAutoDownloadTile() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textColor(context).withAlpha(26),
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          tr(context, 'auto_download_translations'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          tr(context, 'download_when_switching_languages'),
          style: TextStyle(
            color: AppTheme.textColor(context).withAlpha(179),
            fontSize: 14,
          ),
        ),
        value: _autoDownload,
        onChanged: (value) async {
          setState(() => _autoDownload = value);
          await _saveAutoDownloadPreference(value);
        },
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTheme.primaryColor;
          }
          return null;
        }),
      ),
    );
  }

  Widget _buildStorageOverview() {
    final totalSizeKB = _languageStats.values.fold<int>(
      0,
      (sum, stats) => sum + (stats['sizeKB'] as int),
    );
    final downloadedLanguages = _languageStats.values.where((stats) => stats['isDownloaded'] as bool).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textColor(context).withAlpha(26),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.storage, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(context, 'total_storage_used'),
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatSize(totalSizeKB),
                      style: TextStyle(
                        color: AppTheme.textColor(context).withAlpha(179),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$downloadedLanguages/${_languageStats.length} ${tr(context, 'languages')}',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagePackageTile(Language language) {
    final stats = _languageStats[language.code] ?? {
      'meals': 0,
      'exercises': 0,
      'isDownloaded': false,
      'sizeKB': 0,
      'sizeDisplay': '0KB',
    };

    final isDownloaded = stats['isDownloaded'] as bool;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final isCurrentLanguage = language.code == currentLanguage.code;
    final isDownloading = _downloadingLanguages.contains(language.code);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentLanguage
            ? AppTheme.primaryColor.withAlpha(26)
            : AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentLanguage
              ? AppTheme.primaryColor.withAlpha(128)
              : AppTheme.textColor(context).withAlpha(26),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          isDownloaded ? Icons.cloud_done : Icons.cloud_download,
          color: isDownloaded ? Colors.green : AppTheme.textColor(context).withAlpha(179),
          size: 28,
        ),
        title: Row(
          children: [
            Text(
              translateCountry(context, language.code),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isCurrentLanguage) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tr(context, 'current'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          isDownloading
              ? tr(context, 'downloading_translations')
              : isDownloaded
                  ? '${stats['meals']} ${tr(context, 'meals')}, ${stats['exercises']} ${tr(context, 'exercises')} • ${stats['sizeDisplay']}'
                  : tr(context, 'not_downloaded'),
          style: TextStyle(
            color: isDownloading
                ? AppTheme.primaryColor
                : AppTheme.textColor(context).withAlpha(179),
            fontSize: 12,
          ),
        ),
        trailing: isDownloading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : isDownloaded
                ? PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: AppTheme.textColor(context)),
                    onSelected: (value) {
                      if (value == 'redownload' && !isDownloading) {
                        _downloadLanguage(language.code);
                      } else if (value == 'delete' && !isDownloading) {
                        _deleteLanguageTranslations(language.code);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'redownload',
                        enabled: !isDownloading,
                        child: Row(
                          children: [
                            const Icon(Icons.refresh, size: 20),
                            const SizedBox(width: 8),
                            Text(tr(context, 'redownload')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        enabled: !isDownloading,
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 20, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              tr(context, 'delete'),
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : IconButton(
                    icon: const Icon(Icons.download, color: Colors.blue),
                    onPressed: isDownloading ? null : () => _downloadLanguage(language.code),
                  ),
      ),
    );
  }

  Widget _buildBulkActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _downloadAllLanguages,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_download, size: 20),
                const SizedBox(width: 8),
                Text(tr(context, 'download_all_languages')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _clearAllTranslations,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.clear_all, size: 20),
                const SizedBox(width: 8),
                Text(tr(context, 'clear_all_translations')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}