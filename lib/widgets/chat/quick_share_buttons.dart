import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/chat/enhanced_chat_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';

class QuickShareButtons extends ConsumerWidget {
  final String conversationId;
  final String receiverId;
  final VoidCallback? onShareComplete;

  const QuickShareButtons({
    super.key,
    required this.conversationId,
    required this.receiverId,
    this.onShareComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'quick_share'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareButton(
                context,
                icon: '🍽️',
                label: tr(context, 'meal'),
                onTap: () => _showMealShareDialog(context),
              ),
              _buildShareButton(
                context,
                icon: '💪',
                label: tr(context, 'workout'),
                onTap: () => _showWorkoutShareDialog(context),
              ),
              _buildShareButton(
                context,
                icon: '🏆',
                label: tr(context, 'challenge'),
                onTap: () => _showChallengeShareDialog(context),
              ),
              _buildShareButton(
                context,
                icon: '🎉',
                label: tr(context, 'achievement'),
                onTap: () => _showAchievementShareDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(
    BuildContext context, {
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textColor(context),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showMealShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MealShareDialog(
        conversationId: conversationId,
        receiverId: receiverId,
        onShareComplete: () {
          Navigator.pop(context);
          onShareComplete?.call();
        },
      ),
    );
  }

  void _showWorkoutShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => WorkoutShareDialog(
        conversationId: conversationId,
        receiverId: receiverId,
        onShareComplete: () {
          Navigator.pop(context);
          onShareComplete?.call();
        },
      ),
    );
  }

  void _showChallengeShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ChallengeShareDialog(
        conversationId: conversationId,
        receiverId: receiverId,
        onShareComplete: () {
          Navigator.pop(context);
          onShareComplete?.call();
        },
      ),
    );
  }

  void _showAchievementShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AchievementShareDialog(
        conversationId: conversationId,
        receiverId: receiverId,
        onShareComplete: () {
          Navigator.pop(context);
          onShareComplete?.call();
        },
      ),
    );
  }
}

// ==================== SHARE DIALOGS ====================

class MealShareDialog extends ConsumerStatefulWidget {
  final String conversationId;
  final String receiverId;
  final VoidCallback? onShareComplete;

  const MealShareDialog({
    super.key,
    required this.conversationId,
    required this.receiverId,
    this.onShareComplete,
  });

  @override
  ConsumerState<MealShareDialog> createState() => _MealShareDialogState();
}

class _MealShareDialogState extends ConsumerState<MealShareDialog> {
  final _personalNoteController = TextEditingController();
  String? _selectedMealId;
  String? _selectedMealName;
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      backgroundColor: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Text('🍽️'),
          const SizedBox(width: 8),
          Text(
            tr(context, 'share_meal'),
            style: TextStyle(color: AppTheme.textColor(context)),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Recent meals list (simplified for demo)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(context, 'select_recent_meal'),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _personalNoteController,
              decoration: InputDecoration(
                hintText: tr(context, 'add_personal_note'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppTheme.surfaceColor(context),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr(context, 'cancel')),
        ),
        ElevatedButton(
          onPressed: _isSharing ? null : _shareMeal,
          child: _isSharing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(tr(context, 'share')),
        ),
      ],
    );
  }

  Future<void> _shareMeal() async {
    if (_selectedMealId == null) {
      // For demo purposes, create a sample meal
      _selectedMealId = 'demo_meal_${DateTime.now().millisecondsSinceEpoch}';
      _selectedMealName = 'Healthy Quinoa Salad';
    }

    setState(() => _isSharing = true);

    final chatService = EnhancedChatService();
    final success = await chatService.shareMeal(
      conversationId: widget.conversationId,
      receiverId: widget.receiverId,
      mealId: _selectedMealId!,
      mealName: _selectedMealName!,
      description: 'A nutritious and delicious quinoa salad',
      calories: 350,
      nutrients: {
        'protein': 15,
        'carbs': 45,
        'fat': 12,
        'fiber': 8,
      },
      ingredients: ['Quinoa', 'Mixed vegetables', 'Olive oil', 'Lemon'],
      personalNote: _personalNoteController.text.isEmpty
          ? null
          : _personalNoteController.text,
    );

    setState(() => _isSharing = false);

    if (success) {
      widget.onShareComplete?.call();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'share_failed')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _personalNoteController.dispose();
    super.dispose();
  }
}

class WorkoutShareDialog extends ConsumerStatefulWidget {
  final String conversationId;
  final String receiverId;
  final VoidCallback? onShareComplete;

  const WorkoutShareDialog({
    super.key,
    required this.conversationId,
    required this.receiverId,
    this.onShareComplete,
  });

  @override
  ConsumerState<WorkoutShareDialog> createState() => _WorkoutShareDialogState();
}

class _WorkoutShareDialogState extends ConsumerState<WorkoutShareDialog> {
  final _personalNoteController = TextEditingController();
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      backgroundColor: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Text('💪'),
          const SizedBox(width: 8),
          Text(
            tr(context, 'share_workout'),
            style: TextStyle(color: AppTheme.textColor(context)),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(context, 'select_recent_workout'),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _personalNoteController,
              decoration: InputDecoration(
                hintText: tr(context, 'add_personal_note'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppTheme.surfaceColor(context),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr(context, 'cancel')),
        ),
        ElevatedButton(
          onPressed: _isSharing ? null : _shareWorkout,
          child: _isSharing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(tr(context, 'share')),
        ),
      ],
    );
  }

  Future<void> _shareWorkout() async {
    setState(() => _isSharing = true);

    final chatService = EnhancedChatService();
    final success = await chatService.shareWorkout(
      conversationId: widget.conversationId,
      receiverId: widget.receiverId,
      workoutId: 'demo_workout_${DateTime.now().millisecondsSinceEpoch}',
      workoutName: 'Morning HIIT Routine',
      description: 'High-intensity interval training for a great start to the day',
      duration: 30,
      exercises: [
        {'name': 'Burpees', 'reps': 10, 'sets': 3},
        {'name': 'Mountain Climbers', 'duration': 30, 'sets': 3},
        {'name': 'Jump Squats', 'reps': 15, 'sets': 3},
      ],
      difficulty: 'Intermediate',
      personalNote: _personalNoteController.text.isEmpty
          ? null
          : _personalNoteController.text,
    );

    setState(() => _isSharing = false);

    if (success) {
      widget.onShareComplete?.call();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'share_failed')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _personalNoteController.dispose();
    super.dispose();
  }
}

// Placeholder dialogs for Challenge and Achievement sharing
class ChallengeShareDialog extends StatelessWidget {
  final String conversationId;
  final String receiverId;
  final VoidCallback? onShareComplete;

  const ChallengeShareDialog({
    super.key,
    required this.conversationId,
    required this.receiverId,
    this.onShareComplete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🏆 Share Challenge'),
      content: const Text('Challenge sharing feature coming soon!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class AchievementShareDialog extends StatelessWidget {
  final String conversationId;
  final String receiverId;
  final VoidCallback? onShareComplete;

  const AchievementShareDialog({
    super.key,
    required this.conversationId,
    required this.receiverId,
    this.onShareComplete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🎉 Share Achievement'),
      content: const Text('Achievement sharing feature coming soon!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}