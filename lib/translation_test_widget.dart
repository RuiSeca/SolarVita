import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/riverpod/meal_provider.dart';
import 'providers/riverpod/language_provider.dart';

/// Simple widget to test if translation system is working
/// This will automatically update when you change languages
class TranslationTestWidget extends ConsumerWidget {
  const TranslationTestWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(currentLanguageProvider);
    final mealsAsync = ref.watch(mealsByCategoryLanguageAwareProvider('Chicken'));

    return Scaffold(
      appBar: AppBar(
        title: Text('Translation Test - ${currentLanguage.code.toUpperCase()}'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Language selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              children: [
                Text(
                  'Current Language: ${currentLanguage.name}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    _languageButton(ref, 'en', 'English'),
                    _languageButton(ref, 'es', 'Spanish'),
                    _languageButton(ref, 'fr', 'French'),
                    _languageButton(ref, 'pt', 'Portuguese'),
                    _languageButton(ref, 'de', 'German'),
                    _languageButton(ref, 'it', 'Italian'),
                  ],
                ),
              ],
            ),
          ),

          // Meals display
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chicken Meals (should auto-translate):',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: mealsAsync.when(
                      data: (meals) {
                        if (meals.isEmpty) {
                          return const Center(
                            child: Text(
                              'No meals found. Check your internet connection.',
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: meals.length,
                          itemBuilder: (context, index) {
                            final meal = meals[index];
                            final isTranslated = meal['isTranslated'] == true;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: meal['imagePath'] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          meal['imagePath'],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.restaurant, size: 50),
                                        ),
                                      )
                                    : const Icon(Icons.restaurant, size: 50),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        meal['titleKey'] ?? meal['name'] ?? 'Unknown Meal',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (isTranslated && currentLanguage.code != 'en')
                                      const Icon(
                                        Icons.translate,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (meal['category'] != null)
                                      Text('Category: ${meal['category']}'),
                                    if (meal['area'] != null)
                                      Text('Area: ${meal['area']}'),
                                    if (isTranslated)
                                      Text(
                                        '✅ Translated to ${currentLanguage.code.toUpperCase()}',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    else if (currentLanguage.code != 'en')
                                      const Text(
                                        '⏳ Translation in progress...',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Text('#${index + 1}'),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading meals...'),
                          ],
                        ),
                      ),
                      error: (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading meals:\\n$error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                ref.invalidate(mealsByCategoryLanguageAwareProvider);
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageButton(WidgetRef ref, String code, String name) {
    final currentLanguage = ref.watch(currentLanguageProvider);
    final isSelected = currentLanguage.code == code;

    return ElevatedButton(
      onPressed: () async {
        await ref.read(languageNotifierProvider.notifier).setLanguage(code);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey.shade300,
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(name),
    );
  }
}