import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import 'meal_detail_screen.dart';

class FavoriteMealsScreen extends StatefulWidget {
  final Set<String> favoriteMeals;
  final List<Map<String, dynamic>> meals;
  final Function(String) onFavoriteToggle; // Add this

  const FavoriteMealsScreen({
    super.key,
    required this.favoriteMeals,
    required this.meals,
    required this.onFavoriteToggle, // Add this
  });

  @override
  State<FavoriteMealsScreen> createState() => _FavoriteMealsScreenState();
}

class _FavoriteMealsScreenState extends State<FavoriteMealsScreen> {
  late final NavigatorState _navigator;

  @override
  void initState() {
    super.initState();
    _navigator = Navigator.of(context);
  }

  @override
  Widget build(BuildContext context) {
    final filteredMeals = widget.meals
        .where((meal) => widget.favoriteMeals.contains(meal['id']))
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr(context, 'favorite_meals'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: filteredMeals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: AppTheme.textColor(context).withAlpha(179),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr(context, 'no_favorites'),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'add_favorites_hint'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textColor(context).withAlpha(179),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredMeals.length,
              itemBuilder: (context, index) => _buildMealCard(
                context,
                filteredMeals[index],
              ),
            ),
    );
  }

  Widget _buildMealCard(BuildContext context, Map<String, dynamic> meal) {
    return GestureDetector(
      onTap: () => _handleMealTap(context, meal),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Hero(
                    tag: meal['id'],
                    child: Image.network(
                      meal['imagePath'],
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 140,
                          width: double.infinity,
                          color: AppTheme.cardColor(context),
                          child: const Icon(Icons.broken_image, size: 40),
                        );
                      },
                    ),
                  ),
                ),
                if (meal['isVegan'] == true)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.eco,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'VEGAN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['titleKey'],
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 12,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  meal['calories'],
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (meal['area'] != null) ...[
                        const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    AppTheme.textColor(context).withAlpha(26),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.public,
                                  size: 12,
                                  color: AppTheme.textColor(context),
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    meal['area'],
                                    style: TextStyle(
                                      color: AppTheme.textColor(context),
                                      fontSize: 10,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMealTap(
      BuildContext context, Map<String, dynamic> meal) async {
    final mealId = meal['id']?.toString() ?? '';
    if (mealId.isEmpty) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealDetailScreen(
          mealId: mealId,
          mealTitle: meal['titleKey']?.toString() ?? 'Unnamed Meal',
          imagePath: meal['imagePath']?.toString() ?? '',
          calories: meal['calories']?.toString() ?? '0 kcal',
          nutritionFacts: Map<String, String>.from(meal['nutritionFacts'] ??
              {'calories': '0', 'protein': '0g', 'carbs': '0g', 'fat': '0g'}),
          ingredients: List<String>.from(meal['ingredients'] ?? []),
          measures: List<String>.from(meal['measures'] ?? []),
          instructions: List<String>.from(meal['instructions'] ?? []),
          area: meal['area']?.toString(),
          category: meal['category']?.toString(),
          isVegan: meal['isVegan'] ?? false,
          youtubeUrl: meal['youtubeUrl']?.toString(),
          isFavorite: true,
          onFavoriteToggle: widget.onFavoriteToggle,
        ),
      ),
    );

    if (result != null && mounted) {
      _navigator.pop(result);
    }
  }
}
