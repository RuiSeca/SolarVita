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

  // Expansion states
  bool _allergiesExpanded = false;
  bool _restrictionsExpanded = false;

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
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: _isLoading
            ? const Center(child: LottieLoadingWidget())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDietTypeSection(),
                  const SizedBox(height: 20),
                  _buildAllergiesSection(),
                  const SizedBox(height: 20),
                  _buildRestrictionsSection(),
                  const SizedBox(height: 20),
                  _buildSustainabilitySection(),
                  const SizedBox(height: 20),
                  _buildNutritionGoalsSection(),
                  const SizedBox(height: 20),
                  _buildMealPlanningSection(),
                  const SizedBox(height: 24),
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
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.isDarkMode(context) 
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.08),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDietTypeSection() {
    return _buildSection(
      title: tr(context, 'diet_type'),
      icon: Icons.restaurant_rounded,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: _dietTypeOptions.map((type) {
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
                    activeColor: AppColors.primary,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllergiesSection() {
    return _buildSection(
      title: tr(context, 'allergies'),
      icon: Icons.warning_rounded,
      iconColor: Colors.red,
      children: [
        // Preview section when collapsed
        if (!_allergiesExpanded) _buildPreviewTile(
          icon: Icons.warning_rounded,
          iconColor: Colors.red,
          title: tr(context, 'common_allergies'),
          subtitle: tr(context, 'tap_to_view_allergies'),
          previewItems: _commonAllergies.take(4).map((item) => tr(context, item.toLowerCase())).toList(),
          selectedCount: _allergies.length,
          onTap: () => setState(() => _allergiesExpanded = true),
        ),
        
        // Full selection section when expanded
        if (_allergiesExpanded) Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr(context, 'select_allergies'),
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _allergiesExpanded = false),
                    child: Text(
                      tr(context, 'collapse'),
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.red : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textColor(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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
      icon: Icons.block_rounded,
      iconColor: Colors.orange,
      children: [
        // Preview section when collapsed
        if (!_restrictionsExpanded) _buildPreviewTile(
          icon: Icons.block_rounded,
          iconColor: Colors.orange,
          title: tr(context, 'common_restrictions'),
          subtitle: tr(context, 'tap_to_view_restrictions'),
          previewItems: _commonRestrictions.take(4).map((item) => tr(context, item.toLowerCase().replaceAll(' ', '_'))).toList(),
          selectedCount: _restrictions.length,
          onTap: () => setState(() => _restrictionsExpanded = true),
        ),
        
        // Full selection section when expanded
        if (_restrictionsExpanded) Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr(context, 'select_dietary_restrictions'),
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _restrictionsExpanded = false),
                    child: Text(
                      tr(context, 'collapse'),
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
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
                    selectedColor: AppColors.primary,
                    backgroundColor: AppTheme.cardColor(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textColor(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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
      icon: Icons.eco_rounded,
      iconColor: Colors.green,
      children: [
        _buildModernSwitchTile(
          tr(context, 'prefer_organic'),
          tr(context, 'prefer_organic_foods'),
          _preferOrganic,
          (value) => setState(() => _preferOrganic = value),
          Icons.eco_rounded,
          isFirst: true,
        ),
        _buildModernSwitchTile(
          tr(context, 'prefer_local'),
          tr(context, 'support_local_producers'),
          _preferLocal,
          (value) => setState(() => _preferLocal = value),
          Icons.location_on_rounded,
        ),
        _buildModernSwitchTile(
          tr(context, 'prefer_seasonal'),
          tr(context, 'choose_seasonal_produce'),
          _preferSeasonal,
          (value) => setState(() => _preferSeasonal = value),
          Icons.wb_sunny_rounded,
        ),
        _buildModernSwitchTile(
          tr(context, 'reduce_meat_consumption'),
          tr(context, 'lower_environmental_impact'),
          _reduceMeatConsumption,
          (value) => setState(() => _reduceMeatConsumption = value),
          Icons.grass_rounded,
        ),
        _buildModernSwitchTile(
          tr(context, 'sustainable_seafood'),
          tr(context, 'choose_responsibly_sourced_seafood'),
          _sustainableSeafood,
          (value) => setState(() => _sustainableSeafood = value),
          Icons.waves_rounded,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildNutritionGoalsSection() {
    return _buildSection(
      title: tr(context, 'nutrition_goals'),
      icon: Icons.pie_chart_rounded,
      iconColor: Colors.blue,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
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
      icon: Icons.schedule_rounded,
      iconColor: Colors.purple,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
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
              _buildModernSwitchTile(
                tr(context, 'enable_snacks'),
                tr(context, 'include_healthy_snacks'),
                _enableSnacks,
                (value) => setState(() => _enableSnacks = value),
                Icons.cookie_rounded,
                isFirst: true,
              ),
              _buildModernSwitchTile(
                tr(context, 'intermittent_fasting'),
                tr(context, 'time_restricted_eating'),
                _intermittentFasting,
                (value) => setState(() => _intermittentFasting = value),
                Icons.timer_rounded,
                isLast: true,
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
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                displayValue,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.primary.withValues(alpha: 0.3),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.1),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildModernSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: !isLast ? Border(
          bottom: BorderSide(
            color: AppTheme.textColor(context).withValues(alpha: 0.08),
            width: 0.5,
          ),
        ) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon, 
              color: AppColors.primary, 
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textColor(context).withValues(alpha: 0.6),
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _savePreferences,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: LottieLoadingWidget(width: 20, height: 20),
              )
            : Text(
                tr(context, 'save_preferences'),
                style: const TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildPreviewTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<String> previewItems,
    required int selectedCount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (selectedCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$selectedCount',
                                style: TextStyle(
                                  color: iconColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.textColor(context).withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.expand_more_rounded,
                  color: AppTheme.textColor(context).withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: previewItems.map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
            if (previewItems.length < _commonAllergies.length || previewItems.length < _commonRestrictions.length)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  tr(context, 'and_more_options_available'),
                  style: TextStyle(
                    color: AppTheme.textColor(context).withValues(alpha: 0.5),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
