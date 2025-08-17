import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'health_alert_models.dart';
import 'smart_health_data_collector.dart';

enum ColorPriority {
  userOverride(priority: 100, duration: Duration(minutes: 30)),    // Highest - User explicitly chose
  healthAlert(priority: 80, duration: Duration(minutes: 10)),      // High - Important health feedback
  healthNormal(priority: 60, duration: Duration.zero),             // Medium - Regular health influence
  circadian(priority: 40, duration: Duration.zero),               // Low - Background natural rhythm
  default_(priority: 20, duration: Duration.zero);                // Lowest - Fallback

  const ColorPriority({required this.priority, required this.duration});
  final int priority;
  final Duration duration;
}

class ColorSource {
  final ColorPriority priority;
  final Color color;
  final DateTime? activatedAt;
  final String? description;

  ColorSource({
    required this.priority,
    required this.color,
    this.activatedAt,
    this.description,
  });

  bool get isActive {
    if (priority.duration == Duration.zero) return true;
    if (activatedAt == null) return false;
    
    return DateTime.now().difference(activatedAt!) < priority.duration;
  }

  bool get isExpired => !isActive;
}

class PulseColorManager extends ChangeNotifier {
  static final Logger _logger = Logger();
  static PulseColorManager? _instance;
  
  // Color management state
  final Map<ColorPriority, ColorSource> _colorSources = {};
  Color _currentColor = const Color(0xFF4CAF50); // Default green
  AnimationController? _transitionController;
  late Animation<Color?> _colorAnimation;
  Timer? _priorityCleanupTimer;
  
  // Health data integration
  SmartHealthDataCollector? _healthCollector;
  StreamSubscription? _healthDataSubscription;
  
  // Singleton pattern
  static PulseColorManager get instance {
    _instance ??= PulseColorManager._internal();
    return _instance!;
  }
  
  PulseColorManager._internal() {
    _setupCleanupTimer();
  }
  
  // Getters
  Color get currentColor => _colorAnimation.value ?? _currentColor;
  ColorSource? get activeSource => _getHighestPrioritySource();
  bool get isTransitioning => _transitionController?.isAnimating ?? false;
  
  // Initialize the color manager
  Future<void> initialize({
    required TickerProvider vsync,
  }) async {
    try {
      _logger.i('Initializing PulseColorManager...');
      
      // Set up animation controller
      _transitionController = AnimationController(
        duration: Duration(seconds: 2),
        vsync: vsync,
      );
      
      _colorAnimation = ColorTween(
        begin: _currentColor,
        end: _currentColor,
      ).animate(CurvedAnimation(
        parent: _transitionController!,
        curve: Curves.easeInOut,
      ));
      
      // Initialize health data collector
      _healthCollector = SmartHealthDataCollector.instance;
      await _healthCollector!.initialize();
      
      // Set up initial colors
      _setupInitialColors();
      
      // Listen to health data changes
      _healthCollector!.addListener(_onHealthDataChanged);
      
      _logger.i('PulseColorManager initialized successfully');
      
    } catch (e) {
      _logger.e('Failed to initialize PulseColorManager: $e');
    }
  }
  
  // Set up initial color sources
  void _setupInitialColors() {
    // Set circadian rhythm as base
    _updateCircadianColor();
    
    // Process current health data
    _onHealthDataChanged();
  }
  
  // Handle health data changes
  void _onHealthDataChanged() {
    if (_healthCollector == null) return;
    
    try {
      final healthSummary = _healthCollector!.getHealthSummary();
      final alertLevel = healthSummary['alertLevel'] as AlertLevel;
      
      // Update health-based colors
      if (alertLevel != AlertLevel.normal) {
        _setHealthAlertColor(alertLevel);
      } else {
        _removeHealthAlert();
      }
      
      // Update circadian color
      _updateCircadianColor();
      
      // Evaluate color change
      _evaluateColorChange();
      
    } catch (e) {
      _logger.e('Error processing health data change: $e');
    }
  }
  
  // Update circadian rhythm color
  void _updateCircadianColor() {
    final circadianColor = _calculateCircadianColor();
    _colorSources[ColorPriority.circadian] = ColorSource(
      priority: ColorPriority.circadian,
      color: circadianColor,
      description: 'Circadian rhythm',
    );
  }
  
