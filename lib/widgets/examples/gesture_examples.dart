import 'package:flutter/material.dart';
import '../gestures/swipe_action_widget.dart';
import '../gestures/smart_refresh_widget.dart';

/// Example implementation showing how to use the gesture controls
class GestureExamplesScreen extends StatefulWidget {
  const GestureExamplesScreen({super.key});

  @override
  State<GestureExamplesScreen> createState() => _GestureExamplesScreenState();
}

class _GestureExamplesScreenState extends State<GestureExamplesScreen> {
  List<WorkoutItem> workouts = [
    WorkoutItem(id: '1', name: 'Morning Cardio', isCompleted: false),
    WorkoutItem(id: '2', name: 'Strength Training', isCompleted: false),
    WorkoutItem(id: '3', name: 'Yoga Session', isCompleted: true),
    WorkoutItem(id: '4', name: 'HIIT Workout', isCompleted: false),
  ];

  List<MealItem> meals = [
    MealItem(id: '1', name: 'Breakfast', description: 'Greek yogurt with berries'),
    MealItem(id: '2', name: 'Lunch', description: 'Grilled chicken salad'),
    MealItem(id: '3', name: 'Dinner', description: 'Salmon with quinoa'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gesture Controls Demo'),
      ),
      body: SmartRefreshWidget(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Workouts', 'Swipe right to complete, left to delete'),
              _buildWorkoutsList(),
              const SizedBox(height: 32),
              _buildSectionHeader('Meals', 'Swipe to add/edit/share'),
              _buildMealsList(),
              const SizedBox(height: 32),
              _buildGestureGuide(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SwipeActionWidget(
            leftAction: CommonSwipeActions.delete(
              onDelete: () => _deleteWorkout(workout.id),
            ),
            rightAction: workout.isCompleted
                ? CommonSwipeActions.archive(
                    onArchive: () => _archiveWorkout(workout.id),
                    label: 'Archive',
                  )
                : CommonSwipeActions.complete(
                    onComplete: () => _completeWorkout(workout.id),
                  ),
            child: Card(
              child: ListTile(
                leading: workout.isCompleted
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.fitness_center),
                title: Text(
                  workout.name,
                  style: TextStyle(
                    decoration: workout.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: Text(
                  workout.isCompleted ? 'Completed' : 'Pending',
                  style: TextStyle(
                    color: workout.isCompleted ? Colors.green : Colors.orange,
                  ),
                ),
                trailing: const Icon(Icons.drag_handle),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMealsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SwipeActionWidget(
            leftAction: CommonSwipeActions.edit(
              onEdit: () => _editMeal(meal.id),
            ),
            rightAction: CommonSwipeActions.share(
              onShare: () => _shareMeal(meal.id),
            ),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.restaurant, color: Colors.green),
                title: Text(meal.name),
                subtitle: Text(meal.description),
                trailing: const Icon(Icons.drag_handle),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGestureGuide() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 Gesture Guide',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildGestureItem(
            Icons.swipe_right,
            'Swipe Right',
            'Complete workouts, favorite items',
          ),
          _buildGestureItem(
            Icons.swipe_left,
            'Swipe Left',
            'Delete, archive, or secondary actions',
          ),
          _buildGestureItem(
            Icons.refresh,
            'Pull to Refresh',
            'Refresh data by pulling down',
          ),
          _buildGestureItem(
            Icons.touch_app,
            'Tap Navigation',
            'Double-tap tab to scroll to top',
          ),
        ],
      ),
    );
  }

  Widget _buildGestureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
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
    );
  }

  Future<void> _handleRefresh() async {
    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      // Add a new workout
      workouts.insert(0, WorkoutItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'New Workout',
        isCompleted: false,
      ));
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data refreshed!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _completeWorkout(String id) {
    setState(() {
      final index = workouts.indexWhere((w) => w.id == id);
      if (index != -1) {
        workouts[index] = workouts[index].copyWith(isCompleted: true);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Workout completed! 🎉'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteWorkout(String id) {
    setState(() {
      workouts.removeWhere((w) => w.id == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Workout deleted'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _archiveWorkout(String id) {
    setState(() {
      workouts.removeWhere((w) => w.id == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Workout archived'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  void _editMeal(String id) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit meal feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _shareMeal(String id) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share meal feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

/// Example data models
class WorkoutItem {
  final String id;
  final String name;
  final bool isCompleted;

  WorkoutItem({
    required this.id,
    required this.name,
    required this.isCompleted,
  });

  WorkoutItem copyWith({
    String? id,
    String? name,
    bool? isCompleted,
  }) {
    return WorkoutItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class MealItem {
  final String id;
  final String name;
  final String description;

  MealItem({
    required this.id,
    required this.name,
    required this.description,
  });
}