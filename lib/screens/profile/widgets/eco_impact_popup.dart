import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/riverpod/eco_provider.dart';
import '../../../providers/riverpod/auth_provider.dart';
import '../../../models/eco/eco_metrics.dart';
import '../../../models/eco/carbon_activity.dart';
import '../../../theme/app_theme.dart';
import '../screens/eco_impact_screen.dart';

/// Modern custom overlay popup for eco impact stats
/// Features blur background, smooth animations, and toggle between daily/all-time
class EcoImpactPopup extends ConsumerStatefulWidget {
  final EcoMetrics ecoMetrics;

  const EcoImpactPopup({
    super.key,
    required this.ecoMetrics,
  });

  @override
  ConsumerState<EcoImpactPopup> createState() => _EcoImpactPopupState();

  /// Show the popup with beautiful animations
  static Future<void> show(
    BuildContext context,
    EcoMetrics ecoMetrics,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (context) => EcoImpactPopup(ecoMetrics: ecoMetrics),
    );
  }
}

class _EcoImpactPopupState extends ConsumerState<EcoImpactPopup>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _showTodaysStats = true;

  // Rotating eco tips
  final List<String> _ecoTips = [
    "🌱 Great job! You're making a difference!",
    "🌍 Every small action counts toward a greener future",
    "♻️ Your eco choices inspire others to follow",
    "🌿 Together we can heal our planet",
    "💚 Sustainable living is the way forward",
    "🌳 Thank you for caring about our Earth",
    "⚡ Clean energy powers a better tomorrow",
    "🚲 Active transportation keeps you and Earth healthy",
  ];

  @override
  void initState() {
    super.initState();
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
      curve: Curves.easeOut,
    ));
  }

  Future<void> _startEntryAnimation() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _scaleController.forward();
  }

  Future<void> _closePopup() async {
    await _scaleController.reverse();
    await _fadeController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _fadeAnimation]),
        builder: (context, child) {
          return Stack(
            children: [
              // Blur background
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3 * _fadeAnimation.value),
                ),
              ),
              // Popup content
              Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: _buildPopupContent(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
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
          // Header with close button
          _buildHeader(),
          const SizedBox(height: 20),
          // Stats display
          _buildStatsDisplay(),
          const SizedBox(height: 20),
          // Eco tip
          _buildEcoTip(),
          const SizedBox(height: 24),
          // Toggle buttons
          _buildToggleButtons(),
          const SizedBox(height: 24),
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                const Color(0xFF4CAF50).withValues(alpha: 0.2),
                const Color(0xFF4CAF50).withValues(alpha: 0.1),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.eco,
            color: Color(0xFF4CAF50),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _showTodaysStats ? "Today's Impact" : "All-Time Impact",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              Text(
                _showTodaysStats ? "Your daily progress" : "Your journey so far",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _closePopup,
          icon: Icon(
            Icons.close,
            color: Colors.grey.shade600,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsDisplay() {
    if (_showTodaysStats) {
      return _buildTodaysStats();
    } else {
      return _buildAllTimeStats();
    }
  }

  Widget _buildTodaysStats() {
    final todaysCarbon = ref.watch(todaysCarbonSavedProvider);
    final todaysBottles = ref.watch(todaysBottlesSavedProvider);
    final todaysActivityCount = ref.watch(todaysActivityCountProvider);

    return todaysCarbon.when(
      loading: () => _buildLoadingStats(),
      error: (_, __) => _buildErrorStats(),
      data: (carbonSaved) => Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.co2,
              value: '${carbonSaved.toStringAsFixed(1)}kg',
              label: 'CO₂ Saved',
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: todaysBottles.when(
              data: (bottles) => _buildStatCard(
                icon: Icons.water_drop,
                value: '$bottles',
                label: 'Bottles',
                color: const Color(0xFF2196F3),
              ),
              loading: () => _buildLoadingStatCard(),
              error: (_, __) => _buildErrorStatCard(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: todaysActivityCount.when(
              data: (count) => _buildStatCard(
                icon: Icons.eco,
                value: '$count',
                label: 'Actions',
                color: const Color(0xFF8BC34A),
              ),
              loading: () => _buildLoadingStatCard(),
              error: (_, __) => _buildErrorStatCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTimeStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.co2,
            value: '${widget.ecoMetrics.totalCarbonSaved.toStringAsFixed(1)}kg',
            label: 'Total CO₂',
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department,
            value: '${widget.ecoMetrics.currentStreak}',
            label: 'Day Streak',
            color: const Color(0xFFFF9800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.stars,
            value: '${widget.ecoMetrics.ecoScore}',
            label: 'Eco Points',
            color: const Color(0xFFFFC107),
          ),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
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
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStats() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Color(0xFF4CAF50)),
        SizedBox(width: 16),
        Text('Loading today\'s impact...'),
      ],
    );
  }

  Widget _buildErrorStats() {
    return Text(
      'Unable to load today\'s stats',
      style: TextStyle(color: Colors.red.shade600),
    );
  }

  Widget _buildLoadingStatCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(height: 8),
          Text('--', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Loading', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildErrorStatCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20),
          SizedBox(height: 8),
          Text('--', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Error', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEcoTip() {
    final tipIndex = DateTime.now().millisecond % _ecoTips.length;
    final tip = _ecoTips[tipIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withValues(alpha: 0.1),
            const Color(0xFF8BC34A).withValues(alpha: 0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Color(0xFF4CAF50),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
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
              text: "Today's Stats",
              isSelected: _showTodaysStats,
              onTap: () => setState(() => _showTodaysStats = true),
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              text: "All-Time",
              isSelected: !_showTodaysStats,
              onTap: () => setState(() => _showTodaysStats = false),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: isSelected
            ? const Color(0xFF4CAF50)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              await _closePopup();
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EcoImpactScreen(),
                  ),
                );
              }
            },
            icon: const Icon(Icons.analytics, size: 18),
            label: const Text('View Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await _closePopup();
              if (mounted) {
                _showQuickLogDialog(context, ref);
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Log Activity'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4CAF50),
              side: const BorderSide(color: Color(0xFF4CAF50)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showQuickLogDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4CAF50).withValues(alpha: 0.2),
                    const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.eco,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quick Log Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose an eco-friendly action you just completed',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor(context).withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildQuickActivityButton(
              context,
              ref,
              'Used Reusable Bottle',
              Icons.water_drop,
              Colors.blue,
              () async {
                final actions = ref.read(ecoActivityActionsProvider);
                await actions.logConsumptionActivity('reusableBottle');
                if (context.mounted) {
                  Navigator.pop(context);
                  _showSuccessMessage(context, 'Reusable bottle logged!');
                }
              },
            ),
            const SizedBox(height: 12),
            _buildQuickActivityButton(
              context,
              ref,
              'Walked/Biked Instead',
              Icons.directions_walk,
              Colors.green,
              () async {
                final actions = ref.read(ecoActivityActionsProvider);
                await actions.logTransportActivity('walking');
                if (context.mounted) {
                  Navigator.pop(context);
                  _showSuccessMessage(context, 'Active transport logged!');
                }
              },
            ),
            const SizedBox(height: 12),
            _buildQuickActivityButton(
              context,
              ref,
              'Recycled Items',
              Icons.recycling,
              Colors.orange,
              () async {
                final actions = ref.read(ecoActivityActionsProvider);
                final currentUser = ref.read(currentUserProvider);
                if (currentUser != null) {
                  final ecoActivity = EcoActivity(
                    id: '',
                    userId: currentUser.uid,
                    type: EcoActivityType.waste,
                    activity: 'recycling',
                    carbonSaved: 0.3, // Default recycling carbon saved
                    date: DateTime.now(),
                  );
                  await actions.addActivity(ecoActivity);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  _showSuccessMessage(context, 'Recycling activity logged!');
                }
              },
            ),
            const SizedBox(height: 12),
            _buildQuickActivityButton(
              context,
              ref,
              'Saved Energy',
              Icons.lightbulb_outline,
              Colors.amber,
              () async {
                final actions = ref.read(ecoActivityActionsProvider);
                final currentUser = ref.read(currentUserProvider);
                if (currentUser != null) {
                  final ecoActivity = EcoActivity(
                    id: '',
                    userId: currentUser.uid,
                    type: EcoActivityType.energy,
                    activity: 'unplugDevices',
                    carbonSaved: 0.5, // Default energy saving carbon saved
                    date: DateTime.now(),
                  );
                  await actions.addActivity(ecoActivity);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  _showSuccessMessage(context, 'Energy saving logged!');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActivityButton(
    BuildContext context,
    WidgetRef ref,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.add_circle_outline,
                  color: color,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}