import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_vitas/utils/translation_helper.dart';
import '../../../providers/riverpod/user_profile_provider.dart';
import '../../../providers/riverpod/health_data_provider.dart';

class ModernStatsRow extends ConsumerWidget {
  const ModernStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileProvider = ref.watch(userProfileNotifierProvider);
    final healthDataAsync = ref.watch(healthDataNotifierProvider);
    
    final supportersCount = userProfileProvider.value?.supportersCount ?? 0;
    final healthData = healthDataAsync.value;
    
    // Calculate CO2 savings based on real data (if available)
    final totalSteps = healthData?.steps ?? 0;
    final co2Saved = totalSteps > 0 ? (totalSteps * 0.00035).toStringAsFixed(1) : null; // ~0.35g CO2 per step
    
    // Calculate total active time from user progress
    final totalActiveMinutes = healthData?.activeMinutes ?? 0;
    final activeTime = totalActiveMinutes > 0 ? '${(totalActiveMinutes / 60).toStringAsFixed(1)}h' : null;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.people,
              value: supportersCount.toString(),
              label: 'supporters',
              baseColor: Colors.purple,
              hasData: true, // Always show supporter count
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.eco,
              value: co2Saved != null ? '${co2Saved}g' : null,
              label: 'co2_saved',
              baseColor: Colors.green,
              hasData: co2Saved != null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.timer,
              value: activeTime,
              label: 'active_time',
              baseColor: Colors.blue,
              hasData: activeTime != null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String? value,
    required String label,
    required Color baseColor,
    required bool hasData,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            baseColor.withAlpha(128),
            baseColor.withAlpha(179),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: baseColor.withAlpha(71),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            hasData ? value! : '--',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: hasData ? Colors.white : Colors.white54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(context, label),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