  // Calculate color based on time of day
  Color _calculateCircadianColor() {
    final hour = DateTime.now().hour;
    
    if (hour >= 0 && hour < 6) {
      // Sleep time (midnight to 6am): Deep purple for restful sleep
      final progress = hour / 6.0;
      return Color.lerp(
        Colors.purple.shade800,
        Colors.purple.shade600,
        progress,
      )!;
    } else if (hour >= 6 && hour < 9) {
      // Morning: Energizing orange/yellow
      final progress = (hour - 6) / 3.0;
      return Color.lerp(
        Colors.orange.shade300,
        Colors.amber.shade400,
        progress,
      )!;
    } else if (hour >= 9 && hour < 12) {
      // Late Morning: Active green
      return const Color(0xFF4CAF50);
    } else if (hour >= 12 && hour < 17) {
      // Afternoon: Balanced blue-green
      final progress = (hour - 12) / 5.0;
      return Color.lerp(
        const Color(0xFF4CAF50),
        Colors.teal.shade400,
        progress,
      )!;
    } else if (hour >= 17 && hour < 20) {
      // Evening: Calming blue
      final progress = (hour - 17) / 3.0;
      return Color.lerp(
        Colors.teal.shade400,
        Colors.blue.shade400,
        progress,
      )!;
    } else {
      // Late Night (8pm to midnight): Transition to deep sleep colors
      final progress = (hour - 20) / 4.0;
      return Color.lerp(
        Colors.blue.shade600,
        Colors.purple.shade800,
        progress.clamp(0.0, 1.0),
      )!;
    }
  }
  
  // Set health alert color
  void _setHealthAlertColor(AlertLevel alertLevel) {
    // All health alerts (warning, high, critical) should have 10-minute expiration
    final priority = ColorPriority.healthAlert;
    
    _colorSources[priority] = ColorSource(
      priority: priority,
      color: alertLevel.color,
      activatedAt: DateTime.now(),
      description: 'Health alert: ${alertLevel.name}',
    );
  }
  
  // Remove health alert colors
  void _removeHealthAlert() {
    final removed = _colorSources.remove(ColorPriority.healthAlert);
    if (removed != null) {
      _evaluateColorChange();
      _logger.d('Health alert color removed, evaluating color change');
    }
  }
  
  // User mood color selection
  void setUserMoodColor(Color moodColor, {String? description}) {
    _colorSources[ColorPriority.userOverride] = ColorSource(
      priority: ColorPriority.userOverride,
      color: moodColor,
      activatedAt: DateTime.now(),
      description: description ?? 'User selected mood',
    );
    
    _evaluateColorChange();
    
    _logger.d('User mood color set: $moodColor');
  }
  
  // Clear user override
  void clearUserOverride() {
    _colorSources.remove(ColorPriority.userOverride);
    
    // Force a fresh health data evaluation to ensure we get current state
    _forceHealthDataRefresh();
    
    _evaluateColorChange();
    
    _logger.d('User color override cleared');
  }
  
  // Force a fresh evaluation of health data and clear stale alerts
  void _forceHealthDataRefresh() {
    if (_healthCollector == null) return;
    
    try {
      // Clear any existing health alert colors to force fresh evaluation
      _colorSources.remove(ColorPriority.healthAlert);
      _colorSources.remove(ColorPriority.healthNormal);
      
      // Update circadian color to current time
      _updateCircadianColor();
      
      // Re-evaluate health status
      _onHealthDataChanged();
      
      _logger.d('Forced health data refresh completed');
    } catch (e) {
      _logger.e('Error during forced health data refresh: $e');
    }
  }
  
  // Get highest priority active source
  ColorSource? _getHighestPrioritySource() {
    final activeSources = _colorSources.values
        .where((source) => source.isActive)
        .toList();
    
    if (activeSources.isEmpty) return null;
    
    activeSources.sort((a, b) => b.priority.priority.compareTo(a.priority.priority));
    return activeSources.first;
  }
  
  // Evaluate if color should change
  void _evaluateColorChange() {
    final newSource = _getHighestPrioritySource();
    Color newColor;
    
    if (newSource != null) {
      newColor = newSource.color;
      _logger.d('Using color source: ${newSource.description} (priority: ${newSource.priority.priority})');
    } else {
      // No active sources, use circadian color if available, otherwise default green
      final circadianSource = _colorSources[ColorPriority.circadian];
      if (circadianSource != null) {
        newColor = circadianSource.color;
        _logger.d('No active sources, falling back to circadian color');
      } else {
        newColor = const Color(0xFF4CAF50);
        _logger.d('No active sources, using default green color');
      }
    }
    
    if (newColor != _currentColor) {
      _animateToColor(newColor);
      _logger.d('Color changing to: $newColor');
    } else {
      _logger.d('Color unchanged: $newColor');
    }
  }
  
