import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import 'meal_edit_screen.dart';

class MealDetailScreen extends StatefulWidget {
  final String mealId; // Unique identifier
  final String mealTitle;
  final String imagePath;
  final String calories;
  final Map<String, dynamic> nutritionFacts;
  final List<String> ingredients;
  final List<String> measures;
  final List<String> instructions;
  final String? area;
  final String? category;
  final bool isVegan;
  final String? youtubeUrl;
  final Function(String)? onFavoriteToggle;
  final bool isFavorite;
  final int? selectedDayIndex; // Add this
  final String? currentMealTime; // Add this

  const MealDetailScreen({
    super.key,
    required this.mealId,
    required this.mealTitle,
    required this.imagePath,
    required this.calories,
    required this.nutritionFacts,
    required this.ingredients,
    required this.measures,
    required this.instructions,
    this.area,
    this.category,
    this.isVegan = false,
    this.youtubeUrl,
    this.onFavoriteToggle,
    this.isFavorite = false,
    this.selectedDayIndex,
    this.currentMealTime,
  });

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  int _servings = 1;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  void _updateServings(int newServings) {
    if (newServings > 0) {
      setState(() {
        _servings = newServings;
      });
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
      // Now using mealId for toggling favorite status
      widget.onFavoriteToggle?.call(widget.mealId);
    });
    HapticFeedback.lightImpact();
  }

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
                  _buildMealInfo(context),
                  const SizedBox(height: 24),
                  _buildServingsAdjuster(context),
                  const SizedBox(height: 24),
                  _buildNutritionSection(context),
                  const SizedBox(height: 24),
                  _buildIngredientsSection(context),
                  const SizedBox(height: 24),
                  _buildInstructionsSection(context),
                  if (widget.youtubeUrl != null) ...[
                    const SizedBox(height: 24),
                    _buildYoutubeButton(context),
                  ],
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
              // Use mealId as the hero tag for consistency
              tag: widget.mealId,
              child: Image.network(
                widget.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.cardColor(context),
                    child: const Icon(Icons.broken_image, size: 40),
                  );
                },
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
          widget.mealTitle,
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
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor(context).withAlpha(204),
              shape: BoxShape.circle,
            ),
            child: AnimatedSwitcher(
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
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                key: ValueKey<bool>(_isFavorite),
                color: _isFavorite ? Colors.red : AppTheme.textColor(context),
              ),
            ),
          ),
          onPressed: _toggleFavorite,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMealInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isVegan)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eco, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  'VEGAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (widget.category != null) ...[
              Icon(
                Icons.restaurant,
                size: 16,
                color: AppTheme.textColor(context).withAlpha(179),
              ),
              const SizedBox(width: 4),
              Text(
                widget.category!,
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                  fontSize: 14,
                ),
              ),
            ],
            if (widget.area != null) ...[
              const SizedBox(width: 16),
              Icon(
                Icons.public,
                size: 16,
                color: AppTheme.textColor(context).withAlpha(179),
              ),
              const SizedBox(width: 4),
              Text(
                widget.area!,
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildServingsAdjuster(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            tr(context, 'servings'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed:
                    _servings > 1 ? () => _updateServings(_servings - 1) : null,
                color: AppColors.primary,
              ),
              Text(
                _servings.toString(),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _updateServings(_servings + 1),
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSection(BuildContext context) {
    final adjustedNutrition = widget.nutritionFacts.map(
      (key, value) => MapEntry(key, _adjustNutritionForServings(value)),
    );

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
            children: adjustedNutrition.entries.map((entry) {
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

  String _adjustNutritionForServings(String value) {
    final regex = RegExp(r'(\d+(?:\.\d+)?)\s*(\w+)');
    final match = regex.firstMatch(value);

    if (match != null) {
      final number = double.parse(match.group(1)!);
      final unit = match.group(2);
      return '${(number * _servings).toStringAsFixed(1)}$unit';
    }
    return value;
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
        ...List.generate(
          widget.ingredients.length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.textColor(context).withAlpha(26),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.ingredients[index],
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    _adjustMeasure(widget.measures[index]),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _adjustMeasure(String measure) {
    final regex = RegExp(r'(\d+(?:\.\d+)?)\s*(.+)');
    final match = regex.firstMatch(measure);

    if (match != null) {
      final number = double.parse(match.group(1)!);
      final unit = match.group(2);
      return '${(number * _servings).toStringAsFixed(1)} $unit';
    }
    return measure;
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
        ...widget.instructions.asMap().entries.map((entry) {
          final index = entry.key;
          final instruction = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.textColor(context).withAlpha(179),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      instruction,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildYoutubeButton(BuildContext context) {
    return InkWell(
      onTap: () {
        // Handle YouTube URL opening
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_circle_fill,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              tr(context, 'watch_video'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _handleAddToMealPlan(),
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
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: () =>
              _showMealOptions(context, widget.mealTitle, widget.imagePath),
          icon: Icon(
            Icons.more_vert,
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

  // Updated _handleAddToMealPlan: Use context directly after awaiting.

  void _handleAddToMealPlan() async {
    final mealData = {
      'id': widget.mealId,
      'titleKey': widget.mealTitle,
      'imagePath': widget.imagePath,
      'calories': widget.calories,
      'nutritionFacts': widget.nutritionFacts,
      'ingredients': widget.ingredients,
      'measures': widget.measures,
      'instructions': widget.instructions,
      'area': widget.area,
      'category': widget.category,
      'isVegan': widget.isVegan,
      'isFavorite': _isFavorite,
    };

    // Always show the meal time selection bottom sheet
    final String? selectedMealTime = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Add this to ensure proper display
      builder: (modalContext) => Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(modalContext),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          // Add SafeArea to handle notches and system UI
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textColor(modalContext).withAlpha(51),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  tr(context, 'select_meal_time'),
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...['breakfast', 'lunch', 'dinner', 'snacks'].map(
                (mealTime) => ListTile(
                  leading: Icon(_getMealTimeIcon(mealTime),
                      color: AppColors.primary),
                  title: Text(
                    tr(context, mealTime),
                    style: TextStyle(color: AppTheme.textColor(modalContext)),
                  ),
                  onTap: () => Navigator.pop(modalContext, mealTime),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;

    if (selectedMealTime != null) {
      final result = {
        'action': 'add_meal',
        'mealTime': selectedMealTime,
        'meal': mealData,
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'meal_added_to_plan')),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop(result);
    }
  }

  IconData _getMealTimeIcon(String mealTime) {
    switch (mealTime) {
      case 'breakfast':
        return Icons.breakfast_dining;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snacks':
        return Icons.restaurant_menu;
      default:
        return Icons.restaurant;
    }
  }

  void _showMealOptions(
      BuildContext context, String titleKey, String imagePath) {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(modalContext),
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
                color: AppTheme.textColor(modalContext).withAlpha(51),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: Text(
                tr(modalContext, 'edit_meal'),
                style: TextStyle(color: AppTheme.textColor(modalContext)),
              ),
              onTap: () {
                Navigator.pop(modalContext);

                final nutritionFacts = Map<String, String>.from(widget
                    .nutritionFacts
                    .map((key, value) => MapEntry(key, value.toString())));

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MealEditScreen(
                      mealTitle: titleKey,
                      imagePath: imagePath,
                      nutritionFacts: nutritionFacts,
                      ingredients: widget.ingredients,
                      instructions: widget.instructions,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: AppColors.primary),
              title: Text(
                tr(modalContext, 'share'),
                style: TextStyle(color: AppTheme.textColor(modalContext)),
              ),
              onTap: () {
                Navigator.pop(modalContext);
                // Implement share functionality
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
