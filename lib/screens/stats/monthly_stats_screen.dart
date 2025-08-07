import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../providers/riverpod/stats_provider.dart';
import '../../models/stats/daily_stats.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../providers/riverpod/user_progress_provider.dart';
import '../../models/user/user_progress.dart';
import '../../providers/riverpod/health_data_provider.dart';
import '../../models/health/health_data.dart';

class MonthlyStatsScreen extends ConsumerWidget {
  const MonthlyStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigation = ref.watch(monthNavigationProvider);
    final monthStatsAsync = ref.watch(currentViewedMonthStatsProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final userProgressAsync = ref.watch(userProgressNotifierProvider);
    
    // Auto-select current day if viewing current month and no day is selected
    final today = DateTime.now();
    final isCurrentMonth = navigation.year == today.year && navigation.month == today.month;
    
    ref.listen<AsyncValue<MonthlyStats>>(currentViewedMonthStatsProvider, (previous, next) {
      if (next.hasValue && selectedDay == null && isCurrentMonth) {
        final todayStats = next.value!.getDay(today.day);
        if (todayStats != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedDayProvider.notifier).state = todayStats;
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Futuristic App Bar
          _buildFuturisticAppBar(context, ref, navigation),
          
          // Main Content
          SliverToBoxAdapter(
            child: monthStatsAsync.when(
              data: (monthStats) => _buildFuturisticContent(context, monthStats, navigation, ref),
              loading: () => _buildFuturisticLoading(),
              error: (error, stack) => _buildFuturisticError(context, ref),
            ),
          ),
          
          // Selected Day Details at Bottom - Show current day by default if available
          if (selectedDay != null)
            SliverToBoxAdapter(
              child: _buildBottomDayCard(context, ref, selectedDay, userProgressAsync),
            )
          else if (isCurrentMonth)
            monthStatsAsync.when(
              data: (monthStats) {
                final todayStats = monthStats.getDay(today.day);
                if (todayStats != null) {
                  return SliverToBoxAdapter(
                    child: _buildBottomDayCard(context, ref, todayStats, userProgressAsync),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
        ],
      ),
    );
  }

  Widget _buildFuturisticAppBar(BuildContext context, WidgetRef ref, MonthNavigationState navigation) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.darkSurface,
                AppColors.textFieldDark,
                Colors.black,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Animated background particles
              ...List.generate(20, (index) => _buildParticle(index)),
              // Header content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios,
                              color: AppColors.white,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          _buildHolographicTitle(tr(context, 'monthly_stats')),
                          const Spacer(),
                          _buildGlowButton(
                            icon: Icons.today,
                            onTap: () => ref.read(monthNavigationProvider.notifier).goToCurrentMonth(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      _buildFuturisticMonthNavigation(context, ref, navigation),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticContent(
    BuildContext context,
    MonthlyStats monthStats,
    MonthNavigationState navigation,
    WidgetRef ref,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Futuristic Monthly Overview Stats
          _buildFuturisticOverview(context, monthStats),
          const SizedBox(height: 30),
          
          // Calendar Days Header with Holographic Effect
          _buildFuturisticCalendarHeader(context),
          const SizedBox(height: 15),
          
          // Futuristic Calendar Grid
          _buildFuturisticCalendarGrid(context, monthStats, ref),
        ],
      ),
    );
  }

  Widget _buildFuturisticOverview(
    BuildContext context,
    MonthlyStats monthStats,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardDark,
            AppColors.textFieldDark,
            AppColors.darkSurface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFuturisticStat(
                tr(context, 'complete_days'),
                monthStats.completeDays.toString(),
                Icons.check_circle,
                const Color(0xFF00FF88),
              ),
              _buildFuturisticStat(
                tr(context, 'partial_days'),
                monthStats.partialDays.toString(),
                Icons.pie_chart_outline,
                const Color(0xFFFFAA00),
              ),
              _buildFuturisticStat(
                tr(context, 'empty_days'),
                monthStats.emptyDays.toString(),
                Icons.circle_outlined,
                const Color(0xFF6B7280),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFuturisticStat(
                tr(context, 'completion_rate'),
                '${monthStats.completionRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                AppColors.primary,
              ),
              _buildFuturisticStat(
                tr(context, 'best_streak'),
                monthStats.maxStreak.toString(),
                Icons.local_fire_department,
                const Color(0xFFFF4444),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.2),
                color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: AppColors.primary,
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFuturisticCalendarHeader(BuildContext context) {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: weekdays.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  shadows: [
                    Shadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFuturisticCalendarGrid(
    BuildContext context,
    MonthlyStats monthStats,
    WidgetRef ref,
  ) {
    final calendarGrid = monthStats.getCalendarGrid();
    
    return SizedBox(
      height: 320,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.0,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: calendarGrid.length,
        itemBuilder: (context, index) {
          final dayStats = calendarGrid[index];
          
          if (dayStats == null) {
            // Empty day (before month starts)
            return const SizedBox.shrink();
          }
          
          return _buildFuturisticDayCell(context, dayStats, ref);
        },
      ),
    );
  }

  Widget _buildFuturisticDayCell(
    BuildContext context,
    DailyStats dayStats,
    WidgetRef ref,
  ) {
    final isToday = _isToday(dayStats.date);
    final isFuture = dayStats.date.isAfter(DateTime.now());
    
    Color primaryColor;
    Color shadowColor;
    List<Color> gradientColors;
    
    if (dayStats.isComplete) {
      primaryColor = const Color(0xFF00FF88);
      shadowColor = const Color(0xFF00FF88);
      gradientColors = [
        const Color(0xFF00FF88).withValues(alpha: 0.3),
        const Color(0xFF00CC6A).withValues(alpha: 0.1),
      ];
    } else if (dayStats.isPartial) {
      primaryColor = const Color(0xFFFFAA00);
      shadowColor = const Color(0xFFFFAA00);
      gradientColors = [
        const Color(0xFFFFAA00).withValues(alpha: 0.3),
        const Color(0xFFCC8800).withValues(alpha: 0.1),
      ];
    } else if (dayStats.isEmpty) {
      primaryColor = const Color(0xFF6B7280);
      shadowColor = const Color(0xFF6B7280);
      gradientColors = [
        const Color(0xFF6B7280).withValues(alpha: 0.2),
        const Color(0xFF4B5563).withValues(alpha: 0.1),
      ];
    } else {
      primaryColor = const Color(0xFF1E2749);
      shadowColor = AppColors.primary;
      gradientColors = [
        const Color(0xFF1E2749),
        const Color(0xFF2D3561),
      ];
    }
    
    return GestureDetector(
      onTap: () => ref.read(selectedDayProvider.notifier).state = dayStats,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            if (dayStats.isComplete || dayStats.isPartial) ...[
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayStats.date.day.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isFuture 
                    ? AppColors.textSecondary 
                    : AppColors.white,
                shadows: [
                  if (!isFuture)
                    Shadow(
                      color: primaryColor.withValues(alpha: 0.6),
                      blurRadius: 3,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomDayCard(BuildContext context, WidgetRef ref, DailyStats dayStats, AsyncValue<UserProgress> userProgressAsync) {
    final today = DateTime.now();
    final isToday = dayStats.date.year == today.year && 
                    dayStats.date.month == today.month && 
                    dayStats.date.day == today.day;
    
    // Get current health data if this is today's stats
    final currentHealthDataAsync = isToday ? ref.watch(healthDataNotifierProvider) : null;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardDark,
            AppColors.textFieldDark,
            AppColors.darkSurface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with date, navigation arrows, and close button
          Row(
            children: [
              // Previous day arrow
              IconButton(
                onPressed: () {
                  final prevDate = dayStats.date.subtract(Duration(days: 1));
                  final monthStats = ref.read(currentViewedMonthStatsProvider).value;
                  if (monthStats != null) {
                    final prevDayStats = monthStats.getDay(prevDate.day);
                    if (prevDayStats != null && prevDate.month == monthStats.month) {
                      ref.read(selectedDayProvider.notifier).state = prevDayStats;
                    }
                  }
                },
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
              Expanded(
                child: Text(
                  '${dayStats.date.day} ${_getMonthName(dayStats.date.month)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: AppColors.primary,
                      blurRadius: 4,
                    ),
                  ],
                ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Next day arrow
              IconButton(
                onPressed: () {
                  final nextDate = dayStats.date.add(Duration(days: 1));
                  final monthStats = ref.read(currentViewedMonthStatsProvider).value;
                  if (monthStats != null && !nextDate.isAfter(DateTime.now())) {
                    final nextDayStats = monthStats.getDay(nextDate.day);
                    if (nextDayStats != null && nextDate.month == monthStats.month) {
                      ref.read(selectedDayProvider.notifier).state = nextDayStats;
                    }
                  }
                },
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      dayStats.isComplete
                          ? const Color(0xFF00FF88)
                          : dayStats.isPartial
                              ? const Color(0xFFFFAA00)
                              : const Color(0xFF6B7280),
                      dayStats.isComplete
                          ? const Color(0xFF00CC6A)
                          : dayStats.isPartial
                              ? const Color(0xFFCC8800)
                              : const Color(0xFF4B5563),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  isToday && currentHealthDataAsync?.hasValue == true && userProgressAsync.hasValue
                      ? '${_calculateCurrentCompletedGoals(currentHealthDataAsync!.value!, userProgressAsync.value!)}/5'
                      : '${dayStats.completedGoalsCount}/5',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Minimize/Back to calendar arrow
              IconButton(
                onPressed: () => ref.read(selectedDayProvider.notifier).state = null,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white70,
                  size: 24,
                ),
                tooltip: 'Back to calendar',
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => ref.read(selectedDayProvider.notifier).state = null,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Goals with actual numbers from user's goals
          userProgressAsync.when(
            data: (userProgress) {
              // Use current health data if available and this is today, otherwise use stored data
              if (isToday && currentHealthDataAsync?.hasValue == true) {
                final currentHealthData = currentHealthDataAsync!.value!;
                return Column(
                  children: [
                    _buildFuturisticGoalWithStats(
                      'Steps', 
                      currentHealthData.steps >= userProgress.dailyGoals.stepsGoal, 
                      currentHealthData.steps, 
                      _formatGoalNumber(userProgress.dailyGoals.stepsGoal)
                    ),
                    _buildFuturisticGoalWithStats(
                      'Active Minutes', 
                      currentHealthData.activeMinutes >= userProgress.dailyGoals.activeMinutesGoal, 
                      currentHealthData.activeMinutes, 
                      '${userProgress.dailyGoals.activeMinutesGoal}'
                    ),
                    _buildFuturisticGoalWithStats(
                      'Calories', 
                      currentHealthData.caloriesBurned >= userProgress.dailyGoals.caloriesBurnGoal, 
                      currentHealthData.caloriesBurned, 
                      _formatGoalNumber(userProgress.dailyGoals.caloriesBurnGoal)
                    ),
                    _buildFuturisticGoalWithStats(
                      'Water Intake', 
                      false, // Water intake completion is managed separately
                      0, // Water intake shown separately in health screen
                      '${(userProgress.dailyGoals.waterIntakeGoal ~/ 250)}'
                    ),
                    _buildFuturisticGoalWithStats(
                      'Sleep Quality', 
                      currentHealthData.sleepHours >= userProgress.dailyGoals.sleepHoursGoal, 
                      currentHealthData.sleepHours.toInt(), 
                      '${userProgress.dailyGoals.sleepHoursGoal.toInt()}'
                    ),
                  ],
                );
              } else {
                // Use historical data for past days
                return Column(
                  children: [
                    _buildFuturisticGoalWithStats(
                      'Steps', 
                      dayStats.stepsCompleted, 
                      dayStats.healthData['steps']?.toInt() ?? 0, 
                      _formatGoalNumber(userProgress.dailyGoals.stepsGoal)
                    ),
                    _buildFuturisticGoalWithStats(
                      'Active Minutes', 
                      dayStats.activeMinutesCompleted, 
                      dayStats.healthData['activeMinutes']?.toInt() ?? 0, 
                      '${userProgress.dailyGoals.activeMinutesGoal}'
                    ),
                    _buildFuturisticGoalWithStats(
                      'Calories', 
                      dayStats.caloriesBurnCompleted, 
                      dayStats.healthData['caloriesBurned']?.toInt() ?? 0, 
                      _formatGoalNumber(userProgress.dailyGoals.caloriesBurnGoal)
                    ),
                    _buildFuturisticGoalWithStats(
                      'Water Intake', 
                      dayStats.waterIntakeCompleted, 
                      (dayStats.healthData['waterIntake']?.toDouble() ?? 0.0) ~/ 250, 
                      '${(userProgress.dailyGoals.waterIntakeGoal ~/ 250)}'
                    ),
                    _buildFuturisticGoalWithStats(
                      'Sleep Quality', 
                      dayStats.sleepQualityCompleted, 
                      dayStats.healthData['sleepHours']?.toInt() ?? 0, 
                      '${userProgress.dailyGoals.sleepHoursGoal.toInt()}'
                    ),
                  ],
                );
              }
            },
            loading: () => Column(
              children: [
                _buildFuturisticGoalWithStats('Steps', dayStats.stepsCompleted, dayStats.healthData['steps']?.toInt() ?? 0, 'N/A'),
                _buildFuturisticGoalWithStats('Active Minutes', dayStats.activeMinutesCompleted, dayStats.healthData['activeMinutes']?.toInt() ?? 0, 'N/A'),
                _buildFuturisticGoalWithStats('Calories', dayStats.caloriesBurnCompleted, dayStats.healthData['caloriesBurned']?.toInt() ?? 0, 'N/A'),
                _buildFuturisticGoalWithStats('Water Intake', dayStats.waterIntakeCompleted, (dayStats.healthData['waterIntake']?.toDouble() ?? 0.0) ~/ 250, 'N/A'),
                _buildFuturisticGoalWithStats('Sleep Quality', dayStats.sleepQualityCompleted, dayStats.healthData['sleepHours']?.toInt() ?? 0, 'N/A'),
              ],
            ),
            error: (_, __) => Column(
              children: [
                _buildFuturisticGoalWithStats('Steps', dayStats.stepsCompleted, dayStats.healthData['steps']?.toInt() ?? 0, 'N/A'),
                _buildFuturisticGoalWithStats('Active Minutes', dayStats.activeMinutesCompleted, dayStats.healthData['activeMinutes']?.toInt() ?? 0, 'N/A'),
                _buildFuturisticGoalWithStats('Calories', dayStats.caloriesBurnCompleted, dayStats.healthData['caloriesBurned']?.toInt() ?? 0, 'N/A'),
                _buildFuturisticGoalWithStats('Water Intake', dayStats.waterIntakeCompleted, (dayStats.healthData['waterIntake']?.toDouble() ?? 0.0) ~/ 250, 'N/A'),
                _buildFuturisticGoalWithStats('Sleep Quality', dayStats.sleepQualityCompleted, dayStats.healthData['sleepHours']?.toInt() ?? 0, 'N/A'),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (dayStats.dayStreak > 0)
                _buildFuturisticMetric(
                  Icons.local_fire_department,
                  'Day Streak',
                  dayStats.dayStreak.toString(),
                  const Color(0xFFFF4444),
                ),
              _buildFuturisticMetric(
                Icons.trending_up,
                'Level',
                dayStats.level.toString(),
                AppColors.primary,
              ),
              if (dayStats.ecoScore > 0)
                _buildFuturisticMetric(
                  Icons.eco,
                  'Eco Score',
                  dayStats.ecoScore.toStringAsFixed(1),
                  const Color(0xFF00FF88),
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _buildParticle(int index) {
    final random = math.Random(index);
    return Positioned(
      left: random.nextDouble() * 400,
      top: random.nextDouble() * 200,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 2000 + random.nextInt(3000)),
        curve: Curves.easeInOut,
        child: Container(
          width: 2 + random.nextDouble() * 3,
          height: 2 + random.nextDouble() * 3,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: AppColors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildHolographicTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
        shadows: [
          Shadow(
            color: AppColors.primary,
            blurRadius: 8,
          ),
          Shadow(
            color: AppColors.primary,
            blurRadius: 15,
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticMonthNavigation(
    BuildContext context,
    WidgetRef ref,
    MonthNavigationState navigation,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildGlowButton(
          icon: Icons.arrow_back_ios,
          onTap: () => ref.read(monthNavigationProvider.notifier).goToPreviousMonth(),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.cardDark,
                AppColors.textFieldDark,
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            '${_getMonthName(navigation.month)} ${navigation.year}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: AppColors.primary,
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
        _buildGlowButton(
          icon: Icons.arrow_forward_ios,
          onTap: !navigation.nextMonth().isFutureMonth
              ? () => ref.read(monthNavigationProvider.notifier).goToNextMonth()
              : () {},
        ),
      ],
    );
  }

  Widget _buildFuturisticLoading() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading Stats...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticError(BuildContext context, WidgetRef ref) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF4A1A1A),
              Color(0xFF2D1111),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFF4444).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: const Color(0xFFFF4444),
            ),
            const SizedBox(height: 16),
            Text(
              tr(context, 'error_loading_stats'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildGlowButton(
              icon: Icons.refresh,
              onTap: () => ref.refresh(currentViewedMonthStatsProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticGoalWithStats(String goalName, bool completed, int current, String target) {
    // Always show the actual data, N/A only when target is 'N/A'
    final currentText = current.toString();
    final isDataAvailable = target != 'N/A';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              (completed ? const Color(0xFF00FF88) : 
               isDataAvailable ? const Color(0xFF6B7280) : const Color(0xFF4B5563))
                  .withValues(alpha: 0.1),
              (completed ? const Color(0xFF00CC6A) : 
               isDataAvailable ? const Color(0xFF4B5563) : const Color(0xFF374151))
                  .withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (completed ? const Color(0xFF00FF88) : 
                   isDataAvailable ? const Color(0xFF6B7280) : const Color(0xFF4B5563))
                .withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (completed ? const Color(0xFF00FF88) : 
                       isDataAvailable ? const Color(0xFF6B7280) : const Color(0xFF4B5563))
                    .withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                completed ? Icons.check_circle : 
                isDataAvailable ? Icons.circle_outlined : Icons.help_outline,
                color: completed ? const Color(0xFF00FF88) : 
                      isDataAvailable ? const Color(0xFF6B7280) : const Color(0xFF4B5563),
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goalName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$currentText / $target',
                    style: TextStyle(
                      color: (completed ? const Color(0xFF00FF88) : 
                             isDataAvailable ? const Color(0xFF6B7280) : const Color(0xFF4B5563)),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (completed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00FF88),
                      Color(0xFF00CC6A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (!isDataAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4B5563).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No Data',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticMetric(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.2),
                color.withValues(alpha: 0.05),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.4),
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
  
  String _formatGoalNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}k';
    }
    return number.toString();
  }
  
  int _calculateCurrentCompletedGoals(HealthData healthData, UserProgress userProgress) {
    int completed = 0;
    final goals = userProgress.dailyGoals;
    
    if (healthData.steps >= goals.stepsGoal) completed++;
    if (healthData.activeMinutes >= goals.activeMinutesGoal) completed++;
    if (healthData.caloriesBurned >= goals.caloriesBurnGoal) completed++;
    if (healthData.sleepHours >= goals.sleepHoursGoal) completed++;
    // Note: Water intake is handled separately in the health screen
    
    return completed;
  }
}