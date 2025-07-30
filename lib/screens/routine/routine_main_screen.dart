import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../models/workout_routine.dart';
import '../../providers/routine_providers.dart';
import '../../widgets/common/lottie_loading_widget.dart';
import 'routine_detail_screen.dart';
import 'routine_creation_screen.dart';

class RoutineMainScreen extends ConsumerStatefulWidget {
  const RoutineMainScreen({super.key});

  @override
  ConsumerState<RoutineMainScreen> createState() => _RoutineMainScreenState();
}

class _RoutineMainScreenState extends ConsumerState<RoutineMainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(
          tr(context, 'weekly_routines'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.textColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: AppTheme.primaryColor,
            ),
            onPressed: () => _createNewRoutine(),
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final routineManagerAsync = ref.watch(routineManagerProvider);
          
          return routineManagerAsync.when(
            loading: () => const Center(child: LottieLoadingWidget()),
            error: (error, stack) => _buildErrorState(error.toString()),
            data: (routineManager) => _buildContent(routineManager),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.textColor(context).withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            tr(context, 'error_loading_routines'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: AppTheme.textColor(context).withAlpha(179),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(routineManagerProvider),
            child: Text(tr(context, 'retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(RoutineManager routineManager) {
    if (routineManager.routines.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsOverview(routineManager),
          const SizedBox(height: 24),
          _buildActiveRoutineSection(routineManager),
          const SizedBox(height: 24),
          _buildAllRoutinesSection(routineManager),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: AppTheme.textColor(context).withAlpha(102),
          ),
          const SizedBox(height: 24),
          Text(
            tr(context, 'no_routines_yet'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'create_first_routine_desc'),
            style: TextStyle(
              color: AppTheme.textColor(context).withAlpha(179),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _createNewRoutine(),
            icon: const Icon(Icons.add),
            label: Text(tr(context, 'create_routine')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _showTemplates(),
            icon: const Icon(Icons.library_books),
            label: Text(tr(context, 'browse_templates')),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(RoutineManager routineManager) {
    final activeRoutine = routineManager.activeRoutine;
    final availableSlots = routineManager.availableSlots;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withAlpha(26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'routine_overview'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  tr(context, 'total_routines'),
                  '${routineManager.routines.length}',
                  Icons.fitness_center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  tr(context, 'available_slots'),
                  '$availableSlots',
                  Icons.add_circle_outline,
                ),
              ),
            ],
          ),
          if (activeRoutine != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    tr(context, 'weekly_workouts'),
                    '${activeRoutine.totalWorkouts}',
                    Icons.today,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    tr(context, 'weekly_minutes'),
                    '${activeRoutine.totalWeeklyMinutes}',
                    Icons.timer,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textColor(context).withAlpha(179),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRoutineSection(RoutineManager routineManager) {
    final activeRoutine = routineManager.activeRoutine;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'active_routine'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (activeRoutine != null)
          _buildRoutineCard(activeRoutine, isActive: true)
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.textColor(context).withAlpha(51),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.schedule,
                  size: 48,
                  color: AppTheme.textColor(context).withAlpha(102),
                ),
                const SizedBox(height: 12),
                Text(
                  tr(context, 'no_active_routine'),
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr(context, 'select_routine_to_activate'),
                  style: TextStyle(
                    color: AppTheme.textColor(context).withAlpha(179),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAllRoutinesSection(RoutineManager routineManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr(context, 'all_routines'),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${routineManager.routines.length}/5',
              style: TextStyle(
                color: AppTheme.textColor(context).withAlpha(179),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...routineManager.routines.map((routine) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRoutineCard(routine),
        )),
      ],
    );
  }

  Widget _buildRoutineCard(WorkoutRoutine routine, {bool isActive = false}) {
    return GestureDetector(
      onTap: () => _navigateToRoutineDetail(routine),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive 
              ? AppTheme.primaryColor.withAlpha(26)
              : AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive 
                ? AppTheme.primaryColor
                : AppTheme.primaryColor.withAlpha(26),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            routine.name,
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tr(context, 'active'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (routine.category != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          routine.category!,
                          style: TextStyle(
                            color: AppTheme.textColor(context).withAlpha(179),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.textColor(context).withAlpha(179),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildRoutineInfo(
                  Icons.fitness_center,
                  '${routine.totalWorkouts}',
                  tr(context, 'exercises'),
                ),
                const SizedBox(width: 16),
                _buildRoutineInfo(
                  Icons.timer,
                  '${routine.totalWeeklyMinutes}',
                  tr(context, 'min_week'),
                ),
                const SizedBox(width: 16),
                _buildRoutineInfo(
                  Icons.date_range,
                  '${7 - routine.weeklyPlan.where((d) => d.isRestDay).length}',
                  tr(context, 'days'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineInfo(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: TextStyle(
            color: AppTheme.textColor(context).withAlpha(179),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _createNewRoutine() async {
    final routineManager = await ref.read(routineManagerProvider.future);
    
    if (routineManager.availableSlots <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'max_routines_reached')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RoutineCreationScreen(),
        ),
      );

      if (result == true) {
        ref.invalidate(routineManagerProvider);
      }
    }
  }

  void _showTemplates() async {
    final service = ref.read(routineServiceProvider);
    final templates = service.getRoutineTemplates();

    if (mounted) {
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'routine_templates'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...templates.map((template) => ListTile(
                title: Text(template.name),
                subtitle: Text(template.description ?? ''),
                trailing: const Icon(Icons.add),
                onTap: () => _useTemplate(template),
              )),
            ],
          ),
        ),
      );
    }
  }

  void _useTemplate(WorkoutRoutine template) async {
    Navigator.pop(context); // Close bottom sheet
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutineCreationScreen(template: template),
      ),
    );

    if (result == true) {
      ref.invalidate(routineManagerProvider);
    }
  }

  void _navigateToRoutineDetail(WorkoutRoutine routine) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutineDetailScreen(routine: routine),
      ),
    );

    if (result == true) {
      ref.invalidate(routineManagerProvider);
    }
  }
}