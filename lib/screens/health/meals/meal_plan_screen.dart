// lib/screens/health/meal_plan_screen.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import 'meal_detail_screen.dart';
import 'meal_edit_screen.dart';
import 'meal_search_screen.dart';
import 'favorite_meals_screen.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final List<String> _mealTimes = ['breakfast', 'lunch', 'dinner', 'snacks'];
  String _currentMealTime = 'breakfast';
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

  final Map<String, List<Map<String, String>>> _mealData = {
    'breakfast': [
      {
        'titleKey': 'breakfast_oatmeal',
        'imagePath': 'assets/images/health/meals/breakfast_1.jpg',
        'calories': '300 kcal',
      },
      {
        'titleKey': 'breakfast_smoothie',
        'imagePath': 'assets/images/health/meals/breakfast_2.jpg',
        'calories': '250 kcal',
      },
    ],
    'lunch': [
      {
        'titleKey': 'lunch_salad',
        'imagePath': 'assets/images/health/meals/lunch_1.jpg',
        'calories': '400 kcal',
      },
      {
        'titleKey': 'lunch_sandwich',
        'imagePath': 'assets/images/health/meals/lunch_2.jpg',
        'calories': '450 kcal',
      },
    ],
    'dinner': [
      {
        'titleKey': 'dinner_salmon',
        'imagePath': 'assets/images/health/meals/dinner_1.jpg',
        'calories': '550 kcal',
      },
      {
        'titleKey': 'dinner_pasta',
        'imagePath': 'assets/images/health/meals/dinner_2.jpg',
        'calories': '600 kcal',
      },
    ],
    'snacks': [
      {
        'titleKey': 'snack_fruits',
        'imagePath': 'assets/images/health/meals/snacks_1.jpg',
        'calories': '100 kcal',
      },
      {
        'titleKey': 'snack_nuts',
        'imagePath': 'assets/images/health/meals/snacks_2.jpg',
        'calories': '150 kcal',
      },
    ],
  };

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

  void _showAddMealOptions(BuildContext context, String mealTime) {
    // Add mealTime parameter
    _currentMealTime = mealTime; // Set current meal time
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textColor(context).withAlpha(51),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle, color: AppColors.primary),
              title: Text(
                tr(context, 'create_new_meal'),
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
              onTap: () async {
                Navigator.pop(context);
                final newMeal = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MealEditScreen(),
                  ),
                );
                if (newMeal != null) {
                  setState(() {
                    _mealData[_currentMealTime]?.add(newMeal);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.search, color: AppColors.primary),
              title: Text(
                tr(context, 'search_meals'),
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
              onTap: () async {
                Navigator.pop(context);
                final selectedMeal = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MealSearchScreen(),
                  ),
                );
                if (selectedMeal != null) {
                  setState(() {
                    _mealData[_currentMealTime]?.add(selectedMeal);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: AppColors.primary),
              title: Text(
                tr(context, 'from_favorites'),
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
              onTap: () async {
                Navigator.pop(context);
                final selectedMeal = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FavoriteMealsScreen(favoriteMeals: _favoriteMeals),
                  ),
                );
                if (selectedMeal != null) {
                  setState(() {
                    _mealData[_currentMealTime]?.add(selectedMeal);
                  });
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showMealOptions(
      BuildContext context, String mealTitle, String imagePath) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      transitionAnimationController: AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: Navigator.of(context),
      ),
      builder: (context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textColor(context).withAlpha(51),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: 1.0,
                child: const Icon(Icons.visibility, color: AppColors.primary),
              ),
              title: Text(
                tr(context, 'view_details'),
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MealDetailScreen(
                      mealTitle: mealTitle,
                      imagePath: imagePath,
                      calories: '300',
                      nutritionFacts: {
                        'protein': '20g',
                        'carbs': '30g',
                        'fat': '10g',
                      },
                      ingredients: [
                        'ingredient_1',
                        'ingredient_2',
                        'ingredient_3',
                      ],
                      instructions: [
                        'instruction_1',
                        'instruction_2',
                        'instruction_3',
                      ],
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: 1.0,
                child: const Icon(Icons.edit, color: AppColors.primary),
              ),
              title: Text(
                tr(context, 'edit_meal'),
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MealEditScreen(
                      mealTitle: mealTitle,
                      imagePath: imagePath,
                      nutritionFacts: {
                        'calories': '300',
                        'protein': '20g',
                        'carbs': '30g',
                        'fat': '10g',
                      },
                      ingredients: [
                        'ingredient_1',
                        'ingredient_2',
                        'ingredient_3',
                      ],
                      instructions: [
                        'instruction_1',
                        'instruction_2',
                        'instruction_3',
                      ],
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 200),
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: child,
                ),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
              title: Text(
                tr(context, 'remove_meal'),
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                // Show delete confirmation dialog with animation
                showGeneralDialog(
                  context: context,
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return ScaleTransition(
                      scale: animation,
                      child: AlertDialog(
                        backgroundColor: AppTheme.cardColor(context),
                        title: Text(
                          tr(context, 'confirm_delete'),
                          style: TextStyle(color: AppTheme.textColor(context)),
                        ),
                        content: Text(
                          tr(context, 'delete_meal_confirmation'),
                          style: TextStyle(color: AppTheme.textColor(context)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              tr(context, 'cancel'),
                              style:
                                  TextStyle(color: AppTheme.textColor(context)),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Implement meal removal logic
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(context); // Close bottom sheet
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 200),
                  barrierDismissible: true,
                  barrierLabel: '',
                  barrierColor: Colors.black54,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, String mealTime) {
    return DragTarget<Map<String, String>>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        setState(() {
          _mealData[mealTime]?.add(details.data);
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: candidateData.isNotEmpty
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
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
                  onPressed: () => _showAddMealOptions(
                      context, mealTime), // Pass mealTime here
                ),
              ),
              _buildMealItems(context, mealTime),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMealItems(BuildContext context, String mealTime) {
    final meals = _mealData[mealTime] ?? [];
    return Column(
      children: meals
          .map((meal) => _buildMealItem(
                context,
                meal['imagePath']!,
                meal['titleKey']!,
                meal['calories']!,
              ))
          .toList(),
    );
  }

  final Set<String> _favoriteMeals = {};

  void _toggleFavorite(String mealId) {
    setState(() {
      if (_favoriteMeals.contains(mealId)) {
        _favoriteMeals.remove(mealId);
      } else {
        _favoriteMeals.add(mealId);
      }
    });
  }

  // Update _buildMealItem to be draggable:
  Widget _buildMealItem(BuildContext context, String imagePath, String titleKey,
      String calories) {
    return LongPressDraggable<Map<String, String>>(
      data: {
        'titleKey': titleKey,
        'imagePath': imagePath,
        'calories': calories,
      },
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
          ),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tr(context, titleKey),
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          calories,
                          style: TextStyle(
                            color: AppTheme.textColor(context).withAlpha(179),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context).withAlpha(128),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withAlpha(128),
            width: 2,
          ),
        ),
      ),
      child: InkWell(
        onTap: () => _showMealOptions(context, titleKey, imagePath),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Hero(
                tag: titleKey,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    imagePath,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
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
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          calories,
                          style: TextStyle(
                            color: AppTheme.textColor(context).withAlpha(179),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _favoriteMeals.contains(titleKey)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _favoriteMeals.contains(titleKey)
                          ? Colors.red
                          : AppTheme.textColor(context).withAlpha(179),
                    ),
                    onPressed: () => _toggleFavorite(titleKey),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: AppTheme.textColor(context).withAlpha(179),
                    ),
                    onPressed: () =>
                        _showMealOptions(context, titleKey, imagePath),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
