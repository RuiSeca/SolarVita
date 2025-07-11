import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../services/user_profile_service.dart';
import '../../providers/user_profile_provider.dart';

class DiaryPreferencesScreen extends StatefulWidget {
  const DiaryPreferencesScreen({super.key});

  @override
  State<DiaryPreferencesScreen> createState() => _DiaryPreferencesScreenState();
}

class _DiaryPreferencesScreenState extends State<DiaryPreferencesScreen> {
  final UserProfileService _userProfileService = UserProfileService();
  bool _isLoading = false;

  bool _enableDailyReminders = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  final List<String> _selectedTrackingCategories = ['workout', 'nutrition', 'mood', 'sustainability'];
  bool _enableMoodTracking = true;
  bool _enableGoalTracking = true;
  bool _enableProgressPhotos = false;
  bool _privateByDefault = true;
  String _defaultTemplate = 'daily_summary';

  final List<String> _trackingCategoryOptions = [
    'workout',
    'nutrition',
    'mood',
    'sustainability',
    'sleep',
    'energy',
    'social',
    'productivity',
    'gratitude',
    'challenges',
  ];

  final List<String> _templateOptions = [
    'daily_summary',
    'detailed_log',
    'quick_notes',
    'custom',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary Preferences'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildRemindersSection(),
            const SizedBox(height: 24),
            _buildTrackingCategoriesSection(),
            const SizedBox(height: 24),
            _buildFeaturesSection(),
            const SizedBox(height: 24),
            _buildPrivacySection(),
            const SizedBox(height: 24),
            _buildTemplateSection(),
            const SizedBox(height: 32),
            _buildCompleteButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set up your personal diary',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Customize your diary experience to track your progress and reflect on your journey.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRemindersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Reminders',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Enable Daily Reminders'),
          subtitle: const Text('Get reminded to update your diary'),
          value: _enableDailyReminders,
          onChanged: (bool value) {
            setState(() {
              _enableDailyReminders = value;
            });
          },
        ),
        if (_enableDailyReminders) ...[
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Reminder Time'),
            subtitle: Text(_formatTime(_reminderTime)),
            trailing: const Icon(Icons.access_time),
            onTap: _selectReminderTime,
          ),
        ],
      ],
    );
  }

  Widget _buildTrackingCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What would you like to track in your diary?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _trackingCategoryOptions.map((category) {
            final isSelected = _selectedTrackingCategories.contains(category);
            return FilterChip(
              label: Text(_formatCategoryName(category)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTrackingCategories.add(category);
                  } else {
                    _selectedTrackingCategories.remove(category);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diary Features',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Mood Tracking'),
          subtitle: const Text('Track your daily mood and emotions'),
          value: _enableMoodTracking,
          onChanged: (bool value) {
            setState(() {
              _enableMoodTracking = value;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Goal Tracking'),
          subtitle: const Text('Monitor progress towards your goals'),
          value: _enableGoalTracking,
          onChanged: (bool value) {
            setState(() {
              _enableGoalTracking = value;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Progress Photos'),
          subtitle: const Text('Add photos to track visual progress'),
          value: _enableProgressPhotos,
          onChanged: (bool value) {
            setState(() {
              _enableProgressPhotos = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Private by Default'),
          subtitle: const Text('Keep diary entries private unless you choose to share'),
          value: _privateByDefault,
          onChanged: (bool value) {
            setState(() {
              _privateByDefault = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTemplateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Default Template',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ..._templateOptions.map((template) {
          return RadioListTile<String>(
            title: Text(_formatTemplateName(template)),
            subtitle: Text(_getTemplateDescription(template)),
            value: template,
            groupValue: _defaultTemplate,
            onChanged: (value) {
              setState(() {
                _defaultTemplate = value!;
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _completeOnboarding,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text('Complete Setup'),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatCategoryName(String category) {
    return category.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  String _formatTemplateName(String template) {
    switch (template) {
      case 'daily_summary':
        return 'Daily Summary';
      case 'detailed_log':
        return 'Detailed Log';
      case 'quick_notes':
        return 'Quick Notes';
      case 'custom':
        return 'Custom';
      default:
        return template;
    }
  }

  String _getTemplateDescription(String template) {
    switch (template) {
      case 'daily_summary':
        return 'Brief overview of your day';
      case 'detailed_log':
        return 'Comprehensive daily tracking';
      case 'quick_notes':
        return 'Simple note-taking format';
      case 'custom':
        return 'Create your own template';
      default:
        return '';
    }
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    if (_selectedTrackingCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one tracking category'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final diaryPreferences = DiaryPreferences(
        enableDailyReminders: _enableDailyReminders,
        reminderTime: _formatTime(_reminderTime),
        trackingCategories: _selectedTrackingCategories,
        enableMoodTracking: _enableMoodTracking,
        enableGoalTracking: _enableGoalTracking,
        enableProgressPhotos: _enableProgressPhotos,
        privateByDefault: _privateByDefault,
        defaultTemplate: _defaultTemplate,
      );

      final profile = await _userProfileService.getOrCreateUserProfile();
      final updatedProfile = profile.copyWith(
        diaryPreferences: diaryPreferences,
        isOnboardingComplete: true,
      );
      await _userProfileService.updateUserProfile(updatedProfile);

      if (mounted) {
        // Update the provider so the main app can handle navigation
        final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
        await userProfileProvider.refreshUserProfile();
        
        // Check mounted again after async operation
        if (mounted) {
          // Navigate to main app route instead of directly to dashboard
          Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing setup: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}