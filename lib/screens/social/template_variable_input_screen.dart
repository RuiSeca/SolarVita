// lib/screens/social/template_variable_input_screen.dart
import 'package:flutter/material.dart';
import '../../models/post_template.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../widgets/common/lottie_loading_widget.dart';
import 'create_post_screen.dart';

class TemplateVariableInputScreen extends StatefulWidget {
  final PostTemplate template;

  const TemplateVariableInputScreen({
    super.key,
    required this.template,
  });

  @override
  State<TemplateVariableInputScreen> createState() => _TemplateVariableInputScreenState();
}

class _TemplateVariableInputScreenState extends State<TemplateVariableInputScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _dropdownValues = {};
  final _formKey = GlobalKey<FormState>();
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    for (final placeholder in widget.template.placeholders) {
      _controllers[placeholder] = TextEditingController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: _buildAppBar(),
      body: _isGenerating
          ? const Center(child: LottieLoadingWidget())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTemplateHeader(),
                    const SizedBox(height: 24),
                    _buildVariableInputs(),
                    const SizedBox(height: 24),
                    _buildPreview(),
                    const SizedBox(height: 32),
                    _buildGenerateButton(),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surfaceColor(context),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        tr(context, 'customize_template'),
        style: TextStyle(
          color: AppTheme.textColor(context),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTemplateHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.template.color.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.template.color.withAlpha(51),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.template.color.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.template.icon,
              color: widget.template.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.template.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.template.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textColor(context).withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariableInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'fill_details'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr(context, 'personalize_post'),
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textColor(context).withAlpha(153),
          ),
        ),
        const SizedBox(height: 16),
        ...widget.template.placeholders.map((placeholder) {
          final prompt = widget.template.variablePrompts[placeholder] ?? placeholder;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildVariableInput(placeholder, prompt),
          );
        }),
      ],
    );
  }

  Widget _buildVariableInput(String placeholder, String prompt) {
    // Check if this is a dropdown type (based on common patterns)
    final isDropdown = _isDropdownField(placeholder);
    final isRequired = _isRequiredField(placeholder);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              prompt,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        if (isDropdown)
          _buildDropdownField(placeholder)
        else
          _buildTextFieldInput(placeholder, isRequired),
      ],
    );
  }

  Widget _buildTextFieldInput(String placeholder, bool isRequired) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textColor(context).withAlpha(51),
        ),
      ),
      child: TextFormField(
        controller: _controllers[placeholder],
        maxLines: _isLongTextField(placeholder) ? 3 : 1,
        decoration: InputDecoration(
          hintText: _getPlaceholderHint(placeholder),
          hintStyle: TextStyle(
            color: AppTheme.textColor(context).withAlpha(128),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: TextStyle(
          color: AppTheme.textColor(context),
          fontSize: 16,
        ),
        validator: isRequired ? (value) {
          if (value == null || value.trim().isEmpty) {
            return tr(context, 'field_required');
          }
          return null;
        } : null,
        onChanged: (value) => setState(() {}), // Trigger preview update
      ),
    );
  }

  Widget _buildDropdownField(String placeholder) {
    final options = _getDropdownOptions(placeholder);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textColor(context).withAlpha(51),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _dropdownValues[placeholder],
          hint: Text(
            _getPlaceholderHint(placeholder),
            style: TextStyle(
              color: AppTheme.textColor(context).withAlpha(128),
            ),
          ),
          isExpanded: true,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 16,
          ),
          dropdownColor: AppTheme.cardColor(context),
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _dropdownValues[placeholder] = value!;
              _controllers[placeholder]?.text = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final userInputs = <String, String>{};
    
    // Collect current values
    for (final placeholder in widget.template.placeholders) {
      final value = _dropdownValues[placeholder] ?? _controllers[placeholder]?.text ?? '';
      userInputs[placeholder] = value.isNotEmpty ? value : '[$placeholder]';
    }

    final previewText = widget.template.generateContent(userInputs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'preview'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textColor(context).withAlpha(51),
            ),
          ),
          child: Text(
            previewText,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: AppTheme.textColor(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _canGenerate() ? _generatePost : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.template.color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          tr(context, 'create_post'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  bool _canGenerate() {
    // Check if all required fields are filled
    for (final placeholder in widget.template.placeholders) {
      if (_isRequiredField(placeholder)) {
        final value = _dropdownValues[placeholder] ?? _controllers[placeholder]?.text ?? '';
        if (value.trim().isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _generatePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      // Collect user inputs
      final userInputs = <String, String>{};
      for (final placeholder in widget.template.placeholders) {
        userInputs[placeholder] = _dropdownValues[placeholder] ?? _controllers[placeholder]!.text;
      }

      // Generate the post content
      final generatedContent = widget.template.generateContent(userInputs);

      // Navigate to create post screen with pre-filled content
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CreatePostScreen(
            initialPostType: widget.template.postType,
            sourceData: {
              'pre_filled_content': generatedContent,
              'default_pillars': widget.template.defaultPillars.map((p) => p.toString()).toList(),
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'failed_generate_post').replaceAll('{error}', '$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  // Helper methods
  bool _isDropdownField(String placeholder) {
    const dropdownFields = ['feeling', 'workout_type', 'unit'];
    return dropdownFields.contains(placeholder);
  }

  bool _isRequiredField(String placeholder) {
    const optionalFields = ['additional_notes', 'prep_tips', 'weekly_reflection', 'cooking_tip'];
    return !optionalFields.contains(placeholder);
  }

  bool _isLongTextField(String placeholder) {
    const longTextFields = ['additional_notes', 'journey', 'encouragement', 'advice', 'call_to_action'];
    return longTextFields.contains(placeholder);
  }

  String _getPlaceholderHint(String placeholder) {
    final hints = {
      'achievement': tr(context, 'achievement_example'),
      'feeling': tr(context, 'how_you_feel'),
      'workout_type': tr(context, 'workout_type'),
      'details': tr(context, 'what_made_special'),
      'next_goal': tr(context, 'aiming_next'),
      'timeframe': tr(context, 'timeframe_example'),
      'changes': tr(context, 'what_changes_notice'),
      'challenge': tr(context, 'what_was_difficult'),
      'additional_notes': tr(context, 'extra_thoughts_optional'),
    };
    return hints[placeholder] ?? tr(context, 'enter_field').replaceAll('{field}', placeholder);
  }

  List<String> _getDropdownOptions(String placeholder) {
    switch (placeholder) {
      case 'feeling':
        return ['amazing', 'energized', 'proud', 'accomplished', 'motivated', 'tired but satisfied'];
      case 'workout_type':
        return [tr(context, 'strength_training'), tr(context, 'cardio'), tr(context, 'yoga'), tr(context, 'hiit'), tr(context, 'pilates'), tr(context, 'running'), tr(context, 'cycling')];
      case 'unit':
        return ['lbs', 'kg'];
      default:
        return [];
    }
  }
}