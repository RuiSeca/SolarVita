import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../models/nutrition/flexible_nutrition_calculator.dart';

class FlexibleNutritionCalculatorWidget extends StatefulWidget {
  final Map<String, dynamic> nutritionFacts;
  final Function(NutritionCalculationResult)? onResultChanged;

  const FlexibleNutritionCalculatorWidget({
    super.key,
    required this.nutritionFacts,
    this.onResultChanged,
  });

  @override
  State<FlexibleNutritionCalculatorWidget> createState() =>
      _FlexibleNutritionCalculatorWidgetState();
}

class _FlexibleNutritionCalculatorWidgetState
    extends State<FlexibleNutritionCalculatorWidget> {
  late FlexibleNutritionCalculator _calculator;
  NutritionDisplayMode _currentMode = NutritionDisplayMode.perServing;
  final TextEditingController _gramsController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  
  double _currentGrams = 0;
  double _currentServings = 1;

  @override
  void initState() {
    super.initState();
    _servingsController.text = '1.0';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeCalculator();
  }


  void _initializeCalculator() {
    // Extract nutrition data from widget  
    final servings = _parseInt(widget.nutritionFacts['servings'] ?? '1');
    
    final totalNutrients = {
      'calories': _parseDouble(widget.nutritionFacts['calories'] ?? '0'),
      'protein': _parseDouble(widget.nutritionFacts['protein']?.toString().replaceAll('g', '') ?? '0'),
      'carbs': _parseDouble(widget.nutritionFacts['carbs']?.toString().replaceAll('g', '') ?? '0'),
      'fat': _parseDouble(widget.nutritionFacts['fat']?.toString().replaceAll('g', '') ?? '0'),
    };
    
    // Intelligent weight calculation
    final totalWeight = _calculateTotalWeight(servings, totalNutrients['protein']!, totalNutrients['carbs']!, totalNutrients['fat']!);

    _calculator = FlexibleNutritionCalculator(
      totalWeight: totalWeight,
      totalNutrients: totalNutrients,
      servings: servings,
    );

    _currentGrams = _calculator.weightPerServing;
    _gramsController.text = _currentGrams.round().toString();
    _updateResult();
  }

  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleanValue) ?? 0.0;
    }
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
      return int.tryParse(cleanValue) ?? 1;
    }
    return 1;
  }

  double _calculateTotalWeight(int servings, double protein, double carbs, double fat) {
    // 1. First check if totalWeight is explicitly provided
    final explicitWeight = _parseDouble(widget.nutritionFacts['totalWeight'] ?? '0');
    if (explicitWeight > 0) {
      return explicitWeight;
    }

    // 2. Try to estimate from ingredient breakdown if available (most accurate)
    final ingredientWeight = _estimateWeightFromIngredients();
    if (ingredientWeight > 0) {
      return ingredientWeight;
    }

    // 3. Use calorie-based estimation (more reliable than macro weight)
    final totalCalories = _parseDouble(widget.nutritionFacts['calories'] ?? '0');
    if (totalCalories > 0) {
      // Average calorie density: 1.5-2.5 kcal/g for most foods
      // Use 2.0 kcal/g as reasonable middle ground
      final estimatedWeight = (totalCalories / 2.0) * servings;
      return estimatedWeight.clamp(100.0, 2000.0); // Reasonable bounds
    }

    // 4. Fallback to reasonable default based on servings
    // Most meals: 200-400g per serving
    return (servings * 300.0); // 300g per serving default
  }

  double _estimateWeightFromIngredients() {
    final breakdown = widget.nutritionFacts['ingredientBreakdown'];
    if (breakdown != null && breakdown is List) {
      double totalGrams = 0;
      for (final ingredient in breakdown) {
        if (ingredient is Map && ingredient['grams'] != null) {
          totalGrams += _parseDouble(ingredient['grams'].toString());
        }
      }
      return totalGrams;
    }
    return 0;
  }

  void _recreateCalculatorWithServings(int newServings) {
    // Get base nutrition values (per original serving count)
    final originalServings = _parseInt(widget.nutritionFacts['servings'] ?? '1');
    final scalingFactor = newServings / originalServings;
    
    final baseTotalNutrients = {
      'calories': _parseDouble(widget.nutritionFacts['calories'] ?? '0'),
      'protein': _parseDouble(widget.nutritionFacts['protein']?.toString().replaceAll('g', '') ?? '0'),
      'carbs': _parseDouble(widget.nutritionFacts['carbs']?.toString().replaceAll('g', '') ?? '0'),
      'fat': _parseDouble(widget.nutritionFacts['fat']?.toString().replaceAll('g', '') ?? '0'),
    };
    
    // Scale nutrition values for new serving count
    final scaledNutrients = {
      'calories': baseTotalNutrients['calories']! * scalingFactor,
      'protein': baseTotalNutrients['protein']! * scalingFactor,
      'carbs': baseTotalNutrients['carbs']! * scalingFactor,
      'fat': baseTotalNutrients['fat']! * scalingFactor,
    };
    
    // Calculate scaled weight
    final baseWeight = _calculateTotalWeight(originalServings, baseTotalNutrients['protein']!, baseTotalNutrients['carbs']!, baseTotalNutrients['fat']!);
    final scaledWeight = baseWeight * scalingFactor;
    
    // Create new calculator with scaled values
    _calculator = FlexibleNutritionCalculator(
      totalWeight: scaledWeight,
      totalNutrients: scaledNutrients,
      servings: newServings,
    );
    
    // Update current grams to match new serving size
    _currentGrams = _calculator.weightPerServing;
    _gramsController.text = _currentGrams.round().toString();
  }

  void _updateResult() {
    late NutritionCalculationResult result;
    
    switch (_currentMode) {
      case NutritionDisplayMode.wholeMeal:
        result = NutritionCalculationResult(
          mode: _currentMode,
          nutrition: _calculator.totalNutrients,
          grams: _calculator.totalWeight,
          description: tr(context, 'whole_meal_description').replaceAll('{servings}', _calculator.servings.toString()),
        );
        break;
        
      case NutritionDisplayMode.per100g:
        result = NutritionCalculationResult(
          mode: _currentMode,
          nutrition: _calculator.nutritionPer100g,
          grams: 100,
          description: tr(context, 'standard_format'),
        );
        break;
        
      case NutritionDisplayMode.perServing:
        result = NutritionCalculationResult(
          mode: _currentMode,
          nutrition: _calculator.nutritionPerServing,
          grams: _calculator.weightPerServing,
          servingFraction: 1.0,
          description: tr(context, 'per_serving_description').replaceAll('{servings}', _calculator.servings.toString()),
        );
        break;
        
      case NutritionDisplayMode.customGrams:
        final servingFraction = _calculator.servingFractionForGrams(_currentGrams);
        result = NutritionCalculationResult(
          mode: _currentMode,
          nutrition: _calculator.nutritionForGrams(_currentGrams),
          grams: _currentGrams,
          servingFraction: servingFraction,
          description: '${_currentGrams.round()}g (${FlexibleNutritionCalculator.roundToOneDecimal(servingFraction)} ${tr(context, 'servings').toLowerCase()})',
        );
        break;
    }
    
    widget.onResultChanged?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textColor(context).withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildModeSelector(),
          const SizedBox(height: 16),
          _buildInputSection(),
          const SizedBox(height: 16),
          _buildNutritionDisplay(),
          const SizedBox(height: 12),
          _buildServingInfo(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.calculate,
          color: AppColors.primary,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          tr(context, 'flexible_calculator'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildModeButton(NutritionDisplayMode.wholeMeal, tr(context, 'whole_meal')),
          _buildModeButton(NutritionDisplayMode.per100g, tr(context, 'per_100g')),
          _buildModeButton(NutritionDisplayMode.perServing, tr(context, 'per_serving')),
          _buildModeButton(NutritionDisplayMode.customGrams, tr(context, 'custom_amount')),
        ],
      ),
    );
  }

  Widget _buildModeButton(NutritionDisplayMode mode, String label) {
    final isSelected = _currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentMode = mode;
            if (mode == NutritionDisplayMode.customGrams) {
              _currentGrams = double.tryParse(_gramsController.text) ?? _calculator.weightPerServing;
            } else if (mode == NutritionDisplayMode.perServing) {
              _currentServings = double.tryParse(_servingsController.text) ?? 1.0;
              _currentGrams = _calculator.gramsForServings(_currentServings);
              _gramsController.text = _currentGrams.round().toString();
            }
            _updateResult();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textColor(context),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    if (_currentMode != NutritionDisplayMode.customGrams && _currentMode != NutritionDisplayMode.perServing) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(51)),
      ),
      child: Row(
        children: [
          if (_currentMode == NutritionDisplayMode.customGrams) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'enter_grams'),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _gramsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: tr(context, 'grams_placeholder'),
                      hintStyle: TextStyle(
                        color: AppTheme.textColor(context).withAlpha(128),
                        fontSize: 14,
                      ),
                      suffixText: 'g',
                      suffixStyle: TextStyle(
                        color: AppTheme.textColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      final grams = double.tryParse(value) ?? 0;
                      setState(() {
                        _currentGrams = grams;
                        _updateResult();
                      });
                    },
                  ),
                ],
              ),
            ),
          ] else if (_currentMode == NutritionDisplayMode.perServing) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'serving_count'),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _servingsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: '1.0',
                      hintStyle: TextStyle(
                        color: AppTheme.textColor(context).withAlpha(128),
                        fontSize: 14,
                      ),
                      suffixText: tr(context, 'servings').toLowerCase(),
                      suffixStyle: TextStyle(
                        color: AppTheme.textColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      final servings = double.tryParse(value) ?? 1.0;
                      setState(() {
                        _currentServings = servings;
                        // Recreate calculator with new serving count (scales the entire meal)
                        _recreateCalculatorWithServings(servings.round());
                        _updateResult();
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.refresh,
              color: AppColors.primary,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionDisplay() {
    Map<String, double> nutrition;
    
    switch (_currentMode) {
      case NutritionDisplayMode.wholeMeal:
        nutrition = _calculator.totalNutrients;
        break;
      case NutritionDisplayMode.per100g:
        nutrition = _calculator.nutritionPer100g;
        break;
      case NutritionDisplayMode.perServing:
        nutrition = _calculator.nutritionPerServing;
        break;
      case NutritionDisplayMode.customGrams:
        nutrition = _calculator.nutritionForGrams(_currentGrams);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'nutrition_breakdown'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildNutrientItem('calories', nutrition['calories'] ?? 0, 'kcal'),
              _buildNutrientItem('protein', nutrition['protein'] ?? 0, 'g'),
              _buildNutrientItem('carbs', nutrition['carbs'] ?? 0, 'g'),
              _buildNutrientItem('fat', nutrition['fat'] ?? 0, 'g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientItem(String key, double value, String unit) {
    return Expanded(
      child: Column(
        children: [
          Text(
            FlexibleNutritionCalculator.formatNutritionValue(value, unit),
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tr(context, '${key}_label'),
            style: TextStyle(
              color: AppTheme.textColor(context).withAlpha(179),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServingInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem(
              tr(context, 'total_weight'),
              _currentMode == NutritionDisplayMode.per100g 
                ? '100g' 
                : '${_calculator.totalWeight.round()}g',
            ),
          ),
          Expanded(
            child: _buildInfoItem(
              tr(context, 'weight_per_serving'),
              _currentMode == NutritionDisplayMode.per100g 
                ? '100g' 
                : '${_calculator.weightPerServing.round()}g',
            ),
          ),
          if (_currentMode == NutritionDisplayMode.customGrams)
            Expanded(
              child: _buildInfoItem(
                tr(context, 'serving_fraction'),
                FlexibleNutritionCalculator.roundToOneDecimal(
                  _calculator.servingFractionForGrams(_currentGrams)
                ).toString(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textColor(context).withAlpha(179),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _gramsController.dispose();
    _servingsController.dispose();
    super.dispose();
  }
}