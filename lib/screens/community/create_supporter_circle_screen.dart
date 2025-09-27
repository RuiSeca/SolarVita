import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/community/supporter_circle.dart';
import '../../services/community/enhanced_social_service.dart';
import '../../utils/translation_helper.dart';
import '../../theme/app_theme.dart';

class CreateSupporterCircleScreen extends ConsumerStatefulWidget {
  const CreateSupporterCircleScreen({super.key});

  @override
  ConsumerState<CreateSupporterCircleScreen> createState() => _CreateSupporterCircleScreenState();
}

class _CreateSupporterCircleScreenState extends ConsumerState<CreateSupporterCircleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  CircleType _selectedType = CircleType.support;
  CirclePrivacy _selectedPrivacy = CirclePrivacy.public;
  int _maxMembers = 10;
  bool _allowMentoring = true;
  bool _isCreating = false;

  final EnhancedSocialService _socialService = EnhancedSocialService();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          tr(context, 'create_supporter_circle'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isCreating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Circle Name
            _buildSection(
              title: tr(context, 'circle_name'),
              child: TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: tr(context, 'enter_circle_name'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr(context, 'circle_name_required');
                  }
                  if (value.trim().length < 3) {
                    return tr(context, 'circle_name_too_short');
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 24),

            // Circle Description
            _buildSection(
              title: tr(context, 'description'),
              child: TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: tr(context, 'describe_your_circle'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr(context, 'description_required');
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 24),

            // Circle Type
            _buildSection(
              title: tr(context, 'circle_type'),
              child: _buildTypeSelector(isDarkMode),
            ),

            const SizedBox(height: 24),

            // Privacy Settings
            _buildSection(
              title: tr(context, 'privacy'),
              child: _buildPrivacySelector(isDarkMode),
            ),

            const SizedBox(height: 24),

            // Settings
            _buildSection(
              title: tr(context, 'settings'),
              child: Column(
                children: [
                  _buildSliderSetting(
                    title: tr(context, 'max_members'),
                    value: _maxMembers,
                    min: 3,
                    max: 50,
                    divisions: 47,
                    onChanged: (value) => setState(() => _maxMembers = value.round()),
                  ),
                  _buildSwitchSetting(
                    title: tr(context, 'allow_mentoring'),
                    subtitle: tr(context, 'allow_mentoring_description'),
                    value: _allowMentoring,
                    onChanged: (value) => setState(() => _allowMentoring = value),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tags
            _buildSection(
              title: tr(context, 'tags_optional'),
              child: TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(
                  hintText: tr(context, 'enter_tags_comma_separated'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Create Button
            ElevatedButton(
              onPressed: _isCreating ? null : _createCircle,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isCreating ? tr(context, 'creating') : tr(context, 'create_circle'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildTypeSelector(bool isDarkMode) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CircleType.values.map((type) {
        final isSelected = _selectedType == type;
        final color = _getCircleTypeColor(type);

        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.2)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCircleTypeIcon(type),
                  color: isSelected ? color : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _getCircleTypeName(type),
                  style: TextStyle(
                    color: isSelected ? color : Colors.grey,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrivacySelector(bool isDarkMode) {
    return Column(
      children: CirclePrivacy.values.map((privacy) {
        final isSelected = _selectedPrivacy == privacy;
        return GestureDetector(
          onTap: () => setState(() => _selectedPrivacy = privacy),
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isSelected
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPrivacyName(privacy),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getPrivacyDescription(privacy),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSliderSetting({
    required String title,
    required int value,
    required int min,
    required int max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: divisions,
          onChanged: onChanged,
          activeColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeThumbColor: Theme.of(context).primaryColor,
    );
  }

  Color _getCircleTypeColor(CircleType type) {
    switch (type) {
      case CircleType.fitness:
        return Colors.orange;
      case CircleType.nutrition:
        return Colors.green;
      case CircleType.sustainability:
        return Colors.teal;
      case CircleType.family:
        return Colors.pink;
      case CircleType.professional:
        return Colors.blue;
      case CircleType.support:
        return Colors.purple;
    }
  }

  IconData _getCircleTypeIcon(CircleType type) {
    switch (type) {
      case CircleType.fitness:
        return Icons.fitness_center;
      case CircleType.nutrition:
        return Icons.restaurant;
      case CircleType.sustainability:
        return Icons.eco;
      case CircleType.family:
        return Icons.family_restroom;
      case CircleType.professional:
        return Icons.work_outline;
      case CircleType.support:
        return Icons.favorite_outline;
    }
  }

  String _getCircleTypeName(CircleType type) {
    switch (type) {
      case CircleType.fitness:
        return tr(context, 'fitness');
      case CircleType.nutrition:
        return tr(context, 'nutrition');
      case CircleType.sustainability:
        return tr(context, 'sustainability');
      case CircleType.family:
        return tr(context, 'family');
      case CircleType.professional:
        return tr(context, 'professional');
      case CircleType.support:
        return tr(context, 'support');
    }
  }

  String _getPrivacyName(CirclePrivacy privacy) {
    switch (privacy) {
      case CirclePrivacy.public:
        return tr(context, 'public');
      case CirclePrivacy.private:
        return tr(context, 'private');
      case CirclePrivacy.discoverable:
        return tr(context, 'discoverable');
    }
  }

  String _getPrivacyDescription(CirclePrivacy privacy) {
    switch (privacy) {
      case CirclePrivacy.public:
        return tr(context, 'public_description');
      case CirclePrivacy.private:
        return tr(context, 'private_description');
      case CirclePrivacy.discoverable:
        return tr(context, 'discoverable_description');
    }
  }

  Future<void> _createCircle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      await _socialService.createSupporterCircle(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        privacy: _selectedPrivacy,
        tags: tags,
        settings: {
          'maxMembers': _maxMembers,
          'allowMentoring': _allowMentoring,
        },
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'circle_created_successfully')),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create circle: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}