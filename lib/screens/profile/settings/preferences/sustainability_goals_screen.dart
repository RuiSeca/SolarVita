// lib/screens/profile/settings/preferences/sustainability_goals_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../theme/app_theme.dart';
import '../../../../utils/translation_helper.dart';
import '../../../../services/notification_service.dart';

class SustainabilityGoalsScreen extends StatefulWidget {
  const SustainabilityGoalsScreen({super.key});

  @override
  State<SustainabilityGoalsScreen> createState() =>
      _SustainabilityGoalsScreenState();
}

class _SustainabilityGoalsScreenState extends State<SustainabilityGoalsScreen> {
  final NotificationService _notificationService = NotificationService();

  // Goal categories and their current values
  Map<String, SustainabilityGoal> _goals = {};
  bool _isLoading = true;

  // Achievement thresholds
  final Map<String, List<int>> _achievementLevels = {
    'carbon_reduction': [50, 100, 250, 500, 1000], // kg CO2
    'eco_workouts': [10, 25, 50, 100, 200], // number of eco workouts
    'active_transport': [50, 100, 250, 500, 1000], // km walked/biked
    'waste_reduction': [20, 50, 100, 200, 365], // plastic items saved
    'sustainable_meals': [25, 50, 100, 250, 500], // eco-friendly meals
    'energy_conservation': [30, 60, 120, 250, 500], // kWh saved
  };

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goalsJson = prefs.getString('sustainability_goals');