  // Animate to new color
  void _animateToColor(Color newColor) {
    if (_transitionController == null) {
      _currentColor = newColor;
      notifyListeners();
      return;
    }
    
    _colorAnimation = ColorTween(
      begin: _colorAnimation.value ?? _currentColor,
      end: newColor,
    ).animate(CurvedAnimation(
      parent: _transitionController!,
      curve: Curves.easeInOut,
    ));
    
    _transitionController!.forward(from: 0).then((_) {
      _currentColor = newColor;
      notifyListeners();
    });
    
    // Notify listeners during animation
    _colorAnimation.addListener(() => notifyListeners());
  }
  
  // Set up cleanup timer for expired sources
  void _setupCleanupTimer() {
    _priorityCleanupTimer = Timer.periodic(Duration(minutes: 1), (_) {
      _cleanupExpiredSources();
    });
  }
  
  // Clean up expired color sources
  void _cleanupExpiredSources() {
    final initialCount = _colorSources.length;
    _colorSources.removeWhere((priority, source) => source.isExpired);
    
    if (_colorSources.length != initialCount) {
      _evaluateColorChange();
      _logger.d('Cleaned up expired color sources');
    }
  }
  
  
  // Get color for specific mood
  static Color getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'calm':
      case 'relaxed':
        return Colors.blue.shade400;
      case 'energetic':
      case 'active':
        return Colors.green.shade400;
      case 'focused':
      case 'concentrated':
        return Colors.purple.shade400;
      case 'happy':
      case 'joyful':
        return Colors.yellow.shade400;
      case 'peaceful':
      case 'zen':
        return Colors.teal.shade300;
      case 'motivated':
      case 'determined':
        return Colors.orange.shade400;
      default:
        return const Color(0xFF4CAF50);
    }
  }
  
  // Get available mood options
  static List<Map<String, dynamic>> getMoodOptions() {
    return [
      {'name': 'Calm', 'color': Colors.blue.shade400, 'icon': Icons.spa},
      {'name': 'Energetic', 'color': Colors.green.shade400, 'icon': Icons.bolt},
      {'name': 'Focused', 'color': Colors.purple.shade400, 'icon': Icons.center_focus_strong},
      {'name': 'Happy', 'color': Colors.yellow.shade400, 'icon': Icons.sentiment_very_satisfied},
      {'name': 'Peaceful', 'color': Colors.teal.shade300, 'icon': Icons.self_improvement},
      {'name': 'Motivated', 'color': Colors.orange.shade400, 'icon': Icons.trending_up},
    ];
  }
  
  // Get debug information
  Map<String, dynamic> getDebugInfo() {
    final healthSummary = _healthCollector?.getHealthSummary();
    return {
      'currentColor': _currentColor.toString(),
      'isTransitioning': isTransitioning,
      'activeSource': activeSource?.description,
      'activeSources': _colorSources.length,
      'healthAlertLevel': healthSummary?['alertLevel']?.toString() ?? 'unknown',
      'healthAlertCount': healthSummary?['alertCount'] ?? 0,
      'sources': _colorSources.entries.map((e) => {
        'priority': e.key.name,
        'priorityValue': e.key.priority,
        'color': e.value.color.toString(),
        'isActive': e.value.isActive,
        'description': e.value.description,
        'activatedAt': e.value.activatedAt?.toString(),
        'duration': e.key.duration.toString(),
      }).toList(),
    };
  }
  
  // Force cleanup of all expired sources and re-evaluate
  void forceCleanupAndReevaluate() {
    _logger.i('Manual cleanup and re-evaluation requested');
    _cleanupExpiredSources();
    _forceHealthDataRefresh();
    _evaluateColorChange();
    
    final debugInfo = getDebugInfo();
    _logger.i('After cleanup - Active sources: ${debugInfo['activeSources']}, Current source: ${debugInfo['activeSource']}');
  }
  
  // Dispose resources
  @override
  void dispose() {
    _priorityCleanupTimer?.cancel();
    _healthDataSubscription?.cancel();
    _healthCollector?.removeListener(_onHealthDataChanged);
    _transitionController?.dispose();
    super.dispose();
  }
}