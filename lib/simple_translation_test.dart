// Simple test to verify the translation system compiles and works
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/translation/unified_api_provider.dart';

class SimpleTranslationTest extends ConsumerWidget {
  const SimpleTranslationTest({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translationServiceName = ref.watch(translationServiceNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Translation System Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Translation System Status',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text('Service: $translationServiceName'),
            const SizedBox(height: 16),

            // Test loading meals
            const Text(
              'Sample Chicken Meals:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final mealsAsync = ref.watch(mealsByCategoryProvider('Chicken'));

                  return mealsAsync.when(
                    data: (meals) => ListView.builder(
                      itemCount: meals.length,
                      itemBuilder: (context, index) {
                        final meal = meals[index];
                        return Card(
                          child: ListTile(
                            leading: meal['imagePath'] != null
                                ? Image.network(
                                    meal['imagePath'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.restaurant),
                                  )
                                : const Icon(Icons.restaurant),
                            title: Text(meal['titleKey'] ?? 'Unknown Meal'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (meal['category'] != null)
                                  Text('Category: ${meal['category']}'),
                                if (meal['isTranslated'] == true)
                                  const Row(
                                    children: [
                                      Icon(Icons.translate, size: 16, color: Colors.green),
                                      SizedBox(width: 4),
                                      Text('Translated', style: TextStyle(color: Colors.green, fontSize: 12)),
                                    ],
                                  ),
                              ],
                            ),
                            trailing: meal['calories'] != null
                                ? Text(meal['calories'].toString())
                                : null,
                          ),
                        );
                      },
                    ),
                    loading: () => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading and translating meals...'),
                        ],
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: $error'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref.invalidate(mealsByCategoryProvider);
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Force refresh translations
          ref.invalidate(mealsByCategoryProvider);
        },
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}