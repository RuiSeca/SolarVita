import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../../../utils/video_platform_helper.dart';
import '../../../widgets/common/holographic_nutrition_pie.dart';
import '../../../widgets/nutrition/flexible_nutrition_calculator_widget.dart';
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
  bool _isFavorite = false;
  String _videoPlatform = 'youtube'; // Default to YouTube
  Map<String, dynamic> _currentNutritionData = {};

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _currentNutritionData = Map<String, dynamic>.from(widget.nutritionFacts);
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


  Widget _buildNutritionSection(BuildContext context) {
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
              nutritionFacts: _currentNutritionData,
              isCompact: true,
              onTap: () => _showHolographicNutritionModal(context, _currentNutritionData),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Flexible Nutrition Calculator
        FlexibleNutritionCalculatorWidget(
          nutritionFacts: widget.nutritionFacts,
          onResultChanged: (result) {
            // Update pie chart with current calculation result
            // Use post-frame callback to avoid setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _currentNutritionData = {
                    'calories': result.nutrition['calories']?.round() ?? 0,
                    'protein': '${result.nutrition['protein']?.round() ?? 0}g',
                    'carbs': '${result.nutrition['carbs']?.round() ?? 0}g',
                    'fat': '${result.nutrition['fat']?.round() ?? 0}g',
                  };
                });
              }
            });
          },
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
                      if (index < widget.measures.length && _shouldShowGrams(widget.measures[index])) ...[
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
    // Safety check for null or empty measures
    if (measure.isEmpty) {
      return '1 serving';
    }

    final regex = RegExp(r'(\d+(?:\.\d+)?)\s*(.+)');
    final match = regex.firstMatch(measure);

    if (match != null) {
      final number = double.parse(match.group(1)!);
      final unit = match.group(2);
      final servings = int.parse(widget.nutritionFacts['servings']?.toString() ?? '1');
      return '${(number * servings).toStringAsFixed(1)} $unit';
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
                        tr(context, 'youtube_platform'),
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
                        color: _videoPlatform == 'google' 
                          ? (AppTheme.isDarkMode(context) ? Colors.white : Colors.grey[400])
                          : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        tr(context, 'google_videos_platform'),
                        style: TextStyle(
                          color: _videoPlatform == 'google' 
                            ? (AppTheme.isDarkMode(context) ? Colors.black : Colors.white)
                            : AppTheme.textColor(context),
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
            final errorMessage = tr(context, 'unable_to_open_video_search');
            
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
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // Dynamic color based on platform and theme
              color: _videoPlatform == 'youtube' 
                ? const Color(0xFFFF0000) 
                : (AppTheme.isDarkMode(context) ? Colors.white : Colors.grey[600]),
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
                    color: _videoPlatform == 'youtube' 
                      ? Colors.white
                      : (AppTheme.isDarkMode(context) ? Colors.black : Colors.white),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    _videoPlatform == 'youtube' ? Icons.play_arrow : Icons.video_library,
                    color: _videoPlatform == 'youtube' 
                      ? const Color(0xFFFF0000) 
                      : (AppTheme.isDarkMode(context) ? Colors.white : Colors.grey[600]),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _videoPlatform == 'youtube' 
                      ? tr(context, 'watch_on_youtube')
                      : tr(context, 'watch_on_platform').replaceAll('{platform}', VideoPlatformHelper.getPlatformDisplayName(_videoPlatform)),
                  style: TextStyle(
                    color: _videoPlatform == 'youtube' 
                      ? Colors.white
                      : (AppTheme.isDarkMode(context) ? Colors.black : Colors.white),
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
    // Check if widget is still mounted before starting
    if (!mounted) return;
    
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

    // Check mounted state before async operation
    if (!mounted) return;

    // Always show the meal time selection bottom sheet
    final String? selectedMealTime = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      builder: (modalContext) => Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(modalContext),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textColor(modalContext).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  tr(modalContext, 'select_meal_time'),
                  style: TextStyle(
                    color: AppTheme.textColor(modalContext),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Meal time options
              ...['breakfast', 'lunch', 'dinner', 'snacks'].map(
                (mealTime) => InkWell(
                  onTap: () => Navigator.pop(modalContext, mealTime),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getMealTimeIcon(mealTime),
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            tr(modalContext, mealTime),
                            style: TextStyle(
                              color: AppTheme.textColor(modalContext),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppTheme.textColor(modalContext).withValues(alpha: 0.5),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;

    if (selectedMealTime != null) {
      // Save meal to SharedPreferences
      final success = await _saveMealToPlan(selectedMealTime, mealData);
      
      if (success && mounted) {
        final messenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);
        final translatedMessage = tr(context, 'meal_added_to_plan');
        
        messenger.showSnackBar(
          SnackBar(
            content: Text(translatedMessage),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        // Return result to trigger profile refresh
        final result = {
          'action': 'add_meal',
          'mealTime': selectedMealTime,
          'meal': mealData,
          'success': true,
        };

        navigator.pop(result);
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_adding_meal')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<bool> _saveMealToPlan(String mealTime, Map<String, dynamic> mealData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final weekOffset = 0; // Current week
      final dayIndex = now.weekday - 1; // 0-6 for Mon-Sun
      
      // Get existing data or create new structure
      String? existingDataString = prefs.getString('weeklyMealData');
      Map<String, dynamic> weeklyData = {};
      
      if (existingDataString != null) {
        final decoded = jsonDecode(existingDataString);
        weeklyData = Map<String, dynamic>.from(decoded);
      }
      
      // Initialize week data if not exists
      final weekOffsetKey = weekOffset.toString();
      if (!weeklyData.containsKey(weekOffsetKey)) {
        weeklyData[weekOffsetKey] = <String, dynamic>{};
      }
      
      final weekDataDynamic = weeklyData[weekOffsetKey];
      final weekData = Map<String, dynamic>.from(weekDataDynamic);
      weeklyData[weekOffsetKey] = weekData;
      
      // Initialize day data if not exists
      final dayIndexKey = dayIndex.toString();
      if (!weekData.containsKey(dayIndexKey)) {
        weekData[dayIndexKey] = <String, dynamic>{};
      }
      
      final dayDataDynamic = weekData[dayIndexKey];
      final dayData = Map<String, dynamic>.from(dayDataDynamic);
      weekData[dayIndexKey] = dayData;
      
      // Initialize meal time array if not exists
      if (!dayData.containsKey(mealTime)) {
        dayData[mealTime] = <Map<String, dynamic>>[];
      }
      
      final mealsForTimeDynamic = dayData[mealTime];
      final mealsForTime = List<dynamic>.from(mealsForTimeDynamic);
      
      // Format meal data consistently with meal_plan_screen.dart
      final formattedMeal = <String, dynamic>{
        'id': mealData['id'] ?? '',
        'name': mealData['titleKey'] ?? '',
        'imagePath': mealData['imagePath'] ?? '',
        'nutritionFacts': mealData['nutritionFacts'] ?? {},
        'ingredients': mealData['ingredients'] ?? [],
        'measures': mealData['measures'] ?? [],
        'instructions': mealData['instructions'] ?? [],
        'area': mealData['area'] ?? '',
        'category': mealData['category'] ?? '',
        'isVegan': mealData['isVegan'] ?? false,
        'isFavorite': mealData['isFavorite'] ?? false,
        'isSuggested': false, // This is a user-added meal
        'dateAdded': now.toIso8601String(),
      };
      
      // Add meal to the list
      mealsForTime.add(formattedMeal);
      dayData[mealTime] = mealsForTime;
      
      // Save back to SharedPreferences
      await prefs.setString('weeklyMealData', jsonEncode(weeklyData));
      
      return true;
    } catch (e) {
      debugPrint('Error saving meal to plan: $e');
      return false;
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
      
      // Always show per serving for ingredient breakdown
      final servings = int.parse(widget.nutritionFacts['servings']?.toString() ?? '1');
      return (perMealCalories / servings).round();
    }
    return null;
  }


  int? _getIngredientGrams(int index) {
    final breakdown = widget.nutritionFacts['ingredientBreakdown'];
    if (breakdown != null && breakdown is List && index < breakdown.length) {
      final perMealGrams = breakdown[index]['grams'] as int?;
      if (perMealGrams == null) return null;
      
      // Always show per serving for ingredient breakdown
      final servings = int.parse(widget.nutritionFacts['servings']?.toString() ?? '1');
      return (perMealGrams / servings).round();  
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
    // Safety check: ensure index is within bounds
    if (index >= widget.measures.length) {
      return '1 serving'; // Default fallback
    }

    final originalMeasure = _adjustMeasure(widget.measures[index]);

    // Adjust measures for per serving display
    final servings = int.parse(widget.nutritionFacts['servings']?.toString() ?? '1');
    return _adjustMeasureForServings(originalMeasure, servings);
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
