import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../../../theme/app_theme.dart';
import '../../../models/privacy_settings.dart';
import 'supporter_meal_detail_screen.dart';

class SupporterMealSharingWidget extends ConsumerWidget {
  final String supporterId;
  final PrivacySettings privacySettings;
  final Map<String, List<Map<String, dynamic>>>? dailyMeals;

  const SupporterMealSharingWidget({
    super.key,
    required this.supporterId,
    required this.privacySettings,
    this.dailyMeals,
  });

  // Helper method to determine whether to use File or Network image
  Widget _buildImageWidget(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        color: Colors.grey[300],
        child: Icon(Icons.restaurant, color: Colors.grey[500]),
      );
    }
    
    final isLocalFile = imagePath.startsWith('/') || imagePath.startsWith('file://');
    
    if (isLocalFile) {
      final file = File(imagePath.replaceFirst('file://', ''));
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 60,
            height: 60,
            color: Colors.grey[300],
            child: Icon(Icons.restaurant, color: Colors.grey[500]),
          ),
        );
      } else {
        // File doesn't exist, show default icon
        return Container(
          width: 60,
          height: 60,
          color: Colors.grey[300],
          child: Icon(Icons.restaurant, color: Colors.grey[500]),
        );
      }
    }
    
    return CachedNetworkImage(
      imageUrl: imagePath,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: 60,
        height: 60,
        color: Colors.grey[300],
        child: Icon(Icons.restaurant, color: Colors.grey[500]),
      ),
      errorWidget: (context, url, error) => Container(
        width: 60,
        height: 60,
        color: Colors.grey[300],
        child: Icon(Icons.restaurant, color: Colors.grey[500]),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withValues(alpha: 0.1),
            Colors.red.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Today\'s Meal Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ),
              if (!privacySettings.showNutritionStats)
                Icon(
                  Icons.lock_outline,
                  color: Colors.grey[500],
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMealsContent(context),
        ],
      ),
    );
  }

  Widget _buildMealsContent(BuildContext context) {
    if (!privacySettings.showNutritionStats) {
      return _buildPrivateMealsView(context);
    }

    if (dailyMeals == null || _isEmptyMealPlan()) {
      return _buildNoMealsView(context);
    }

    return _buildMealsList(context);
  }

  bool _isEmptyMealPlan() {
    if (dailyMeals == null) return true;
    
    for (final meals in dailyMeals!.values) {
      if (meals.isNotEmpty) return false;
    }
    return true;
  }

  Widget _buildPrivateMealsView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_dining,
            color: Colors.grey[500],
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Meal Plan Shared Privately',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This supporter keeps their meal plan private.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoMealsView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.no_meals_outlined,
            color: Colors.orange[600],
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No Meals Added Today',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This supporter hasn\'t planned any meals for today yet.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList(BuildContext context) {
    final mealTypes = ['breakfast', 'lunch', 'dinner', 'snacks'];
    
    return Column(
      children: mealTypes.map((mealType) {
        final meals = dailyMeals![mealType] ?? [];
        return _buildMealTypeSection(context, mealType, meals);
      }).toList(),
    );
  }

  Widget _buildMealTypeSection(
    BuildContext context, 
    String mealType, 
    List<Map<String, dynamic>> meals
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _getMealTypeIcon(mealType),
              const SizedBox(width: 8),
              Text(
                _getMealTypeTitle(mealType),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor(context),
                ),
              ),
              const Spacer(),
              if (meals.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${meals.length} ${meals.length == 1 ? 'meal' : 'meals'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (meals.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No ${_getMealTypeTitle(mealType).toLowerCase()} planned',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ...meals.map((meal) => _buildMealCard(context, meal)),
        ],
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, Map<String, dynamic> meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _viewMealDetails(context, meal),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Meal Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImageWidget(meal['image'] ?? meal['imagePath']),
              ),
              const SizedBox(width: 12),
              
              // Meal Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal['name'] ?? 'Unnamed Meal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (meal['calories'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${meal['calories']} calories',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (meal['servings'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Serves ${meal['servings']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Action Buttons
              Column(
                children: [
                  IconButton(
                    onPressed: () => _viewMealDetails(context, meal),
                    icon: Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    tooltip: 'View Details',
                  ),
                  IconButton(
                    onPressed: () => _addToMyMealPlan(context, meal),
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    tooltip: 'Add to My Plan',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icon(Icons.free_breakfast, color: Colors.orange[600], size: 20);
      case 'lunch':
        return Icon(Icons.lunch_dining, color: Colors.orange[600], size: 20);
      case 'dinner':
        return Icon(Icons.dinner_dining, color: Colors.orange[600], size: 20);
      case 'snacks':
        return Icon(Icons.cookie, color: Colors.orange[600], size: 20);
      default:
        return Icon(Icons.restaurant, color: Colors.orange[600], size: 20);
    }
  }

  String _getMealTypeTitle(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snacks':
        return 'Snacks';
      default:
        return mealType.toUpperCase();
    }
  }

  void _viewMealDetails(BuildContext context, Map<String, dynamic> meal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupporterMealDetailScreen(
          meal: meal,
        ),
      ),
    );
  }

  void _addToMyMealPlan(BuildContext context, Map<String, dynamic> meal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAddToMealPlanDialog(context, meal),
    );
  }

  Widget _buildAddToMealPlanDialog(BuildContext context, Map<String, dynamic> meal) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          Text(
            'Add to My Meal Plan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            meal['name'] ?? 'Unnamed Meal',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          Text(
            'Choose meal time:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildMealTimeButton(context, 'breakfast', 'Breakfast', Icons.free_breakfast, meal),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMealTimeButton(context, 'lunch', 'Lunch', Icons.lunch_dining, meal),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMealTimeButton(context, 'dinner', 'Dinner', Icons.dinner_dining, meal),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMealTimeButton(context, 'snacks', 'Snacks', Icons.cookie, meal),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMealTimeButton(
    BuildContext context,
    String mealType,
    String label,
    IconData icon,
    Map<String, dynamic> meal,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _showDaySelectionDialog(context, meal, mealType);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDaySelectionDialog(BuildContext context, Map<String, dynamic> meal, String mealType) {
    final List<String> weekDays = [
      'Monday',
      'Tuesday', 
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    
    final DateTime now = DateTime.now();
    final int todayIndex = now.weekday - 1; // Convert to 0-6 index
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Choose Day',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add "${meal['name']}" to ${_getMealTypeTitle(mealType).toLowerCase()}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: weekDays.length,
                  itemBuilder: (context, index) {
                    final String dayName = weekDays[index];
                    final bool isToday = index == todayIndex;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _addMealToMyPlan(context, meal, mealType, index);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isToday 
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isToday 
                                  ? AppColors.primary.withValues(alpha: 0.3)
                                  : Colors.grey.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isToday ? Icons.today : Icons.calendar_today,
                                color: isToday ? AppColors.primary : Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  dayName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                                    color: isToday ? AppColors.primary : AppTheme.textColor(context),
                                  ),
                                ),
                              ),
                              if (isToday)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Today',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
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
              ),
              
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addMealToMyPlan(BuildContext context, Map<String, dynamic> meal, String mealType, int dayIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Format the meal data consistently with meal plan screen
      final formattedMeal = {
        'id': meal['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'titleKey': meal['name'],
        'name': meal['name'] ?? 'Unnamed Meal',
        'imagePath': meal['image'],
        'image': meal['image'],
        'calories': meal['calories']?.toString() ?? '0',
        'servings': meal['servings'] ?? 1,
        'prepTime': meal['prepTime'],
        'description': meal['description'],
        'nutritionFacts': {
          'calories': meal['calories']?.toString() ?? '0',
          'protein': meal['protein'] ?? '0g',
          'carbs': meal['carbs'] ?? '0g',
          'fat': meal['fat'] ?? '0g',
        },
        'nutrition': meal['nutrition'] ?? {},
        'ingredients': meal['ingredients'] ?? [],
        'measures': meal['measures'] ?? [],
        'instructions': meal['instructions'] ?? [],
        'area': meal['area'],
        'category': meal['category'],
        'isVegan': meal['isVegan'] ?? false,
      };
      
      // Load existing weekly meal data
      const String weeklyMealDataKey = 'weeklyMealData';
      Map<String, dynamic> weeklyData = {};
      
      final savedData = prefs.getString(weeklyMealDataKey);
      if (savedData != null) {
        weeklyData = Map<String, dynamic>.from(json.decode(savedData));
      }
      
      // Initialize day data if it doesn't exist
      if (!weeklyData.containsKey(dayIndex.toString())) {
        weeklyData[dayIndex.toString()] = {
          'breakfast': [],
          'lunch': [],
          'dinner': [],
          'snacks': [],
        };
      }
      
      // Get the day's data
      final dayData = Map<String, dynamic>.from(weeklyData[dayIndex.toString()]);
      
      // Initialize meal type list if it doesn't exist
      if (!dayData.containsKey(mealType)) {
        dayData[mealType] = [];
      }
      
      // Convert to list and check for duplicates
      final meals = List<Map<String, dynamic>>.from(dayData[mealType]);
      final mealId = formattedMeal['id']?.toString();
      
      // Prevent duplicate meals
      if (!meals.any((m) => m['id']?.toString() == mealId)) {
        meals.add(formattedMeal);
        dayData[mealType] = meals;
        weeklyData[dayIndex.toString()] = dayData;
        
        // Save back to SharedPreferences
        await prefs.setString(weeklyMealDataKey, json.encode(weeklyData));
        
        final List<String> weekDays = [
          'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
        ];
        
        // Check if context is still mounted before using it
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "${meal['name']}" to ${weekDays[dayIndex]} ${_getMealTypeTitle(mealType).toLowerCase()}!'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'View Plan',
                textColor: Colors.white,
                onPressed: () {
                  if (context.mounted) {
                    Navigator.pushNamed(context, '/meal-plan');
                  }
                },
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This meal is already in your plan'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add meal to your plan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}