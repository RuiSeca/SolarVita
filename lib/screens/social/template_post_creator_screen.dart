// lib/screens/social/template_post_creator_screen.dart
import 'package:flutter/material.dart';
import '../../models/post_template.dart';
import '../../models/social_post.dart';
import '../../theme/app_theme.dart';
import 'create_post_screen.dart';

class TemplatePostCreatorScreen extends StatefulWidget {
  final PostTemplate template;

  const TemplatePostCreatorScreen({
    super.key,
    required this.template,
  });

  @override
  State<TemplatePostCreatorScreen> createState() => _TemplatePostCreatorScreenState();
}

class _TemplatePostCreatorScreenState extends State<TemplatePostCreatorScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final _formKey = GlobalKey<FormState>();
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (final placeholder in widget.template.placeholders) {
      _controllers[placeholder] = TextEditingController();
      _focusNodes[placeholder] = FocusNode();
    }
  }


  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: _buildAppBar(),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTemplateHeader(),
              const SizedBox(height: 24),
              _buildInputFields(),
              const SizedBox(height: 24),
              _buildPreview(),
              const SizedBox(height: 24),
              _buildBottomActions(),
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
        'Create Template Post',
        style: TextStyle(
          color: AppTheme.textColor(context),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTemplateHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.template.color.withAlpha(51),
            widget.template.color.withAlpha(26),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.template.color.withAlpha(77),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.template.color.withAlpha(51),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              widget.template.icon,
              color: widget.template.color,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.template.title,
                  style: TextStyle(
                    fontSize: 20,
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

  Widget _buildInputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fill in the details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Complete the prompts below to create your personalized post',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textColor(context).withAlpha(153),
          ),
        ),
        const SizedBox(height: 16),
        
        ...widget.template.placeholders.asMap().entries.map((entry) {
          final index = entry.key;
          final placeholder = entry.value;
          final prompt = widget.template.variablePrompts[placeholder] ?? placeholder;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildInputField(
              placeholder: placeholder,
              prompt: prompt,
              isLast: index == widget.template.placeholders.length - 1,
            ),
          );
        })
      ],
    );
  }

  Widget _buildInputField({
    required String placeholder,
    required String prompt,
    bool isLast = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          prompt,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textColor(context).withAlpha(51),
            ),
          ),
          child: TextFormField(
            controller: _controllers[placeholder],
            focusNode: _focusNodes[placeholder],
            maxLines: _isLongFormField(placeholder) ? null : 1,
            minLines: _isLongFormField(placeholder) ? 3 : 1,
            keyboardType: _isLongFormField(placeholder) ? TextInputType.multiline : TextInputType.text,
            textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
            onFieldSubmitted: (_) {
              if (!isLast) {
                final nextIndex = widget.template.placeholders.indexOf(placeholder) + 1;
                if (nextIndex < widget.template.placeholders.length) {
                  final nextPlaceholder = widget.template.placeholders[nextIndex];
                  _focusNodes[nextPlaceholder]?.requestFocus();
                }
              }
            },
            onChanged: (_) => setState(() {}), // Update preview
            decoration: InputDecoration(
              hintText: _getHintText(placeholder),
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
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            },
          ),
        ),
        
        // Suggestions for this field
        if (widget.template.suggestedContent.isNotEmpty && _shouldShowSuggestions(placeholder))
          _buildSuggestions(placeholder),
      ],
    );
  }

  Widget _buildSuggestions(String placeholder) {
    final suggestions = _getSuggestionsForField(placeholder);
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: suggestions.take(3).map((suggestion) {
          return GestureDetector(
            onTap: () {
              _controllers[placeholder]?.text = suggestion;
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.template.color.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.template.color.withAlpha(77),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 12,
                    color: widget.template.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.template.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.visibility,
              size: 20,
              color: AppTheme.textColor(context).withAlpha(153),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mock user header
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.person, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'You',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Generated content
              Text(
                _generatePreviewContent(),
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: AppTheme.textColor(context),
                ),
              ),
              
              // Pillar tags
              if (widget.template.defaultPillars.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: widget.template.defaultPillars.map((pillar) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPillarColor(pillar).withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getPillarName(pillar),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getPillarColor(pillar),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppTheme.textColor(context).withAlpha(77)),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canCreatePost() ? _createPostFromTemplate : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.template.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: AppTheme.textColor(context).withAlpha(51),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.create,
                    size: 18,
                    color: _canCreatePost() ? Colors.white : AppTheme.textColor(context).withAlpha(128),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Create Post',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _canCreatePost() ? Colors.white : AppTheme.textColor(context).withAlpha(128),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  bool _isLongFormField(String placeholder) {
    return ['details', 'journey', 'feeling', 'insight', 'advice', 'reason'].contains(placeholder);
  }

  String _getHintText(String placeholder) {
    switch (placeholder) {
      case 'achievement':
        return 'What did you accomplish?';
      case 'details':
        return 'Tell us more about it...';
      case 'next_goal':
        return 'What\'s next for you?';
      case 'amount':
        return 'e.g., 10';
      case 'unit':
        return 'lbs, kg, etc.';
      case 'time':
        return 'e.g., 25:30';
      default:
        return 'Enter your ${placeholder.replaceAll('_', ' ')}...';
    }
  }

  bool _shouldShowSuggestions(String placeholder) {
    return placeholder == 'achievement' && widget.template.suggestedContent.isNotEmpty;
  }

  List<String> _getSuggestionsForField(String placeholder) {
    if (placeholder == 'achievement') {
      return widget.template.suggestedContent;
    }
    return [];
  }

  String _generatePreviewContent() {
    final inputs = <String, String>{};
    for (final placeholder in widget.template.placeholders) {
      final value = _controllers[placeholder]?.text.trim() ?? '';
      inputs[placeholder] = value.isEmpty ? '[${placeholder.replaceAll('_', ' ')}]' : value;
    }
    return widget.template.generateContent(inputs);
  }

  bool _canCreatePost() {
    return _controllers.values.every((controller) => controller.text.trim().isNotEmpty);
  }

  void _createPostFromTemplate() {
    if (!_formKey.currentState!.validate()) return;

    final inputs = <String, String>{};
    for (final entry in _controllers.entries) {
      inputs[entry.key] = entry.value.text.trim();
    }

    final generatedContent = widget.template.generateContent(inputs);

    // Navigate to create post screen with pre-filled content
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(
          initialPostType: widget.template.postType,
          sourceData: {
            'template_id': widget.template.id,
            'template_title': widget.template.title,
            'user_inputs': inputs,
            'pre_filled_content': generatedContent,
            'default_pillars': widget.template.defaultPillars.map((p) => p.toString()).toList(),
          },
        ),
      ),
    );
  }

  Color _getPillarColor(pillar) {
    switch (pillar) {
      case PostPillar.fitness:
        return const Color(0xFF2196F3);
      case PostPillar.nutrition:
        return const Color(0xFF4CAF50);
      case PostPillar.eco:
        return const Color(0xFF8BC34A);
      default:
        return Colors.grey;
    }
  }

  String _getPillarName(pillar) {
    switch (pillar) {
      case PostPillar.fitness:
        return 'Fitness';
      case PostPillar.nutrition:
        return 'Nutrition';
      case PostPillar.eco:
        return 'Eco';
      default:
        return 'Other';
    }
  }
}