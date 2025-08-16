import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'modern_profile_header.dart';
import 'memoized_daily_goals.dart';
import 'modern_weekly_summary.dart';
import 'modern_action_grid.dart';
import 'modern_achievements_section.dart';

// Optimized wrapper widgets with RepaintBoundary for better performance
class OptimizedProfileHeader extends ConsumerWidget {
  const OptimizedProfileHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RepaintBoundary(
      child: ModernProfileHeader(),
    );
  }
}

class OptimizedDailyGoals extends ConsumerWidget {
  const OptimizedDailyGoals({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RepaintBoundary(
      child: MemoizedDailyGoals(),
    );
  }
}

class OptimizedWeeklySummary extends ConsumerWidget {
  const OptimizedWeeklySummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RepaintBoundary(
      child: ModernWeeklySummary(),
    );
  }
}

class OptimizedActionGrid extends ConsumerWidget {
  const OptimizedActionGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RepaintBoundary(
      child: ModernActionGrid(),
    );
  }
}

class OptimizedAchievements extends ConsumerWidget {
  const OptimizedAchievements({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RepaintBoundary(
      child: ModernAchievementsSection(),
    );
  }
}