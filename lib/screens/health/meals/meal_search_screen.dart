import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:retry/retry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import 'meal_detail_screen.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class MealSearchScreen extends StatefulWidget {
  final int selectedDayIndex;
  final String currentMealTime;

  const MealSearchScreen({
    super.key,
    required this.selectedDayIndex,
    required this.currentMealTime,
  });

  @override
  State createState() => _MealSearchScreenState();
}

class _MealSearchScreenState extends State<MealSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Set<String> _favoriteMeals = {};
  List<Map<String, dynamic>> _meals = [];
  List<Map<String, String>> _categories = [];
  String _selectedCategory = 'All';
  bool _isLoading = false;
  bool _isLoadingMore = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadInitialData();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreMeals();
    }
  }

  Future<void> _loadMoreMeals() async {
    if (_selectedCategory == 'All' || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://www.themealdb.com/api/json/v1/1/filter.php?c=$_selectedCategory'),
        headers: {'Accept': 'application/json', 'Connection': 'keep-alive'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          List<Map<String, dynamic>> newMeals = [];
          final allMeals = List.from(data['meals']);
          final existingMealIds = _meals.map((m) => m['id']).toSet();
          final newMealsToFetch = allMeals
              .where((meal) => !existingMealIds.contains(meal['idMeal']))
              .take(6)
              .toList();

          for (var meal in newMealsToFetch) {
            final detailResponse = await http.get(
              Uri.parse(
                  'https://www.themealdb.com/api/json/v1/1/lookup.php?i=${meal['idMeal']}'),
              headers: {
                'Accept': 'application/json',
                'Connection': 'keep-alive'
              },
            ).timeout(const Duration(seconds: 30));

            if (detailResponse.statusCode == 200) {
              final detailData = json.decode(detailResponse.body);
              if (detailData['meals'] != null &&
                  detailData['meals'].isNotEmpty) {
                final formattedMeal = _formatMealData(detailData['meals'][0]);
                newMeals.add(formattedMeal);
              }
            }
          }

          if (mounted) {
            setState(() {
              _meals.addAll(newMeals);
            });
          }
        }
      } else {
        logger.d('Failed to load more meals: ${response.statusCode}');
      }
    } catch (e) {
      logger.d('Error loading more meals: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedCategories = prefs.getString('meal_categories');

      // Try loading categories from cache
      if (cachedCategories != null) {
        try {
          final data = json.decode(cachedCategories);
          if (data['categories'] != null) {
            setState(() {
              _categories = [
                {
                  'strCategory': 'All',
                  'strCategoryThumb': '',
                  'strCategoryDescription': ''
                }
              ];
              for (var category in data['categories']) {
                _categories.add({
                  'strCategory': category['strCategory']?.toString() ?? '',
                  'strCategoryThumb':
                      category['strCategoryThumb']?.toString() ?? '',
                  'strCategoryDescription':
                      category['strCategoryDescription']?.toString() ?? '',
                });
              }
            });
            await _loadMeals();
            return;
          }
        } catch (e) {
          logger.d('Error parsing cached categories: $e');
        }
      }

      // Fetch categories from API
      try {
        const retryOptions = RetryOptions(
          maxAttempts: 3,
          delayFactor: Duration(milliseconds: 500),
        );
        final categoryResponse = await retryOptions.retry(
          () => http.get(
            Uri.parse('https://www.themealdb.com/api/json/v1/1/categories.php'),
            headers: {'Accept': 'application/json', 'Connection': 'keep-alive'},
          ).timeout(const Duration(seconds: 30)),
          retryIf: (e) => e is SocketException || e is TimeoutException,
        );

        logger.d('Category request sent');
        logger.d('Response status: ${categoryResponse.statusCode}');
        logger
            .d('Response body: ${categoryResponse.body.substring(0, 100)}...');

        if (!mounted) return;

        if (categoryResponse.statusCode == 200) {
          final data = json.decode(categoryResponse.body);
          await prefs.setString('meal_categories', json.encode(data));
          if (data['categories'] == null) {
            throw Exception('No categories data found');
          }

          setState(() {
            _categories = [
              {
                'strCategory': 'All',
                'strCategoryThumb': '',
                'strCategoryDescription': ''
              }
            ];
            for (var category in data['categories']) {
              _categories.add({
                'strCategory': category['strCategory']?.toString() ?? '',
                'strCategoryThumb':
                    category['strCategoryThumb']?.toString() ?? '',
                'strCategoryDescription':
                    category['strCategoryDescription']?.toString() ?? '',
              });
            }
          });
        } else {
          throw Exception(
              'Categories API error: ${categoryResponse.statusCode}');
        }
      } catch (e) {
        logger.d('Categories error: $e');
        throw Exception('Failed to load categories: $e');
      }

      // Load meals
      await _loadMeals();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Network error. Please check your connection and try again.';
        _categories = [
          {
            'strCategory': 'All',
            'strCategoryThumb': '',
            'strCategoryDescription': ''
          }
        ];
        _meals = [];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMeals() async {
    try {
      List<Map<String, dynamic>> allMeals = [];
      final response = await http.get(
        Uri.parse('https://www.themealdb.com/api/json/v1/1/filter.php?c=Beef'),
        headers: {'Accept': 'application/json', 'Connection': 'keep-alive'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          for (var meal in data['meals'].take(20)) {
            final detailResponse = await http.get(
              Uri.parse(
                  'https://www.themealdb.com/api/json/v1/1/lookup.php?i=${meal['idMeal']}'),
              headers: {
                'Accept': 'application/json',
                'Connection': 'keep-alive'
              },
            ).timeout(const Duration(seconds: 30));
            if (detailResponse.statusCode == 200) {
              final detailData = json.decode(detailResponse.body);
              if (detailData['meals'] != null &&
                  detailData['meals'].isNotEmpty) {
                allMeals.add(_formatMealData(detailData['meals'][0]));
              }
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _meals = allMeals..shuffle();
      });
    } catch (e) {
      logger.d('Meals error: $e');
      throw Exception('Failed to load meals: $e');
    }
  }

  Future<void> _searchMeals(String query) async {
    if (!mounted) return;

    if (query.isEmpty) {
      _loadInitialData();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://www.themealdb.com/api/json/v1/1/search.php?s=$query'),
        headers: {'Accept': 'application/json', 'Connection': 'keep-alive'},
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (data['meals'] != null) {
            _meals = List<Map<String, dynamic>>.from(
                data['meals'].map((meal) => _formatMealData(meal)));
          } else {
            _meals = [];
          }
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to search meals');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to search meals. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _filterByCategory(String category) async {
    if (!mounted) return;

    setState(() {
      _selectedCategory = category;
      _isLoading = true;
      _error = null;
    });

    try {
      if (category == 'All') {
        await _loadInitialData();
        return;
      }

      final response = await http.get(
        Uri.parse(
            'https://www.themealdb.com/api/json/v1/1/filter.php?c=$category'),
        headers: {'Accept': 'application/json', 'Connection': 'keep-alive'},
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          List<Map<String, dynamic>> categoryMeals = [];
          final allMeals = List.from(data['meals']);
          final mealsToFetch = allMeals.take(12).toList();

          for (var meal in mealsToFetch) {
            final detailResponse = await http.get(
              Uri.parse(
                  'https://www.themealdb.com/api/json/v1/1/lookup.php?i=${meal['idMeal']}'),
              headers: {
                'Accept': 'application/json',
                'Connection': 'keep-alive'
              },
            ).timeout(const Duration(seconds: 30));

            if (detailResponse.statusCode == 200) {
              final detailData = json.decode(detailResponse.body);
              if (detailData['meals'] != null &&
                  detailData['meals'].isNotEmpty) {
                final formattedMeal = _formatMealData(detailData['meals'][0]);
                categoryMeals.add(formattedMeal);
              }
            }
          }

          if (!mounted) return;

          setState(() {
            _meals = categoryMeals;
            _isLoading = false;
          });
          return;
        }
        setState(() => _meals = []);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              'Failed to load category meals. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _formatMealData(Map<String, dynamic> meal) {
    try {
      if (meal['idMeal'] == null || meal['strMeal'] == null) {
        throw Exception('Invalid meal data structure');
      }

      List<String> ingredients = [];
      List<String> measures = [];

      for (int i = 1; i <= 20; i++) {
        final ingredient = meal['strIngredient$i'];
        final measure = meal['strMeasure$i'];

        if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
          ingredients.add(ingredient.toString().trim());
          measures.add(measure?.toString().trim() ?? '');
        }
      }

      List<String> instructions = [];
      if (meal['strInstructions'] != null) {
        instructions = meal['strInstructions']
            .toString()
            .split(RegExp(r'\r\n|\n|\r'))
            .where((step) => step.trim().isNotEmpty)
            .map((step) => step.trim())
            .toList();
      }

      final calories = ingredients.length * 100;

      return {
        'id': meal['idMeal'].toString(),
        'titleKey': meal['strMeal'].toString(),
        'imagePath': meal['strMealThumb']?.toString() ?? '',
        'category': meal['strCategory']?.toString() ?? '',
        'area': meal['strArea']?.toString() ?? '',
        'instructions': instructions,
        'ingredients': ingredients,
        'measures': measures,
        'calories': '$calories kcal',
        'nutritionFacts': {
          'calories': calories.toString(),
          'protein': '${(calories / 20).round()}g',
          'carbs': '${(calories / 4).round()}g',
          'fat': '${(calories / 9).round()}g',
        },
        'isVegan': !ingredients.any((ingredient) => [
              'chicken',
              'beef',
              'meat',
              'fish',
              'pork',
              'lamb',
              'egg',
              'milk',
              'cream',
              'cheese',
              'butter',
              'yogurt'
            ].any((nonVegan) => ingredient.toLowerCase().contains(nonVegan))),
        'isFavorite': _favoriteMeals.contains(meal['idMeal']),
        'youtubeUrl': meal['strYoutube']?.toString(),
      };
    } catch (e) {
      logger.d('Error formatting meal data: $e');
      return {
        'id': meal['idMeal']?.toString() ?? 'unknown',
        'titleKey': meal['strMeal']?.toString() ?? 'Unknown Meal',
        'imagePath': meal['strMealThumb']?.toString() ?? '',
        'category': '',
        'area': '',
        'instructions': <String>[],
        'ingredients': <String>[],
        'measures': <String>[],
        'calories': '0 kcal',
        'nutritionFacts': {
          'calories': '0',
          'protein': '0g',
          'carbs': '0g',
          'fat': '0g',
        },
        'isVegan': false,
        'isFavorite': false,
        'youtubeUrl': null,
      };
    }
  }

  void _toggleFavorite(String mealId) {
    setState(() {
      if (_favoriteMeals.contains(mealId)) {
        _favoriteMeals.remove(mealId);
      } else {
        _favoriteMeals.add(mealId);
      }
      _meals = _meals.map((meal) {
        if (meal['id'] == mealId) {
          return {...meal, 'isFavorite': _favoriteMeals.contains(mealId)};
        }
        return meal;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategorySelector(),
            _buildMealGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            tr(context, 'discover_meals'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _searchMeals,
        style: TextStyle(color: AppTheme.textColor(context)),
        decoration: InputDecoration(
          hintText: tr(context, 'search_meals_hint'),
          hintStyle:
              TextStyle(color: AppTheme.textColor(context).withAlpha(128)),
          prefixIcon: Icon(Icons.search, color: AppTheme.textColor(context)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppTheme.textColor(context)),
                  onPressed: () {
                    _searchController.clear();
                    _searchMeals('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(top: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category['strCategory'] == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () => _filterByCategory(category['strCategory']!),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppTheme.cardColor(context),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      image: category['strCategory'] != 'All'
                          ? DecorationImage(
                              image:
                                  NetworkImage(category['strCategoryThumb']!),
                              fit: BoxFit.cover,
                              opacity: isSelected ? 0.7 : 1.0,
                            )
                          : null,
                    ),
                    child: category['strCategory'] == 'All'
                        ? Icon(
                            Icons.restaurant_menu,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textColor(context),
                          )
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category['strCategory']!,
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildMealGrid() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.withAlpha(128),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadInitialData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 8, 178, 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_meals.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: AppTheme.textColor(context).withAlpha(128),
              ),
              const SizedBox(height: 16),
              Text(
                tr(context, 'no_meals_found'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _meals.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _meals.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _buildMealCard(_meals[index]);
        },
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    return GestureDetector(
      onTap: () async {
        final formattedMeal = {
          'id': meal['id'],
          'titleKey': meal['titleKey'],
          'imagePath': meal['imagePath'],
          'calories': meal['calories'],
          'nutritionFacts': {
            'calories': meal['nutritionFacts']['calories'].toString(),
            'protein': meal['nutritionFacts']['protein'],
            'carbs': meal['nutritionFacts']['carbs'],
            'fat': meal['nutritionFacts']['fat'],
          },
          'ingredients': meal['ingredients'],
          'measures': meal['measures'],
          'instructions': meal['instructions'],
          'area': meal['area'],
          'category': meal['category'],
          'isVegan': meal['isVegan'] ?? false,
          'isFavorite': meal['isFavorite'],
        };

        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => MealDetailScreen(
              mealId: formattedMeal['id'],
              mealTitle: formattedMeal['titleKey'],
              imagePath: formattedMeal['imagePath'],
              calories: formattedMeal['calories'],
              nutritionFacts:
                  Map<String, dynamic>.from(formattedMeal['nutritionFacts']),
              ingredients: List<String>.from(formattedMeal['ingredients']),
              measures: List<String>.from(formattedMeal['measures']),
              instructions: List<String>.from(formattedMeal['instructions']),
              area: formattedMeal['area'],
              category: formattedMeal['category'],
              isVegan: formattedMeal['isVegan'],
              youtubeUrl: meal['youtubeUrl'],
              isFavorite: formattedMeal['isFavorite'],
              onFavoriteToggle: (id) => _toggleFavorite(id),
              selectedDayIndex: widget.selectedDayIndex,
              currentMealTime: widget.currentMealTime,
            ),
          ),
        );

        if (!mounted) return;

        if (result != null) {
          final mealPlanResult = {
            ...result,
            'meal': formattedMeal,
          };
          Navigator.of(context).pop(mealPlanResult);
        }
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Image.network(
                      meal['imagePath'],
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppTheme.cardColor(context),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.cardColor(context),
                          child: const Icon(Icons.broken_image, size: 40),
                        );
                      },
                    ),
                  ),
                  if (meal['isVegan'])
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor(context).withAlpha(204),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          meal['isFavorite']
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: meal['isFavorite'] ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                        onPressed: () => _toggleFavorite(meal['id']),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal['titleKey'],
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
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
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
