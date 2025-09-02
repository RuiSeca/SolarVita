import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/eco/eco_metrics.dart';
import '../../../utils/translation_helper.dart';
import '../../../providers/riverpod/eco_provider.dart';
import 'eco_impact_popup.dart';

/// Futuristic eco impact widget with 2x2 grid layout
/// Combines modern tech aesthetics with nature-inspired design
class FuturisticEcoGrid extends ConsumerWidget {
  final EcoMetrics ecoMetrics;
  
  const FuturisticEcoGrid({
    super.key,
    required this.ecoMetrics,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isShowingToday = ref.watch(ecoWidgetViewStateProvider);
    
    return GestureDetector(
      onTap: () => EcoImpactPopup.show(context, ecoMetrics),
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Futuristic gradient - nature meets technology
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1a4645).withValues(alpha: 0.9), // Deep forest green
            const Color(0xFF2d5a27).withValues(alpha: 0.8), // Rich pine
            const Color(0xFF4a7c59).withValues(alpha: 0.7), // Sage green
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        // Futuristic glow effect
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 16),
          ),
        ],
        // Subtle border for tech feel
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header with holographic effect
          _buildHeader(context, ref, isShowingToday),
          const SizedBox(height: 24),
          // 2x2 Grid
          _build2x2Grid(context, ref, isShowingToday),
        ],
      ),
    ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isShowingToday) {
    return Row(
      children: [
        // Animated eco icon with glow
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                const Color(0xFF66BB6A).withValues(alpha: 0.3),
                const Color(0xFF4CAF50).withValues(alpha: 0.1),
              ],
            ),
            shape: BoxShape.circle,
            // Inner glow effect
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Icon(
            Icons.eco,
            color: Color(0xFF81C784),
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Futuristic title with gradient text effect
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF81C784), // Light green
                    Color(0xFFA5D6A7), // Very light green
                    Color(0xFFE8F5E8), // Almost white green
                  ],
                ).createShader(bounds),
                child: Text(
                  isShowingToday ? tr(context, 'todays_impact') : tr(context, 'alltime_impact'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white, // This will be masked by shader
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Subtitle with tech aesthetic
              Text(
                tr(context, 'future_earth_today'),
                style: TextStyle(
                  color: const Color(0xFFA5D6A7).withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        // Hologram-style status indicator
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _build2x2Grid(BuildContext context, WidgetRef ref, bool isShowingToday) {
    if (isShowingToday) {
      // Today's stats - show daily progress
      return _buildTodayStatsGrid(context, ref);
    } else {
      // All-time stats - show cumulative achievements
      return _buildAllTimeStatsGrid(context);
    }
  }

  Widget _buildTodayStatsGrid(BuildContext context, WidgetRef ref) {
    final todaysCarbon = ref.watch(todaysCarbonSavedProvider);
    final todaysBottles = ref.watch(todaysBottlesSavedProvider);
    final todaysActivityCount = ref.watch(todaysActivityCountProvider);

    return Column(
      children: [
        // Top row
        Row(
          children: [
            Expanded(
              child: todaysCarbon.when(
                data: (carbon) => _buildEcoStatCard(
                  context,
                  icon: Icons.co2_outlined,
                  value: carbon.toStringAsFixed(1),
                  unit: 'kg',
                  label: tr(context, 'co2_saved'),
                  color: const Color(0xFF4CAF50), // Natural green
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
              child: todaysBottles.when(
                data: (bottles) => _buildEcoStatCard(
                  context,
                  icon: Icons.water_drop_outlined,
                  value: '$bottles',
                  label: tr(context, 'bottles_equivalent'),
                  color: const Color(0xFF03A9F4), // Cyan blue - water
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
              child: todaysActivityCount.when(
                data: (count) => _buildEcoStatCard(
                  context,
                  icon: Icons.eco_outlined,
                  value: '$count',
                  label: tr(context, 'eco_actions'),
                  color: const Color(0xFF8BC34A), // Light green
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
                color: const Color(0xFFFF6F00), // Energy orange
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

  Widget _buildAllTimeStatsGrid(BuildContext context) {
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
                color: const Color(0xFF03A9F4), // Cyan blue - water
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
                color: const Color(0xFF4CAF50), // Natural green
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
                color: const Color(0xFFFF6F00), // Energy orange
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
                color: const Color(0xFFFFC107), // Golden amber
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
    String? unit,
    required Color color,
    required List<Color> gradient,
    required EcoCardAnimation animationType,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animationValue),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // Glass morphism effect
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
              // Futuristic glow
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
              // Subtle gradient backdrop
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated icon with holographic effect
                _buildAnimatedIcon(
                  icon: icon,
                  color: color,
                  animationType: animationType,
                  animationValue: animationValue,
                ),
                const SizedBox(height: 12),
                
                // Value with futuristic number styling
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Animated number counter
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 800),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        // Digital/tech font feel
                        letterSpacing: 0.5,
                        // Subtle text shadow for depth
                        shadows: [
                          Shadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(value),
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: 2),
                      Text(
                        unit,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color.withValues(alpha: 0.8),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                
                // Label with tech aesthetics
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 0.8,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Animated progress indicator
                const SizedBox(height: 8),
                _buildProgressIndicator(
                  color: color,
                  animationValue: animationValue,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedIcon({
    required IconData icon,
    required Color color,
    required EcoCardAnimation animationType,
    required double animationValue,
  }) {
    Widget iconWidget = Icon(
      icon,
      size: 32,
      color: color,
    );

    // Apply different animation effects
    switch (animationType) {
      case EcoCardAnimation.flow:
        return Transform.translate(
          offset: Offset(0, -2 * (1 - animationValue)),
          child: iconWidget,
        );
      case EcoCardAnimation.particles:
        return Transform.rotate(
          angle: 0.1 * animationValue,
          child: iconWidget,
        );
      case EcoCardAnimation.pulse:
        return Transform.scale(
          scale: 1.0 + (0.1 * animationValue),
          child: iconWidget,
        );
      case EcoCardAnimation.shimmer:
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              color,
              color.withValues(alpha: 0.7),
              Colors.white.withValues(alpha: 0.9),
              color,
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
            transform: GradientRotation(animationValue * 3.14159 * 2),
          ).createShader(bounds),
          child: iconWidget,
        );
    }
  }

  Widget _buildProgressIndicator({
    required Color color,
    required double animationValue,
  }) {
    return Container(
      width: 40,
      height: 2,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(1),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: animationValue,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(1),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
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
}

enum EcoCardAnimation {
  flow,      // Water-like flowing motion
  particles, // Carbon particle effect
  pulse,     // Streak pulse effect
  shimmer,   // Score shimmer effect
}