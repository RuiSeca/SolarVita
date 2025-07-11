import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../services/user_profile_service.dart';
import '../../providers/user_profile_provider.dart';
import 'diary_preferences_screen.dart';

class SustainabilityPreferencesScreen extends StatefulWidget {
  const SustainabilityPreferencesScreen({super.key});

  @override
  State<SustainabilityPreferencesScreen> createState() => _SustainabilityPreferencesScreenState();
}

class _SustainabilityPreferencesScreenState extends State<SustainabilityPreferencesScreen> {
  final UserProfileService _userProfileService = UserProfileService();
  bool _isLoading = false;

  final List<String> _selectedGoals = [];
  String _carbonFootprintTarget = 'moderate';
  bool _trackWaterUsage = true;
  bool _trackEnergyUsage = true;
  bool _trackWasteReduction = true;
  bool _trackTransportation = true;
  final List<String> _selectedCategories = [];
  bool _receiveEcoTips = true;
  int _ecoTipFrequency = 3;

  final List<String> _sustainabilityGoalOptions = [
    'Reduce Carbon Footprint',
    'Save Water',
    'Reduce Waste',
    'Use Renewable Energy',
    'Sustainable Transportation',
    'Eco-Friendly Shopping',
    'Plant-Based Diet',
    'Energy Conservation',
    'Sustainable Fashion',
    'Green Home',
  ];

  final List<String> _carbonTargetOptions = [
    'low',
    'moderate',
    'high',
  ];

  final List<String> _categoryOptions = [
    'Energy',
    'Water',
    'Waste Management',
    'Transportation',
    'Food & Diet',
    'Shopping',
    'Home & Garden',
    'Travel',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sustainability Preferences'),
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
            _buildGoalsSection(),
            const SizedBox(height: 24),
            _buildCarbonFootprintSection(),
            const SizedBox(height: 24),
            _buildTrackingSection(),
            const SizedBox(height: 24),
            _buildCategoriesSection(),
            const SizedBox(height: 24),
            _buildEcoTipsSection(),
            const SizedBox(height: 32),
            _buildContinueButton(),
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
          'Let\'s set up your sustainability goals',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Help us understand your environmental priorities so we can provide personalized eco-tips and tracking.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What are your sustainability goals?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _sustainabilityGoalOptions.map((goal) {
            final isSelected = _selectedGoals.contains(goal);
            return FilterChip(
              label: Text(goal),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedGoals.add(goal);
                  } else {
                    _selectedGoals.remove(goal);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCarbonFootprintSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s your carbon footprint reduction target?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ..._carbonTargetOptions.map((target) {
          return RadioListTile<String>(
            title: Text(_formatCarbonTarget(target)),
            subtitle: Text(_getCarbonTargetDescription(target)),
            value: target,
            groupValue: _carbonFootprintTarget,
            onChanged: (value) {
              setState(() {
                _carbonFootprintTarget = value!;
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildTrackingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What would you like to track?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('Water Usage'),
          subtitle: const Text('Track daily water consumption'),
          value: _trackWaterUsage,
          onChanged: (bool? value) {
            setState(() {
              _trackWaterUsage = value ?? false;
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Energy Usage'),
          subtitle: const Text('Monitor electricity and gas consumption'),
          value: _trackEnergyUsage,
          onChanged: (bool? value) {
            setState(() {
              _trackEnergyUsage = value ?? false;
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Waste Reduction'),
          subtitle: const Text('Track recycling and waste management'),
          value: _trackWasteReduction,
          onChanged: (bool? value) {
            setState(() {
              _trackWasteReduction = value ?? false;
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Transportation'),
          subtitle: const Text('Monitor travel and commuting habits'),
          value: _trackTransportation,
          onChanged: (bool? value) {
            setState(() {
              _trackTransportation = value ?? false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which eco-categories interest you most?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categoryOptions.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(category);
                  } else {
                    _selectedCategories.remove(category);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEcoTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Eco-Tips Preferences',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Receive Eco-Tips'),
          subtitle: const Text('Get personalized sustainability tips'),
          value: _receiveEcoTips,
          onChanged: (bool value) {
            setState(() {
              _receiveEcoTips = value;
            });
          },
        ),
        if (_receiveEcoTips) ...[
          const SizedBox(height: 12),
          Text(
            'How often would you like to receive eco-tips?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Slider(
            value: _ecoTipFrequency.toDouble(),
            min: 1,
            max: 7,
            divisions: 6,
            label: '$_ecoTipFrequency times per week',
            onChanged: (value) {
              setState(() {
                _ecoTipFrequency = value.round();
              });
            },
          ),
          Text(
            '$_ecoTipFrequency times per week',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveSustainabilityPreferences,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text('Continue'),
      ),
    );
  }

  String _formatCarbonTarget(String target) {
    switch (target) {
      case 'low':
        return 'Low Impact';
      case 'moderate':
        return 'Moderate Reduction';
      case 'high':
        return 'High Impact';
      default:
        return target;
    }
  }

  String _getCarbonTargetDescription(String target) {
    switch (target) {
      case 'low':
        return 'Small changes, gradual improvement';
      case 'moderate':
        return 'Balanced approach with noticeable impact';
      case 'high':
        return 'Significant lifestyle changes for maximum impact';
      default:
        return '';
    }
  }

  Future<void> _saveSustainabilityPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sustainabilityPreferences = SustainabilityPreferences(
        sustainabilityGoals: _selectedGoals,
        carbonFootprintTarget: _carbonFootprintTarget,
        trackWaterUsage: _trackWaterUsage,
        trackEnergyUsage: _trackEnergyUsage,
        trackWasteReduction: _trackWasteReduction,
        trackTransportation: _trackTransportation,
        interestedCategories: _selectedCategories,
        receiveEcoTips: _receiveEcoTips,
        ecoTipFrequency: _ecoTipFrequency,
      );

      final profile = await _userProfileService.getOrCreateUserProfile();
      final updatedProfile = profile.copyWith(
        sustainabilityPreferences: sustainabilityPreferences,
      );
      await _userProfileService.updateUserProfile(updatedProfile);

      if (mounted) {
        // Update the provider with the latest profile
        final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
        await userProfileProvider.refreshUserProfile();
        
        // Check mounted again after async operation
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const DiaryPreferencesScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
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