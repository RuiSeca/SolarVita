import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../../../theme/app_theme.dart';

class SupporterMealDetailScreen extends StatefulWidget {
  final Map<String, dynamic> meal;

  const SupporterMealDetailScreen({
    super.key,
    required this.meal,
  });

  @override
  State<SupporterMealDetailScreen> createState() => _SupporterMealDetailScreenState();
}

class _SupporterMealDetailScreenState extends State<SupporterMealDetailScreen> {
  int _servings = 1;

  void _updateServings(int newServings) {
    if (newServings > 0) {
      setState(() {
        _servings = newServings;
      });
    }
  }

  // Helper method to determine whether to use File or Network image
  Widget _buildImageWidget(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: Icon(
          Icons.restaurant,
          size: 80,
          color: Colors.grey[500],
        ),
      );
    }
    
    final isLocalFile = imagePath.startsWith('/') || imagePath.startsWith('file://');
    
    if (isLocalFile) {
      final file = File(imagePath.replaceFirst('file://', ''));
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[300],
            child: Icon(
              Icons.restaurant,
              size: 80,
              color: Colors.grey[500],
            ),
          ),
        );
      } else {
        // File doesn't exist, show default icon
        return Container(
          color: Colors.grey[300],
          child: Icon(
            Icons.restaurant,
            size: 80,
            color: Colors.grey[500],
          ),
        );
      }
    }
    
    return CachedNetworkImage(
      imageUrl: imagePath,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        child: Icon(
          Icons.restaurant,
          size: 80,
          color: Colors.grey[500],
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: Icon(
          Icons.restaurant,
          size: 80,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, meal),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMealInfo(context, meal),
                  const SizedBox(height: 24),
                  _buildNutritionSection(context, meal),
                  const SizedBox(height: 24),
                  _buildIngredientsSection(context, meal),
                  const SizedBox(height: 24),
                  _buildInstructionsSection(context, meal),
                  const SizedBox(height: 24),
                  _buildActionButtons(context, meal),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Map<String, dynamic> meal) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppTheme.surfaceColor(context),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(38),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withAlpha(77),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.arrow_back,
            color: AppTheme.textColor(context),
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            onPressed: () => _showAddToMealPlanDialog(context, meal),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(38),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withAlpha(77),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildImageWidget(meal['image'] ?? meal['imagePath']),
      ),
    );
  }

  Widget _buildMealInfo(BuildContext context, Map<String, dynamic> meal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                meal['name'] ?? 'Unnamed Meal',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'From Supporter',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            if (meal['calories'] != null) ...[
              _buildInfoChip(
                context,
                Icons.local_fire_department,
                '${meal['calories']} cal',
                Colors.red,
              ),
              const SizedBox(width: 8),
            ],
            if (meal['servings'] != null) ...[
              _buildInfoChip(
                context,
                Icons.people,
                'Serves ${meal['servings']}',
                Colors.blue,
              ),
              const SizedBox(width: 8),
            ],
            if (meal['prepTime'] != null) ...[
              _buildInfoChip(
                context,
                Icons.timer,
                '${meal['prepTime']} min',
                Colors.green,
              ),
            ],
          ],
        ),
        
        if (meal['description'] != null) ...[
          const SizedBox(height: 16),
          Text(
            meal['description'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSection(BuildContext context, Map<String, dynamic> meal) {
    final nutrition = meal['nutrition'] as Map<String, dynamic>?;
    if (nutrition == null || nutrition.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutrition Facts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _buildServingsControls(context),
              const SizedBox(height: 16),
              ...nutrition.entries.map((entry) =>
                _buildNutritionRow(entry.key, entry.value.toString())
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServingsControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Servings:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor(context),
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: () => _updateServings(_servings - 1),
              icon: Icon(Icons.remove_circle_outline, color: AppColors.primary),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_servings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _updateServings(_servings + 1),
              icon: Icon(Icons.add_circle_outline, color: AppColors.primary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(BuildContext context, Map<String, dynamic> meal) {
    final ingredients = meal['ingredients'] as List<dynamic>?;
    if (ingredients == null || ingredients.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredients',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: ingredients.asMap().entries.map((entry) {
              final ingredient = entry.value.toString();
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ingredient,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textColor(context),
                          height: 1.4,
                        ),
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

  Widget _buildInstructionsSection(BuildContext context, Map<String, dynamic> meal) {
    final instructions = meal['instructions'] as List<dynamic>?;
    if (instructions == null || instructions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: instructions.asMap().entries.map((entry) {
              final index = entry.key;
              final instruction = entry.value.toString();
              
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
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        instruction,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textColor(context),
                          height: 1.5,
                        ),
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

  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> meal) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showAddToMealPlanDialog(context, meal),
            icon: Icon(Icons.add_circle_outline),
            label: Text('Add to My Meal Plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () => _shareMeal(context, meal),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Icon(
              Icons.share,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddToMealPlanDialog(BuildContext context, Map<String, dynamic> meal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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

  void _shareMeal(BuildContext context, Map<String, dynamic> meal) {
    // Implement meal sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing feature coming soon!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}