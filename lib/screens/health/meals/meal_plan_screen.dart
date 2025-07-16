import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import 'meal_detail_screen.dart';
import 'meal_edit_screen.dart';
import 'meal_search_screen.dart';
import 'favorite_meals_screen.dart';
import 'dart:async';
import 'package:logger/logger.dart';

var logger = Logger();

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  // Storage key constants
  static const String _weeklyMealDataKey = 'weeklyMealData';
  static const String _favoriteMealsKey = 'favoriteMeals';

  // Carousel setup
  late final PageController _pageController;
  Timer? _carouselTimer;

  // Weekly meal data structure
  final Map<int, Map<String, List<Map<String, dynamic>>>> _weeklyMealData = {};

  // Lists for meal times and week days
  final List<String> _mealTimes = ['breakfast', 'lunch', 'dinner', 'snacks'];
  final List<String> _weekDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  // Current selections
  String _currentMealTime = 'breakfast';
  int _selectedDayIndex = 0;

  // Daily meal data structure
  Map<String, List<Map<String, dynamic>>> _mealData = {
    'breakfast': [],
    'lunch': [],
    'dinner': [],
    'snacks': [],
  };

  // Favorite meals set
  final Set<String> _favoriteMeals = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.8,
      initialPage: 1,
    );
    _startCarouselTimer();
    _loadSavedData(); // Load saved data when screen initializes
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.round() + 1;
        if (nextPage >= 3) {
          nextPage = 0;
          _pageController.jumpToPage(0);
        } else {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        }
      }
    });
  }

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
            _buildCarousel(context),
            _buildNutritionSummary(context),
            Expanded(child: _buildMealsList(context)),
          ],
        ),
      ),
    );
  }

  // Add these methods to the _MealPlanScreenState class

// Load saved data from SharedPreferences
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load weekly meal data
      final savedWeeklyData = prefs.getString(_weeklyMealDataKey);
      if (savedWeeklyData != null) {
        final decodedData = json.decode(savedWeeklyData);
        setState(() {
          decodedData.forEach((String key, dynamic value) {
            final dayIndex = int.parse(key);
            _weeklyMealData[dayIndex] = {};

            (value as Map<String, dynamic>).forEach((mealTime, meals) {
              _weeklyMealData[dayIndex]![mealTime] = (meals as List)
                  .map((meal) => Map<String, dynamic>.from(meal))
                  .toList();
            });
          });

          // Load current day's data
          _mealData = _weeklyMealData[_selectedDayIndex] ??
              {
                'breakfast': [],
                'lunch': [],
                'dinner': [],
                'snacks': [],
              };
        });
      }

      // Load favorite meals
      final savedFavorites = prefs.getStringList(_favoriteMealsKey);
      if (savedFavorites != null) {
        setState(() {
          _favoriteMeals.addAll(savedFavorites);
        });
      }
    } catch (e) {
      logger.d('Error loading saved data: $e');
    }
  }

// Save meal data to SharedPreferences
  Future<void> _saveMealData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save current day's data to weekly data
      _weeklyMealData[_selectedDayIndex] =
          Map<String, List<Map<String, dynamic>>>.from(_mealData);

      // Convert data for storage
      final dataToSave = {};
      _weeklyMealData.forEach((key, value) {
        dataToSave[key.toString()] = value;
      });

      // Save both weekly data and favorites
      await prefs.setString(_weeklyMealDataKey, json.encode(dataToSave));
      await prefs.setStringList(_favoriteMealsKey, _favoriteMeals.toList());
    } catch (e) {
      logger.d('Error saving meal data: $e');
    }
  }

// Add a meal to the current day
  void _addMealToDay(String mealTime, Map<String, dynamic> meal) {
    // Format the meal data consistently
    final formattedMeal = {
      'id': meal['id'],
      'titleKey': meal['titleKey'],
      'imagePath': meal['imagePath'],
      'nutritionFacts': {
        'calories': meal['nutritionFacts']?['calories']?.toString() ?? '0',
        'protein': meal['nutritionFacts']?['protein'] ?? '0g',
        'carbs': meal['nutritionFacts']?['carbs'] ?? '0g',
        'fat': meal['nutritionFacts']?['fat'] ?? '0g',
      },
      'ingredients': meal['ingredients'] ?? [],
      'measures': meal['measures'] ?? [],
      'instructions': meal['instructions'] ?? [],
      'area': meal['area'],
      'category': meal['category'],
      'isVegan': meal['isVegan'] ?? false,
    };

    setState(() {
      if (!_mealData.containsKey(mealTime)) {
        _mealData[mealTime] = [];
      }
      // Prevent duplicate meals
      if (!_mealData[mealTime]!.any((m) => m['id']?.toString() == formattedMeal['id']?.toString())) {
        _mealData[mealTime]!.add(formattedMeal);
      }
    });

    // Save the updated data
    _saveMealData();

    // Debug print to verify the data
    logger.d('Added meal to $mealTime: ${formattedMeal['titleKey']}');
    logger.d('Nutrition facts: ${formattedMeal['nutritionFacts']}');
  }

