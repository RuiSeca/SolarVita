import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
        background: meal['image'] != null
            ? CachedNetworkImage(
                imageUrl: meal['image'],
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
              )
            : Container(
                color: Colors.grey[300],
                child: Icon(
                  Icons.restaurant,
                  size: 80,
                  color: Colors.grey[500],
                ),
              ),
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
      // Integrate with existing meal plan service
      // For now, show success message
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${meal['name']}" to your $mealType!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View Plan',
            textColor: Colors.white,
            onPressed: () {
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