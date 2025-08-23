import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/health_alerts/pulse_color_manager.dart';
import '../services/health_alerts/health_alert_models.dart';
import '../services/health_alerts/smart_health_data_collector.dart';
import '../services/health_alerts/health_info_service.dart';
import '../widgets/health_info_popup.dart';
import '../screens/health_info_screen.dart';
import '../utils/translation_helper.dart';
import 'dart:async';

class WellnessBreathingPulse extends StatefulWidget {
  final double height;
  final VoidCallback? onTap;
  final Widget? child;
  final bool showColorSelector;

  const WellnessBreathingPulse({
    super.key,
    this.height = 280,
    this.onTap,
    this.child,
    this.showColorSelector = true,
  });

  @override
  State<WellnessBreathingPulse> createState() => _WellnessBreathingPulseState();
}

class _WellnessBreathingPulseState extends State<WellnessBreathingPulse>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _colorController;
  late AnimationController _typewriterController;
  PulseColorManager? _colorManager;
  
  String _displayedText = '';
  String _targetText = '';
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation (breathing rhythm)
    _pulseController = AnimationController(
      duration: Duration(seconds: 4), // Slow breathing rhythm
      vsync: this,
    )..repeat();
    
    // Color transition animation
    _colorController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    // Typewriter animation
    _typewriterController = AnimationController(
      duration: Duration(milliseconds: 1200), // Faster: 2000ms -> 1200ms
      vsync: this,
    );
    
    _initializeColorManager();
  }

  Future<void> _initializeColorManager() async {
    _colorManager = PulseColorManager.instance;
    await _colorManager!.initialize(vsync: this);
    
    // Listen to color changes
    _colorManager!.addListener(() {
      if (mounted) {
        _updateStatusLabel();
        setState(() {});
      }
    });
    
    // Set initial status label
    _updateStatusLabel();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _colorController.dispose();
    _typewriterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Transform.translate(
        offset: Offset(0, -widget.height * 0.1), // Move up by 10% of height
        child: Stack(
          alignment: Alignment.center,
          children: [
          // Pulse background effect
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return CustomPaint(
                painter: BreathingPulsePainter(
                  animationValue: _getBreathingValue(_pulseController.value),
                  baseColor: _colorManager?.currentColor ?? Colors.green.shade400,
                ),
                size: Size.infinite,
              );
            },
          ),
          
          // Center content
          if (widget.child != null)
            widget.child!
          else
            _buildDefaultContent(),
          
          // Color selector button
          if (widget.showColorSelector)
            Positioned(
              bottom: 16,
              right: 16,
              child: _buildColorSelector(),
            ),
          
          // Tap detector (excluding color selector area)
          if (widget.onTap != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  color: Colors.transparent,
                  margin: EdgeInsets.only(
                    bottom: widget.showColorSelector ? 60 : 0,
                    right: widget.showColorSelector ? 60 : 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.spa,
          size: 48,
          color: textColor,
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            Text(
              tr(context, 'take_moment_breathe'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              tr(context, 'wellness_matters'),
              style: TextStyle(
                fontSize: 14,
                color: textColor.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            _buildStatusLabel(textColor),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentColor = _colorManager?.currentColor ?? Colors.green.shade400;
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark 
          ? Colors.white.withValues(alpha: 0.9)
          : Colors.black.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: FloatingActionButton.small(
        onPressed: _showMoodSelector,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(
          Icons.palette,
          color: isDark ? currentColor : Colors.white,
          size: 20,
        ),
      ),
    );
  }

  void _showMoodSelector() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildMoodSelectorSheet(),
    );
  }

  Widget _buildMoodSelectorSheet() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tr(context, 'choose_wellness_mood'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            tr(context, 'select_color_mood'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: PulseColorManager.getMoodOptions().map((mood) {
              return GestureDetector(
                onTap: () {
                  _colorManager?.setUserMoodColor(
                    mood['color'],
                    description: mood['name'],
                  );
                  Navigator.pop(context);
                  _showMoodFeedback(mood['name'], mood['color']);
                },
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: mood['color'],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        mood['icon'],
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      tr(context, 'mood_options.${mood['name'].toLowerCase()}'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          TextButton(
            onPressed: () {
              _colorManager?.clearUserOverride();
              Navigator.pop(context);
            },
            child: Text(tr(context, 'reset_automatic')),
          ),
        ],
      ),
    );
  }

  void _showMoodFeedback(String moodName, Color moodColor) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => _buildMoodConfirmationDialog(moodName, moodColor),
    );
  }

  Widget _buildMoodConfirmationDialog(String moodName, Color moodColor) {
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated mood indicator
            TweenAnimationBuilder(
              duration: Duration(milliseconds: 600),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: moodColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: moodColor,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.spa,
                      size: 40,
                      color: moodColor,
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: 20),
            
            // Title
            Text(
              tr(context, 'mood_set'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: moodColor,
              ),
            ),
            
            SizedBox(height: 12),
            
            // Description
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: "${tr(context, 'mood_reflecting')} "),
                  TextSpan(
                    text: tr(context, 'mood_options.${moodName.toLowerCase()}').toLowerCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: moodColor,
                    ),
                  ),
                  TextSpan(text: " ${tr(context, 'mood_for_next')} "),
                  TextSpan(
                    text: tr(context, 'thirty_minutes'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: moodColor,
                    ),
                  ),
                  TextSpan(text: "."),
                ],
              ),
            ),
            
            SizedBox(height: 8),
            
            Text(
              tr(context, 'after_return_health'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 24),
            
            // Close button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: moodColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: Text(
                tr(context, 'perfect'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update status label based on current state
  void _updateStatusLabel() {
    final colorManager = _colorManager;
    if (colorManager == null) return;
    
    final activeSource = colorManager.activeSource;
    String newTargetText;
    
    if (activeSource?.priority == ColorPriority.userOverride) {
      // Show mood name
      final moodName = activeSource?.description?.replaceAll('User selected mood', '').trim() ?? '';
      if (moodName.isNotEmpty) {
        newTargetText = tr(context, 'mood_options.${moodName.toLowerCase()}');
      } else {
        newTargetText = tr(context, 'solar');
      }
    } else {
      // Check health data for alert level
      final healthCollector = SmartHealthDataCollector.instance;
      final healthSummary = healthCollector.getHealthSummary();
      final alertLevel = healthSummary['alertLevel'] ?? AlertLevel.normal;
      
      switch (alertLevel) {
        case AlertLevel.critical:
        case AlertLevel.high:
          newTargetText = tr(context, 'major_concern');
          break;
        case AlertLevel.warning:
          newTargetText = tr(context, 'minor_concern');
          break;
        default:
          newTargetText = tr(context, 'solar');
      }
    }
    
    if (newTargetText != _targetText) {
      _targetText = newTargetText;
      // Don't auto-start animation here, wait for scroll trigger
      if (_hasAnimated) {
        // Update immediately if already animated
        setState(() {
          _displayedText = _targetText;
        });
      }
    }
  }
  
  // Start typewriter animation
  void _startTypewriterAnimation() {
    if (_hasAnimated) return;
    
    _hasAnimated = true;
    _displayedText = '';
    _typewriterController.reset();
    
    // Create smooth curved animation
    final curvedAnimation = CurvedAnimation(
      parent: _typewriterController,
      curve: Curves.easeOutQuart, // Smooth ease-out curve
    );
    
    curvedAnimation.addListener(() {
      final progress = curvedAnimation.value;
      final targetLength = _targetText.length;
      final currentLength = (progress * targetLength).round().clamp(0, targetLength);
      
      setState(() {
        _displayedText = _targetText.substring(0, currentLength);
      });
    });
    
    _typewriterController.forward();
  }
  
  // Reset animation state (call when user scrolls away and back)
  void resetAnimation() {
    _hasAnimated = false;
    _displayedText = '';
  }
  
  // Trigger animation when pulse becomes visible
  void triggerAnimation() {
    if (!_hasAnimated && _targetText.isNotEmpty) {
      _startTypewriterAnimation();
    }
  }
  
  // Build status label widget
  Widget _buildStatusLabel(Color textColor) {
    // Animation will be triggered by scroll visibility, not automatically
    
    return AnimatedOpacity(
      opacity: _displayedText.isNotEmpty ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: textColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          _displayedText,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
  
  // Calculate breathing animation value
  double _getBreathingValue(double animationValue) {
    if (animationValue <= 0.4) {
      // Inhale - gradual expansion (40% of cycle)
      return Curves.easeInOut.transform(animationValue / 0.4);
    } else if (animationValue <= 0.6) {
      // Hold - stay expanded (20% of cycle)
      return 1.0;
    } else {
      // Exhale - gentle contraction (40% of cycle)
      double exhaleProgress = (animationValue - 0.6) / 0.4;
      return 1.0 - Curves.easeInOut.transform(exhaleProgress);
    }
  }
}

class BreathingPulsePainter extends CustomPainter {
  final double animationValue;
  final Color baseColor;

  BreathingPulsePainter({
    required this.animationValue,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.4;

    // Create multiple concentric circles with different opacities
    for (int i = 0; i < 4; i++) {
      final radius = maxRadius * (0.3 + 0.7 * animationValue) * (1 + i * 0.25);
      final opacity = (0.4 - i * 0.08) * (0.5 + 0.5 * animationValue);
      
      // Create radial gradient for each circle
      final gradient = RadialGradient(
        colors: [
          baseColor.withValues(alpha: opacity),
          baseColor.withValues(alpha: opacity * 0.3),
          baseColor.withValues(alpha: 0.0),
        ],
        stops: [0.0, 0.6, 1.0],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius)
        );

      canvas.drawCircle(center, radius, paint);
    }

    // Add a subtle inner glow
    final innerGlow = Paint()
      ..color = baseColor.withValues(alpha: 0.6 * animationValue)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20);
    
    canvas.drawCircle(
      center, 
      maxRadius * 0.2 * (0.8 + 0.2 * animationValue), 
      innerGlow
    );
  }

  @override
  bool shouldRepaint(BreathingPulsePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.baseColor != baseColor;
  }
}

// Scroll-aware pulse widget that hides when community section is visible
class ScrollAwarePulse extends StatefulWidget {
  final ScrollController? scrollController;
  final double height;

  const ScrollAwarePulse({
    super.key,
    this.scrollController,
    this.height = 280,
  });

  @override
  State<ScrollAwarePulse> createState() => _ScrollAwarePulseState();
}

class _ScrollAwarePulseState extends State<ScrollAwarePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _visibilityController;
  late Animation<double> _opacityAnimation;
  bool _isVisible = true;
  final GlobalKey<_WellnessBreathingPulseState> _pulseKey = GlobalKey<_WellnessBreathingPulseState>();
  
  // Track shown alerts to prevent duplicate popups
  final Set<String> _shownAlertIds = {};

  @override
  void initState() {
    super.initState();
    
    _visibilityController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    
    _opacityAnimation = CurvedAnimation(
      parent: _visibilityController,
      curve: Curves.easeInOut,
    );
    
    _visibilityController.forward();
    
    // Listen to scroll changes if controller provided
    widget.scrollController?.addListener(_onScroll);
    
    // Note: Health alert popups now triggered when opening wellness modal
  }

  void _onScroll() {
    if (widget.scrollController == null) return;
    
    final offset = widget.scrollController!.offset;
    final maxScrollExtent = widget.scrollController!.position.maxScrollExtent;
    
    // Calculate visibility based on scroll position
    // Only hide when user is very close to the bottom (90% of total scroll)
    // This way the pulse stays visible through most of the community section
    final hideThreshold = maxScrollExtent * 0.9;
    final shouldBeVisible = offset < hideThreshold;
    
    // Trigger animation when user scrolls to see the pulse for the first time
    // Animation should start when pulse area becomes visible (around 200px scroll)
    final animationTriggerOffset = 200.0;
    final shouldTriggerAnimation = offset >= animationTriggerOffset && _isVisible;
    
    if (shouldBeVisible != _isVisible) {
      setState(() {
        _isVisible = shouldBeVisible;
        if (_isVisible) {
          _visibilityController.forward();
        } else {
          _visibilityController.reverse();
          // Reset animation when pulse goes out of view
          _pulseKey.currentState?.resetAnimation();
        }
      });
    }
    
    // Trigger animation when scrolling into pulse view
    if (shouldTriggerAnimation) {
      _pulseKey.currentState?.triggerAnimation();
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    _visibilityController.dispose();
    super.dispose();
  }
  
  // Check for new health alerts when wellness modal is opened
  void _checkForNewHealthAlerts() {
    final healthCollector = SmartHealthDataCollector.instance;
    final alerts = healthCollector.activeAlerts;
    
    for (final alert in alerts) {
      final alertId = '${alert.type.name}_${alert.level.name}';
      if (!_shownAlertIds.contains(alertId)) {
        _shownAlertIds.add(alertId);
        // Delay popup slightly to allow modal to settle
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            _showHealthAlertPopup(alert);
          }
        });
        break; // Only show one popup at a time
      }
    }
  }
  
  // Show health alert popup based on severity
  void _showHealthAlertPopup(HealthAlert alert) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => _buildHealthAlertDialog(alert),
    );
  }
  
  // Show health alert popup for manual viewing (doesn't affect auto-popup tracking)
  void _showHealthAlertManually(HealthAlert alert) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => _buildHealthAlertDialog(alert),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: SizedBox(
            height: widget.height,
            child: WellnessBreathingPulse(
              key: _pulseKey,
              height: widget.height,
              onTap: () {
                // Show health information modal
                _showHealthInfoModal();
              },
            ),
          ),
        );
      },
    );
  }

  void _showHealthInfoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildHealthInfoModal(),
    );
    
    // Check for new health alerts when modal opens
    _checkForNewHealthAlerts();
  }

  Widget _buildHealthInfoModal() {
    final colorManager = PulseColorManager.instance;
    final healthCollector = SmartHealthDataCollector.instance;
    final healthSummary = healthCollector.getHealthSummary();
    
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorManager.currentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  tr(context, 'wellness_environment'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Status Overview Card
                  _buildModernStatusCard(healthSummary),
                  SizedBox(height: 20),
                  
                  // Active Alerts (if any)
                  if (healthCollector.activeAlerts.isNotEmpty) ...[
                    _buildActiveAlertsCard(healthSummary),
                    SizedBox(height: 20),
                  ],
                  
                  // Weather Conditions Section
                  _buildWeatherSection(healthSummary),
                  SizedBox(height: 20),
                  
                  // Air Quality Section
                  _buildAirQualitySection(healthSummary),
                  SizedBox(height: 20),
                  
                  // Personal Health Metrics Grid  
                  _buildPersonalHealthGrid(healthSummary),
                  SizedBox(height: 20),
                  
                  // Quick Recommendations
                  _buildQuickRecommendations(healthSummary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }








  
  // Build active alerts card showing current concerns
  Widget _buildActiveAlertsCard(Map<String, dynamic>? healthSummary) {
    final healthCollector = SmartHealthDataCollector.instance;
    final alerts = healthCollector.activeAlerts;
    
    if (alerts.isEmpty) {
      return SizedBox.shrink(); // No alerts, no card
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Text(
                tr(context, 'active_health_concerns'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...alerts.take(3).map((alert) => _buildAlertTile(alert)),
          if (alerts.length > 3)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '+${alerts.length - 3} more concerns',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Build individual alert tile (clickable)
  Widget _buildAlertTile(HealthAlert alert) {
    Color alertColor;
    IconData alertIcon;
    
    switch (alert.level) {
      case AlertLevel.critical:
        alertColor = Colors.red;
        alertIcon = Icons.error;
        break;
      case AlertLevel.high:
        alertColor = Colors.orange;
        alertIcon = Icons.warning;
        break;
      case AlertLevel.warning:
        alertColor = Colors.yellow[700]!;
        alertIcon = Icons.info;
        break;
      default:
        alertColor = Colors.green;
        alertIcon = Icons.check_circle;
    }
    
    return GestureDetector(
      onTap: () => _showHealthAlertManually(alert),
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: alertColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: alertColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(alertIcon, color: alertColor, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                alert.message,
                style: TextStyle(
                  fontSize: 14,
                  color: alertColor,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right, color: alertColor, size: 16),
          ],
        ),
      ),
    );
  }
  
  // Build health alert dialog (similar to mood confirmation)
  Widget _buildHealthAlertDialog(HealthAlert alert) {
    Color alertColor;
    IconData alertIcon;
    String severityText;
    
    switch (alert.level) {
      case AlertLevel.critical:
        alertColor = Colors.red;
        alertIcon = Icons.error;
        severityText = tr(context, 'critical_alert');
        break;
      case AlertLevel.high:
        alertColor = Colors.orange;
        alertIcon = Icons.warning;
        severityText = tr(context, 'high_alert');
        break;
      case AlertLevel.warning:
        alertColor = Colors.yellow[700]!;
        alertIcon = Icons.info;
        severityText = tr(context, 'warning_alert');
        break;
      default:
        alertColor = Colors.green;
        alertIcon = Icons.check_circle;
        severityText = tr(context, 'normal_status');
    }
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated alert indicator
            TweenAnimationBuilder(
              duration: Duration(milliseconds: 600),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: alertColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: alertColor,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      alertIcon,
                      size: 40,
                      color: alertColor,
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: 20),
            
            // Severity title
            Text(
              severityText,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: alertColor,
              ),
            ),
            
            SizedBox(height: 12),
            
            // Alert message
            Text(
              alert.message,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 16),
            
            // Action message
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: alertColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                alert.actionMessage ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: alertColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      tr(context, 'dismiss'),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showHealthInfoModal();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: alertColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      tr(context, 'view_details'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  /// Show UV Index information popup
  void _showUVIndexInfo(BuildContext context, double? uvIndex) {
    final infoService = HealthInfoService.instance;
    final uvInfo = infoService.getUVIndexInfo(uvIndex);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'UV Index Information',
          infoData: uvInfo,
          currentValue: uvIndex?.toStringAsFixed(1),
          customScale: uvIndex != null ? UVIndexScale(currentUV: uvIndex) : null,
        ),
      ),
    );
  }

  /// Show Temperature information popup
  void _showTemperatureInfo(BuildContext context, double? temperature) {
    final infoService = HealthInfoService.instance;
    final tempInfo = infoService.getTemperatureInfo(temperature);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'Temperature Information',
          infoData: tempInfo,
          currentValue: temperature != null ? '${temperature.toStringAsFixed(1)}°C' : null,
        ),
      ),
    );
  }

  /// Show Humidity information popup
  void _showHumidityInfo(BuildContext context, double? humidity) {
    final infoService = HealthInfoService.instance;
    final humidityInfo = infoService.getHumidityInfo(humidity);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'Humidity Information',
          infoData: humidityInfo,
          currentValue: humidity != null ? '${humidity.toStringAsFixed(0)}%' : null,
        ),
      ),
    );
  }

  /// Show Air Quality Index information popup
  void _showAQIInfo(BuildContext context, int? aqi) {
    final infoService = HealthInfoService.instance;
    final aqiInfo = infoService.getAQIInfo(aqi);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'Air Quality Index',
          infoData: aqiInfo,
          currentValue: aqi?.toString(),
          customScale: aqi != null ? AQIScale(currentAQI: aqi) : null,
        ),
      ),
    );
  }

  /// Show Heart Rate information popup
  void _showHeartRateInfo(BuildContext context, int? heartRate) {
    final infoService = HealthInfoService.instance;
    final hrInfo = infoService.getHeartRateInfo(heartRate);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'Heart Rate Information',
          infoData: hrInfo,
          currentValue: heartRate != null ? '$heartRate bpm' : null,
        ),
      ),
    );
  }

  /// Show Hydration information popup
  void _showHydrationInfo(BuildContext context, double? hydration) {
    final infoService = HealthInfoService.instance;
    final hydrationInfo = infoService.getHydrationInfo(hydration);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'Hydration Information',
          infoData: hydrationInfo,
          currentValue: hydration != null ? '${(hydration * 100).toStringAsFixed(0)}%' : null,
        ),
      ),
    );
  }

  /// Show Sleep Quality information popup
  void _showSleepQualityInfo(BuildContext context, String sleepQuality) {
    final infoService = HealthInfoService.instance;
    final sleepInfo = infoService.getSleepQualityInfo(sleepQuality);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'Sleep Quality Information',
          infoData: sleepInfo,
          currentValue: sleepQuality.toUpperCase(),
        ),
      ),
    );
  }

  /// Show Activity Level information popup
  void _showActivityLevelInfo(BuildContext context, String activityLevel) {
    final infoService = HealthInfoService.instance;
    final activityInfo = infoService.getActivityLevelInfo(activityLevel);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'Activity Level Information',
          infoData: activityInfo,
          currentValue: activityLevel.toUpperCase(),
        ),
      ),
    );
  }

  /// Modern status overview card with gradient and better layout
  Widget _buildModernStatusCard(Map<String, dynamic>? healthSummary) {
    final alertLevel = healthSummary?['alertLevel'] ?? AlertLevel.normal;
    final alertCount = healthSummary?['alertCount'] ?? 0;
    
    Color primaryColor;
    Color secondaryColor;
    String statusText;
    String description;
    IconData icon;
    
    switch (alertLevel) {
      case AlertLevel.critical:
        primaryColor = Colors.red;
        secondaryColor = Colors.red.shade100;
        statusText = tr(context, 'health_alert');
        description = tr(context, 'environmental_conditions_attention');
        icon = Icons.warning_rounded;
        break;
      case AlertLevel.high:
        primaryColor = Colors.orange;
        secondaryColor = Colors.orange.shade100;
        statusText = tr(context, 'caution_advised');
        description = tr(context, 'conditions_affect_sensitive');
        icon = Icons.info_rounded;
        break;
      case AlertLevel.warning:
        primaryColor = Colors.yellow[700]!;
        secondaryColor = Colors.yellow.shade100;
        statusText = tr(context, 'minor_concerns');
        description = tr(context, 'generally_safe_considerations');
        icon = Icons.lightbulb_rounded;
        break;
      default:
        primaryColor = Colors.green;
        secondaryColor = Colors.green.shade100;
        statusText = tr(context, 'all_good');
        description = tr(context, 'excellent_conditions_outdoor');
        icon = Icons.check_circle_rounded;
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [secondaryColor, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  if (alertCount > 0) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        alertCount > 1 ? "$alertCount ${tr(context, 'active_alerts')}" : "$alertCount ${tr(context, 'active_alert')}",
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Weather conditions section
  Widget _buildWeatherSection(Map<String, dynamic>? healthSummary) {
    final weatherData = healthSummary?['weather'];
    final location = weatherData != null ? _getWeatherLocation(weatherData) : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.wb_sunny_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                tr(context, 'weather_conditions'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ),
            if (location != null) ...[
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                location,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 16),
        // 2x2 Grid layout for weather metrics
        Column(
          children: [
            // First row: Temperature, Humidity
            Row(
              children: [
                Expanded(
                  child: _buildModernHealthCard(
                    icon: Icons.thermostat,
                    color: Colors.orange,
                    title: tr(context, 'temperature'),
                    value: weatherData?.temperature != null 
                        ? "${weatherData!.temperature!.toStringAsFixed(1)}°C"
                        : tr(context, 'not_available'),
                    onTap: () => _showTemperatureInfo(context, weatherData?.temperature),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildModernHealthCard(
                    icon: Icons.opacity,
                    color: Colors.blue,
                    title: tr(context, 'humidity'),
                    value: weatherData?.humidity != null 
                        ? "${weatherData!.humidity}%"
                        : tr(context, 'not_available'),
                    onTap: () => _showHumidityInfo(context, weatherData?.humidity?.toDouble()),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // Second row: UV Index, Weather Condition
            Row(
              children: [
                Expanded(
                  child: _buildModernHealthCard(
                    icon: Icons.wb_sunny,
                    color: Colors.amber,
                    title: tr(context, 'uv_index'),
                    value: weatherData?.uvIndex != null 
                        ? weatherData!.uvIndex!.toStringAsFixed(1)
                        : tr(context, 'not_available'),
                    onTap: () => _showUVIndexInfo(context, weatherData?.uvIndex),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildModernHealthCard(
                    icon: Icons.cloud,
                    color: Colors.indigo,
                    title: tr(context, 'condition'),
                    value: weatherData?.condition != null 
                        ? weatherData!.condition!.toUpperCase()
                        : tr(context, 'not_available'),
                    onTap: () => _showWeatherConditionInfo(context, weatherData?.condition),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Air quality section
  Widget _buildAirQualitySection(Map<String, dynamic>? healthSummary) {
    final airQualityData = healthSummary?['airQuality'];
    final location = airQualityData != null ? _getAirQualityLocation(airQualityData) : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.air_rounded, color: Colors.teal, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                tr(context, 'air_quality'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ),
            if (location != null) ...[
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                location,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 16),
        // First row: AQI, Quality, Source
        Row(
          children: [
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.air,
                color: airQualityData?.aqi != null && airQualityData!.aqi <= 50 ? Colors.green : 
                       airQualityData?.aqi != null && airQualityData!.aqi <= 100 ? Colors.yellow[700]! :
                       airQualityData?.aqi != null && airQualityData!.aqi <= 150 ? Colors.orange : Colors.red,
                title: tr(context, 'aqi'),
                value: airQualityData?.aqi != null 
                    ? "${airQualityData!.aqi}"
                    : tr(context, 'not_available'),
                onTap: () => _showAQIInfo(context, airQualityData?.aqi),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.health_and_safety,
                color: airQualityData?.aqi != null && airQualityData!.aqi <= 50 ? Colors.green : 
                       airQualityData?.aqi != null && airQualityData!.aqi <= 100 ? Colors.yellow[700]! :
                       airQualityData?.aqi != null && airQualityData!.aqi <= 150 ? Colors.orange : Colors.red,
                title: tr(context, 'quality'),
                value: airQualityData?.qualityDescription != null 
                    ? airQualityData!.qualityDescription!
                    : tr(context, 'not_available'),
                onTap: () => _showAirQualityInfo(context, airQualityData?.qualityDescription),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.source,
                color: Colors.grey[600]!,
                title: tr(context, 'source'),
                value: airQualityData?.source != null 
                    ? airQualityData!.source!
                    : tr(context, 'not_available'),
                onTap: () => _showSourceInfo(context, airQualityData?.source),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        // Second row: PM2.5, PM10, NO2
        Row(
          children: [
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.blur_on,
                color: Colors.purple,
                title: 'PM2.5',
                value: airQualityData?.pollutants?['pm2_5'] != null 
                    ? "${airQualityData!.pollutants!['pm2_5']!.toStringAsFixed(1)} μg/m³"
                    : tr(context, 'not_available'),
                onTap: () => _showPM25Info(context, airQualityData?.pollutants?['pm2_5']),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.grain,
                color: Colors.brown,
                title: 'PM10',
                value: airQualityData?.pollutants?['pm10'] != null 
                    ? "${airQualityData!.pollutants!['pm10']!.toStringAsFixed(1)} μg/m³"
                    : tr(context, 'not_available'),
                onTap: () => _showPM10Info(context, airQualityData?.pollutants?['pm10']),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.local_gas_station,
                color: Colors.red[600]!,
                title: 'NO₂',
                value: airQualityData?.pollutants?['no2'] != null 
                    ? "${airQualityData!.pollutants!['no2']!.toStringAsFixed(1)} μg/m³"
                    : tr(context, 'not_available'),
                onTap: () => _showNO2Info(context, airQualityData?.pollutants?['no2']),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        // Third row: SO2, O3, CO
        Row(
          children: [
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.smoke_free,
                color: Colors.orange[700]!,
                title: 'SO₂',
                value: airQualityData?.pollutants?['so2'] != null 
                    ? "${airQualityData!.pollutants!['so2']!.toStringAsFixed(1)} μg/m³"
                    : tr(context, 'not_available'),
                onTap: () => _showSO2Info(context, airQualityData?.pollutants?['so2']),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.wb_sunny_outlined,
                color: Colors.cyan[600]!,
                title: 'O₃',
                value: airQualityData?.pollutants?['o3'] != null 
                    ? "${airQualityData!.pollutants!['o3']!.toStringAsFixed(1)} μg/m³"
                    : tr(context, 'not_available'),
                onTap: () => _showO3Info(context, airQualityData?.pollutants?['o3']),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.cloud_queue,
                color: Colors.grey[700]!,
                title: 'CO',
                value: airQualityData?.pollutants?['co'] != null 
                    ? "${(airQualityData!.pollutants!['co']! / 1000).toStringAsFixed(1)} mg/m³"
                    : tr(context, 'not_available'),
                onTap: () => _showCOInfo(context, airQualityData?.pollutants?['co']),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Personal health metrics in a modern grid
  Widget _buildPersonalHealthGrid(Map<String, dynamic>? healthSummary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.favorite_rounded, color: Colors.pink, size: 24),
            SizedBox(width: 8),
            Text(
              tr(context, 'personal_health'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.favorite,
                color: Colors.red,
                title: tr(context, 'heart_rate'),
                value: healthSummary?['heartRate'] != null ? "${healthSummary!['heartRate']} bpm" : tr(context, 'not_available'),
                onTap: () => _showHeartRateInfo(context, healthSummary?['heartRate']),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.water_drop,
                color: Colors.blue,
                title: tr(context, 'hydration'),
                value: healthSummary?['hydration'] != null 
                    ? "${(healthSummary!['hydration'] * 100).toStringAsFixed(0)}%"
                    : tr(context, 'not_tracked'),
                onTap: () => _showHydrationInfo(context, healthSummary?['hydration']),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.bedtime,
                color: Colors.indigo,
                title: tr(context, 'sleep_quality'),
                value: tr(context, 'good'),
                onTap: () => _showSleepQualityInfo(context, 'good'),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.directions_run,
                color: Colors.green,
                title: tr(context, 'activity_level'),
                value: tr(context, 'moderate'),
                onTap: () => _showActivityLevelInfo(context, 'moderate'),
              ),
            ),
          ],
        ),
      ],
    );
  }


  /// Modern health card for personal metrics
  Widget _buildModernHealthCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: color.withValues(alpha: 0.7),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  /// Quick recommendations card
  Widget _buildQuickRecommendations(Map<String, dynamic>? healthSummary) {
    final alertLevel = healthSummary?['alertLevel'] ?? AlertLevel.normal;
    
    List<String> recommendations;
    Color accentColor;
    
    switch (alertLevel) {
      case AlertLevel.critical:
      case AlertLevel.high:
        recommendations = [
          tr(context, 'stay_indoors_possible'),
          tr(context, 'limit_outdoor_exercise'),
          tr(context, 'stay_hydrated'),
        ];
        accentColor = Colors.red;
        break;
      case AlertLevel.warning:
        recommendations = [
          tr(context, 'drink_plenty_water'),
          tr(context, 'monitor_air_quality'),
          tr(context, 'mindful_sun_exposure'),
        ];
        accentColor = Colors.orange;
        break;
      default:
        recommendations = [
          tr(context, 'great_day_outdoor'),
          tr(context, 'perfect_exercise'),
          tr(context, 'enjoy_fresh_air'),
        ];
        accentColor = Colors.green;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: accentColor, size: 24),
                SizedBox(width: 8),
                Text(
                  tr(context, 'quick_tips'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...recommendations.take(3).map((rec) => 
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: EdgeInsets.only(top: 6, right: 12),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        rec,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get weather location
  String? _getWeatherLocation(dynamic weatherData) {
    if (weatherData?.city != null && weatherData!.city!.isNotEmpty && weatherData!.city != 'Unknown') {
      return weatherData!.city!;
    } else if (weatherData?.country != null && weatherData!.country!.isNotEmpty && weatherData!.country != 'Unknown') {
      return weatherData!.country!;
    }
    return null;
  }

  // Helper method to get air quality location
  String? _getAirQualityLocation(dynamic airQualityData) {
    if (airQualityData?.city != null && airQualityData!.city!.isNotEmpty && airQualityData!.city != 'Unknown') {
      return airQualityData!.city!;
    } else if (airQualityData?.country != null && airQualityData!.country!.isNotEmpty && airQualityData!.country != 'Unknown') {
      return airQualityData!.country!;
    }
    return null;
  }

  // Show weather condition information popup
  void _showWeatherConditionInfo(BuildContext context, String? condition) {
    final infoService = HealthInfoService.instance;
    final conditionInfo = infoService.getWeatherConditionInfo(condition);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'Weather Condition Information',
          infoData: conditionInfo,
          currentValue: condition?.toUpperCase(),
        ),
      ),
    );
  }

  // Show air quality description popup
  void _showAirQualityInfo(BuildContext context, String? quality) {
    final infoService = HealthInfoService.instance;
    final qualityInfo = infoService.getAirQualityDescriptionInfo(quality);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'Air Quality Description',
          infoData: qualityInfo,
          currentValue: quality,
        ),
      ),
    );
  }

  // Show source information popup
  void _showSourceInfo(BuildContext context, String? source) {
    final infoService = HealthInfoService.instance;
    final sourceInfo = infoService.getSourceInfo(source);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'Data Source Information',
          infoData: sourceInfo,
          currentValue: source,
        ),
      ),
    );
  }

  // Show PM2.5 information popup
  void _showPM25Info(BuildContext context, double? pm25) {
    final infoService = HealthInfoService.instance;
    final pm25Info = infoService.getPM25Info(pm25);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'PM2.5 Information',
          infoData: pm25Info,
          currentValue: pm25 != null ? "${pm25.toStringAsFixed(1)} μg/m³" : null,
        ),
      ),
    );
  }

  // Show PM10 information popup
  void _showPM10Info(BuildContext context, double? pm10) {
    final infoService = HealthInfoService.instance;
    final pm10Info = infoService.getPM10Info(pm10);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'PM10 Information',
          infoData: pm10Info,
          currentValue: pm10 != null ? "${pm10.toStringAsFixed(1)} μg/m³" : null,
        ),
      ),
    );
  }

  // Show NO2 information popup
  void _showNO2Info(BuildContext context, double? no2) {
    final infoService = HealthInfoService.instance;
    final no2Info = infoService.getNO2Info(no2);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'NO₂ Information',
          infoData: no2Info,
          currentValue: no2 != null ? "${no2.toStringAsFixed(1)} μg/m³" : null,
        ),
      ),
    );
  }

  // Show SO2 information popup
  void _showSO2Info(BuildContext context, double? so2) {
    final infoService = HealthInfoService.instance;
    final so2Info = infoService.getSO2Info(so2);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'SO₂ Information',
          infoData: so2Info,
          currentValue: so2 != null ? "${so2.toStringAsFixed(1)} μg/m³" : null,
        ),
      ),
    );
  }

  // Show O3 information popup
  void _showO3Info(BuildContext context, double? o3) {
    final infoService = HealthInfoService.instance;
    final o3Info = infoService.getO3Info(o3);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'O₃ Information',
          infoData: o3Info,
          currentValue: o3 != null ? "${o3.toStringAsFixed(1)} μg/m³" : null,
        ),
      ),
    );
  }

  // Show CO information popup
  void _showCOInfo(BuildContext context, double? co) {
    final infoService = HealthInfoService.instance;
    final coInfo = infoService.getCOInfo(co);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'CO Information',
          infoData: coInfo,
          currentValue: co != null ? "${(co / 1000).toStringAsFixed(1)} mg/m³" : null,
        ),
      ),
    );
  }
}

