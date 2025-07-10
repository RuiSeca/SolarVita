// lib/screens/profile/settings/preferences/dietary_preferences_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/translation_helper.dart';
import '../account/notifications_screen.dart';
import '../../../../services/notification_service.dart'; // ADD THIS LINE

class DietaryPreferencesScreen extends StatefulWidget {
  const DietaryPreferencesScreen({super.key});

  @override
  State<DietaryPreferencesScreen> createState() =>
      _DietaryPreferencesScreenState();
}

class _DietaryPreferencesScreenState extends State<DietaryPreferencesScreen> {
  final NotificationService _notificationService =
      NotificationService(); // ADD THIS LINE

  // Diet Type
  String _selectedDietType = 'omnivore';

  // Sustainability Preferences
  bool _preferOrganic = true;
  bool _preferLocal = true;
  bool _preferSeasonal = true;
  bool _reduceMeatConsumption = false;
  bool _sustainableSeafood = true;

  // Allergies and Restrictions
  final Set<String> _allergies = {};
  final Set<String> _restrictions = {};

  // Nutrition Goals
  int _dailyCalorieGoal = 2000;
  int _proteinPercentage = 20;
  int _carbsPercentage = 50;
  int _fatPercentage = 30;

  // Meal Preferences and Planning
  int _mealsPerDay = 3;
  bool _enableSnacks = true;
  bool _intermittentFasting = false;

