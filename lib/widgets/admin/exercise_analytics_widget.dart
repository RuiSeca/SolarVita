import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod/exercise_provider.dart';
import '../../services/exercises/optimized_exercise_service.dart';
import '../../theme/app_theme.dart';

/// Analytics widget to monitor ExerciseDB API optimization
/// Shows cache hits, API calls saved, and performance metrics
class ExerciseAnalyticsWidget extends ConsumerWidget {
  const ExerciseAnalyticsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(exerciseServiceProvider) as OptimizedExerciseService;
    final analytics = service.getUsageAnalytics();
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'API Optimization Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Key metrics row
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'API Calls',
                    analytics['totalApiCalls'].toString(),
                    Icons.cloud_upload_outlined,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Cache Hits',
                    analytics['cacheHits'].toString(),
                    Icons.memory_outlined,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Hit Rate',
                    analytics['cacheHitRate'].toString(),
                    Icons.trending_up_outlined,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Secondary metrics
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow(
                    'Active Cache Entries',
                    analytics['activeCacheEntries'].toString(),
                    Icons.storage_outlined,
                  ),
                ),
                Expanded(
                  child: _buildDetailRow(
                    'Active Requests',
                    analytics['activeRequests'].toString(),
                    Icons.sync_outlined,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Cost savings estimate
            _buildCostSavingsEstimate(context, analytics),
            
            const SizedBox(height: 12),
            
            // Action buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _resetAnalytics(ref),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _clearCache(ref),
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear Cache'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textColor(context).withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostSavingsEstimate(
    BuildContext context,
    Map<String, dynamic> analytics,
  ) {
    final apiCalls = analytics['totalApiCalls'] as int;
    final cacheHits = analytics['cacheHits'] as int;
    final totalRequests = apiCalls + cacheHits;
    
    if (totalRequests == 0) {
      return const SizedBox.shrink();
    }
    
    // Estimate cost savings ($0.001 per API call)
    final savedCalls = cacheHits;
    final savedCost = savedCalls * 0.001;
    final potentialCost = totalRequests * 0.001;
    final actualCost = apiCalls * 0.001;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.1),
            Colors.green.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.savings_outlined, color: Colors.green, size: 16),
              const SizedBox(width: 6),
              Text(
                'Cost Savings Estimate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Potential Cost: \$${potentialCost.toStringAsFixed(3)}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Actual Cost: \$${actualCost.toStringAsFixed(3)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Saved: \$${savedCost.toStringAsFixed(3)} ($savedCalls calls)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _resetAnalytics(WidgetRef ref) {
    final service = ref.read(exerciseServiceProvider) as OptimizedExerciseService;
    service.resetAnalytics();
    // Refresh the analytics display
    ref.invalidate(exerciseServiceProvider);
  }

  void _clearCache(WidgetRef ref) {
    final service = ref.read(exerciseServiceProvider) as OptimizedExerciseService;
    service.clearSessionCache();
    // Also clear the provider cache
    ref.read(exerciseNotifierProvider.notifier).clearExercises();
    // Refresh the analytics display
    ref.invalidate(exerciseServiceProvider);
  }
}

/// Smaller widget for showing just the key metrics in debug mode
class ExerciseAnalyticsIndicator extends ConsumerWidget {
  const ExerciseAnalyticsIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(exerciseServiceProvider) as OptimizedExerciseService;
    final analytics = service.getUsageAnalytics();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            'API: ${analytics['totalApiCalls']} | Cache: ${analytics['cacheHitRate']}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}