// Enhanced scroll-aware pulse with FIRST FLY animation transition
class ScrollAwarePulseWithFly extends StatefulWidget {
  final ScrollController? scrollController;
  final double height;

  const ScrollAwarePulseWithFly({
    super.key,
    this.scrollController,
    this.height = 280,
  });

  @override
  State<ScrollAwarePulseWithFly> createState() => _ScrollAwarePulseWithFlyState();
}

class _ScrollAwarePulseWithFlyState extends State<ScrollAwarePulseWithFly>
    with TickerProviderStateMixin {
  late AnimationController _pulseVisibilityController;
  late AnimationController _flyAnimationController;
  late Animation<double> _pulseOpacityAnimation;
  late Animation<double> _flyOpacityAnimation;
  
  bool _showPulse = true;
  bool _showFly = false;
  final GlobalKey<_WellnessBreathingPulseState> _pulseKey = GlobalKey<_WellnessBreathingPulseState>();
  

  @override
  void initState() {
    super.initState();
    
    // Pulse visibility animation
    _pulseVisibilityController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    // FIRST FLY animation
    _flyAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseOpacityAnimation = CurvedAnimation(
      parent: _pulseVisibilityController,
      curve: Curves.easeInOut,
    );
    
    _flyOpacityAnimation = CurvedAnimation(
      parent: _flyAnimationController,
      curve: Curves.easeInOut,
    );
    
    // Start with pulse visible
    _pulseVisibilityController.forward();
    
    
    // Listen to scroll changes
    widget.scrollController?.addListener(_onScroll);
  }


  void _onScroll() {
    if (widget.scrollController == null) return;
    
    final offset = widget.scrollController!.offset;
    final maxScrollExtent = widget.scrollController!.position.maxScrollExtent;
    
    // Calculate transition points
    // Start hiding pulse when user reaches 70% of scroll (approaching community)
    final pulseHideThreshold = maxScrollExtent * 0.7;
    // Show FIRST FLY when pulse starts hiding
    final flyShowThreshold = maxScrollExtent * 0.75;
    // Hide FIRST FLY when very close to bottom
    final flyHideThreshold = maxScrollExtent * 0.9;
    
    final shouldShowPulse = offset < pulseHideThreshold;
    final shouldShowFly = offset >= flyShowThreshold && offset < flyHideThreshold;
    
    // Trigger pulse animation when scrolling into view
    final animationTriggerOffset = 200.0;
    if (offset >= animationTriggerOffset && shouldShowPulse) {
      _pulseKey.currentState?.triggerAnimation();
    }
    
    // Handle pulse visibility
    if (shouldShowPulse != _showPulse) {
      setState(() {
        _showPulse = shouldShowPulse;
        if (_showPulse) {
          _pulseVisibilityController.forward();
        } else {
          _pulseVisibilityController.reverse();
          // Reset pulse animation when hidden
          _pulseKey.currentState?.resetAnimation();
        }
      });
    }
    
    // Handle FIRST FLY visibility with smooth transition
    if (shouldShowFly != _showFly) {
      setState(() {
        _showFly = shouldShowFly;
        if (_showFly) {
          _flyAnimationController.forward();
        } else {
          _flyAnimationController.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    _pulseVisibilityController.dispose();
    _flyAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height + 100, // Extra space for FIRST FLY animation
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse animation
          AnimatedBuilder(
            animation: _pulseOpacityAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _pulseOpacityAnimation.value,
                child: SizedBox(
                  height: widget.height,
                  child: WellnessBreathingPulse(
                    key: _pulseKey,
                    height: widget.height,
                    onTap: () {
                      // Show health information modal (same as original)
                      _showHealthInfoModal();
                    },
                  ),
                ),
              );
            },
          ),
          
          // FIRST FLY animation positioned below pulse
          Positioned(
            bottom: 0,
            child: AnimatedBuilder(
              animation: _flyOpacityAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _flyOpacityAnimation.value,
                  child: SizedBox(
                    width: 200,
                    height: 100,
                    child: _buildFirstFlyAnimation(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstFlyAnimation() {
    return SizedBox(
      width: 200,
      height: 100,
      child: Center(
        child: TweenAnimationBuilder(
          duration: Duration(seconds: 2),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, double value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Icon(
                Icons.flight_takeoff,
                size: 40,
                color: Colors.blue.withValues(alpha: value),
              ),
            );
          },
          onEnd: () {
            // Restart animation
            setState(() {});
          },
        ),
      ),
    );
  }

  void _showHealthInfoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildHealthInfoModal(),
    );
  }

  Widget _buildHealthInfoModal() {
    final colorManager = PulseColorManager.instance;
    final healthCollector = SmartHealthDataCollector.instance;
    final healthSummary = healthCollector.getHealthSummary();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorManager.currentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  tr(context, 'wellness_environment'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Status Overview Card
                  _buildModernStatusCard(healthSummary),
                  SizedBox(height: 20),
                  
                  // Active Alerts (if any)
                  if (healthCollector.activeAlerts.isNotEmpty) ...[
                    _buildActiveAlertsCard(healthSummary),
                    SizedBox(height: 20),
                  ],
                  
                  // Weather Conditions Section
                  _buildWeatherSection(healthSummary),
                  SizedBox(height: 20),
                  
                  // Air Quality Section
                  _buildAirQualitySection(healthSummary),
                  SizedBox(height: 20),
                  
                  // Personal Health Metrics Grid  
                  _buildPersonalHealthGrid(healthSummary),
                  SizedBox(height: 20),
                  
                  // Quick Recommendations
                  _buildQuickRecommendations(healthSummary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for health modal

  Widget _buildActiveAlertsCard(Map<String, dynamic>? healthSummary) {
    final healthCollector = SmartHealthDataCollector.instance;
    final alerts = healthCollector.activeAlerts;
    
    if (alerts.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Text(
                tr(context, 'active_health_concerns'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...alerts.take(3).map((alert) => Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              alert.message,
              style: TextStyle(fontSize: 14, color: Colors.orange),
            ),
          )),
        ],
      ),
    );
  }






  /// Modern status overview card with gradient and better layout
  Widget _buildModernStatusCard(Map<String, dynamic>? healthSummary) {
    final alertLevel = healthSummary?['alertLevel'] ?? AlertLevel.normal;
    final alertCount = healthSummary?['alertCount'] ?? 0;
    
    Color primaryColor;
    Color secondaryColor;
    String statusText;
    String description;
    IconData icon;
    
    switch (alertLevel) {
      case AlertLevel.critical:
        primaryColor = Colors.red;
        secondaryColor = Colors.red.shade100;
        statusText = tr(context, 'health_alert');
        description = tr(context, 'environmental_conditions_attention');
        icon = Icons.warning_rounded;
        break;
      case AlertLevel.high:
        primaryColor = Colors.orange;
        secondaryColor = Colors.orange.shade100;
        statusText = tr(context, 'caution_advised');
        description = tr(context, 'conditions_affect_sensitive');
        icon = Icons.info_rounded;
        break;
      case AlertLevel.warning:
        primaryColor = Colors.yellow[700]!;
        secondaryColor = Colors.yellow.shade100;
        statusText = tr(context, 'minor_concerns');
        description = tr(context, 'generally_safe_considerations');
        icon = Icons.lightbulb_rounded;
        break;
      default:
        primaryColor = Colors.green;
        secondaryColor = Colors.green.shade100;
        statusText = tr(context, 'all_good');
        description = tr(context, 'excellent_conditions_outdoor');
        icon = Icons.check_circle_rounded;
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [secondaryColor, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  if (alertCount > 0) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        alertCount > 1 ? "$alertCount ${tr(context, 'active_alerts')}" : "$alertCount ${tr(context, 'active_alert')}",
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Weather conditions section
  Widget _buildWeatherSection(Map<String, dynamic>? healthSummary) {
    final weatherData = healthSummary?['weather'];
    final location = weatherData != null ? _getWeatherLocation(weatherData) : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.wb_sunny_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                tr(context, 'weather_conditions'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ),
            if (location != null) ...[
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                location,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 16),
        // 2x2 Grid layout for weather metrics
        Column(
          children: [
            // First row: Temperature, Humidity
            Row(
              children: [
                Expanded(
                  child: _buildModernHealthCard(
                    icon: Icons.thermostat,
                    color: Colors.orange,
                    title: tr(context, 'temperature'),
                    value: weatherData?.temperature != null 
                        ? "${weatherData!.temperature!.toStringAsFixed(1)}°C"
                        : tr(context, 'not_available'),
                    onTap: () => _showTemperatureInfo(context, weatherData?.temperature),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildModernHealthCard(
                    icon: Icons.opacity,
                    color: Colors.blue,
                    title: tr(context, 'humidity'),
                    value: weatherData?.humidity != null 
                        ? "${weatherData!.humidity}%"
                        : tr(context, 'not_available'),
                    onTap: () => _showHumidityInfo(context, weatherData?.humidity?.toDouble()),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // Second row: UV Index, Weather Condition
            Row(
              children: [
                Expanded(
                  child: _buildModernHealthCard(
                    icon: Icons.wb_sunny,
                    color: Colors.amber,
                    title: tr(context, 'uv_index'),
                    value: weatherData?.uvIndex != null 
                        ? weatherData!.uvIndex!.toStringAsFixed(1)
                        : tr(context, 'not_available'),
                    onTap: () => _showUVIndexInfo(context, weatherData?.uvIndex),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildModernHealthCard(
                    icon: Icons.cloud,
                    color: Colors.indigo,
                    title: tr(context, 'condition'),
                    value: weatherData?.condition != null 
                        ? weatherData!.condition!.toUpperCase()
                        : tr(context, 'not_available'),
                    onTap: () => _showWeatherConditionInfo(context, weatherData?.condition),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Air quality section
  Widget _buildAirQualitySection(Map<String, dynamic>? healthSummary) {
    final airQualityData = healthSummary?['airQuality'];
    final location = airQualityData != null ? _getAirQualityLocation(airQualityData) : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.air_rounded, color: Colors.teal, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                tr(context, 'air_quality'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ),
            if (location != null) ...[
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                location,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 16),
        // First row: AQI, Quality, Source
        Row(
          children: [
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.air,
                color: airQualityData?.aqi != null && airQualityData!.aqi <= 50 ? Colors.green : 
                       airQualityData?.aqi != null && airQualityData!.aqi <= 100 ? Colors.yellow[700]! :
                       airQualityData?.aqi != null && airQualityData!.aqi <= 150 ? Colors.orange : Colors.red,
                title: tr(context, 'aqi'),
                value: airQualityData?.aqi != null 
                    ? "${airQualityData!.aqi}"
                    : tr(context, 'not_available'),
                onTap: () => _showAQIInfo(context, airQualityData?.aqi),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.health_and_safety,
                color: airQualityData?.aqi != null && airQualityData!.aqi <= 50 ? Colors.green : 
                       airQualityData?.aqi != null && airQualityData!.aqi <= 100 ? Colors.yellow[700]! :
                       airQualityData?.aqi != null && airQualityData!.aqi <= 150 ? Colors.orange : Colors.red,
                title: tr(context, 'quality'),
                value: airQualityData?.qualityDescription != null 
                    ? airQualityData!.qualityDescription!
                    : tr(context, 'not_available'),
                onTap: () => _showAirQualityInfo(context, airQualityData?.qualityDescription),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.source,
                color: Colors.grey[600]!,
                title: tr(context, 'source'),
                value: airQualityData?.source != null 
                    ? airQualityData!.source!
                    : tr(context, 'not_available'),
                onTap: () => _showSourceInfo(context, airQualityData?.source),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        // Second row: PM2.5, PM10, NO2
        Row(
          children: [
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.blur_on,
                color: Colors.purple,
                title: 'PM2.5',
                value: airQualityData?.pollutants?['pm2_5'] != null 
                    ? "${airQualityData!.pollutants!['pm2_5']!.toStringAsFixed(1)} μg/m³"
                    : tr(context, 'not_available'),
                onTap: () => _showPM25Info(context, airQualityData?.pollutants?['pm2_5']),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.grain,
                color: Colors.brown,
                title: 'PM10',
                value: airQualityData?.pollutants?['pm10'] != null 
                    ? "${airQualityData!.pollutants!['pm10']!.toStringAsFixed(1)} μg/m³"
                    : tr(context, 'not_available'),
                onTap: () => _showPM10Info(context, airQualityData?.pollutants?['pm10']),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.local_gas_station,
                color: Colors.red[600]!,
                title: 'NO₂',
                value: airQualityData?.pollutants?['no2'] != null 
                    ? "${airQualityData!.pollutants!['no2']!.toStringAsFixed(1)} μg/m³"
                    : tr(context, 'not_available'),
                onTap: () => _showNO2Info(context, airQualityData?.pollutants?['no2']),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        // Third row: SO2, O3, CO
        Row(
          children: [
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.smoke_free,
                color: Colors.orange[700]!,
                title: 'SO₂',
                value: airQualityData?.pollutants?['so2'] != null 
                    ? "${airQualityData!.pollutants!['so2']!.toStringAsFixed(1)} μg/m³"
                    : tr(context, 'not_available'),
                onTap: () => _showSO2Info(context, airQualityData?.pollutants?['so2']),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.wb_sunny_outlined,
                color: Colors.cyan[600]!,
                title: 'O₃',
                value: airQualityData?.pollutants?['o3'] != null 
                    ? "${airQualityData!.pollutants!['o3']!.toStringAsFixed(1)} μg/m³"
                    : tr(context, 'not_available'),
                onTap: () => _showO3Info(context, airQualityData?.pollutants?['o3']),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.cloud_queue,
                color: Colors.grey[700]!,
                title: 'CO',
                value: airQualityData?.pollutants?['co'] != null 
                    ? "${(airQualityData!.pollutants!['co']! / 1000).toStringAsFixed(1)} mg/m³"
                    : tr(context, 'not_available'),
                onTap: () => _showCOInfo(context, airQualityData?.pollutants?['co']),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Personal health metrics in a modern grid
  Widget _buildPersonalHealthGrid(Map<String, dynamic>? healthSummary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.favorite_rounded, color: Colors.pink, size: 24),
            SizedBox(width: 8),
            Text(
              tr(context, 'personal_health'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.favorite,
                color: Colors.red,
                title: tr(context, 'heart_rate'),
                value: healthSummary?['heartRate'] != null ? "${healthSummary!['heartRate']} bpm" : tr(context, 'not_available'),
                onTap: () => _showHeartRateInfo(context, healthSummary?['heartRate']),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.water_drop,
                color: Colors.blue,
                title: tr(context, 'hydration'),
                value: healthSummary?['hydration'] != null 
                    ? "${(healthSummary!['hydration'] * 100).toStringAsFixed(0)}%"
                    : tr(context, 'not_tracked'),
                onTap: () => _showHydrationInfo(context, healthSummary?['hydration']),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.bedtime,
                color: Colors.indigo,
                title: tr(context, 'sleep_quality'),
                value: tr(context, 'good'),
                onTap: () => _showSleepQualityInfo(context, 'good'),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildModernHealthCard(
                icon: Icons.directions_run,
                color: Colors.green,
                title: tr(context, 'activity_level'),
                value: tr(context, 'moderate'),
                onTap: () => _showActivityLevelInfo(context, 'moderate'),
              ),
            ),
          ],
        ),
      ],
    );
  }


  /// Modern health card for personal metrics
  Widget _buildModernHealthCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: color.withValues(alpha: 0.7),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  /// Quick recommendations card
  Widget _buildQuickRecommendations(Map<String, dynamic>? healthSummary) {
    final alertLevel = healthSummary?['alertLevel'] ?? AlertLevel.normal;
    
    List<String> recommendations;
    Color accentColor;
    
    switch (alertLevel) {
      case AlertLevel.critical:
      case AlertLevel.high:
        recommendations = [
          tr(context, 'stay_indoors_possible'),
          tr(context, 'limit_outdoor_exercise'),
          tr(context, 'stay_hydrated'),
        ];
        accentColor = Colors.red;
        break;
      case AlertLevel.warning:
        recommendations = [
          tr(context, 'drink_plenty_water'),
          tr(context, 'monitor_air_quality'),
          tr(context, 'mindful_sun_exposure'),
        ];
        accentColor = Colors.orange;
        break;
      default:
        recommendations = [
          tr(context, 'great_day_outdoor'),
          tr(context, 'perfect_exercise'),
          tr(context, 'enjoy_fresh_air'),
        ];
        accentColor = Colors.green;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: accentColor, size: 24),
                SizedBox(width: 8),
                Text(
                  tr(context, 'quick_tips'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...recommendations.take(3).map((rec) => 
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: EdgeInsets.only(top: 6, right: 12),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        rec,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }




  /// Show UV Index information popup
  void _showUVIndexInfo(BuildContext context, double? uvIndex) {
    final infoService = HealthInfoService.instance;
    final uvInfo = infoService.getUVIndexInfo(uvIndex);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'UV Index Information',
          infoData: uvInfo,
          currentValue: uvIndex?.toStringAsFixed(1),
          customScale: uvIndex != null ? UVIndexScale(currentUV: uvIndex) : null,
        ),
      ),
    );
  }

  /// Show Temperature information popup
  void _showTemperatureInfo(BuildContext context, double? temperature) {
    final infoService = HealthInfoService.instance;
    final tempInfo = infoService.getTemperatureInfo(temperature);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'Temperature Information',
          infoData: tempInfo,
          currentValue: temperature != null ? '${temperature.toStringAsFixed(1)}°C' : null,
        ),
      ),
    );
  }

  /// Show Humidity information popup
  void _showHumidityInfo(BuildContext context, double? humidity) {
    final infoService = HealthInfoService.instance;
    final humidityInfo = infoService.getHumidityInfo(humidity);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'Humidity Information',
          infoData: humidityInfo,
          currentValue: humidity != null ? '${humidity.toStringAsFixed(0)}%' : null,
        ),
      ),
    );
  }

  /// Show Air Quality Index information popup
  void _showAQIInfo(BuildContext context, int? aqi) {
    final infoService = HealthInfoService.instance;
    final aqiInfo = infoService.getAQIInfo(aqi);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'Air Quality Index',
          infoData: aqiInfo,
          currentValue: aqi?.toString(),
          customScale: aqi != null ? AQIScale(currentAQI: aqi) : null,
        ),
      ),
    );
  }

  /// Show Heart Rate information popup
  void _showHeartRateInfo(BuildContext context, int? heartRate) {
    final infoService = HealthInfoService.instance;
    final hrInfo = infoService.getHeartRateInfo(heartRate);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'Heart Rate Information',
          infoData: hrInfo,
          currentValue: heartRate != null ? '$heartRate bpm' : null,
        ),
      ),
    );
  }

  /// Show Hydration information popup
  void _showHydrationInfo(BuildContext context, double? hydration) {
    final infoService = HealthInfoService.instance;
    final hydrationInfo = infoService.getHydrationInfo(hydration);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'Hydration Information',
          infoData: hydrationInfo,
          currentValue: hydration != null ? '${(hydration * 100).toStringAsFixed(0)}%' : null,
        ),
      ),
    );
  }

  /// Show Sleep Quality information popup
  void _showSleepQualityInfo(BuildContext context, String sleepQuality) {
    final infoService = HealthInfoService.instance;
    final sleepInfo = infoService.getSleepQualityInfo(sleepQuality);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'Sleep Quality Information',
          infoData: sleepInfo,
          currentValue: sleepQuality.toUpperCase(),
        ),
      ),
    );
  }

  /// Show Activity Level information popup
  void _showActivityLevelInfo(BuildContext context, String activityLevel) {
    final infoService = HealthInfoService.instance;
    final activityInfo = infoService.getActivityLevelInfo(activityLevel);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'Activity Level Information',
          infoData: activityInfo,
          currentValue: activityLevel.toUpperCase(),
        ),
      ),
    );
  }

  // Helper method to get weather location
  String? _getWeatherLocation(dynamic weatherData) {
    if (weatherData?.city != null && weatherData!.city!.isNotEmpty && weatherData!.city != 'Unknown') {
      return weatherData!.city!;
    } else if (weatherData?.country != null && weatherData!.country!.isNotEmpty && weatherData!.country != 'Unknown') {
      return weatherData!.country!;
    }
    return null;
  }

  // Helper method to get air quality location
  String? _getAirQualityLocation(dynamic airQualityData) {
    if (airQualityData?.city != null && airQualityData!.city!.isNotEmpty && airQualityData!.city != 'Unknown') {
      return airQualityData!.city!;
    } else if (airQualityData?.country != null && airQualityData!.country!.isNotEmpty && airQualityData!.country != 'Unknown') {
      return airQualityData!.country!;
    }
    return null;
  }

  // Show weather condition information popup
  void _showWeatherConditionInfo(BuildContext context, String? condition) {
    final infoService = HealthInfoService.instance;
    final conditionInfo = infoService.getWeatherConditionInfo(condition);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'Weather Condition Information',
          infoData: conditionInfo,
          currentValue: condition?.toUpperCase(),
        ),
      ),
    );
  }

  // Show air quality description popup
  void _showAirQualityInfo(BuildContext context, String? quality) {
    final infoService = HealthInfoService.instance;
    final qualityInfo = infoService.getAirQualityDescriptionInfo(quality);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'Air Quality Description',
          infoData: qualityInfo,
          currentValue: quality,
        ),
      ),
    );
  }

  // Show source information popup
  void _showSourceInfo(BuildContext context, String? source) {
    final infoService = HealthInfoService.instance;
    final sourceInfo = infoService.getSourceInfo(source);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'Data Source Information',
          infoData: sourceInfo,
          currentValue: source,
        ),
      ),
    );
  }

  // Show PM2.5 information popup
  void _showPM25Info(BuildContext context, double? pm25) {
    final infoService = HealthInfoService.instance;
    final pm25Info = infoService.getPM25Info(pm25);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'PM2.5 Information',
          infoData: pm25Info,
          currentValue: pm25 != null ? "${pm25.toStringAsFixed(1)} μg/m³" : null,
        ),
      ),
    );
  }

  // Show PM10 information popup
  void _showPM10Info(BuildContext context, double? pm10) {
    final infoService = HealthInfoService.instance;
    final pm10Info = infoService.getPM10Info(pm10);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'PM10 Information',
          infoData: pm10Info,
          currentValue: pm10 != null ? "${pm10.toStringAsFixed(1)} μg/m³" : null,
        ),
      ),
    );
  }

  // Show NO2 information popup
  void _showNO2Info(BuildContext context, double? no2) {
    final infoService = HealthInfoService.instance;
    final no2Info = infoService.getNO2Info(no2);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'NO₂ Information',
          infoData: no2Info,
          currentValue: no2 != null ? "${no2.toStringAsFixed(1)} μg/m³" : null,
        ),
      ),
    );
  }

  // Show SO2 information popup
  void _showSO2Info(BuildContext context, double? so2) {
    final infoService = HealthInfoService.instance;
    final so2Info = infoService.getSO2Info(so2);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'SO₂ Information',
          infoData: so2Info,
          currentValue: so2 != null ? "${so2.toStringAsFixed(1)} μg/m³" : null,
        ),
      ),
    );
  }

  // Show O3 information popup
  void _showO3Info(BuildContext context, double? o3) {
    final infoService = HealthInfoService.instance;
    final o3Info = infoService.getO3Info(o3);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'O₃ Information',
          infoData: o3Info,
          currentValue: o3 != null ? "${o3.toStringAsFixed(1)} μg/m³" : null,
        ),
      ),
    );
  }

  // Show CO information popup
  void _showCOInfo(BuildContext context, double? co) {
    final infoService = HealthInfoService.instance;
    final coInfo = infoService.getCOInfo(co);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          title: 'CO Information',
          infoData: coInfo,
          currentValue: co != null ? "${(co / 1000).toStringAsFixed(1)} mg/m³" : null,
        ),
      ),
    );
  }

}
