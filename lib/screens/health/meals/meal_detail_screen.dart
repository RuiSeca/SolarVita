// lib/screens/health/meal_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';

class MealDetailScreen extends StatelessWidget {
  final String mealTitle;
  final String imagePath;
  final String calories;
  final Map<String, String> nutritionFacts;
  final List<String> ingredients;
  final List<String> instructions;

  const MealDetailScreen({
    super.key,
    required this.mealTitle,
    required this.imagePath,
    required this.calories,
    required this.nutritionFacts,
    required this.ingredients,
    required this.instructions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNutritionSection(context),
                  const SizedBox(height: 24),
                  _buildIngredientsSection(context),
                  const SizedBox(height: 24),
                  _buildInstructionsSection(context),
                  const SizedBox(height: 24),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppTheme.surfaceColor(context),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: mealTitle,
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.surfaceColor(context),
                  ],
                ),
              ),
            ),
          ],
        ),
        title: Text(
          tr(context, mealTitle),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context).withAlpha(204),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back,
            color: AppTheme.textColor(context),
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildNutritionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'nutrition_facts'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: nutritionFacts.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr(context, entry.key),
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      entry.value,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'ingredients'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...ingredients.map((ingredient) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    tr(context, ingredient),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildInstructionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'instructions'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...instructions.asMap().entries.map((entry) {
          final index = entry.key;
          final instruction = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr(context, instruction),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              tr(context, 'add_to_meal_plan'),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.edit,
            color: AppTheme.textColor(context),
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.cardColor(context),
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}
