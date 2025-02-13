// lib/screens/health/meal_plan_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final List<String> _mealTimes = ['breakfast', 'lunch', 'dinner', 'snacks'];
  int _selectedDayIndex = 0;
  final List<String> _weekDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildWeekDaySelector(context),
            _buildNutritionSummary(context),
            Expanded(
              child: _buildMealsList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            tr(context, 'meal_plan'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon:
                Icon(Icons.calendar_month, color: AppTheme.textColor(context)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDaySelector(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _weekDays.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedDayIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tr(context, _weekDays[index]).substring(0, 3).toUpperCase(),
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.white
                          : AppTheme.textColor(context),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.white
                          : AppTheme.textColor(context).withAlpha(179),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNutritionSummary(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNutritionItem(context, 'calories', '2100', 'kcal'),
          _buildNutritionItem(context, 'protein', '130', 'g'),
          _buildNutritionItem(context, 'carbs', '240', 'g'),
          _buildNutritionItem(context, 'fat', '65', 'g'),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(
      BuildContext context, String title, String value, String unit) {
    return Column(
      children: [
        Text(
          tr(context, title),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: unit,
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealsList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mealTimes.length,
      itemBuilder: (context, index) {
        return _buildMealCard(context, _mealTimes[index]);
      },
    );
  }

  Widget _buildMealCard(BuildContext context, String mealTime) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              tr(context, mealTime),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.add_circle, color: AppColors.primary),
              onPressed: () {},
            ),
          ),
          _buildMealItems(context, mealTime),
        ],
      ),
    );
  }

  Widget _buildMealItems(BuildContext context, String mealTime) {
    // Sample meal items - in production, these would come from a data source
    return Column(
      children: [
        _buildMealItem(
          context,
          'assets/images/health/meals/${mealTime}_1.jpg',
          '${mealTime}_item_1',
          '300 kcal',
        ),
        _buildMealItem(
          context,
          'assets/images/health/meals/${mealTime}_2.jpg',
          '${mealTime}_item_2',
          '250 kcal',
        ),
      ],
    );
  }

  Widget _buildMealItem(BuildContext context, String imagePath, String titleKey,
      String calories) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              imagePath,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, titleKey),
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                  ),
                ),
                Text(
                  calories,
                  style: TextStyle(
                    color: AppTheme.textColor(context).withAlpha(179),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: AppTheme.textColor(context).withAlpha(179),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
