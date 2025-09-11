import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/exercise/exercise_log.dart';
import '../../services/exercises/exercise_tracking_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';

class CalorieBalanceChart extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>>? todaysMeals;
  final bool showWeeklyView;
  
  const CalorieBalanceChart({
    super.key,
    this.todaysMeals,
    this.showWeeklyView = false,
  });

  @override
  State<CalorieBalanceChart> createState() => _CalorieBalanceChartState();
}

class _CalorieBalanceChartState extends State<CalorieBalanceChart> {
  final ExerciseTrackingService _trackingService = ExerciseTrackingService();
  List<ExerciseLog> _exerciseLogs = [];
  Map<String, Map<String, List<Map<String, dynamic>>>> _weeklyMealData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load exercise logs
      final allLogs = await _trackingService.getAllLogs();
      
      // Load meal data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedWeeklyData = prefs.getString('weeklyMealData');
      
      Map<String, Map<String, List<Map<String, dynamic>>>> weeklyMeals = {};
      if (savedWeeklyData != null) {
        final decodedData = json.decode(savedWeeklyData);
        decodedData.forEach((String key, dynamic value) {
          final dayIndex = int.parse(key);
          weeklyMeals[dayIndex.toString()] = {};
          
          (value as Map<String, dynamic>).forEach((mealTime, meals) {
            weeklyMeals[dayIndex.toString()]![mealTime] = (meals as List)
                .map((meal) => Map<String, dynamic>.from(meal))
                .toList();
          });
        });
      }
      
