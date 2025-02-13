// lib/screens/health/favorite_meals_screen.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';

class FavoriteMealsScreen extends StatelessWidget {
  final Set<String> favoriteMeals;

  const FavoriteMealsScreen({
    super.key,
    required this.favoriteMeals,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        title: Text(
          tr(context, 'favorite_meals'),
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
      body: favoriteMeals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: AppTheme.textColor(context).withAlpha(128),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr(context, 'no_favorites'),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoriteMeals.length,
              itemBuilder: (context, index) {
                final mealId = favoriteMeals.elementAt(index);
                // Find the meal data from your meal database
                final meal = findMealById(mealId);
                if (meal == null) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        meal['imagePath']!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      tr(context, meal['titleKey']!),
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          meal['calories']!,
                          style: TextStyle(
                            color: AppTheme.textColor(context).withAlpha(179),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.pop(context, meal),
                  ),
                );
              },
            ),
    );
  }

  Map<String, String>? findMealById(String mealId) {
    // This should be replaced with your actual meal data lookup logic
    final allMeals = {
      'breakfast_oatmeal': {
        'titleKey': 'breakfast_oatmeal',
        'imagePath': 'assets/images/health/meals/breakfast_1.jpg',
        'calories': '300 kcal',
      },
      'breakfast_smoothie': {
        'titleKey': 'breakfast_smoothie',
        'imagePath': 'assets/images/health/meals/breakfast_2.jpg',
        'calories': '250 kcal',
      },
      // Add more meals here
    };

    return allMeals[mealId];
  }
}
