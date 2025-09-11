import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/exercise/exercise_log.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';

class ExerciseTypePieChart extends StatelessWidget {
  final List<ExerciseLog> logs;
  final double? size;

  const ExerciseTypePieChart({
    super.key,
    required this.logs,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return _buildEmptyState(context);
    }

    final chartData = _prepareChartData();
    
    if (chartData.isEmpty) {
      return _buildEmptyState(context);
    }

    return Container(
      height: size ?? 180, // Reduced from 200
      padding: const EdgeInsets.all(12), // Reduced padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'exercise_type_distribution'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 14, // Reduced from 16
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12), // Reduced from 16
          Expanded(
            child: Row(
              children: [
                // Pie Chart - smaller
                SizedBox(
                  width: 120, // Fixed smaller width
                  child: PieChart(
                    PieChartData(
                      sections: chartData,
                      centerSpaceRadius: 25, // Reduced from 40
                      sectionsSpace: 1, // Reduced spacing
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          // Handle touch interactions if needed
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Legend - takes remaining space
                Expanded(
                  child: _buildLegend(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      height: size ?? 180,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart,
              size: 48,
              color: AppTheme.textColor(context).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              tr(context, 'no_exercise_data'),
              style: TextStyle(
                color: AppTheme.textColor(context).withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _prepareChartData() {
    // Categorize exercises by type
    final exerciseCategories = <String, int>{};
    
    for (final log in logs) {
      final category = _categorizeExercise(log.exerciseName);
      exerciseCategories[category] = (exerciseCategories[category] ?? 0) + 1;
    }
    
    if (exerciseCategories.isEmpty) return [];
    
    // Define colors for different categories
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    
    final sections = <PieChartSectionData>[];
    int colorIndex = 0;
    
    exerciseCategories.forEach((category, count) {
      final percentage = (count / logs.length) * 100;
      
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: count.toDouble(),
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 35, // Reduced from 50
          titleStyle: const TextStyle(
            fontSize: 10, // Reduced from 12
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      
      colorIndex++;
    });
    
    return sections;
  }

  Widget _buildLegend(BuildContext context) {
    final exerciseCategories = <String, int>{};
    
    for (final log in logs) {
      final category = _categorizeExercise(log.exerciseName);
      exerciseCategories[category] = (exerciseCategories[category] ?? 0) + 1;
    }
    
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: exerciseCategories.entries.map((entry) {
        final index = exerciseCategories.keys.toList().indexOf(entry.key);
        final color = colors[index % colors.length];
        final percentage = (entry.value / logs.length) * 100;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 6), // Reduced from 8
          child: Row(
            children: [
              Container(
                width: 10, // Reduced from 12
                height: 10, // Reduced from 12
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6), // Reduced from 8
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCategoryDisplayName(context, entry.key),
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 11, // Reduced from 12
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${entry.value} (${percentage.toStringAsFixed(0)}%)',
                      style: TextStyle(
                        color: AppTheme.textColor(context).withValues(alpha: 0.6),
                        fontSize: 9, // Reduced from 10
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _categorizeExercise(String exerciseName) {
    final name = exerciseName.toLowerCase();
    
    // Strength training patterns
    if (name.contains('bench') || 
        name.contains('press') || 
        name.contains('squat') || 
        name.contains('deadlift') ||
        name.contains('curl') ||
        name.contains('row')) {
      return 'strength';
    }
    
    // Cardio patterns
    if (name.contains('run') || 
        name.contains('bike') || 
        name.contains('cycle') ||
        name.contains('cardio') ||
        name.contains('treadmill')) {
      return 'cardio';
    }
    
    // Calisthenics patterns
    if (name.contains('push') || 
        name.contains('pull') || 
        name.contains('dip') ||
        name.contains('chin') ||
        name.contains('bodyweight')) {
      return 'calisthenics';
    }
    
    // Flexibility patterns
    if (name.contains('stretch') || 
        name.contains('yoga') || 
        name.contains('pilates') ||
        name.contains('flexibility')) {
      return 'flexibility';
    }
    
    // Sports patterns
    if (name.contains('ball') || 
        name.contains('tennis') || 
        name.contains('soccer') ||
        name.contains('basketball') ||
        name.contains('football')) {
      return 'sports';
    }
    
    // Core patterns
    if (name.contains('plank') || 
        name.contains('crunch') || 
        name.contains('sit') ||
        name.contains('abs') ||
        name.contains('core')) {
      return 'core';
    }
    
    // HIIT patterns
    if (name.contains('hiit') || 
        name.contains('interval') || 
        name.contains('circuit') ||
        name.contains('tabata')) {
      return 'hiit';
    }
    
    // Default to general
    return 'general';
  }

  String _getCategoryDisplayName(BuildContext context, String category) {
    switch (category) {
      case 'strength':
        return tr(context, 'strength_training');
      case 'cardio':
        return tr(context, 'cardio');
      case 'calisthenics':
        return tr(context, 'calisthenics');
      case 'flexibility':
        return tr(context, 'flexibility');
      case 'sports':
        return tr(context, 'sports');
      case 'core':
        return tr(context, 'core_training');
      case 'hiit':
        return tr(context, 'hiit');
      case 'general':
        return tr(context, 'general_fitness');
      default:
        return category;
    }
  }
}