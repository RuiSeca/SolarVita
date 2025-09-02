import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/eco/eco_metrics.dart';
import '../../../models/user/privacy_settings.dart';
import '../../../utils/translation_helper.dart';
import '../../../providers/riverpod/eco_provider.dart';
import '../../../theme/app_theme.dart';
import 'supporter_eco_popup.dart';

/// Supporter's eco impact widget - shows another user's eco metrics
/// Respects privacy settings and displays eco data when permitted
class SupporterEcoWidget extends ConsumerWidget {
  final String supporterId;
  final PrivacySettings privacySettings;
  final String supporterName;

  const SupporterEcoWidget({
    super.key,
    required this.supporterId,
    required this.privacySettings,
    required this.supporterName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Validate supporter ID
    if (supporterId.isEmpty) {
      return _buildErrorWidget(context, 'Invalid supporter ID');
    }

    // Check if eco stats are allowed to be shown
    if (!privacySettings.showEcoScore) {
      return _buildPrivacyBlockedWidget(context);
    }

    // Get supporter's eco metrics
    final supporterEcoMetrics = ref.watch(supporterEcoMetricsProvider(supporterId));

    return Container(
      margin: const EdgeInsets.all(16),
      child: supporterEcoMetrics.when(
        loading: () => _buildLoadingWidget(context),
        error: (error, stackTrace) => _buildErrorWidget(context, error),
        data: (ecoMetrics) => _buildEcoWidget(context, ref, ecoMetrics),
      ),
    );
  }

  Widget _buildEcoWidget(BuildContext context, WidgetRef ref, EcoMetrics ecoMetrics) {
    final isShowingToday = ref.watch(ecoWidgetViewStateProvider);
    
    return GestureDetector(
      onTap: () => SupporterEcoPopup.show(context, ecoMetrics, supporterName, supporterId),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.withValues(alpha: 0.1),
              Colors.blue.withValues(alpha: 0.08),
              Colors.teal.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.1),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(context, ref, isShowingToday),
            const SizedBox(height: 24),
            // 2x2 Grid
            _build2x2Grid(context, ref, isShowingToday, ecoMetrics),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isShowingToday) {
    return Row(
      children: [
        // Eco icon with glow effect
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF4CAF50),
                Color(0xFF66BB6A),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                spreadRadius: 0,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.eco,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title with supporter's name
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF81C784),
                    Color(0xFFA5D6A7),
                    Color(0xFFE8F5E8),
                  ],
                ).createShader(bounds),
                child: Text(
                  "$supporterName's ${isShowingToday ? tr(context, 'todays_impact') : tr(context, 'alltime_impact')}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Subtitle
              Text(
                tr(context, 'future_earth_today'),
                style: TextStyle(
                  color: const Color(0xFFA5D6A7).withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _build2x2Grid(BuildContext context, WidgetRef ref, bool isShowingToday, EcoMetrics ecoMetrics) {
    if (isShowingToday) {
      return _buildTodayStatsGrid(context, ref, ecoMetrics);
    } else {
      return _buildAllTimeStatsGrid(context, ecoMetrics);
    }
  }

  Widget _buildTodayStatsGrid(BuildContext context, WidgetRef ref, EcoMetrics ecoMetrics) {
    final supporterTodaysCarbon = ref.watch(supporterTodaysCarbonSavedProvider(supporterId));
    final supporterTodaysBottles = ref.watch(supporterTodaysBottlesSavedProvider(supporterId));
    final supporterTodaysActivityCount = ref.watch(supporterTodaysActivityCountProvider(supporterId));

    return Column(
      children: [
        // Top row
        Row(
          children: [
            Expanded(
              child: supporterTodaysCarbon.when(
                data: (carbon) => _buildEcoStatCard(
                  context,
                  icon: Icons.co2_outlined,
                  value: '${carbon.toStringAsFixed(1)}kg',
                  label: tr(context, 'co2_saved'),
                  color: const Color(0xFF4CAF50),
                  gradient: const [
                    Color(0xFF2E7D32),
                    Color(0xFF4CAF50),
                    Color(0xFF66BB6A),
                  ],
                  animationType: EcoCardAnimation.particles,
                ),
                loading: () => _buildLoadingCard(context, tr(context, 'co2_saved')),
                error: (_, __) => _buildErrorCard(context, tr(context, 'co2_saved')),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: supporterTodaysBottles.when(
                data: (bottles) => _buildEcoStatCard(
                  context,
                  icon: Icons.water_drop_outlined,
                  value: '$bottles',
                  label: tr(context, 'bottles_equivalent'),
                  color: const Color(0xFF03A9F4),
                  gradient: const [
                    Color(0xFF0277BD),
                    Color(0xFF03A9F4),
                    Color(0xFF4FC3F7),
                  ],
                  animationType: EcoCardAnimation.flow,
                ),
                loading: () => _buildLoadingCard(context, tr(context, 'bottles_equivalent')),
                error: (_, __) => _buildErrorCard(context, tr(context, 'bottles_equivalent')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Bottom row
        Row(
          children: [
            Expanded(
              child: supporterTodaysActivityCount.when(
                data: (count) => _buildEcoStatCard(
                  context,
                  icon: Icons.eco_outlined,
                  value: '$count',
                  label: tr(context, 'eco_actions'),
                  color: const Color(0xFF8BC34A),
                  gradient: const [
                    Color(0xFF689F38),
                    Color(0xFF8BC34A),
                    Color(0xFFAED581),
                  ],
                  animationType: EcoCardAnimation.pulse,
                ),
                loading: () => _buildLoadingCard(context, tr(context, 'eco_actions')),
                error: (_, __) => _buildErrorCard(context, tr(context, 'eco_actions')),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildEcoStatCard(
                context,
                icon: Icons.local_fire_department_outlined,
                value: '${ecoMetrics.currentStreak}',
                label: tr(context, 'day_streak'),
                unit: tr(context, 'days'),
                color: const Color(0xFFFF6F00),
                gradient: const [
                  Color(0xFFE65100),
                  Color(0xFFFF6F00),
                  Color(0xFFFF8F00),
                ],
                animationType: EcoCardAnimation.pulse,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAllTimeStatsGrid(BuildContext context, EcoMetrics ecoMetrics) {
    return Column(
      children: [
        // Top row
        Row(
          children: [
            Expanded(
              child: _buildEcoStatCard(
                context,
                icon: Icons.water_drop_outlined,
                value: '${ecoMetrics.plasticBottlesSaved}',
                label: tr(context, 'bottles_saved'),
                color: const Color(0xFF03A9F4),
                gradient: const [
                  Color(0xFF0277BD),
                  Color(0xFF03A9F4),
                  Color(0xFF4FC3F7),
                ],
                animationType: EcoCardAnimation.flow,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildEcoStatCard(
                context,
                icon: Icons.co2_outlined,
                value: ecoMetrics.totalCarbonSaved.toStringAsFixed(1),
                unit: 'kg',
                label: tr(context, 'total_co2'),
                color: const Color(0xFF4CAF50),
                gradient: const [
                  Color(0xFF2E7D32),
                  Color(0xFF4CAF50),
                  Color(0xFF66BB6A),
                ],
                animationType: EcoCardAnimation.particles,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Bottom row
        Row(
          children: [
            Expanded(
              child: _buildEcoStatCard(
                context,
                icon: Icons.local_fire_department_outlined,
                value: '${ecoMetrics.currentStreak}',
                label: tr(context, 'eco_streak'),
                unit: tr(context, 'days'),
                color: const Color(0xFFFF6F00),
                gradient: const [
                  Color(0xFFE65100),
                  Color(0xFFFF6F00),
                  Color(0xFFFF8F00),
                ],
                animationType: EcoCardAnimation.pulse,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildEcoStatCard(
                context,
                icon: Icons.star_outline,
                value: '${ecoMetrics.ecoScore}',
                label: tr(context, 'eco_score'),
                unit: tr(context, 'pts'),
                color: const Color(0xFFFFC107),
                gradient: const [
                  Color(0xFFFF8F00),
                  Color(0xFFFFC107),
                  Color(0xFFFFD54F),
                ],
                animationType: EcoCardAnimation.shimmer,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEcoStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required List<Color> gradient,
    required EcoCardAnimation animationType,
    String? unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient.map((c) => c.withValues(alpha: 0.15)).toList(),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor(context).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context, String label) {
    return _buildEcoStatCard(
      context,
      icon: Icons.hourglass_empty,
      value: '--',
      label: label,
      color: Colors.grey,
      gradient: const [
        Color(0xFF757575),
        Color(0xFF9E9E9E),
        Color(0xFFBDBDBD),
      ],
      animationType: EcoCardAnimation.pulse,
    );
  }

  Widget _buildErrorCard(BuildContext context, String label) {
    return _buildEcoStatCard(
      context,
      icon: Icons.error_outline,
      value: '!',
      label: label,
      color: Colors.orange,
      gradient: const [
        Color(0xFFE65100),
        Color(0xFFFF6F00),
        Color(0xFFFF8F00),
      ],
      animationType: EcoCardAnimation.pulse,
    );
  }

  Widget _buildPrivacyBlockedWidget(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.eco_outlined,
            size: 48,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            tr(context, 'eco_stats_private'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'eco_stats_privacy_message'),
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textColor(context).withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            tr(context, 'loading_eco_data'),
            style: TextStyle(
              color: AppTheme.textColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, dynamic error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            tr(context, 'error_loading_eco_data'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

enum EcoCardAnimation {
  flow,
  particles,
  pulse,
  shimmer,
}