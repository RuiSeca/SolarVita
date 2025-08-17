import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/health_alerts/pulse_color_manager.dart';
import '../services/health_alerts/health_alert_models.dart';
import '../services/health_alerts/smart_health_data_collector.dart';
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
                  _buildHealthStatusCard(healthSummary),
                  SizedBox(height: 16),
                  _buildActiveAlertsCard(healthSummary),
                  SizedBox(height: 16),
                  _buildWeatherCard(healthSummary['weather']),
                  SizedBox(height: 16),
                  _buildAirQualityCard(healthSummary['airQuality']),
                  SizedBox(height: 16),
                  _buildHealthMetricsCard(healthSummary),
                  SizedBox(height: 16),
                  _buildRecommendationsCard(healthSummary),
                  SizedBox(height: 16),
                  _buildDebugCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStatusCard(Map<String, dynamic>? healthSummary) {
    final alertLevel = healthSummary?['alertLevel'] ?? AlertLevel.normal;
    final alertCount = healthSummary?['alertCount'] ?? 0;
    
    String statusText;
    String description;
    IconData icon;
    Color color;
    
    switch (alertLevel) {
      case AlertLevel.critical:
        statusText = tr(context, 'health_alert');
        description = tr(context, 'environmental_conditions_attention');
        icon = Icons.warning;
        color = Colors.red;
        break;
      case AlertLevel.high:
        statusText = tr(context, 'caution_advised');
        description = tr(context, 'conditions_affect_sensitive');
        icon = Icons.info;
        color = Colors.orange;
        break;
      case AlertLevel.warning:
        statusText = tr(context, 'minor_concerns');
        description = tr(context, 'generally_safe_considerations');
        icon = Icons.lightbulb_outline;
        color = Colors.yellow[700]!;
        break;
      default:
        statusText = tr(context, 'all_good');
        description = tr(context, 'excellent_conditions_outdoor');
        icon = Icons.check_circle;
        color = Colors.green;
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (alertCount > 0)
                  Text(
                    alertCount > 1 ? "$alertCount ${tr(context, 'active_alerts')}" : "$alertCount ${tr(context, 'active_alert')}",
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(dynamic weatherData) {
    if (weatherData == null) {
      return _buildInfoCard(
        title: tr(context, 'weather'),
        icon: Icons.wb_sunny,
        content: tr(context, 'weather_unavailable'),
        color: Colors.grey,
      );
    }
    
    final temp = weatherData.temperature?.toStringAsFixed(1) ?? "N/A";
    final humidity = weatherData.humidity?.toString() ?? "N/A";
    final uv = weatherData.uvIndex?.toStringAsFixed(1) ?? "N/A";
    final condition = weatherData.condition ?? "Unknown";
    final location = _formatLocation(weatherData.city, weatherData.country);
    
    return _buildInfoCard(
      title: tr(context, 'weather_conditions'),
      icon: Icons.wb_sunny,
      color: Colors.orange,
      location: location,
      content: Column(
        children: [
          _buildDataRow(tr(context, 'temperature'), "$temp°C"),
          _buildDataRow(tr(context, 'humidity'), "$humidity%"),
          _buildDataRow(tr(context, 'uv_index'), uv),
          _buildDataRow(tr(context, 'condition'), condition.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildAirQualityCard(dynamic airQualityData) {
    if (airQualityData == null) {
      return _buildInfoCard(
        title: tr(context, 'air_quality'),
        icon: Icons.air,
        content: tr(context, 'air_quality_unavailable'),
        color: Colors.grey,
      );
    }
    
    final aqi = airQualityData.aqi?.toString() ?? "N/A";
    final description = airQualityData.qualityDescription ?? "Unknown";
    final source = airQualityData.source ?? "Unknown";
    final location = _formatLocation(airQualityData.city, airQualityData.country);
    
    Color aqiColor;
    if (airQualityData.aqi != null) {
      if (airQualityData.aqi <= 50) {
        aqiColor = Colors.green;
      } else if (airQualityData.aqi <= 100) {
        aqiColor = Colors.yellow[700]!;
      } else if (airQualityData.aqi <= 150) {
        aqiColor = Colors.orange;
      } else {
        aqiColor = Colors.red;
      }
    } else {
      aqiColor = Colors.grey;
    }
    
    return _buildInfoCard(
      title: tr(context, 'air_quality'),
      icon: Icons.air,
      color: aqiColor,
      location: location,
      content: Column(
        children: [
          _buildDataRow(tr(context, 'aqi'), aqi),
          _buildDataRow(tr(context, 'quality'), description),
          _buildDataRow(tr(context, 'source'), source),
          if (airQualityData.pollutants != null)
            ...airQualityData.pollutants.entries.take(3).map((entry) =>
              _buildDataRow(
                entry.key.toUpperCase(),
                "${entry.value.toStringAsFixed(1)} μg/m³",
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHealthMetricsCard(Map<String, dynamic>? healthSummary) {
    final heartRate = healthSummary?['heartRate'];
    final hydration = healthSummary?['hydration'];
    
    return _buildInfoCard(
      title: tr(context, 'personal_health'),
      icon: Icons.favorite,
      color: Colors.pink,
      content: Column(
        children: [
          _buildDataRow(
            tr(context, 'heart_rate'),
            heartRate != null ? "$heartRate bpm" : tr(context, 'not_available'),
          ),
          _buildDataRow(
            tr(context, 'hydration'),
            hydration != null 
              ? "${(hydration * 100).toStringAsFixed(0)}% ${tr(context, 'daily_goal')}"
              : tr(context, 'not_tracked'),
          ),
          _buildDataRow(tr(context, 'sleep_quality'), tr(context, 'good')), // Placeholder
          _buildDataRow(tr(context, 'activity_level'), tr(context, 'moderate')), // Placeholder
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(Map<String, dynamic>? healthSummary) {
    final alertLevel = healthSummary?['alertLevel'] ?? AlertLevel.normal;
    
    List<String> recommendations;
    switch (alertLevel) {
      case AlertLevel.critical:
        recommendations = [
          tr(context, 'stay_indoors_possible'),
          tr(context, 'limit_outdoor_exercise'),
          tr(context, 'consider_mask_outdoors'),
          tr(context, 'keep_windows_closed'),
        ];
        break;
      case AlertLevel.high:
        recommendations = [
          tr(context, 'reduce_outdoor_activities'),
          tr(context, 'stay_hydrated'),
          tr(context, 'monitor_symptoms_sensitive'),
          tr(context, 'consider_indoor_alternatives'),
        ];
        break;
      case AlertLevel.warning:
        recommendations = [
          tr(context, 'drink_plenty_water'),
          tr(context, 'take_breaks_exercise'),
          tr(context, 'monitor_air_quality'),
          tr(context, 'mindful_sun_exposure'),
        ];
        break;
      default:
        recommendations = [
          tr(context, 'great_day_outdoor'),
          tr(context, 'perfect_exercise'),
          tr(context, 'enjoy_fresh_air'),
          tr(context, 'ideal_conditions_wellness'),
        ];
    }
    
    return _buildInfoCard(
      title: tr(context, 'recommendations'),
      icon: Icons.lightbulb,
      color: Colors.blue,
      content: Column(
        children: recommendations.map((rec) => 
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                SizedBox(width: 8),
                Expanded(child: Text(rec, style: TextStyle(fontSize: 14))),
              ],
            ),
          ),
        ).toList(),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required dynamic content,
    required Color color,
    String? location,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (location != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: color,
                      ),
                      SizedBox(width: 4),
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          content is Widget ? content : Text(content.toString()),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Format location information, prioritizing city over country
  String? _formatLocation(String? city, String? country) {
    if (city != null && city.isNotEmpty && city != 'Unknown') {
      return city;
    } else if (country != null && country.isNotEmpty && country != 'Unknown') {
      return country;
    }
    return null;
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

  Widget _buildDebugCard() {
    return _buildInfoCard(
      title: 'Debug Pulse Color',
      icon: Icons.bug_report,
      color: Colors.purple,
      content: Column(
        children: [
          Text(
            'If the pulse color seems stuck, tap below to force a refresh of the color system.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Force cleanup and re-evaluation
                PulseColorManager.instance.forceCleanupAndReevaluate();
                
                // Show feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Pulse color system refreshed'),
                      ],
                    ),
                    backgroundColor: Colors.purple,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Reset Pulse Color',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