  // Meal Times (for planning, not notifications)
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 12, minute: 30);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _snackTime = const TimeOfDay(hour: 15, minute: 30);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _selectedDietType = prefs.getString('diet_type') ?? 'omnivore';
      _preferOrganic = prefs.getBool('prefer_organic') ?? true;
      _preferLocal = prefs.getBool('prefer_local') ?? true;
      _preferSeasonal = prefs.getBool('prefer_seasonal') ?? true;
      _reduceMeatConsumption = prefs.getBool('reduce_meat') ?? false;
      _sustainableSeafood = prefs.getBool('sustainable_seafood') ?? true;
      _dailyCalorieGoal = prefs.getInt('daily_calorie_goal') ?? 2000;
      _proteinPercentage = prefs.getInt('protein_percentage') ?? 20;
      _carbsPercentage = prefs.getInt('carbs_percentage') ?? 50;
      _fatPercentage = prefs.getInt('fat_percentage') ?? 30;
      _mealsPerDay = prefs.getInt('meals_per_day') ?? 3;
      _enableSnacks = prefs.getBool('enable_snacks') ?? true;
      _intermittentFasting = prefs.getBool('intermittent_fasting') ?? false;

      // Load meal times (for planning purposes)
      _breakfastTime = _loadTimeOfDay(
          prefs, 'breakfast_time', const TimeOfDay(hour: 8, minute: 0));
      _lunchTime = _loadTimeOfDay(
          prefs, 'lunch_time', const TimeOfDay(hour: 12, minute: 30));
      _dinnerTime = _loadTimeOfDay(
          prefs, 'dinner_time', const TimeOfDay(hour: 19, minute: 0));
      _snackTime = _loadTimeOfDay(
          prefs, 'snack_time', const TimeOfDay(hour: 15, minute: 30));

      // Load allergies and restrictions
      final allergiesList = prefs.getStringList('allergies') ?? [];
      final restrictionsList = prefs.getStringList('restrictions') ?? [];
      _allergies.addAll(allergiesList);
      _restrictions.addAll(restrictionsList);
    });
  }

  TimeOfDay _loadTimeOfDay(
      SharedPreferences prefs, String key, TimeOfDay defaultTime) {
    final timeString = prefs.getString(key);
    if (timeString != null) {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return defaultTime;
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      prefs.setString('diet_type', _selectedDietType),
      prefs.setBool('prefer_organic', _preferOrganic),
      prefs.setBool('prefer_local', _preferLocal),
      prefs.setBool('prefer_seasonal', _preferSeasonal),
      prefs.setBool('reduce_meat', _reduceMeatConsumption),
      prefs.setBool('sustainable_seafood', _sustainableSeafood),
      prefs.setInt('daily_calorie_goal', _dailyCalorieGoal),
      prefs.setInt('protein_percentage', _proteinPercentage),
      prefs.setInt('carbs_percentage', _carbsPercentage),
      prefs.setInt('fat_percentage', _fatPercentage),
      prefs.setInt('meals_per_day', _mealsPerDay),
      prefs.setBool('enable_snacks', _enableSnacks),
      prefs.setBool('intermittent_fasting', _intermittentFasting),
      prefs.setStringList('allergies', _allergies.toList()),
      prefs.setStringList('restrictions', _restrictions.toList()),

      // Save meal times (for planning)
      prefs.setString(
          'breakfast_time', '${_breakfastTime.hour}:${_breakfastTime.minute}'),
      prefs.setString('lunch_time', '${_lunchTime.hour}:${_lunchTime.minute}'),
      prefs.setString(
          'dinner_time', '${_dinnerTime.hour}:${_dinnerTime.minute}'),
      prefs.setString('snack_time', '${_snackTime.hour}:${_snackTime.minute}'),
    ]);

    // ADD THIS LINE
    await _scheduleNotificationsBasedOnPreferences();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'preferences_saved')),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _adjustMacros(String changedMacro) {
    final total = _proteinPercentage + _carbsPercentage + _fatPercentage;
    if (total != 100) {
      if (changedMacro != 'protein' && changedMacro != 'carbs') {
        _proteinPercentage = ((100 - _fatPercentage) * 0.3).round();
        _carbsPercentage = 100 - _proteinPercentage - _fatPercentage;
      } else if (changedMacro != 'protein' && changedMacro != 'fat') {
        _proteinPercentage = ((100 - _carbsPercentage) * 0.3).round();
        _fatPercentage = 100 - _proteinPercentage - _carbsPercentage;
      } else if (changedMacro != 'carbs' && changedMacro != 'fat') {
        _carbsPercentage = ((100 - _proteinPercentage) * 0.7).round();
        _fatPercentage = 100 - _proteinPercentage - _carbsPercentage;
      }
    }
  }

  Future<void> _scheduleNotificationsBasedOnPreferences() async {
    // Only schedule if meal reminders are enabled in NotificationService
    if (await _notificationService.mealRemindersEnabled) {
      final now = DateTime.now();

      // Schedule breakfast notification
      final breakfastDateTime = DateTime(
        now.year, now.month, now.day + 1, // Tomorrow
        _breakfastTime.hour, _breakfastTime.minute,
      );

      await _notificationService.scheduleMealReminder(
        mealType: 'breakfast',
        scheduledTime: breakfastDateTime,
      );

      // Schedule lunch notification
      final lunchDateTime = DateTime(
        now.year,
        now.month,
        now.day + 1,
        _lunchTime.hour,
        _lunchTime.minute,
      );

      await _notificationService.scheduleMealReminder(
        mealType: 'lunch',
        scheduledTime: lunchDateTime,
      );

      // Schedule dinner notification
      final dinnerDateTime = DateTime(
        now.year,
        now.month,
        now.day + 1,
        _dinnerTime.hour,
        _dinnerTime.minute,
      );

      await _notificationService.scheduleMealReminder(
        mealType: 'dinner',
        scheduledTime: dinnerDateTime,
      );

      // Schedule snack notification if enabled
      if (_enableSnacks) {
        final snackDateTime = DateTime(
          now.year,
          now.month,
          now.day + 1,
          _snackTime.hour,
          _snackTime.minute,
        );

        await _notificationService.scheduleMealReminder(
          mealType: 'snacks',
          scheduledTime: snackDateTime,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        title: Text(
          tr(context, 'dietary_preferences'),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _savePreferences,
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
            _buildDietTypeSection(),
            const SizedBox(height: 24),
            _buildMealPlanningSection(),
            const SizedBox(height: 24),
            _buildSustainabilitySection(),
            const SizedBox(height: 24),
            _buildAllergiesSection(),
            const SizedBox(height: 24),
            _buildNutritionGoalsSection(),
            const SizedBox(height: 24),
            _buildNotificationNavigationSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.textColor(context).withAlpha(179),
              fontSize: 14,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDietTypeSection() {
    final dietTypes = [
      {
        'key': 'omnivore',
        'icon': Icons.restaurant,
        'description': 'diet_omnivore_desc'
      },
      {
        'key': 'vegetarian',
        'icon': Icons.eco,
        'description': 'diet_vegetarian_desc'
      },
      {
        'key': 'vegan',
        'icon': Icons.eco_outlined,
        'description': 'diet_vegan_desc'
      },
      {
        'key': 'pescatarian',
        'icon': Icons.set_meal,
        'description': 'diet_pescatarian_desc'
      },
      {
        'key': 'keto',
        'icon': Icons.fitness_center,
        'description': 'diet_keto_desc'
      },
      {'key': 'paleo', 'icon': Icons.nature, 'description': 'diet_paleo_desc'},
    ];

    return _buildSection(
      title: tr(context, 'diet_type'),
      children: dietTypes
          .map((diet) => _buildDietTypeCard(
                diet['key'] as String,
                diet['icon'] as IconData,
                diet['description'] as String,
              ))
          .toList(),
    );
  }

  Widget _buildDietTypeCard(
      String dietKey, IconData icon, String descriptionKey) {
    final isSelected = _selectedDietType == dietKey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withAlpha(26)
            : AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: AppTheme.textColor(context).withAlpha(26)),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedDietType = dietKey),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.primary.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(context, 'diet_$dietKey'),
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr(context, descriptionKey),
                      style: TextStyle(
                        color: AppTheme.textColor(context).withAlpha(179),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealPlanningSection() {
    return _buildSection(
      title: tr(context, 'meal_planning'),
      subtitle: tr(context, 'meal_planning_description'),
      children: [
        _buildSliderTile(
          title: tr(context, 'meals_per_day'),
          subtitle: '$_mealsPerDay ${tr(context, 'meals')}',
          value: _mealsPerDay.toDouble(),
          min: 2,
          max: 6,
          divisions: 4,
          onChanged: (value) => setState(() => _mealsPerDay = value.round()),
          icon: Icons.restaurant_menu,
        ),

        _buildSwitchTile(
          title: tr(context, 'enable_snacks'),
          subtitle: tr(context, 'snacks_description'),
          value: _enableSnacks,
          onChanged: (value) => setState(() => _enableSnacks = value),
          icon: Icons.cookie,
        ),

        _buildSwitchTile(
          title: tr(context, 'intermittent_fasting'),
          subtitle: tr(context, 'intermittent_fasting_description'),
          value: _intermittentFasting,
          onChanged: (value) => setState(() => _intermittentFasting = value),
          icon: Icons.schedule,
        ),

        const Divider(),

        // Meal Times for Planning (not notifications)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'preferred_meal_times'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr(context, 'meal_times_planning_description'),
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              _buildMealTimeTile(
                title: tr(context, 'breakfast_time'),
                time: _breakfastTime,
                onTimeChanged: (time) => setState(() => _breakfastTime = time),
                icon: Icons.breakfast_dining,
              ),
              _buildMealTimeTile(
                title: tr(context, 'lunch_time'),
                time: _lunchTime,
                onTimeChanged: (time) => setState(() => _lunchTime = time),
                icon: Icons.lunch_dining,
              ),
              _buildMealTimeTile(
                title: tr(context, 'dinner_time'),
                time: _dinnerTime,
                onTimeChanged: (time) => setState(() => _dinnerTime = time),
                icon: Icons.dinner_dining,
              ),
              if (_enableSnacks)
                _buildMealTimeTile(
                  title: tr(context, 'snack_time'),
                  time: _snackTime,
                  onTimeChanged: (time) => setState(() => _snackTime = time),
                  icon: Icons.restaurant_menu,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealTimeTile({
    required String title,
    required TimeOfDay time,
    required Function(TimeOfDay) onTimeChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              final newTime = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (newTime != null) {
                onTimeChanged(newTime);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                time.format(context),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSustainabilitySection() {
    return _buildSection(
      title: tr(context, 'eco_friendly_choices'),
      subtitle: tr(context, 'eco_choices_description'),
      children: [
        _buildSwitchTile(
          title: tr(context, 'prefer_organic'),
          subtitle: tr(context, 'organic_description'),
          value: _preferOrganic,
          onChanged: (value) => setState(() => _preferOrganic = value),
          icon: Icons.eco,
        ),
        _buildSwitchTile(
          title: tr(context, 'prefer_local'),
          subtitle: tr(context, 'local_description'),
          value: _preferLocal,
          onChanged: (value) => setState(() => _preferLocal = value),
          icon: Icons.location_on,
        ),
        _buildSwitchTile(
          title: tr(context, 'prefer_seasonal'),
          subtitle: tr(context, 'seasonal_description'),
          value: _preferSeasonal,
          onChanged: (value) => setState(() => _preferSeasonal = value),
          icon: Icons.wb_sunny,
        ),
        _buildSwitchTile(
          title: tr(context, 'reduce_meat_consumption'),
          subtitle: tr(context, 'reduce_meat_description'),
          value: _reduceMeatConsumption,
          onChanged: (value) => setState(() => _reduceMeatConsumption = value),
          icon: Icons.forest,
        ),
        _buildSwitchTile(
          title: tr(context, 'sustainable_seafood'),
          subtitle: tr(context, 'sustainable_seafood_description'),
          value: _sustainableSeafood,
          onChanged: (value) => setState(() => _sustainableSeafood = value),
          icon: Icons.waves,
        ),
      ],
    );
  }

  Widget _buildAllergiesSection() {
    final commonAllergies = [
      'nuts',
      'dairy',
      'eggs',
      'fish',
      'shellfish',
      'soy',
      'wheat',
      'gluten',
      'sesame'
    ];

    final commonRestrictions = [
      'halal',
      'kosher',
      'no_pork',
      'no_beef',
      'no_alcohol',
      'low_sodium',
      'low_sugar',
      'diabetic_friendly'
    ];

    return _buildSection(
      title: tr(context, 'allergies_restrictions'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Allergies
              Text(
                tr(context, 'allergies'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: commonAllergies
                    .map(
                      (allergy) => _buildFilterChip(
                        label: tr(context, 'allergy_$allergy'),
                        isSelected: _allergies.contains(allergy),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _allergies.add(allergy);
                            } else {
                              _allergies.remove(allergy);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Dietary Restrictions
              Text(
                tr(context, 'dietary_restrictions'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: commonRestrictions
                    .map(
                      (restriction) => _buildFilterChip(
                        label: tr(context, 'restriction_$restriction'),
                        isSelected: _restrictions.contains(restriction),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _restrictions.add(restriction);
                            } else {
                              _restrictions.remove(restriction);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionGoalsSection() {
    return _buildSection(
      title: tr(context, 'nutrition_goals'),
      children: [
        // Daily Calorie Goal
        _buildSliderTile(
          title: tr(context, 'daily_calorie_goal'),
          subtitle: '$_dailyCalorieGoal ${tr(context, 'calories')}',
          value: _dailyCalorieGoal.toDouble(),
          min: 1200,
          max: 4000,
          divisions: 28,
          onChanged: (value) =>
              setState(() => _dailyCalorieGoal = value.round()),
          icon: Icons.local_fire_department,
        ),

        const Divider(),

        // Macronutrient Distribution
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'macronutrient_distribution'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildMacroSlider(
                title: tr(context, 'protein'),
                percentage: _proteinPercentage,
                color: Colors.red,
                onChanged: (value) {
                  setState(() {
                    _proteinPercentage = value.round();
                    _adjustMacros('protein');
                  });
                },
              ),
              _buildMacroSlider(
                title: tr(context, 'carbs'),
                percentage: _carbsPercentage,
                color: Colors.orange,
                onChanged: (value) {
                  setState(() {
                    _carbsPercentage = value.round();
                    _adjustMacros('carbs');
                  });
                },
              ),
              _buildMacroSlider(
                title: tr(context, 'fat'),
                percentage: _fatPercentage,
                color: Colors.blue,
                onChanged: (value) {
                  setState(() {
                    _fatPercentage = value.round();
                    _adjustMacros('fat');
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationNavigationSection() {
    return _buildSection(
      title: tr(context, 'meal_notifications'),
      children: [
        _buildNavigationTile(
          title: tr(context, 'manage_meal_notifications'),
          subtitle: tr(context, 'meal_notification_settings_description'),
          icon: Icons.notifications_active,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textColor(context).withAlpha(179),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textColor(context).withAlpha(179),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.textColor(context),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.textColor(context).withAlpha(179),
          fontSize: 14,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withAlpha(51),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withAlpha(51),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSlider({
    required String title,
    required int percentage,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withAlpha(51),
              thumbColor: color,
              overlayColor: color.withAlpha(51),
              trackHeight: 4,
            ),
            child: Slider(
              value: percentage.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: AppTheme.cardColor(context),
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color:
            isSelected ? AppColors.primary : AppColors.primary.withAlpha(128),
      ),
    );
  }
}
