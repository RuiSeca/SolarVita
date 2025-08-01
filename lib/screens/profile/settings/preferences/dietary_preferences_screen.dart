import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/translation_helper.dart';
import '../../../../providers/riverpod/user_profile_provider.dart';
import '../../../../models/user/user_profile.dart';
import '../../../../widgets/common/lottie_loading_widget.dart';

class DietaryPreferencesScreen extends ConsumerStatefulWidget {
  const DietaryPreferencesScreen({super.key});

  @override
  ConsumerState<DietaryPreferencesScreen> createState() =>
      _DietaryPreferencesScreenState();
}

class _DietaryPreferencesScreenState
    extends ConsumerState<DietaryPreferencesScreen> {
  bool _isLoading = false;

  // Current values - will be populated from UserProfile
  String _selectedDietType = 'omnivore';
  List<String> _allergies = [];
  List<String> _restrictions = [];
  bool _preferOrganic = true;
  bool _preferLocal = true;
  bool _preferSeasonal = true;
  bool _reduceMeatConsumption = false;
  bool _sustainableSeafood = true;
  int _dailyCalorieGoal = 2000;
  int _proteinPercentage = 20;
  int _carbsPercentage = 50;
  int _fatPercentage = 30;
  int _mealsPerDay = 3;
  bool _enableSnacks = true;
  bool _intermittentFasting = false;
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 12, minute: 30);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _snackTime = const TimeOfDay(hour: 15, minute: 30);

  // Options
  final List<String> _dietTypeOptions = [
    'omnivore',
    'vegetarian',
    'vegan',
    'pescatarian',
    'keto',
    'paleo',
    'mediterranean',
    'gluten_free',
    'low_carb',
    'intermittent_fasting',
  ];

  final List<String> _commonAllergies = [
    'Nuts',
    'Dairy',
    'Eggs',
    'Soy',
    'Gluten',
    'Shellfish',
    'Fish',
    'Sesame',
  ];

  final List<String> _commonRestrictions = [
    'Halal',
    'Kosher',
    'No Red Meat',
    'No Pork',
    'Low Sodium',
    'Low Sugar',
    'Organic Only',
    'Non-GMO',
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
    final dietaryPrefs = userProfileProvider.value?.dietaryPreferences;

    if (dietaryPrefs != null) {
      setState(() {
        _selectedDietType = dietaryPrefs.dietType;
        _allergies = List<String>.from(dietaryPrefs.allergies);
        _restrictions = List<String>.from(dietaryPrefs.restrictions);
        _preferOrganic = dietaryPrefs.preferOrganic;
        _preferLocal = dietaryPrefs.preferLocal;
        _preferSeasonal = dietaryPrefs.preferSeasonal;
        _reduceMeatConsumption = dietaryPrefs.reduceMeatConsumption;
        _sustainableSeafood = dietaryPrefs.sustainableSeafood;
        _dailyCalorieGoal = dietaryPrefs.dailyCalorieGoal;
        _proteinPercentage = dietaryPrefs.proteinPercentage;
        _carbsPercentage = dietaryPrefs.carbsPercentage;
        _fatPercentage = dietaryPrefs.fatPercentage;
        _mealsPerDay = dietaryPrefs.mealsPerDay;
        _enableSnacks = dietaryPrefs.enableSnacks;
        _intermittentFasting = dietaryPrefs.intermittentFasting;
        _breakfastTime = _parseTimeOfDay(dietaryPrefs.breakfastTime);
        _lunchTime = _parseTimeOfDay(dietaryPrefs.lunchTime);
        _dinnerTime = _parseTimeOfDay(dietaryPrefs.dinnerTime);
        _snackTime = _parseTimeOfDay(dietaryPrefs.snackTime);
      });
    }
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedDietaryPrefs = DietaryPreferences(
        dietType: _selectedDietType,
        allergies: _allergies,
        restrictions: _restrictions,
        preferOrganic: _preferOrganic,
        preferLocal: _preferLocal,
        preferSeasonal: _preferSeasonal,
        reduceMeatConsumption: _reduceMeatConsumption,
        sustainableSeafood: _sustainableSeafood,
        dailyCalorieGoal: _dailyCalorieGoal,
        proteinPercentage: _proteinPercentage,
        carbsPercentage: _carbsPercentage,
        fatPercentage: _fatPercentage,
        mealsPerDay: _mealsPerDay,
        enableSnacks: _enableSnacks,
        intermittentFasting: _intermittentFasting,
        breakfastTime: _formatTimeOfDay(_breakfastTime),
        lunchTime: _formatTimeOfDay(_lunchTime),
        dinnerTime: _formatTimeOfDay(_dinnerTime),
        snackTime: _formatTimeOfDay(_snackTime),
      );

      await ref
          .read(userProfileNotifierProvider.notifier)
          .updateDietaryPreferences(updatedDietaryPrefs);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'dietary_preferences_updated')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_updating_preferences').replaceAll('{error}', '$e')),
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
          tr(context, 'dietary_preferences'),
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
                  _buildDietTypeSection(),
                  const SizedBox(height: 24),
                  _buildAllergiesSection(),
                  const SizedBox(height: 24),
                  _buildRestrictionsSection(),
                  const SizedBox(height: 24),
                  _buildSustainabilitySection(),
                  const SizedBox(height: 24),
                  _buildNutritionGoalsSection(),
                  const SizedBox(height: 24),
                  _buildMealPlanningSection(),
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
              Icon(
                icon,
                color: iconColor ?? Theme.of(context).primaryColor,
                size: 24,
              ),
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

  Widget _buildDietTypeSection() {
    return _buildSection(
      title: tr(context, 'diet_type'),
      icon: Icons.restaurant,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._dietTypeOptions.map((type) {
                return RadioListTile<String>(
                  value: type,
                  groupValue: _selectedDietType,
                  onChanged: (value) {
                    setState(() {
                      _selectedDietType = value!;
                    });
                  },
                  title: Text(
                    tr(context, type),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  activeColor: Theme.of(context).primaryColor,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllergiesSection() {
    return _buildSection(
      title: tr(context, 'allergies'),
      icon: Icons.warning,
      iconColor: Colors.red,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'select_allergies'),
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonAllergies.map((allergy) {
                  final isSelected = _allergies.contains(allergy);
                  return FilterChip(
                    selected: isSelected,
                    label: Text(tr(context, allergy.toLowerCase())),
                    selectedColor: Colors.red,
                    backgroundColor: AppTheme.cardColor(context),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textColor(context),
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _allergies.add(allergy);
                        } else {
                          _allergies.remove(allergy);
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

  Widget _buildRestrictionsSection() {
    return _buildSection(
      title: tr(context, 'dietary_restrictions'),
      icon: Icons.block,
      iconColor: Colors.orange,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'select_dietary_restrictions'),
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonRestrictions.map((restriction) {
                  final isSelected = _restrictions.contains(restriction);
                  return FilterChip(
                    selected: isSelected,
                    label: Text(tr(context, restriction.toLowerCase().replaceAll(' ', '_'))),
                    selectedColor: Theme.of(context).primaryColor,
                    backgroundColor: AppTheme.cardColor(context),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textColor(context),
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _restrictions.add(restriction);
                        } else {
                          _restrictions.remove(restriction);
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

  Widget _buildSustainabilitySection() {
    return _buildSection(
      title: tr(context, 'sustainability_preferences_section'),
      icon: Icons.eco,
      iconColor: Colors.green,
      children: [
        SwitchListTile(
          title: Text(
            tr(context, 'prefer_organic'),
            style: TextStyle(color: AppTheme.textColor(context)),
          ),
          value: _preferOrganic,
          onChanged: (value) => setState(() => _preferOrganic = value),
          activeColor: Theme.of(context).primaryColor,
        ),
        SwitchListTile(
          title: Text(
            tr(context, 'prefer_local'),
            style: TextStyle(color: AppTheme.textColor(context)),
          ),
          value: _preferLocal,
          onChanged: (value) => setState(() => _preferLocal = value),
          activeColor: Theme.of(context).primaryColor,
        ),
        SwitchListTile(
          title: Text(
            tr(context, 'prefer_seasonal'),
            style: TextStyle(color: AppTheme.textColor(context)),
          ),
          value: _preferSeasonal,
          onChanged: (value) => setState(() => _preferSeasonal = value),
          activeColor: Theme.of(context).primaryColor,
        ),
        SwitchListTile(
          title: Text(
            tr(context, 'reduce_meat_consumption'),
            style: TextStyle(color: AppTheme.textColor(context)),
          ),
          value: _reduceMeatConsumption,
          onChanged: (value) => setState(() => _reduceMeatConsumption = value),
          activeColor: Theme.of(context).primaryColor,
        ),
        SwitchListTile(
          title: Text(
            tr(context, 'sustainable_seafood'),
            style: TextStyle(color: AppTheme.textColor(context)),
          ),
          value: _sustainableSeafood,
          onChanged: (value) => setState(() => _sustainableSeafood = value),
          activeColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }

  Widget _buildNutritionGoalsSection() {
    return _buildSection(
      title: tr(context, 'nutrition_goals'),
      icon: Icons.pie_chart,
      iconColor: Colors.blue,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSliderTile(
                tr(context, 'daily_calorie_goal'),
                _dailyCalorieGoal.toDouble(),
                1200,
                3000,
                (value) => setState(() => _dailyCalorieGoal = value.round()),
                tr(context, 'kcal_label').replaceAll('{count}', '$_dailyCalorieGoal'),
              ),
              const SizedBox(height: 16),
              _buildSliderTile(
                tr(context, 'protein_percentage'),
                _proteinPercentage.toDouble(),
                10,
                40,
                (value) => setState(() => _proteinPercentage = value.round()),
                tr(context, 'percentage_label').replaceAll('{count}', '$_proteinPercentage'),
              ),
              const SizedBox(height: 16),
              _buildSliderTile(
                tr(context, 'carbs_percentage'),
                _carbsPercentage.toDouble(),
                20,
                70,
                (value) => setState(() => _carbsPercentage = value.round()),
                tr(context, 'percentage_label').replaceAll('{count}', '$_carbsPercentage'),
              ),
              const SizedBox(height: 16),
              _buildSliderTile(
                tr(context, 'fat_percentage'),
                _fatPercentage.toDouble(),
                15,
                50,
                (value) => setState(() => _fatPercentage = value.round()),
                tr(context, 'percentage_label').replaceAll('{count}', '$_fatPercentage'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealPlanningSection() {
    return _buildSection(
      title: tr(context, 'meal_planning'),
      icon: Icons.schedule,
      iconColor: Colors.purple,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSliderTile(
                tr(context, 'meals_per_day'),
                _mealsPerDay.toDouble(),
                2,
                6,
                (value) => setState(() => _mealsPerDay = value.round()),
                tr(context, 'meals_label').replaceAll('{count}', '$_mealsPerDay'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(
                  tr(context, 'enable_snacks'),
                  style: TextStyle(color: AppTheme.textColor(context)),
                ),
                value: _enableSnacks,
                onChanged: (value) => setState(() => _enableSnacks = value),
                activeColor: Theme.of(context).primaryColor,
              ),
              SwitchListTile(
                title: Text(
                  tr(context, 'intermittent_fasting'),
                  style: TextStyle(color: AppTheme.textColor(context)),
                ),
                value: _intermittentFasting,
                onChanged: (value) =>
                    setState(() => _intermittentFasting = value),
                activeColor: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliderTile(
    String title,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    String displayValue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(26),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                displayValue,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: Theme.of(context).primaryColor,
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
            : Text(
                tr(context, 'save_preferences'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
