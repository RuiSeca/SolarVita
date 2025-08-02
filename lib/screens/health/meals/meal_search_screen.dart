import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../../../services/meal/recipe_service.dart';
import '../../../providers/riverpod/meal_provider.dart';
import 'meal_detail_screen.dart';
import 'package:logger/logger.dart';
import '../../../widgets/common/lottie_loading_widget.dart';

var logger = Logger();

class MealSearchScreen extends ConsumerStatefulWidget {
  final int selectedDayIndex;
  final String currentMealTime;

  const MealSearchScreen({
    super.key,
    required this.selectedDayIndex,
    required this.currentMealTime,
  });

  @override
  ConsumerState<MealSearchScreen> createState() => _MealSearchScreenState();
}

class _MealSearchScreenState extends ConsumerState<MealSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MealDBService _mealService = MealDBService();

  final Set<String> _favoriteMeals = {};
  List<Map<String, dynamic>> _favoriteMealsList = [];
  List<Map<String, String>> _categories = [];
  String _selectedCategory = 'All';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_onSearchChanged);
    _loadFavorites();
    _loadInitialData();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        final query = _searchController.text.trim();
        if (query.isEmpty) {
          ref
              .read(mealNotifierProvider.notifier)
              .loadMealsByCategory(_selectedCategory);
        } else {
          ref.read(mealNotifierProvider.notifier).searchMeals(query);
        }
      }
    });
  }

  void _scrollListener() {
    // Implement pagination when user scrolls near the bottom
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 500) {
      // Load more meals when user is 500 pixels from the bottom (earlier loading)
      final hasMoreData = ref.read(hasMoreMealsDataProvider);
      final isLoadingMore = ref.read(isLoadingMoreMealsProvider);
      
      if (hasMoreData && !isLoadingMore && mounted) {
        ref.read(mealNotifierProvider.notifier).loadMoreMeals();
      }
    }
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    try {
      // Load categories for the filter
      await _loadCategories();

      // Load initial meals using the provider
      ref
          .read(mealNotifierProvider.notifier)
          .loadMealsByCategory(_selectedCategory);
    } catch (e) {
      logger.d('Error loading initial data: $e');
    }
  }

  Future<void> _loadCategories() async {
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
                  'strCategoryDescription': '',
                },
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
            return;
          }
        } catch (e) {
          logger.d('Error parsing cached categories: $e');
        }
      }

      // Fetch categories from API
      final categories = await _mealService.getCategories();

      if (!mounted) return;

      // Cache the categories
      await prefs.setString(
        'meal_categories',
        json.encode({'categories': categories}),
      );

      setState(() {
        _categories = [
          {
            'strCategory': 'All',
            'strCategoryThumb': '',
            'strCategoryDescription': 'All available meals',
          },
        ];
        for (var category in categories) {
          _categories.add({
            'strCategory': category['strCategory']?.toString() ?? '',
            'strCategoryThumb': category['strCategoryThumb']?.toString() ?? '',
            'strCategoryDescription':
                category['strCategoryDescription']?.toString() ?? '',
          });
        }
      });
    } catch (e) {
      logger.d('Categories error: $e');
      if (!mounted) return;

      setState(() {
        _categories = [
          {
            'strCategory': 'All',
            'strCategoryThumb': '',
            'strCategoryDescription': 'All available meals',
          },
        ];
      });
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });

    // Clear search text when switching categories
    _searchController.clear();

    // Load meals for the selected category using provider
    ref.read(mealNotifierProvider.notifier).loadMealsByCategory(category);
  }

  // Helper method to determine whether to use File or Network image
  Widget _buildImageWidget(String imagePath) {
    final isLocalFile =
        imagePath.startsWith('/') || imagePath.startsWith('file://');

    if (isLocalFile) {
      final file = File(imagePath.replaceFirst('file://', ''));
      if (file.existsSync()) {
        return Image.file(
          file,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppTheme.cardColor(context),
            child: const Icon(Icons.broken_image, size: 40),
          ),
        );
      }
    }

    return CachedNetworkImage(
      imageUrl: imagePath,
      width: double.infinity,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(
        milliseconds: 200,
      ), // Slightly slower for smoother transition
      fadeOutDuration: const Duration(milliseconds: 100),
      placeholder: (context, url) => Container(
        color: AppTheme.cardColor(context),
        child: const Center(
          child: SizedBox(width: 60, height: 60, child: LottieLoadingWidget()),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppTheme.cardColor(context),
        child: const Icon(Icons.broken_image, size: 40),
      ),
    );
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load favorite meal IDs
      final favoriteIds = prefs.getStringList('favorite_meal_ids') ?? [];
      setState(() {
        _favoriteMeals.addAll(favoriteIds);
      });

      // Load favorite meals data
      final favoriteMealsJson = prefs.getString('favorite_meals_data');
      if (favoriteMealsJson != null) {
        final decodedData = json.decode(favoriteMealsJson);
        if (decodedData is List) {
          setState(() {
            _favoriteMealsList = List<Map<String, dynamic>>.from(decodedData);
          });
        }
      }
    } catch (e) {
      logger.d('Error loading favorites: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save favorite meal IDs
      await prefs.setStringList('favorite_meal_ids', _favoriteMeals.toList());

      // Save favorite meals data
      await prefs.setString(
        'favorite_meals_data',
        json.encode(_favoriteMealsList),
      );

      // Debug logging
      logger.d(
        'Saved favorites: ${_favoriteMeals.length} IDs, ${_favoriteMealsList.length} meals',
      );
      logger.d('Favorite IDs: ${_favoriteMeals.toList()}');
    } catch (e) {
      logger.d('Error saving favorites: $e');
    }
  }

  void _toggleFavorite(String mealId, [Map<String, dynamic>? mealData]) {
    setState(() {
      if (_favoriteMeals.contains(mealId)) {
        // Remove from favorites
        _favoriteMeals.remove(mealId);
        _favoriteMealsList.removeWhere((meal) => meal['id'] == mealId);
      } else {
        // Add to favorites
        _favoriteMeals.add(mealId);
        if (mealData != null) {
          // Store the complete meal data for the favorites page
          _favoriteMealsList.add({...mealData, 'isFavorite': true});
        }
      }
    });

    // Persist the changes
    _saveFavorites();

    // Update the meal data in the provider to reflect favorite status
    ref
        .read(mealNotifierProvider.notifier)
        .updateMealFavoriteStatus(mealId, _favoriteMeals.contains(mealId));
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
        style: TextStyle(color: AppTheme.textColor(context)),
        onChanged: (value) {
          setState(() {}); // Trigger rebuild to show/hide clear button
        },
        decoration: InputDecoration(
          hintText: tr(context, 'search_meals_hint'),
          hintStyle: TextStyle(
            color: AppTheme.textColor(context).withAlpha(128),
          ),
          prefixIcon: Icon(Icons.search, color: AppTheme.textColor(context)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppTheme.textColor(context)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {}); // Trigger rebuild after clearing
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 100, // Increased height to accommodate text
      margin: const EdgeInsets.only(top: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _categories.length,
        itemExtent:
            80.0, // Increased width to accommodate longer category names
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category['strCategory'] == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () => _onCategorySelected(category['strCategory']!),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                              image: CachedNetworkImageProvider(
                                category['strCategoryThumb']!,
                              ),
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
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      category['strCategory']!,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
    final isLoading = ref.watch(isMealsLoadingProvider);
    final hasError = ref.watch(hasMealsErrorProvider);
    final errorMessage = ref.watch(mealsErrorMessageProvider);
    final meals = ref.watch(mealsProvider);
    final hasData = ref.watch(hasMealsDataProvider);

    if (isLoading && meals.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LottieLoadingWidget(),
              const SizedBox(height: 16),
              Text(
                tr(context, 'loading_meals'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (hasError) {
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
                errorMessage ?? tr(context, 'error_occurred'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.read(mealNotifierProvider.notifier).retryCurrentSearch();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 8, 178, 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(tr(context, 'try_again')),
              ),
            ],
          ),
        ),
      );
    }

    if (!hasData || meals.isEmpty) {
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
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: meals.length,
              itemBuilder: (context, index) {
                return _buildMealCard(meals[index]);
              },
            ),
          ),
          // Show loading indicator at bottom when loading more data
          Consumer(
            builder: (context, ref, child) {
              final isLoadingMore = ref.watch(isLoadingMoreMealsProvider);
              final hasMoreData = ref.watch(hasMoreMealsDataProvider);
              
              if (isLoadingMore) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: LottieLoadingWidget(),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        tr(context, 'loading_more_meals'),
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              } else if (meals.isNotEmpty && !hasMoreData) {
                // Show "no more data" indicator
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    tr(context, 'no_more_meals'),
                    style: TextStyle(
                      color: AppTheme.textColor(context).withAlpha(128),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    return GestureDetector(
      onTap: () async {
        try {
          // All meals now have detailed data from API, so no need for complex detection
          // Just use the meal data directly since it's already complete
          Map<String, dynamic> formattedMeal = {
            'id': meal['id'] ?? meal['idMeal'] ?? '',
            'titleKey': meal['titleKey'] ?? meal['strMeal'] ?? tr(context, 'unknown_meal'),
            'imagePath': meal['imagePath'] ?? meal['strMealThumb'] ?? '',
            'calories': meal['calories'] ?? '0 kcal',
            'nutritionFacts': meal['nutritionFacts'] ?? {
              'calories': '0',
              'protein': '0g',
              'carbs': '0g', 
              'fat': '0g',
            },
            'ingredients': meal['ingredients'] ?? [],
            'measures': meal['measures'] ?? [],
            'instructions': meal['instructions'] ?? [],
            'area': meal['area'] ?? meal['strArea'] ?? tr(context, 'unknown'),
            'category': meal['category'] ?? meal['strCategory'] ?? tr(context, 'unknown'),
            'isVegan': meal['isVegan'] ?? false,
            'isFavorite': meal['isFavorite'] ?? false,
          };

          if (!mounted) return;

          final result = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(
              builder: (context) => MealDetailScreen(
                mealId: formattedMeal['id'],
                mealTitle: formattedMeal['titleKey'],
                imagePath: formattedMeal['imagePath'],
                calories: formattedMeal['calories'],
                nutritionFacts: Map<String, dynamic>.from(
                  formattedMeal['nutritionFacts'],
                ),
                ingredients: List<String>.from(formattedMeal['ingredients']),
                measures: List<String>.from(formattedMeal['measures']),
                instructions: List<String>.from(formattedMeal['instructions']),
                area: formattedMeal['area'],
                category: formattedMeal['category'],
                isVegan: formattedMeal['isVegan'],
                youtubeUrl: meal['youtubeUrl'] ?? meal['strYoutube'] ?? '',
                isFavorite: _favoriteMeals.contains(formattedMeal['id']),
                onFavoriteToggle: (id) => _toggleFavorite(id, formattedMeal),
                selectedDayIndex: widget.selectedDayIndex,
                currentMealTime: widget.currentMealTime,
              ),
            ),
          );

          if (!mounted) return;

          if (result != null) {
            final mealPlanResult = {...result, 'meal': formattedMeal};
            Navigator.of(context).pop(mealPlanResult);
          }
        } catch (e) {
          // Show error message to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${tr(context, 'error_loading_meal_details')}: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: _buildMealCardContent(meal),
      ),
    );
  }

  Widget _buildMealCardContent(Map<String, dynamic> meal) {
    try {
      return Column(
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
                  child: _buildImageWidget(
                    meal['imagePath'] ?? meal['strMealThumb'] ?? '',
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
                          Icon(Icons.eco, color: Colors.white, size: 14),
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
                        _favoriteMeals.contains(meal['id'] ?? meal['idMeal'])
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color:
                            _favoriteMeals.contains(
                              meal['id'] ?? meal['idMeal'],
                            )
                            ? Colors.red
                            : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () =>
                          _toggleFavorite(meal['id'] ?? meal['idMeal'], meal),
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
                    meal['titleKey'] ?? meal['strMeal'] ?? tr(context, 'unknown_meal'),
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
                                  meal['calories'] ?? tr(context, 'loading_calories'),
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
                                color: AppTheme.textColor(
                                  context,
                                ).withAlpha(26),
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
                                    meal['area'] ??
                                        meal['strArea'] ??
                                        tr(context, 'unknown'),
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
      );
    } catch (e) {
      // Return a fallback card
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 32, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                tr(context, 'error_loading_meal'),
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}