      if (goalsJson != null) {
        final goalsMap = json.decode(goalsJson) as Map<String, dynamic>;
        _goals = goalsMap.map(
            (key, value) => MapEntry(key, SustainabilityGoal.fromJson(value)));
      } else {
        _initializeDefaultGoals();
      }
    } catch (e) {
      _initializeDefaultGoals();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initializeDefaultGoals() {
    _goals = {
      'carbon_reduction': SustainabilityGoal(
        id: 'carbon_reduction',
        titleKey: 'goal_carbon_reduction_title',
        descriptionKey: 'goal_carbon_reduction_desc',
        currentValue: 0,
        targetValue: 100,
        unitKey: 'unit_kg_co2',
        iconData: Icons.eco,
        color: Colors.green,
        category: GoalCategory.environment,
      ),
      'eco_workouts': SustainabilityGoal(
        id: 'eco_workouts',
        titleKey: 'goal_eco_workouts_title',
        descriptionKey: 'goal_eco_workouts_desc',
        currentValue: 0,
        targetValue: 25,
        unitKey: 'unit_workouts',
        iconData: Icons.nature_people,
        color: Colors.lightGreen,
        category: GoalCategory.fitness,
      ),
      'active_transport': SustainabilityGoal(
        id: 'active_transport',
        titleKey: 'goal_active_transport_title',
        descriptionKey: 'goal_active_transport_desc',
        currentValue: 0,
        targetValue: 100,
        unitKey: 'unit_km',
        iconData: Icons.directions_bike,
        color: Colors.blue,
        category: GoalCategory.transport,
      ),
      'waste_reduction': SustainabilityGoal(
        id: 'waste_reduction',
        titleKey: 'goal_waste_reduction_title',
        descriptionKey: 'goal_waste_reduction_desc',
        currentValue: 0,
        targetValue: 50,
        unitKey: 'unit_items_saved',
        iconData: Icons.recycling,
        color: Colors.orange,
        category: GoalCategory.waste,
      ),
      'sustainable_meals': SustainabilityGoal(
        id: 'sustainable_meals',
        titleKey: 'goal_sustainable_meals_title',
        descriptionKey: 'goal_sustainable_meals_desc',
        currentValue: 0,
        targetValue: 50,
        unitKey: 'unit_eco_meals',
        iconData: Icons.restaurant_menu,
        color: Colors.purple,
        category: GoalCategory.nutrition,
      ),
      'energy_conservation': SustainabilityGoal(
        id: 'energy_conservation',
        titleKey: 'goal_energy_conservation_title',
        descriptionKey: 'goal_energy_conservation_desc',
        currentValue: 0,
        targetValue: 60,
        unitKey: 'unit_kwh_saved',
        iconData: Icons.flash_off,
        color: Colors.amber,
        category: GoalCategory.energy,
      ),
    };
  }

  Future<void> _saveGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goalsJson = json
          .encode(_goals.map((key, value) => MapEntry(key, value.toJson())));
      await prefs.setString('sustainability_goals', goalsJson);
    } catch (e) {
      debugPrint('Error saving sustainability goals: $e');
    }
  }

  void _updateGoalTarget(String goalId, double newTarget) {
    setState(() {
      _goals[goalId] = _goals[goalId]!.copyWith(targetValue: newTarget);
    });
    _saveGoals();
  }

  void _addProgress(String goalId, double amount) {
    final goal = _goals[goalId]!;
    final newValue = goal.currentValue + amount;

    setState(() {
      _goals[goalId] = goal.copyWith(currentValue: newValue);
    });

    _saveGoals();
    _checkForAchievements(goalId, newValue);
  }

  void _checkForAchievements(String goalId, double newValue) {
    final levels = _achievementLevels[goalId];
    if (levels != null) {
      for (int level in levels) {
        if (newValue >= level && _goals[goalId]!.currentValue < level) {
          _showAchievementDialog(goalId, level);
          _notificationService.sendProgressCelebration(
            achievement: tr(context, 'sustainability_milestone'),
            message: tr(context, 'milestone_message')
                .replaceAll('{level}', level.toString())
                .replaceAll('{unit}', tr(context, _goals[goalId]!.unitKey))
                .replaceAll('{title}', tr(context, _goals[goalId]!.titleKey)),
          );
          break;
        }
      }
    }
  }

  void _showAchievementDialog(String goalId, int level) {
    final goal = _goals[goalId]!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: AppColors.gold, size: 32),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tr(context, 'achievement_unlocked'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(goal.iconData, size: 64, color: goal.color),
            const SizedBox(height: 16),
            Text(
              '${tr(context, goal.titleKey)}\n$level ${tr(context, goal.unitKey)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'awesome'),
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.surfaceColor(context),
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceColor(context),
          title: Text(
            tr(context, 'sustainability_goals'),
            style: TextStyle(color: AppTheme.textColor(context)),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        title: Text(
          tr(context, 'sustainability_goals'),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: AppTheme.textColor(context)),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          _buildOverviewHeader(),
          _buildGoalCategories(),
          _buildQuickActions(),
          _buildTipsSection(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildOverviewHeader() {
    final totalGoals = _goals.length;
    final completedGoals = _goals.values
        .where((goal) => goal.currentValue >= goal.targetValue)
        .length;
    final totalProgress = _goals.values
            .map((goal) =>
                (goal.currentValue / goal.targetValue).clamp(0.0, 1.0))
            .reduce((a, b) => a + b) /
        totalGoals;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withAlpha(179)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(77),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.eco, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(context, 'your_eco_impact'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tr(context, 'goals_completed_status')
                            .replaceAll(
                                '{completed}', completedGoals.toString())
                            .replaceAll('{total}', totalGoals.toString()),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: totalProgress,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Text(
              tr(context, 'overall_progress').replaceAll(
                  '{progress}', (totalProgress * 100).toInt().toString()),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCategories() {
    final groupedGoals = <GoalCategory, List<SustainabilityGoal>>{};

    for (var goal in _goals.values) {
      if (!groupedGoals.containsKey(goal.category)) {
        groupedGoals[goal.category] = [];
      }
      groupedGoals[goal.category]!.add(goal);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final category = groupedGoals.keys.elementAt(index);
          final goals = groupedGoals[category]!;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    tr(context, _getCategoryTitleKey(category)),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...goals.map((goal) => _buildGoalCard(goal)),
              ],
            ),
          );
        },
        childCount: groupedGoals.length,
      ),
    );
  }

  Widget _buildGoalCard(SustainabilityGoal goal) {
    final progress = (goal.currentValue / goal.targetValue).clamp(0.0, 1.0);
    final isCompleted = goal.currentValue >= goal.targetValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border:
            isCompleted ? Border.all(color: AppColors.gold, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: goal.color.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(goal.iconData, color: goal.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tr(context, goal.titleKey),
                              style: TextStyle(
                                color: AppTheme.textColor(context),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isCompleted)
                            Icon(Icons.check_circle,
                                color: AppColors.gold, size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr(context, goal.descriptionKey),
                        style: TextStyle(
                          color: AppTheme.textColor(context).withAlpha(179),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: goal.color.withAlpha(51),
                        valueColor: AlwaysStoppedAnimation<Color>(goal.color),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${goal.currentValue.toInt()} / ${goal.targetValue.toInt()} ${tr(context, goal.unitKey)}',
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            tr(context, 'percentage_format').replaceAll(
                                '{value}', (progress * 100).toInt().toString()),
                            style: TextStyle(
                              color: goal.color,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.edit,
                      onPressed: () => _showEditGoalDialog(goal),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.add,
                      onPressed: () => _showAddProgressDialog(goal),
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 18),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(context, 'quick_actions'),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildQuickActionCard(
                  tr(context, 'quick_log_eco_workout'),
                  Icons.nature_people,
                  Colors.green,
                  () => _addProgress('eco_workouts', 1),
                ),
                _buildQuickActionCard(
                  tr(context, 'quick_track_transport'),
                  Icons.directions_bike,
                  Colors.blue,
                  () => _showQuickAddDialog('active_transport'),
                ),
                _buildQuickActionCard(
                  tr(context, 'quick_save_plastic'),
                  Icons.recycling,
                  Colors.orange,
                  () => _addProgress('waste_reduction', 1),
                ),
                _buildQuickActionCard(
                  tr(context, 'quick_eco_meal'),
                  Icons.restaurant_menu,
                  Colors.purple,
                  () => _addProgress('sustainable_meals', 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  tr(context, 'sustainability_tips'),
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._getSustainabilityTips().map((tipKey) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          tr(context, tipKey),
                          style: TextStyle(
                            color: AppTheme.textColor(context).withAlpha(204),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  List<String> _getSustainabilityTips() {
    return [
      'tip_active_transport',
      'tip_reusable_bottle',
      'tip_plant_based_protein',
      'tip_outdoor_exercise',
      'tip_meal_prep',
      'tip_energy_conservation',
    ];
  }

  String _getCategoryTitleKey(GoalCategory category) {
    switch (category) {
      case GoalCategory.environment:
        return 'category_environmental_impact';
      case GoalCategory.fitness:
        return 'category_eco_friendly_fitness';
      case GoalCategory.transport:
        return 'category_sustainable_transport';
      case GoalCategory.waste:
        return 'category_waste_reduction';
      case GoalCategory.nutrition:
        return 'category_sustainable_nutrition';
      case GoalCategory.energy:
        return 'category_energy_conservation';
    }
  }

  void _showEditGoalDialog(SustainabilityGoal goal) {
    final controller = TextEditingController(text: goal.targetValue.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          tr(context, 'edit_goal_title')
              .replaceAll('{goal}', tr(context, goal.titleKey)),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppTheme.textColor(context)),
              decoration: InputDecoration(
                labelText: tr(context, 'target_label')
                    .replaceAll('{unit}', tr(context, goal.unitKey)),
                labelStyle: TextStyle(
                    color: AppTheme.textColor(context).withAlpha(179)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel'),
                style: TextStyle(color: AppTheme.textColor(context))),
          ),
          TextButton(
            onPressed: () {
              final newTarget = double.tryParse(controller.text);
              if (newTarget != null && newTarget > 0) {
                _updateGoalTarget(goal.id, newTarget);
                Navigator.pop(context);
              }
            },
            child: Text(tr(context, 'save'),
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showAddProgressDialog(SustainabilityGoal goal) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          tr(context, 'add_progress_title')
              .replaceAll('{goal}', tr(context, goal.titleKey)),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppTheme.textColor(context)),
              decoration: InputDecoration(
                labelText: tr(context, 'amount_label')
                    .replaceAll('{unit}', tr(context, goal.unitKey)),
                labelStyle: TextStyle(
                    color: AppTheme.textColor(context).withAlpha(179)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel'),
                style: TextStyle(color: AppTheme.textColor(context))),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                _addProgress(goal.id, amount);
                Navigator.pop(context);
              }
            },
            child: Text(tr(context, 'add'),
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showQuickAddDialog(String goalId) {
    final goal = _goals[goalId]!;
    final suggestions = _getQuickAddSuggestions(goalId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textColor(context).withAlpha(51),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                tr(context, 'quick_add_title')
                    .replaceAll('{goal}', tr(context, goal.titleKey)),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...suggestions.map((suggestion) => ListTile(
                  leading: Icon(suggestion['icon'], color: goal.color),
                  title: Text(
                    tr(context, suggestion['titleKey']),
                    style: TextStyle(color: AppTheme.textColor(context)),
                  ),
                  subtitle: Text(
                    '${suggestion['value']} ${tr(context, goal.unitKey)}',
                    style: TextStyle(
                        color: AppTheme.textColor(context).withAlpha(179)),
                  ),
                  onTap: () {
                    _addProgress(goalId, suggestion['value'].toDouble());
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getQuickAddSuggestions(String goalId) {
    switch (goalId) {
      case 'active_transport':
        return [
          {
            'titleKey': 'quick_short_walk',
            'value': 1,
            'icon': Icons.directions_walk
          },
          {
            'titleKey': 'quick_bike_ride_30',
            'value': 5,
            'icon': Icons.directions_bike
          },
          {
            'titleKey': 'quick_long_bike_ride',
            'value': 15,
            'icon': Icons.directions_bike
          },
          {
            'titleKey': 'quick_walking_commute',
            'value': 3,
            'icon': Icons.directions_walk
          },
        ];
      case 'energy_conservation':
        return [
          {
            'titleKey': 'quick_turned_off_lights',
            'value': 1,
            'icon': Icons.lightbulb_outline
          },
          {'titleKey': 'quick_used_stairs', 'value': 0.5, 'icon': Icons.stairs},
          {
            'titleKey': 'quick_air_dried_clothes',
            'value': 3,
            'icon': Icons.dry_cleaning
          },
          {
            'titleKey': 'quick_unplugged_devices',
            'value': 2,
            'icon': Icons.power_off
          },
        ];
      default:
        return [];
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Row(
          children: [
            Icon(Icons.info, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              tr(context, 'about_sustainability_goals'),
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
          ],
        ),
        content: Text(
          tr(context, 'sustainability_goals_info'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'got_it'),
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// Supporting classes
enum GoalCategory {
  environment,
  fitness,
  transport,
  waste,
  nutrition,
  energy,
}

class SustainabilityGoal {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final double currentValue;
  final double targetValue;
  final String unitKey;
  final IconData iconData;
  final Color color;
  final GoalCategory category;

  SustainabilityGoal({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.currentValue,
    required this.targetValue,
    required this.unitKey,
    required this.iconData,
    required this.color,
    required this.category,
  });

  SustainabilityGoal copyWith({
    double? currentValue,
    double? targetValue,
  }) {
    return SustainabilityGoal(
      id: id,
      titleKey: titleKey,
      descriptionKey: descriptionKey,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      unitKey: unitKey,
      iconData: iconData,
      color: color,
      category: category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleKey': titleKey,
      'descriptionKey': descriptionKey,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'unitKey': unitKey,
      'iconName': _getIconName(iconData),
      'colorValue': color.toARGB32(),
      'category': category.index,
    };
  }

  String _getIconName(IconData iconData) {
    if (iconData == Icons.eco) return 'eco';
    if (iconData == Icons.nature_people) return 'nature_people';
    if (iconData == Icons.directions_bike) return 'directions_bike';
    if (iconData == Icons.recycling) return 'recycling';
    if (iconData == Icons.restaurant_menu) return 'restaurant_menu';
    if (iconData == Icons.flash_off) return 'flash_off';
    return 'eco'; // default
  }

  static IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'eco':
        return Icons.eco;
      case 'nature_people':
        return Icons.nature_people;
      case 'directions_bike':
        return Icons.directions_bike;
      case 'recycling':
        return Icons.recycling;
      case 'restaurant_menu':
        return Icons.restaurant_menu;
      case 'flash_off':
        return Icons.flash_off;
      default:
        return Icons.eco;
    }
  }

  factory SustainabilityGoal.fromJson(Map<String, dynamic> json) {
    return SustainabilityGoal(
      id: json['id'],
      titleKey: json['titleKey'],
      descriptionKey: json['descriptionKey'],
      currentValue: json['currentValue'].toDouble(),
      targetValue: json['targetValue'].toDouble(),
      unitKey: json['unitKey'],
      iconData:
          _getIconFromName(json['iconName'] ?? 'eco'), // ✅ Now uses const icons
      color: Color(json['colorValue']),
      category: GoalCategory.values[json['category']],
    );
  }
}
