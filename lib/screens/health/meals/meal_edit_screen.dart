// lib/screens/health/meal_edit_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

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
      'imagePath': _selectedImage?.path ?? widget.imagePath ?? '',
      'imageFile': _selectedImage,
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

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
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
                color: AppTheme.textColor(context).withAlpha(64),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tr(context, 'select_image_source'),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceOption(
                    context,
                    Icons.camera_alt,
                    tr(context, 'camera'),
                    () => _selectImageSource(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageSourceOption(
                    context,
                    Icons.photo_library,
                    tr(context, 'gallery'),
                    () => _selectImageSource(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            if (_selectedImage != null || widget.imagePath != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _buildImageSourceOption(
                  context,
                  Icons.delete,
                  tr(context, 'remove_image'),
                  _removeImage,
                ),
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.textColor(context).withAlpha(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectImageSource(ImageSource source) async {
    Navigator.pop(context); // Close the bottom sheet
    
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(tr(context, 'error_picking_image')),
                ),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage() {
    Navigator.pop(context); // Close the bottom sheet
    setState(() {
      _selectedImage = null;
    });
  }

  ImageProvider _getImageProvider(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      // Create a simple 1x1 transparent image as a placeholder
      return MemoryImage(
        Uint8List.fromList([
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
          0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
          0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
          0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
          0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
          0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
        ]),
      );
    }
    
    // Check if it's a network URL
    if (imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    }
    
    // Check if it's a local file path
    if (imagePath.startsWith('/') || imagePath.startsWith('file://')) {
      return FileImage(File(imagePath.replaceFirst('file://', '')));
    }
    
    // Assume it's an asset
    return AssetImage(imagePath);
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
    final hasImage = _selectedImage != null || widget.imagePath != null;
    
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: hasImage 
              ? null 
              : Border.all(
                  color: AppTheme.textColor(context).withAlpha(64),
                  width: 2,
                ),
          image: hasImage
              ? DecorationImage(
                  image: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : _getImageProvider(widget.imagePath),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: hasImage
            ? Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(128),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: AppTheme.textColor(context).withAlpha(128),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'add_meal_photo'),
                    style: TextStyle(
                      color: AppTheme.textColor(context).withAlpha(128),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr(context, 'tap_to_select_image'),
                    style: TextStyle(
                      color: AppTheme.textColor(context).withAlpha(89),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
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
