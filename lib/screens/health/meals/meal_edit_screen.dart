// lib/screens/health/meal_edit_screen.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';

class MealEditScreen extends StatefulWidget {
  final String? mealTitle;
  final String? imagePath;
  final Map<String, String>? nutritionFacts;
  final List<String>? ingredients;
  final List<String>? instructions;

  const MealEditScreen({
    super.key,
    this.mealTitle,
    this.imagePath,
    this.nutritionFacts,
    this.ingredients,
    this.instructions,
  });

  @override
  State<MealEditScreen> createState() => _MealEditScreenState();
}

class _MealEditScreenState extends State<MealEditScreen> {
  late TextEditingController _titleController;
  late List<TextEditingController> _ingredientControllers;
  late List<TextEditingController> _instructionControllers;
  late Map<String, TextEditingController> _nutritionControllers;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.mealTitle);
    _ingredientControllers = (widget.ingredients ?? [''])
        .map((ingredient) => TextEditingController(text: ingredient))
        .toList();
    _instructionControllers = (widget.instructions ?? [''])
        .map((instruction) => TextEditingController(text: instruction))
        .toList();
    _nutritionControllers = {
      'calories':
          TextEditingController(text: widget.nutritionFacts?['calories'] ?? ''),
      'protein':
          TextEditingController(text: widget.nutritionFacts?['protein'] ?? ''),
      'carbs':
          TextEditingController(text: widget.nutritionFacts?['carbs'] ?? ''),
      'fat': TextEditingController(text: widget.nutritionFacts?['fat'] ?? ''),
    };
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _ingredientControllers) {
      controller.dispose();
    }
    for (var controller in _instructionControllers) {
      controller.dispose();
    }
    for (var controller in _nutritionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveMeal() {
    // Here you would save the meal data to your storage/backend
    final meal = {
      'title': _titleController.text,
      'imagePath': widget.imagePath,
      'nutritionFacts': _nutritionControllers.map(
        (key, controller) => MapEntry(key, controller.text),
      ),
      'ingredients': _ingredientControllers
          .map((controller) => controller.text)
          .where((text) => text.isNotEmpty)
          .toList(),
      'instructions': _instructionControllers
          .map((controller) => controller.text)
          .where((text) => text.isNotEmpty)
          .toList(),
    };
    Navigator.pop(context, meal);
  }

  void _addIngredient() {
    setState(() {
      _ingredientControllers.add(TextEditingController());
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredientControllers[index].dispose();
      _ingredientControllers.removeAt(index);
    });
  }

  void _addInstruction() {
    setState(() {
      _instructionControllers.add(TextEditingController());
    });
  }

  void _removeInstruction(int index) {
    setState(() {
      _instructionControllers[index].dispose();
      _instructionControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        title: Text(
          tr(context, widget.mealTitle == null ? 'create_meal' : 'edit_meal'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveMeal,
            child: Text(
              tr(context, 'save'),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePicker(context),
            const SizedBox(height: 24),
            _buildTitleField(context),
            const SizedBox(height: 24),
            _buildNutritionFields(context),
            const SizedBox(height: 24),
            _buildIngredientsList(context),
            const SizedBox(height: 24),
            _buildInstructionsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Implement image picking functionality
      },
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          image: widget.imagePath != null
              ? DecorationImage(
                  image: AssetImage(widget.imagePath!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: widget.imagePath == null
            ? Icon(
                Icons.add_photo_alternate,
                size: 40,
                color: AppTheme.textColor(context).withAlpha(128),
              )
            : null,
      ),
    );
  }

  Widget _buildTitleField(BuildContext context) {
    return TextFormField(
      controller: _titleController,
      style: TextStyle(color: AppTheme.textColor(context)),
      decoration: InputDecoration(
        labelText: tr(context, 'meal_title'),
        labelStyle:
            TextStyle(color: AppTheme.textColor(context).withAlpha(179)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildNutritionFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'nutrition_facts'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _nutritionControllers.entries.map((entry) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 48) / 2,
              child: TextFormField(
                controller: entry.value,
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppTheme.textColor(context)),
                decoration: InputDecoration(
                  labelText: tr(context, entry.key),
                  labelStyle: TextStyle(
                      color: AppTheme.textColor(context).withAlpha(179)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIngredientsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr(context, 'ingredients'),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              onPressed: _addIngredient,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._ingredientControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    style: TextStyle(color: AppTheme.textColor(context)),
                    decoration: InputDecoration(
                      labelText: tr(context, 'ingredient_name'),
                      labelStyle: TextStyle(
                          color: AppTheme.textColor(context).withAlpha(179)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (_ingredientControllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeIngredient(index),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInstructionsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr(context, 'instructions'),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              onPressed: _addInstruction,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._instructionControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
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
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    style: TextStyle(color: AppTheme.textColor(context)),
                    maxLines: null,
                    decoration: InputDecoration(
                      labelText: tr(context, 'instruction_step'),
                      labelStyle: TextStyle(
                          color: AppTheme.textColor(context).withAlpha(179)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (_instructionControllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeInstruction(index),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
