import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../../../providers/riverpod/user_profile_provider.dart';
import '../../../../models/user_profile.dart';
import '../../../../widgets/common/lottie_loading_widget.dart';

class SustainabilityGoalsScreen extends ConsumerStatefulWidget {
  const SustainabilityGoalsScreen({super.key});

  @override
  ConsumerState<SustainabilityGoalsScreen> createState() =>
      _SustainabilityGoalsScreenState();
}

class _SustainabilityGoalsScreenState extends ConsumerState<SustainabilityGoalsScreen> {
  bool _isLoading = false;

  // Current values - will be populated from UserProfile
  List<String> _selectedSustainabilityGoals = [];
  List<String> _ecoFriendlyActivities = [];
  String _transportMode = 'walking';

  // Options
  final List<String> _sustainabilityGoalOptions = [
    'Reduce Carbon Footprint',
    'Minimize Waste',
    'Use Renewable Energy',
    'Support Local Business',
    'Eco-Friendly Transportation',
    'Sustainable Diet',
    'Water Conservation',
    'Plastic-Free Living',
    'Energy Efficiency',
    'Green Exercise',
  ];

  final List<String> _ecoActivityOptions = [
    'Outdoor Workouts',
    'Cycling',
    'Walking/Hiking',
    'Gardening',
    'Beach Cleanup',
    'Tree Planting',
    'Community Gardens',
    'Eco-Tours',
    'Nature Photography',
    'Wildlife Observation',
  ];

  final List<String> _transportOptions = [
    'walking',
    'cycling',
    'public_transport',
    'carpooling',
    'electric_vehicle',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserPreferences();
    });
  }

  void _loadUserPreferences() {
    final userProfileProvider = ref.read(userProfileNotifierProvider);
    final sustainabilityPrefs = userProfileProvider.value?.sustainabilityPreferences;
    
    if (sustainabilityPrefs != null) {
      setState(() {
        _selectedSustainabilityGoals = List<String>.from(sustainabilityPrefs.sustainabilityGoals);
        _ecoFriendlyActivities = List<String>.from(sustainabilityPrefs.ecoFriendlyActivities);
        _transportMode = sustainabilityPrefs.preferredTransportMode;
      });
    }
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedSustainabilityPrefs = SustainabilityPreferences(
        sustainabilityGoals: _selectedSustainabilityGoals,
        ecoFriendlyActivities: _ecoFriendlyActivities,
        preferredTransportMode: _transportMode,
      );

      await ref.read(userProfileNotifierProvider.notifier).updateSustainabilityPreferences(updatedSustainabilityPrefs);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sustainability preferences updated successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating preferences: $e'),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        title: Text(
          'Sustainability Preferences',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: LottieLoadingWidget())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSustainabilityGoalsSection(),
                  const SizedBox(height: 24),
                  _buildEcoActivitiesSection(),
                  const SizedBox(height: 24),
                  _buildTransportModeSection(),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    IconData? icon,
    Color? iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textColor(context).withAlpha(26),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSustainabilityGoalsSection() {
    return _buildSection(
      title: 'Sustainability Goals',
      icon: Icons.eco,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select your sustainability goals:',
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sustainabilityGoalOptions.map((goal) {
                  final isSelected = _selectedSustainabilityGoals.contains(goal);
                  return FilterChip(
                    selected: isSelected,
                    label: Text(goal),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppTheme.cardColor(context),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textColor(context),
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSustainabilityGoals.add(goal);
                        } else {
                          _selectedSustainabilityGoals.remove(goal);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEcoActivitiesSection() {
    return _buildSection(
      title: 'Eco-Friendly Activities',
      icon: Icons.nature_people,
      iconColor: Colors.green,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select activities you enjoy:',
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _ecoActivityOptions.map((activity) {
                  final isSelected = _ecoFriendlyActivities.contains(activity);
                  return FilterChip(
                    selected: isSelected,
                    label: Text(activity),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppTheme.cardColor(context),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textColor(context),
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _ecoFriendlyActivities.add(activity);
                        } else {
                          _ecoFriendlyActivities.remove(activity);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransportModeSection() {
    return _buildSection(
      title: 'Preferred Transport Mode',
      icon: Icons.directions_bike,
      iconColor: Colors.blue,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._transportOptions.map((mode) {
                return RadioListTile<String>(
                  value: mode,
                  groupValue: _transportMode,
                  onChanged: (value) {
                    setState(() {
                      _transportMode = value!;
                    });
                  },
                  title: Text(
                    mode.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  activeColor: AppColors.primary,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _savePreferences,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: LottieLoadingWidget(width: 20, height: 20),
              )
            : const Text(
                'Save Preferences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}