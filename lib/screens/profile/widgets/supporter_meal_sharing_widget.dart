import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
              Text(
                'Today\'s Meal Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
              const Spacer(),
              if (!privacySettings.showNutritionStats)
                Icon(
                  Icons.lock_outline,
                  color: Colors.grey[500],
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 16),
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
                child: meal['image'] != null
                    ? CachedNetworkImage(
                        imageUrl: meal['image'],
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
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: Icon(Icons.restaurant, color: Colors.grey[500]),
                      ),
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
        _addMealToMyPlan(context, meal, mealType);
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

  Future<void> _addMealToMyPlan(BuildContext context, Map<String, dynamic> meal, String mealType) async {
    try {
      // Add meal to current user's meal plan
      // This would integrate with the existing meal plan service
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${meal['name']}" to your ${_getMealTypeTitle(mealType).toLowerCase()}!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View Plan',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to meal plan screen
              Navigator.pushNamed(context, '/meal-plan');
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add meal to your plan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}