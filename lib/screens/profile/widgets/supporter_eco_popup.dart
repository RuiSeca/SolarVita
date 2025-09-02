import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/riverpod/eco_provider.dart';
import '../../../models/eco/eco_metrics.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';

/// Supporter's eco impact popup - shows another user's eco metrics in a modal overlay
/// Similar to the regular eco popup but for viewing supporter data
class SupporterEcoPopup extends ConsumerStatefulWidget {
  final EcoMetrics ecoMetrics;
  final String supporterName;
  final String supporterId;

  const SupporterEcoPopup({
    super.key,
    required this.ecoMetrics,
    required this.supporterName,
    required this.supporterId,
  });

  static Future<void> show(BuildContext context, EcoMetrics ecoMetrics, String supporterName, String supporterId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (context) => SupporterEcoPopup(
        ecoMetrics: ecoMetrics,
        supporterName: supporterName,
        supporterId: supporterId,
      ),
    );
  }

  @override
  ConsumerState<SupporterEcoPopup> createState() => _SupporterEcoPopupState();
}

class _SupporterEcoPopupState extends ConsumerState<SupporterEcoPopup>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late int _selectedTipIndex;

  // Get rotating eco tips from translations
  List<String> _getEcoTips(BuildContext context) {
    return [
      tr(context, 'tip_0'),
      tr(context, 'tip_1'),
      tr(context, 'tip_2'),
      tr(context, 'tip_3'),
      tr(context, 'tip_4'),
      tr(context, 'tip_5'),
      tr(context, 'tip_6'),
      tr(context, 'tip_7'),
      tr(context, 'tip_8'),
      tr(context, 'tip_9'),
      tr(context, 'tip_10'),
      tr(context, 'tip_11'),
      tr(context, 'tip_12'),
      tr(context, 'tip_13'),
      tr(context, 'tip_14'),
      tr(context, 'tip_15'),
      tr(context, 'tip_16'),
      tr(context, 'tip_17'),
    ];
  }

  @override
  void initState() {
    super.initState();
    
    // Select a random tip index that stays fixed for this popup session
    _selectedTipIndex = DateTime.now().millisecondsSinceEpoch % 18;
    
    _setupAnimations();
    _startEntryAnimation();
  }

  void _setupAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  void _startEntryAnimation() {
    _scaleController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _fadeAnimation]),
      builder: (context, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withValues(alpha: 0.3 * _fadeAnimation.value),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildPopupContent(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopupContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppTheme.surfaceColor(context);
    
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [
                surfaceColor.withValues(alpha: 0.95),
                surfaceColor.withValues(alpha: 0.9),
              ]
            : [
                Colors.white.withValues(alpha: 0.95),
                Colors.white.withValues(alpha: 0.9),
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isDark
            ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
            : const Color(0xFF4CAF50).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildToggleButtons(),
          const SizedBox(height: 20),
          _buildStatsDisplay(),
          const SizedBox(height: 20),
          _buildEcoTip(),
          const SizedBox(height: 24),
          _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
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
              Text(
                "${widget.supporterName}'s ${ref.watch(ecoWidgetViewStateProvider) ? tr(context, 'todays_impact') : tr(context, 'alltime_impact')}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
              Text(
                ref.watch(ecoWidgetViewStateProvider) ? tr(context, 'your_daily_progress') : tr(context, 'your_journey_so_far'),
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textColor(context).withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsDisplay() {
    final showTodaysStats = ref.watch(ecoWidgetViewStateProvider);
    if (showTodaysStats) {
      return _buildTodaysStats();
    } else {
      return _buildAllTimeStats();
    }
  }

  Widget _buildTodaysStats() {
    final supporterTodaysCarbon = ref.watch(supporterTodaysCarbonSavedProvider(widget.supporterId));
    final supporterTodaysBottles = ref.watch(supporterTodaysBottlesSavedProvider(widget.supporterId));
    final supporterTodaysActivityCount = ref.watch(supporterTodaysActivityCountProvider(widget.supporterId));

    return Column(
      children: [
        // Top row
        Row(
          children: [
            Expanded(
              child: supporterTodaysCarbon.when(
                data: (carbon) => _buildStatCard(
                  icon: Icons.co2,
                  value: '${carbon.toStringAsFixed(1)}kg',
                  label: tr(context, 'total_co2'),
                  color: const Color(0xFF4CAF50),
                ),
                loading: () => _buildLoadingCard(tr(context, 'total_co2')),
                error: (_, __) => _buildErrorCard(tr(context, 'total_co2')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: supporterTodaysBottles.when(
                data: (bottles) => _buildStatCard(
                  icon: Icons.water_drop,
                  value: '$bottles',
                  label: tr(context, 'bottles_saved'),
                  color: const Color(0xFF2196F3),
                ),
                loading: () => _buildLoadingCard(tr(context, 'bottles_saved')),
                error: (_, __) => _buildErrorCard(tr(context, 'bottles_saved')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bottom row
        Row(
          children: [
            Expanded(
              child: supporterTodaysActivityCount.when(
                data: (count) => _buildStatCard(
                  icon: Icons.eco,
                  value: '$count',
                  label: tr(context, 'eco_actions'),
                  color: const Color(0xFF8BC34A),
                ),
                loading: () => _buildLoadingCard(tr(context, 'eco_actions')),
                error: (_, __) => _buildErrorCard(tr(context, 'eco_actions')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_fire_department,
                value: '${widget.ecoMetrics.currentStreak}',
                label: tr(context, 'day_streak'),
                color: const Color(0xFFFF9800),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAllTimeStats() {
    return Column(
      children: [
        // Top row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.co2,
                value: '${widget.ecoMetrics.totalCarbonSaved.toStringAsFixed(1)}kg',
                label: tr(context, 'total_co2'),
                color: const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.water_drop,
                value: '${widget.ecoMetrics.plasticBottlesSaved}',
                label: tr(context, 'bottles_saved'),
                color: const Color(0xFF2196F3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bottom row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_fire_department,
                value: '${widget.ecoMetrics.currentStreak}',
                label: tr(context, 'day_streak'),
                color: const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.stars,
                value: '${widget.ecoMetrics.ecoScore}',
                label: tr(context, 'eco_points'),
                color: const Color(0xFFFFC107),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
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
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEcoTip() {
    final ecoTips = _getEcoTips(context);
    final tip = ecoTips[_selectedTipIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4CAF50).withValues(alpha: 0.1),
            const Color(0xFF66BB6A).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: const Color(0xFF4CAF50).withValues(alpha: 0.8),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textColor(context).withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    final showTodaysStats = ref.watch(ecoWidgetViewStateProvider);
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              text: tr(context, 'todays_stats'),
              isSelected: showTodaysStats,
              onTap: () => ref.read(ecoWidgetViewStateProvider.notifier).state = true,
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              text: tr(context, 'all_time'),
              isSelected: !showTodaysStats,
              onTap: () => ref.read(ecoWidgetViewStateProvider.notifier).state = false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected 
                ? Colors.white 
                : AppTheme.textColor(context).withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(String label) {
    return _buildStatCard(
      icon: Icons.hourglass_empty,
      value: '--',
      label: label,
      color: Colors.grey,
    );
  }

  Widget _buildErrorCard(String label) {
    return _buildStatCard(
      icon: Icons.error_outline,
      value: '!',
      label: label,
      color: Colors.orange,
    );
  }

  Widget _buildCloseButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4CAF50),
          side: const BorderSide(color: Color(0xFF4CAF50)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          tr(context, 'close'),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}