// Remove a meal from the current day
  void _removeMealFromDay(String mealTime, String mealId) {
    setState(() {
      _mealData[mealTime]?.removeWhere((meal) => meal['id'] == mealId);
    });
    _saveMealData();
  }

// Toggle meal favorite status
  Future<void> _toggleFavorite(String? mealId) async {
    if (mealId == null || mealId.isEmpty) return;

    final id = mealId.toString();

    setState(() {
      if (_favoriteMeals.contains(id)) {
        _favoriteMeals.remove(id);
      } else {
        _favoriteMeals.add(id);
      }

      // Update the isFavorite status in all instances
      void updateMealFavoriteStatus(List<Map<String, dynamic>> meals) {
        for (var meal in meals) {
          if (meal['id']?.toString() == id) {
            meal['isFavorite'] = _favoriteMeals.contains(id);
          }
        }
      }

      // Update weekly data
      _weeklyMealData.forEach((day, mealTimes) {
        mealTimes.forEach((_, meals) {
          updateMealFavoriteStatus(meals);
        });
      });

      // Update current day's meals
      _mealData.forEach((_, meals) {
        updateMealFavoriteStatus(meals);
      });
    });

    await _saveMealData();
  }

  // Add these methods to the _MealPlanScreenState class

  Future<void> _handleShowMealDetail(Map<String, dynamic> meal) async {
    if (!mounted) return;

    // Ensure calories is always a non-null String.
    final caloriesValue = meal['calories']?.toString() ?? '0 kcal';

    final nutritionFactsValue = meal['nutritionFacts'] != null
        ? Map<String, dynamic>.from(meal['nutritionFacts'])
        : {
            'calories': '0',
            'protein': '0g',
            'carbs': '0g',
            'fat': '0g',
          };

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MealDetailScreen(
          mealId: meal['id'],
          mealTitle: meal['titleKey'],
          imagePath: meal['imagePath'],
          calories: caloriesValue,
          nutritionFacts: nutritionFactsValue,
          ingredients: List<String>.from(meal['ingredients'] ?? []),
          measures: List<String>.from(meal['measures'] ?? []),
          instructions: List<String>.from(meal['instructions'] ?? []),
          area: meal['area'] ?? '',
          category: meal['category'] ?? '',
          isVegan: meal['isVegan'] ?? false,
          isFavorite: _favoriteMeals.contains(meal['id']),
          onFavoriteToggle: _toggleFavorite,
        ),
      ),
    );

    if (result != null && mounted) {
      if (result['action'] == 'add_meal') {
        _addMealToDay(result['mealTime'], result['meal']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'meal_added_to_plan')),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Getter to return all meals from all meal times
  List<Map<String, dynamic>> get _meals {
    List<Map<String, dynamic>> allMeals = [];
    _mealData.forEach((_, mealList) {
      allMeals.addAll(mealList);
    });
    return allMeals;
  }

  void _showAddMealOptions(BuildContext context, String mealTime) {
    setState(() {
      _currentMealTime = mealTime;
    });

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
                if (newMeal != null && mounted) {
                  setState(() {
                    if (newMeal is Map<String, dynamic>) {
                      final formattedMeal = {
                        'id': newMeal['title'] ?? DateTime.now().toString(),
                        'titleKey': newMeal['title'],
                        'imagePath': newMeal['imagePath'],
                        'calories':
                            '${newMeal['nutritionFacts']?['calories'] ?? '0'} kcal',
                        'nutritionFacts': newMeal['nutritionFacts'],
                        'ingredients': newMeal['ingredients'],
                        'measures': List<String>.filled(
                            (newMeal['ingredients'] as List).length, '1'),
                        'instructions': newMeal['instructions'],
                        'area': '',
                        'category': '',
                        'isVegan': false,
                      };
                      _addMealToDay(_currentMealTime, formattedMeal);
                    }
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
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MealSearchScreen(
                        selectedDayIndex:
                            _selectedDayIndex, // ensure this variable is defined in your state
                        currentMealTime:
                            _currentMealTime, // ensure this variable is defined in your state
                      ),
                    ),
                  );
                  if (result != null && mounted) {
                    if (result is Map<String, dynamic>) {
                      if (result['action'] == 'add_meal') {
                        _addMealToDay(result['mealTime'], result['meal']);
                      } else {
                        _addMealToDay(_currentMealTime, result);
                      }
                    }
                  }
                }),
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
                    builder: (context) => FavoriteMealsScreen(
                      favoriteMeals: _favoriteMeals,
                      meals: _meals,
                      onFavoriteToggle: _toggleFavorite, // Pass the callback
                    ),
                  ),
                );
                if (selectedMeal != null && mounted) {
                  if (selectedMeal is Map<String, dynamic>) {
                    if (selectedMeal['action'] == 'add_meal') {
                      _addMealToDay(
                          selectedMeal['mealTime'], selectedMeal['meal']);
                    } else {
                      _addMealToDay(_currentMealTime, selectedMeal);
                    }
                  }
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String mealId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
          ),
          TextButton(
            onPressed: () {
              _mealData.forEach((mealTime, meals) {
                _removeMealFromDay(mealTime, mealId);
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showMealOptions(BuildContext context, Map<String, dynamic> meal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
              leading: const Icon(Icons.edit, color: AppColors.primary),
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
                      mealTitle: meal['titleKey'],
                      imagePath: meal['imagePath'],
                      nutritionFacts:
                          Map<String, String>.from(meal['nutritionFacts']),
                      ingredients: List<String>.from(meal['ingredients']),
                      instructions: List<String>.from(meal['instructions']),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                tr(context, 'delete'),
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, meal['id']);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  // Add these UI building methods to the _MealPlanScreenState class

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
        itemExtent: 72.0, // Fixed width for horizontal day selector items (width + margin)
        itemBuilder: (context, index) {
          final isSelected = _selectedDayIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                // Save current day's data
                _weeklyMealData[_selectedDayIndex] =
                    Map<String, List<Map<String, dynamic>>>.from(_mealData);

                // Update selected day
                _selectedDayIndex = index;

                // Load saved meals for selected day or empty
                _mealData = _weeklyMealData[index] ??
                    {
                      'breakfast': [],
                      'lunch': [],
                      'dinner': [],
                      'snacks': [],
                    };
              });
              _saveMealData();
            },
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
                          ? Colors.white
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
                          ? Colors.white
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

  Widget _buildCarousel(BuildContext context) {
    final List<String> carouselImages = [
      'assets/images/health/meals/create_meal.webp',
      'assets/images/health/meals/search_meal.webp',
      'assets/images/health/meals/featured_meal.webp',
    ];

    final List<String> carouselLabels = [
      'Create Meal',
      'Search Meal',
      'Featured Meal',
    ];

    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: _pageController,
        itemCount: carouselImages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              onTap: () async {
                if (index == 0) {
                  final navigator =
                      Navigator.of(context); // Guarda o contexto antes do await
                  final newMeal = await navigator.push(
                    MaterialPageRoute(
                      builder: (context) => const MealEditScreen(),
                    ),
                  );

                  if (!mounted || newMeal == null) return;

                  setState(() {
                    if (newMeal is Map<String, dynamic>) {
                      final formattedMeal = {
                        'id': newMeal['title'] ?? DateTime.now().toString(),
                        'titleKey': newMeal['title'],
                        'imagePath': newMeal['imagePath'],
                        'calories':
                            '${newMeal['nutritionFacts']?['calories'] ?? '0'} kcal',
                        'nutritionFacts': newMeal['nutritionFacts'],
                        'ingredients': newMeal['ingredients'],
                        'measures': List<String>.filled(
                            (newMeal['ingredients'] as List).length, '1'),
                        'instructions': newMeal['instructions'],
                        'area': '',
                        'category': '',
                        'isVegan': false,
                      };
                      _addMealToDay(_currentMealTime, formattedMeal);
                    }
                  });
                } else if (index == 1) {
                  final navigator = Navigator.of(context);
                  final scaffoldMessenger =
                      ScaffoldMessenger.of(context); // Guarda antes do await

                  final result = await navigator.push(
                    MaterialPageRoute(
                      builder: (context) => MealSearchScreen(
                        selectedDayIndex: _selectedDayIndex,
                        currentMealTime: _currentMealTime,
                      ),
                    ),
                  );

                  if (!mounted || result == null) return;

                  if (result is Map<String, dynamic> &&
                      result['action'] == 'add_meal') {
                    _addMealToDay(result['mealTime'], result['meal']);

                    if (!mounted) return;

                    scaffoldMessenger.showSnackBar(
                      // Usa a variável guardada
                      SnackBar(
                        content: Text('Meal added to ${result['mealTime']}'),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      carouselImages[index],
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        color: Colors.black.withAlpha(179),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          carouselLabels[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNutritionSummary(BuildContext context) {
    final nutrition = _calculateDailyNutrition();

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
          _buildNutritionItem(context, 'calories',
              nutrition['calories']!.toStringAsFixed(0), 'kcal'),
          _buildNutritionItem(context, 'protein',
              nutrition['protein']!.toStringAsFixed(0), 'g'),
          _buildNutritionItem(
              context, 'carbs', nutrition['carbs']!.toStringAsFixed(0), 'g'),
          _buildNutritionItem(
              context, 'fat', nutrition['fat']!.toStringAsFixed(0), 'g'),
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
      itemExtent: 200.0, // Fixed height for meal time cards (base height without dynamic content)
      itemBuilder: (context, index) =>
          _buildMealCard(context, _mealTimes[index]),
    );
  }

  Widget _buildMealCard(BuildContext context, String mealTime) {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        _addMealToDay(mealTime, details.data);
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
            mainAxisSize: MainAxisSize.min, // Add this
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
                  onPressed: () => _showAddMealOptions(context, mealTime),
                ),
              ),
              ConstrainedBox(
                // Wrap the meal items in a ConstrainedBox
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(context).size.height * 0.4, // Limit height
                ),
                child: SingleChildScrollView(
                  // Make items scrollable
                  child: Column(
                    children: _buildMealItems(context, mealTime),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildMealItems(BuildContext context, String mealTime) {
    final meals = _mealData[mealTime] ?? [];
    return meals.map((meal) => _buildMealItem(context, meal)).toList();
  }

  Widget _buildMealItem(BuildContext context, Map<String, dynamic> meal) {
    final bool isFavorite = _favoriteMeals.contains(meal['id']?.toString());

    // Helper function to build meal image
    Widget buildMealImage() {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child:
            meal['imagePath'] != null && meal['imagePath'].toString().isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: meal['imagePath'],
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 70,
                      height: 70,
                      color: AppTheme.cardColor(context),
                      child: const CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 70,
                      height: 70,
                      color: AppTheme.cardColor(context),
                      child: const Icon(Icons.restaurant, size: 30),
                    ),
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: AppTheme.cardColor(context),
                    child: const Icon(Icons.restaurant, size: 30),
                  ),
      );
    }

    // Function to build draggable feedback widget
    Widget buildFeedback() {
      return Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              buildMealImage(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  meal['titleKey']?.toString() ?? 'Unnamed Meal',
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LongPressDraggable<Map<String, dynamic>>(
      delay: const Duration(milliseconds: 500),
      hapticFeedbackOnStart: true,
      data: meal,
      onDragStarted: () {
        HapticFeedback.heavyImpact();
      },
      onDragEnd: (details) {
        if (details.wasAccepted) {
          setState(() {
            _mealData.forEach((mealTime, meals) {
              meals.removeWhere(
                  (m) => m['id']?.toString() == meal['id']?.toString());
            });
          });
          _saveMealData();
        }
      },
      onDraggableCanceled: (velocity, offset) {
        setState(() {}); // Trigger rebuild to ensure proper positioning
      },
      feedback: buildFeedback(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => _handleShowMealDetail(meal),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Meal Image with Hero animation
                Hero(
                  tag: meal['id']?.toString() ?? 'default_tag',
                  child: buildMealImage(),
                ),
                const SizedBox(width: 12),

                // Meal Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meal Title
                      Text(
                        meal['titleKey']?.toString() ?? 'Unnamed Meal',
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Nutritional Information Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Calories
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
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
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${meal['nutritionFacts']?['calories'] ?? '0'} kcal",
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Area (if available)
                            if (meal['area'] != null &&
                                meal['area'].toString().isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardColor(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.textColor(context)
                                        .withAlpha(26),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.public,
                                      size: 14,
                                      color: AppTheme.textColor(context),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      meal['area'].toString(),
                                      style: TextStyle(
                                        color: AppTheme.textColor(context),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Favorite Button
                    IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return RotationTransition(
                            turns: animation,
                            child: ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          key: ValueKey(isFavorite),
                          color: isFavorite ? Colors.red : Colors.grey,
                        ),
                      ),
                      onPressed: () =>
                          _toggleFavorite(meal['id']?.toString() ?? ''),
                    ),
                    // More Options Button
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: AppTheme.textColor(context).withAlpha(179),
                      ),
                      onPressed: () => _showMealOptions(context, meal),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, double> _calculateDailyNutrition() {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var mealList in _mealData.values) {
      for (var meal in mealList) {
        if (meal['nutritionFacts'] != null) {
          totalCalories += double.tryParse(meal['nutritionFacts']['calories']
                  ?.replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0;
          totalProtein += double.tryParse(meal['nutritionFacts']['protein']
                  ?.replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0;
          totalCarbs += double.tryParse(meal['nutritionFacts']['carbs']
                  ?.replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0;
          totalFat += double.tryParse(meal['nutritionFacts']['fat']
                  ?.replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0;
        }
      }
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }
}
