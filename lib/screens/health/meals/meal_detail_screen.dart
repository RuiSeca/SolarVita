import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../../../utils/video_platform_helper.dart';
import '../../../widgets/common/holographic_nutrition_pie.dart';
import 'meal_edit_screen.dart';

class MealDetailScreen extends StatefulWidget {
  final String mealId; // Unique identifier
  final String mealTitle;
  final String? imagePath;
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
  final bool isFromSupporter; // New field to identify supporter view

  const MealDetailScreen({
    super.key,
    required this.mealId,
    required this.mealTitle,
    this.imagePath,
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
    this.isFromSupporter = false,
  });

  // Named constructor for supporter meal view
  const MealDetailScreen.fromMeal({
    super.key,
    required Map<String, dynamic> meal,
    this.isFromSupporter = false,
  }) : mealId = '',
       mealTitle = '',
       imagePath = '',
       calories = '',
       nutritionFacts = const {},
       ingredients = const [],
       measures = const [],
       instructions = const [],
       area = null,
       category = null,
       isVegan = false,
       youtubeUrl = null,
       onFavoriteToggle = null,
       isFavorite = false,
       selectedDayIndex = null,
       currentMealTime = null;

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  int _servings = 1;
  bool _isFavorite = false;
  bool _showPerServing = true; // true = per serving, false = per meal
  String _videoPlatform = 'youtube'; // Default to YouTube

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _loadVideoPlatformPreference();
  }

  void _loadVideoPlatformPreference() async {
    final platform = await VideoPlatformHelper.getPreferredVideoPlatform();
    if (mounted) {
      setState(() {
        _videoPlatform = platform;
      });
    }
  }

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
        color: AppTheme.cardColor(context),
        child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
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
            color: AppTheme.cardColor(context),
            child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
          ),
        );
      } else {
        // File doesn't exist, show default icon
        return Container(
          color: AppTheme.cardColor(context),
          child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
        );
      }
    }
    
    return CachedNetworkImage(
      imageUrl: imagePath,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) {
        return Container(
          color: AppTheme.cardColor(context),
          child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
        );
      },
    );
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
                  const SizedBox(height: 24),
                  _buildYoutubeButton(context),
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
              child: _buildImageWidget(widget.imagePath),
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
    // Get both per-meal and per-serving nutrition data
    final perMealNutrition = {
      'calories': widget.nutritionFacts['calories'] ?? '0',
      'protein': widget.nutritionFacts['protein'] ?? '0g',
      'carbs': widget.nutritionFacts['carbs'] ?? '0g',
      'fat': widget.nutritionFacts['fat'] ?? '0g',
    };
    
    final perServingNutrition = {
      'calories': widget.nutritionFacts['caloriesPerServing'] ?? '0',
      'protein': widget.nutritionFacts['proteinPerServing'] ?? '0g',
      'carbs': widget.nutritionFacts['carbsPerServing'] ?? '0g',
      'fat': widget.nutritionFacts['fatPerServing'] ?? '0g',
    };
    
    final servings = widget.nutritionFacts['servings'] ?? _servings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr(context, 'nutrition_facts'),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Holographic pie chart trigger
            HolographicNutritionPie(
              nutritionFacts: _showPerServing ? perServingNutrition : perMealNutrition,
              isCompact: true,
              onTap: () => _showHolographicNutritionModal(context, _showPerServing ? perServingNutrition : perMealNutrition),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Toggle controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.textColor(context).withAlpha(26)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showPerServing = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _showPerServing ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Per Serving',
                        style: TextStyle(
                          color: _showPerServing ? Colors.white : AppTheme.textColor(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showPerServing = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: !_showPerServing ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Per Meal',
                        style: TextStyle(
                          color: !_showPerServing ? Colors.white : AppTheme.textColor(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Servings info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context).withAlpha(128),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant, size: 16, color: AppTheme.textColor(context).withAlpha(179)),
              const SizedBox(width: 8),
              Text(
                _showPerServing ? 'Per 1 serving of $servings total' : 'Whole meal ($servings servings)',
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
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
            children: (_showPerServing ? perServingNutrition : perMealNutrition).entries.map((entry) {
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ingredients[index],
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontSize: 16,
                          ),
                        ),
                        if (_getIngredientCalories(index) != null && _getIngredientCalories(index)! > 5) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${_getIngredientCalories(index)} cal',
                            style: TextStyle(
                              color: AppTheme.textColor(context).withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _getAdjustedMeasure(index),
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_shouldShowGrams(widget.measures[index])) ...[
                        const SizedBox(height: 2),
                        Text(
                          '(~${_getIngredientGrams(index)}g)',
                          style: TextStyle(
                            color: AppTheme.textColor(context).withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
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
    return Column(
      children: [
        // Platform toggle row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.textColor(context).withAlpha(26)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        _videoPlatform = 'youtube';
                      });
                      await VideoPlatformHelper.setPreferredVideoPlatform('youtube');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _videoPlatform == 'youtube' ? const Color(0xFFFF0000) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'YouTube',
                        style: TextStyle(
                          color: _videoPlatform == 'youtube' ? Colors.white : AppTheme.textColor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        _videoPlatform = 'google';
                      });
                      await VideoPlatformHelper.setPreferredVideoPlatform('google');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _videoPlatform == 'google' ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Google Videos',
                        style: TextStyle(
                          color: _videoPlatform == 'google' ? Colors.white : AppTheme.textColor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Main video button
        InkWell(
          onTap: () async {
            // Capture context before async operation
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            
            // Use the specific platform URL based on current selection
            String url;
            if (_videoPlatform == 'google') {
              url = VideoPlatformHelper.getGoogleVideosSearchURL(widget.mealTitle);
            } else {
              url = VideoPlatformHelper.getYouTubeSearchURL(widget.mealTitle);
            }
            
            final uri = Uri.parse(url);
            final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
            
            if (!success && mounted) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Unable to open video search'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // Dynamic color based on platform
              color: _videoPlatform == 'youtube' ? const Color(0xFFFF0000) : AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Platform-specific icon
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    _videoPlatform == 'youtube' ? Icons.play_arrow : Icons.video_library,
                    color: _videoPlatform == 'youtube' ? const Color(0xFFFF0000) : AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _videoPlatform == 'youtube' 
                      ? tr(context, 'watch_on_youtube')
                      : 'Watch on ${VideoPlatformHelper.getPlatformDisplayName(_videoPlatform)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
      BuildContext context, String titleKey, String? imagePath) {
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

  void _showHolographicNutritionModal(BuildContext context, Map<String, dynamic> nutritionFacts) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => HolographicNutritionModal(
        nutritionFacts: nutritionFacts,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  // Helper methods to get ingredient nutrition data
  int? _getIngredientCalories(int index) {
    final breakdown = widget.nutritionFacts['ingredientBreakdown'];
    if (breakdown != null && breakdown is List && index < breakdown.length) {
      final perMealCalories = breakdown[index]['calories'] as int?;
      if (perMealCalories == null) return null;
      
      // If showing per-serving, divide by servings
      if (_showPerServing) {
        final servings = widget.nutritionFacts['servings'] ?? _servings;
        return (perMealCalories / servings).round();
      }
      
      return perMealCalories; // Per meal calories
    }
    return null;
  }


  int? _getIngredientGrams(int index) {
    final breakdown = widget.nutritionFacts['ingredientBreakdown'];
    if (breakdown != null && breakdown is List && index < breakdown.length) {
      final perMealGrams = breakdown[index]['grams'] as int?;
      if (perMealGrams == null) return null;
      
      // If showing per-serving, divide by servings
      if (_showPerServing) {
        final servings = widget.nutritionFacts['servings'] ?? _servings;
        return (perMealGrams / servings).round();
      }
      
      return perMealGrams; // Per meal grams  
    }
    return null;
  }

  // Determine when showing grams is helpful vs confusing
  bool _shouldShowGrams(String measure) {
    final measureLower = measure.toLowerCase();
    
    // Don't show grams for measurements that are already intuitive
    if (measureLower.contains('tbsp') || measureLower.contains('tablespoon') ||
        measureLower.contains('tsp') || measureLower.contains('teaspoon') ||
        measureLower.contains('pinch') || measureLower.contains('dash') ||
        measureLower.contains('clove') || measureLower.contains('handful') ||
        measureLower.contains('leaves') || measureLower.contains('garnish') ||
        measureLower.contains('to taste')) {
      return false; // These are better left as original measurements
    }
    
    // Don't show grams for items already in grams/kg
    if (measureLower.contains('g ') || measureLower.contains('gram') ||
        measureLower.contains('kg') || measureLower.contains('kilogram')) {
      return false;
    }
    
    // Show grams for volume measurements and vague quantities
    if (measureLower.contains('cup') || measureLower.contains('ml') ||
        measureLower.contains('large') || measureLower.contains('medium') ||
        measureLower.contains('small') || measureLower.contains('lb') ||
        measureLower.contains('oz') || measureLower.contains('skinned') ||
        RegExp(r'^\d+\s*$').hasMatch(measure.trim())) { // Just numbers
      return true;
    }
    
    return false; // Default to not showing grams
  }

  // Get measure adjusted for per-serving vs per-meal display
  String _getAdjustedMeasure(int index) {
    final originalMeasure = _adjustMeasure(widget.measures[index]);
    
    // If showing per-serving, adjust the measure
    if (_showPerServing) {
      final servings = widget.nutritionFacts['servings'] ?? _servings;
      return _adjustMeasureForServings(originalMeasure, servings);
    }
    
    return originalMeasure; // Per meal measure
  }

  // Adjust measure quantities for per-serving display
  String _adjustMeasureForServings(String measure, int servings) {
    if (servings <= 1) return measure;
    
    // Extract number from measure
    final regex = RegExp(r'(\d+(?:\.\d+)?)\s*(.*)');
    final match = regex.firstMatch(measure);
    
    if (match != null) {
      final number = double.parse(match.group(1)!);
      final unit = match.group(2)!;
      final adjustedNumber = number / servings;
      
      // Format nicely
      final formattedNumber = adjustedNumber == adjustedNumber.toInt() 
          ? adjustedNumber.toInt().toString()
          : adjustedNumber.toStringAsFixed(1);
      
      return '$formattedNumber $unit';
    }
    
    return measure; // Return original if can't parse
  }
}
