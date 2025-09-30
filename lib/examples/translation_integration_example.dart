// Example of how to integrate the translation system into existing screens
//
// This file shows how to modify your existing meal and exercise screens
// to use the new translation system with minimal code changes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/translation/unified_api_provider.dart';
import '../providers/riverpod/language_provider.dart';

/// Example: Meal Category Screen Integration
///
/// Replace your existing meal category loading with:
class MealCategoryScreenExample extends ConsumerWidget {
  final String category;

  const MealCategoryScreenExample({
    required this.category,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(currentLanguageProvider);
    final mealsAsync = ref.watch(mealsByCategoryProvider(category));

    return Scaffold(
      appBar: AppBar(
        title: Text('$category Meals'),
        // Add translation service indicator
        actions: [
          _buildTranslationIndicator(ref),
        ],
      ),
      body: mealsAsync.when(
        data: (meals) => _buildMealsList(meals, currentLanguage.code),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(error, ref),
      ),
    );
  }

  Widget _buildMealsList(List<Map<String, dynamic>> meals, String language) {
    return ListView.builder(
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        final isTranslated = meal['isTranslated'] == true;

        return Card(
          child: ListTile(
            leading: meal['imagePath'] != null
                ? Image.network(meal['imagePath'], width: 50, height: 50, fit: BoxFit.cover)
                : const Icon(Icons.restaurant),
            title: Row(
              children: [
                Expanded(child: Text(meal['titleKey'] ?? 'Unknown Meal')),
                if (isTranslated && language != 'en')
                  const Icon(Icons.translate, size: 16, color: Colors.green),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (meal['category'] != null) Text('Category: ${meal['category']}'),
                if (meal['area'] != null) Text('Area: ${meal['area']}'),
                if (meal['calories'] != null) Text('Calories: ${meal['calories']}'),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to meal details
              // Navigator.push(context, MaterialPageRoute(
              //   builder: (_) => MealDetailScreen(mealId: meal['id']),
              // ));
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(Object error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Failed to load meals\n${error.toString()}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Refresh the data
              ref.invalidate(mealsByCategoryProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationIndicator(WidgetRef ref) {
    final serviceName = ref.watch(translationServiceNameProvider);
    final needsRefreshAsync = ref.watch(needsRefreshProvider);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.translate),
      tooltip: 'Translation Status',
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Service: $serviceName', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              needsRefreshAsync.when(
                data: (needsRefresh) => Text(
                  needsRefresh ? 'Refresh available' : 'Up to date',
                  style: TextStyle(
                    color: needsRefresh ? Colors.orange : Colors.green,
                    fontSize: 12,
                  ),
                ),
                loading: () => const Text('Checking...', style: TextStyle(fontSize: 12)),
                error: (_, __) => const Text('Status unknown', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'refresh',
          child: Row(
            children: [
              Icon(Icons.refresh),
              SizedBox(width: 8),
              Text('Force Refresh'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'stats',
          child: Row(
            children: [
              Icon(Icons.analytics),
              SizedBox(width: 8),
              Text('Translation Stats'),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        switch (value) {
          case 'refresh':
            _showRefreshDialog(ref);
            break;
          case 'stats':
            _showStatsDialog(ref);
            break;
        }
      },
    );
  }

  void _showRefreshDialog(WidgetRef ref) {
    // Show refresh dialog implementation
  }

  void _showStatsDialog(WidgetRef ref) {
    // Show stats dialog implementation
  }
}

/// Example: Exercise Screen Integration
class ExerciseScreenExample extends ConsumerWidget {
  final String target;

  const ExerciseScreenExample({
    required this.target,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesByTargetProvider(target));
    final currentLanguage = ref.watch(currentLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('$target Exercises'),
      ),
      body: exercisesAsync.when(
        data: (exercises) => ListView.builder(
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            return Card(
              child: ListTile(
                leading: exercise.image.isNotEmpty
                    ? Image.network(exercise.image, width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.fitness_center),
                title: Row(
                  children: [
                    Expanded(child: Text(exercise.title)),
                    if (currentLanguage.code != 'en')
                      const Icon(Icons.translate, size: 16, color: Colors.green),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.description),
                    Row(
                      children: [
                        Text('Duration: ${exercise.duration}'),
                        const SizedBox(width: 16),
                        Text('Difficulty: ${exercise.difficulty}'),
                      ],
                    ),
                  ],
                ),
                trailing: Text('${exercise.rating}/5.0'),
                onTap: () {
                  // Navigate to exercise details
                },
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              ElevatedButton(
                onPressed: () => ref.invalidate(exercisesByTargetProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Example: Search Screen Integration
class SearchScreenExample extends ConsumerStatefulWidget {
  const SearchScreenExample({super.key});

  @override
  ConsumerState<SearchScreenExample> createState() => _SearchScreenExampleState();
}

class _SearchScreenExampleState extends ConsumerState<SearchScreenExample> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = _searchQuery.isNotEmpty
        ? ref.watch(searchMealsProvider(_searchQuery))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Meals'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search for meals...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
            ),
          ),
          Expanded(
            child: searchResultsAsync?.when(
              data: (results) => ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final meal = results[index];
                  return ListTile(
                    leading: meal['imagePath'] != null
                        ? Image.network(meal['imagePath'], width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.restaurant),
                    title: Text(meal['titleKey'] ?? 'Unknown'),
                    subtitle: Text(meal['category'] ?? ''),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ) ?? const Center(
              child: Text('Enter a search query to find meals'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

/// Example: Translation Stats Widget
class TranslationStatsWidget extends ConsumerWidget {
  const TranslationStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(translationStatsProvider);
    final refreshStatusAsync = ref.watch(refreshStatusProvider);
    final serviceName = ref.watch(translationServiceNameProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Translation System',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text('Service: $serviceName'),
            const SizedBox(height: 8),
            statsAsync.when(
              data: (stats) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cached Meals: ${stats['meals']}'),
                  Text('Cached Exercises: ${stats['exercises']}'),
                  Text('Total Translations: ${stats['total']}'),
                ],
              ),
              loading: () => const Text('Loading stats...'),
              error: (error, stack) => Text('Failed to load stats: $error'),
            ),
            const SizedBox(height: 16),
            refreshStatusAsync.when(
              data: (status) => _buildRefreshStatus(status),
              loading: () => const Text('Checking refresh status...'),
              error: (error, stack) => Text('Failed to check status: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshStatus(Map<String, Map<String, dynamic>> status) {
    final languagesWithTranslations = status.entries
        .where((entry) => entry.value['hasTranslations'] == true)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Languages with translations: $languagesWithTranslations'),
        const SizedBox(height: 8),
        for (final entry in status.entries)
          Builder(
            builder: (context) {
              final lang = entry.key;
              final data = entry.value;
              final hasTranslations = data['hasTranslations'] as bool;
              final needsRefresh = data['needsRefresh'] as bool;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    Text(lang.toUpperCase()),
                    const SizedBox(width: 8),
                    Icon(
                      hasTranslations ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: hasTranslations ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    if (needsRefresh)
                      const Icon(Icons.refresh, size: 16, color: Colors.orange),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}