      setState(() {
        _exerciseLogs = allLogs;
        _weeklyMealData = weeklyMeals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _calculateTodaysBalance() {
    final today = DateTime.now();
    final todayIndex = today.weekday - 1; // Convert to 0-6 index
    
    // Calculate calories consumed from meals
    double caloriesConsumed = 0;
    final todaysMealData = widget.todaysMeals ?? _weeklyMealData[todayIndex.toString()] ?? {};
    
    for (final mealList in todaysMealData.values) {
      for (final meal in mealList) {
        if (meal['isSuggested'] != true) { // Only count non-suggested meals
          final caloriesStr = meal['nutritionFacts']?['calories']?.toString() ?? '0';
          final calories = double.tryParse(caloriesStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          caloriesConsumed += calories;
        }
      }
    }
    
    // Calculate calories burned from exercise
    double caloriesBurned = 0;
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final todaysExercises = _exerciseLogs.where((log) {
      return log.date.isAfter(startOfDay) && log.date.isBefore(endOfDay);
    }).toList();
    
    for (final log in todaysExercises) {
      // More realistic calorie estimation
      final totalSets = log.sets.length;
      final volume = log.sets.fold(0.0, (sum, set) => sum + (set.weight * set.reps));
      final estimatedTimeMinutes = totalSets * 2.5; // Assume ~2.5 min per set
      
      // Base calories from time + small volume bonus
      final baseCalories = estimatedTimeMinutes * 4; // 4 cal/min
      final volumeBonus = volume * 0.01; // Much smaller multiplier
      final exerciseCalories = (baseCalories + volumeBonus).clamp(0, 200); // Cap per exercise
      caloriesBurned += exerciseCalories;
    }
    
    final netCalories = caloriesConsumed - caloriesBurned;
    
    return {
      'consumed': caloriesConsumed,
      'burned': caloriesBurned,
      'net': netCalories,
      'exerciseCount': todaysExercises.length,
      'mealCount': todaysMealData.values.fold(0, (sum, meals) => sum + meals.where((m) => m['isSuggested'] != true).length),
    };
  }

  List<Map<String, dynamic>> _calculateWeeklyBalance() {
    final weeklyData = <Map<String, dynamic>>[];
    final today = DateTime.now();
    
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: today.weekday - 1 - i));
      final dayIndex = i;
      
      // Calculate calories consumed for this day
      double caloriesConsumed = 0;
      final dayMealData = _weeklyMealData[dayIndex.toString()] ?? {};
      
      for (final mealList in dayMealData.values) {
        for (final meal in mealList) {
          if (meal['isSuggested'] != true) {
            final caloriesStr = meal['nutritionFacts']?['calories']?.toString() ?? '0';
            final calories = double.tryParse(caloriesStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
            caloriesConsumed += calories;
          }
        }
      }
      
      // Calculate calories burned for this day
      double caloriesBurned = 0;
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final dayExercises = _exerciseLogs.where((log) {
        return log.date.isAfter(startOfDay) && log.date.isBefore(endOfDay);
      }).toList();
      
      for (final log in dayExercises) {
        final totalSets = log.sets.length;
        final volume = log.sets.fold(0.0, (sum, set) => sum + (set.weight * set.reps));
        final estimatedTimeMinutes = totalSets * 2.5;
        
        final baseCalories = estimatedTimeMinutes * 4;
        final volumeBonus = volume * 0.01;
        final exerciseCalories = (baseCalories + volumeBonus).clamp(0, 200);
        caloriesBurned += exerciseCalories;
      }
      
      weeklyData.add({
        'day': i,
        'date': date,
        'consumed': caloriesConsumed,
        'burned': caloriesBurned,
        'net': caloriesConsumed - caloriesBurned,
      });
    }
    
    return weeklyData;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (widget.showWeeklyView) {
      return _buildWeeklyChart();
    } else {
      return _buildDailyBalance();
    }
  }

  Widget _buildLoadingState() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildDailyBalance() {
    final balance = _calculateTodaysBalance();
    final consumed = balance['consumed'] as double;
    final burned = balance['burned'] as double;
    final net = balance['net'] as double;
    final isPositive = net >= 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'calorie_balance_today'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Balance visualization
          Row(
            children: [
              // Consumed
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      Icons.restaurant,
                      color: Colors.blue,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${consumed.toInt()}',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      tr(context, 'consumed'),
                      style: TextStyle(
                        color: AppTheme.textColor(context).withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Balance indicator
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isPositive 
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isPositive ? Colors.orange : Colors.green,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? Colors.orange : Colors.green,
                      size: 20,
                    ),
                    Text(
                      '${isPositive ? '+' : ''}${net.toInt()}',
                      style: TextStyle(
                        color: isPositive ? Colors.orange : Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Burned
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${burned.toInt()}',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      tr(context, 'burned'),
                      style: TextStyle(
                        color: AppTheme.textColor(context).withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress bars
          _buildCalorieBar(
            context,
            tr(context, 'calories_in'),
            consumed,
            consumed + burned > 0 ? consumed / (consumed + burned) : 0,
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildCalorieBar(
            context,
            tr(context, 'calories_out'),
            burned,
            consumed + burned > 0 ? burned / (consumed + burned) : 0,
            Colors.red,
          ),
          
          const SizedBox(height: 12),
          
          // Summary text
          Text(
            isPositive 
                ? tr(context, 'calorie_surplus_message').replaceAll('{calories}', net.toInt().toString())
                : tr(context, 'calorie_deficit_message').replaceAll('{calories}', (-net).toInt().toString()),
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieBar(BuildContext context, String label, double value, double progress, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${value.toInt()}',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    final weeklyData = _calculateWeeklyBalance();
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'weekly_calorie_balance'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: weeklyData.map((data) {
                  final consumed = data['consumed'] as double;
                  final burned = data['burned'] as double;
                  
                  return BarChartGroupData(
                    x: data['day'] as int,
                    barRods: [
                      BarChartRodData(
                        toY: consumed,
                        color: Colors.blue,
                        width: 8,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: burned,
                        color: Colors.red,
                        width: 8,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            color: AppTheme.textColor(context).withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Text(
                          days[value.toInt()],
                          style: TextStyle(
                            color: AppTheme.textColor(context).withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}