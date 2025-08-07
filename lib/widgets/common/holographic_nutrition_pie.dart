// Futuristic Holographic Nutrition Pie Chart Widget
// Features:
// - 3D holographic visual effects with green glass appearance
// - Animated pie chart showing calories, protein, carbs, fat distribution
// - Floating modal overlay with blur effects
// - Real-time updates as nutrition values change
// - Click to expand/collapse functionality
// - Futuristic UI design with glowing effects

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'dart:ui';

/// Accessible color palette for WCAG compliance
class AccessibleNutritionColors {
  // WCAG-compliant colors with 4.5:1 contrast ratio
  static const Color protein = Color(0xFF0288D1); // Teal Blue - works with white text
  static const Color carbs = Color(0xFF00CC6A);   // Adjusted Green - works with black text  
  static const Color fat = Color(0xFF6A1B9A);     // Purple - works with white text
  static const Color empty = Color(0xFF424242);   // Dark Gray - works with white text
  
  /// Dynamic text color based on background luminance
  static Color getTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    // WCAG guideline: use white text on dark backgrounds, black on light
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
  
  /// Get contrasting shadow color for text enhancement
  static Color getShadowColor(Color backgroundColor) {
    final textColor = getTextColor(backgroundColor);
    return textColor == Colors.white ? Colors.black : Colors.white;
  }
  
  /// Enhanced text style with proper contrast and accessibility
  static TextStyle getAccessibleTextStyle(Color backgroundColor, {
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    final textColor = getTextColor(backgroundColor);
    final shadowColor = getShadowColor(backgroundColor);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: textColor,
      shadows: [
        Shadow(
          offset: const Offset(0.5, 0.5),
          blurRadius: 2,
          color: shadowColor.withValues(alpha: 0.8),
        ),
        Shadow(
          offset: const Offset(-0.5, -0.5),
          blurRadius: 2,
          color: shadowColor.withValues(alpha: 0.8),
        ),
      ],
    );
  }

  /// High-contrast black text style for maximum readability
  static TextStyle getBlackTextStyle({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: const Color(0xFF000000), // Pure black for maximum contrast
      shadows: [
        // Subtle dark shadow for depth without white outline
        Shadow(
          offset: const Offset(0.5, 0.5),
          blurRadius: 1,
          color: Colors.black.withValues(alpha: 0.3),
        ),
      ],
    );
  }
}

class HolographicNutritionPie extends StatefulWidget {
  final Map<String, dynamic> nutritionFacts;
  final bool isCompact; // For small trigger button vs full display
  final VoidCallback? onTap;
  
  const HolographicNutritionPie({
    super.key,
    required this.nutritionFacts,
    this.isCompact = true,
    this.onTap,
  });

  @override
  State<HolographicNutritionPie> createState() => _HolographicNutritionPieState();
}

class _HolographicNutritionPieState extends State<HolographicNutritionPie>
    with TickerProviderStateMixin {
  
  late AnimationController _glowController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _typingController;
  
  late Animation<double> _glowAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _typingAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Glow animation for holographic effect
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    // Rotation animation for futuristic spin
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    // Pulse animation for the trigger button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    // Typing animation for futuristic text reveal
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typingController, curve: Curves.easeOut),
    );
    
    // Start typing animation for full display
    if (!widget.isCompact) {
      _typingController.forward();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  // Calculate nutrition distribution for pie chart
  List<PieChartSectionData> _calculateNutritionSections() {
    final calories = double.tryParse(
      widget.nutritionFacts['calories']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0'
    ) ?? 0.0;
    
    final protein = double.tryParse(
      widget.nutritionFacts['protein']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0'
    ) ?? 0.0;
    
    final carbs = double.tryParse(
      widget.nutritionFacts['carbs']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0'
    ) ?? 0.0;
    
    final fat = double.tryParse(
      widget.nutritionFacts['fat']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0'
    ) ?? 0.0;

    // Calculate calories from macros (4 cal/g protein+carbs, 9 cal/g fat)
    final proteinCalories = protein * 4;
    final carbsCalories = carbs * 4;
    final fatCalories = fat * 9;
    final totalMacroCalories = proteinCalories + carbsCalories + fatCalories;
    
    // Use provided calories or calculated if not available
    final totalCalories = calories > 0 ? calories : totalMacroCalories;
    
    if (totalCalories <= 0) {
      return [
        PieChartSectionData(
          color: AccessibleNutritionColors.empty,
          value: 100,
          title: 'No Data',
          radius: widget.isCompact ? 25 : 60,
          titleStyle: AccessibleNutritionColors.getAccessibleTextStyle(
            AccessibleNutritionColors.empty,
            fontSize: 10,
          ),
        ),
      ];
    }

    // Calculate percentages based on macro distribution, ensuring they add up to 100%
    double proteinPercentage = 0;
    double carbsPercentage = 0;
    double fatPercentage = 0;

    if (totalMacroCalories > 0) {
      proteinPercentage = (proteinCalories / totalMacroCalories * 100);
      carbsPercentage = (carbsCalories / totalMacroCalories * 100);
      fatPercentage = (fatCalories / totalMacroCalories * 100);
      
      // Ensure percentages add up to exactly 100% by adjusting the largest one
      final totalPercentage = proteinPercentage + carbsPercentage + fatPercentage;
      if (totalPercentage != 100.0) {
        // Find the largest percentage and adjust it
        if (proteinPercentage >= carbsPercentage && proteinPercentage >= fatPercentage) {
          proteinPercentage += (100.0 - totalPercentage);
        } else if (carbsPercentage >= fatPercentage) {
          carbsPercentage += (100.0 - totalPercentage);
        } else {
          fatPercentage += (100.0 - totalPercentage);
        }
      }
    }

    return [
      // Protein section - Accessible Teal Blue
      PieChartSectionData(
        color: AccessibleNutritionColors.protein,
        value: proteinPercentage,
        title: '${proteinPercentage.toInt()}%',
        radius: widget.isCompact ? 25 : 60,
        titleStyle: AccessibleNutritionColors.getBlackTextStyle(
          fontSize: widget.isCompact ? 8 : 12,
        ),
        badgeWidget: !widget.isCompact ? _buildBadge('P', '${protein.toInt()}g', AccessibleNutritionColors.protein) : null,
        badgePositionPercentageOffset: 1.2,
      ),
      
      // Carbs section - Accessible Green
      PieChartSectionData(
        color: AccessibleNutritionColors.carbs,
        value: carbsPercentage,
        title: '${carbsPercentage.toInt()}%',
        radius: widget.isCompact ? 25 : 60,
        titleStyle: AccessibleNutritionColors.getBlackTextStyle(
          fontSize: widget.isCompact ? 8 : 12,
        ),
        badgeWidget: !widget.isCompact ? _buildBadge('C', '${carbs.toInt()}g', AccessibleNutritionColors.carbs) : null,
        badgePositionPercentageOffset: 1.2,
      ),
      
      // Fat section - Accessible Purple
      PieChartSectionData(
        color: AccessibleNutritionColors.fat,
        value: fatPercentage,
        title: '${fatPercentage.toInt()}%',
        radius: widget.isCompact ? 25 : 60,
        titleStyle: AccessibleNutritionColors.getBlackTextStyle(
          fontSize: widget.isCompact ? 8 : 12,
        ),
        badgeWidget: !widget.isCompact ? _buildBadge('F', '${fat.toInt()}g', AccessibleNutritionColors.fat) : null,
        badgePositionPercentageOffset: 1.2,
      ),
    ];
  }

  Widget _buildBadge(String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: accentColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingAnimation() {
    const String text = "Based on the provided grams and the caloric values, the percentages are approximately:";
    
    return AnimatedBuilder(
      animation: _typingAnimation,
      builder: (context, child) {
        final int charactersToShow = (_typingAnimation.value * text.length).floor();
        final String visibleText = text.substring(0, charactersToShow);
        final bool showCursor = _typingAnimation.value < 1.0 && 
                               (DateTime.now().millisecondsSinceEpoch ~/ 500) % 2 == 0;
        
        return Container(
          width: double.infinity,
          height: 36, // Fixed height to prevent jumping during animation
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: visibleText,
                  style: TextStyle(
                    color: const Color(0xFF00CCDD), // Futuristic cyan
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                    height: 1.4, // Fixed line height
                    shadows: [
                      Shadow(
                        color: const Color(0xFF00CCDD).withValues(alpha: 0.8),
                        blurRadius: 4,
                      ),
                      Shadow(
                        color: const Color(0xFF00CCDD).withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                if (showCursor)
                  TextSpan(
                    text: '▋',
                    style: TextStyle(
                      color: const Color(0xFF00CCDD),
                      fontSize: 11,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00CCDD).withValues(alpha: 0.9),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactTrigger();
    } else {
      return _buildFullDisplay();
    }
  }

  Widget _buildCompactTrigger() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00FF88).withValues(alpha: 0.8),
                    const Color(0xFF00FF88).withValues(alpha: 0.2),
                    const Color(0xFF001122).withValues(alpha: 0.9),
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating background effect
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value * 2 * math.pi,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF00FF88).withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Mini pie chart
                  SizedBox(
                    width: 35,
                    height: 35,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 1,
                        centerSpaceRadius: 8,
                        sections: _calculateNutritionSections(),
                      ),
                    ),
                  ),
                  
                  // Holographic overlay
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.transparent,
                          const Color(0xFF00FF88).withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullDisplay() {
    final calories = double.tryParse(
      widget.nutritionFacts['calories']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0'
    ) ?? 0.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnimation, _rotationAnimation]),
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: RadialGradient(
              colors: [
                const Color(0xFF001122).withValues(alpha: 0.95),
                const Color(0xFF002233).withValues(alpha: 0.9),
                const Color(0xFF003344).withValues(alpha: 0.8),
              ],
            ),
            border: Border.all(
              color: Color.lerp(
                const Color(0xFF00FF88).withValues(alpha: 0.3),
                const Color(0xFF00FF88).withValues(alpha: 0.8),
                _glowAnimation.value,
              )!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FF88).withValues(alpha: _glowAnimation.value * 0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: _glowAnimation.value * 0.2),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'NUTRITION ANALYSIS',
                    style: TextStyle(
                      color: const Color(0xFF00FF88),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00FF88).withValues(alpha: 0.8),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${calories.toInt()} KCAL',
                    style: TextStyle(
                      color: const Color(0xFF00E5FF),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Animated typing text
              _buildTypingAnimation(),
              
              const SizedBox(height: 20),
              
              // Main pie chart with rotation
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  Transform.rotate(
                    angle: _rotationAnimation.value * 2 * math.pi * 0.3,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00FF88).withValues(alpha: _glowAnimation.value * 0.3),
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                  
                  // Middle glow ring
                  Transform.rotate(
                    angle: -_rotationAnimation.value * 2 * math.pi * 0.2,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: _glowAnimation.value * 0.2),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  
                  // Pie chart
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 30,
                        sections: _calculateNutritionSections(),
                      ),
                    ),
                  ),
                  
                  // Center calories display
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00FF88).withValues(alpha: 0.2),
                          const Color(0xFF001122).withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${calories.toInt()}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF00FF88).withValues(alpha: 0.8),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'kcal',
                          style: TextStyle(
                            color: const Color(0xFF00FF88),
                            fontSize: 8,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF00FF88).withValues(alpha: 0.8),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem('PROTEIN', AccessibleNutritionColors.protein, 
                    widget.nutritionFacts['protein']?.toString() ?? '0'),
                  _buildLegendItem('CARBS', AccessibleNutritionColors.carbs, 
                    widget.nutritionFacts['carbs']?.toString() ?? '0'),
                  _buildLegendItem('FAT', AccessibleNutritionColors.fat, 
                    widget.nutritionFacts['fat']?.toString() ?? '0'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color, String value) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: color.withValues(alpha: 0.8),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

// Holographic Modal Overlay Widget
class HolographicNutritionModal extends StatefulWidget {
  final Map<String, dynamic> nutritionFacts;
  final VoidCallback onClose;

  const HolographicNutritionModal({
    super.key,
    required this.nutritionFacts,
    required this.onClose,
  });

  @override
  State<HolographicNutritionModal> createState() => _HolographicNutritionModalState();
}

class _HolographicNutritionModalState extends State<HolographicNutritionModal>
    with TickerProviderStateMixin {
  
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _typingController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _typingAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typingController, curve: Curves.easeOut),
    );
    
    _fadeController.forward();
    _scaleController.forward();
    
    // Start typing animation after modal appears
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _typingController.forward();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _closeModal() async {
    await _scaleController.reverse();
    await _fadeController.reverse();
    widget.onClose();
  }

  Widget _buildTypingAnimation() {
    const String text = "Based on the provided grams and the caloric values, the percentages are approximately:";
    
    return AnimatedBuilder(
      animation: _typingAnimation,
      builder: (context, child) {
        final int charactersToShow = (_typingAnimation.value * text.length).floor();
        final String visibleText = text.substring(0, charactersToShow);
        final bool showCursor = _typingAnimation.value < 1.0 && 
                               (DateTime.now().millisecondsSinceEpoch ~/ 500) % 2 == 0;
        
        return Container(
          width: double.infinity,
          height: 36, // Fixed height to prevent jumping during animation
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: visibleText,
                  style: TextStyle(
                    color: const Color(0xFF00CCDD), // Futuristic cyan
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                    height: 1.4, // Fixed line height
                    shadows: [
                      Shadow(
                        color: const Color(0xFF00CCDD).withValues(alpha: 0.8),
                        blurRadius: 4,
                      ),
                      Shadow(
                        color: const Color(0xFF00CCDD).withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                if (showCursor)
                  TextSpan(
                    text: '▋',
                    style: TextStyle(
                      color: const Color(0xFF00CCDD),
                      fontSize: 11,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00CCDD).withValues(alpha: 0.9),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  // Calculate nutrition distribution for pie chart (modal version)
  List<PieChartSectionData> _calculateNutritionSections(Map<String, dynamic> nutritionFacts) {
    final protein = double.tryParse(
      nutritionFacts['protein']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0'
    ) ?? 0.0;
    
    final carbs = double.tryParse(
      nutritionFacts['carbs']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0'
    ) ?? 0.0;
    
    final fat = double.tryParse(
      nutritionFacts['fat']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0'
    ) ?? 0.0;

    // Calculate calories from macros (4 cal/g protein+carbs, 9 cal/g fat)
    final proteinCalories = protein * 4;
    final carbsCalories = carbs * 4;
    final fatCalories = fat * 9;
    final totalMacroCalories = proteinCalories + carbsCalories + fatCalories;

    if (totalMacroCalories <= 0) {
      return [
        PieChartSectionData(
          color: Colors.grey.withValues(alpha: 0.3),
          value: 100,
          title: 'No Data',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
        ),
      ];
    }

    // Calculate percentages based on macro distribution, ensuring they add up to 100%
    double proteinPercentage = (proteinCalories / totalMacroCalories * 100);
    double carbsPercentage = (carbsCalories / totalMacroCalories * 100);
    double fatPercentage = (fatCalories / totalMacroCalories * 100);
    
    // Ensure percentages add up to exactly 100% by adjusting the largest one
    final totalPercentage = proteinPercentage + carbsPercentage + fatPercentage;
    if (totalPercentage != 100.0) {
      if (proteinPercentage >= carbsPercentage && proteinPercentage >= fatPercentage) {
        proteinPercentage += (100.0 - totalPercentage);
      } else if (carbsPercentage >= fatPercentage) {
        carbsPercentage += (100.0 - totalPercentage);
      } else {
        fatPercentage += (100.0 - totalPercentage);
      }
    }

    return [
      // Protein section - Accessible Teal Blue
      PieChartSectionData(
        color: AccessibleNutritionColors.protein,
        value: proteinPercentage,
        title: '${proteinPercentage.toInt()}%',
        radius: 60,
        titleStyle: AccessibleNutritionColors.getBlackTextStyle(
          fontSize: 12,
        ),
      ),
      
      // Carbs section - Accessible Green
      PieChartSectionData(
        color: AccessibleNutritionColors.carbs,
        value: carbsPercentage,
        title: '${carbsPercentage.toInt()}%',
        radius: 60,
        titleStyle: AccessibleNutritionColors.getBlackTextStyle(
          fontSize: 12,
        ),
      ),
      
      // Fat section - Accessible Purple
      PieChartSectionData(
        color: AccessibleNutritionColors.fat,
        value: fatPercentage,
        title: '${fatPercentage.toInt()}%',
        radius: 60,
        titleStyle: AccessibleNutritionColors.getBlackTextStyle(
          fontSize: 12,
        ),
      ),
    ];
  }

  Widget _buildModalContent() {
    final calories = double.tryParse(
      widget.nutritionFacts['calories']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0'
    ) ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: RadialGradient(
          colors: [
            const Color(0xFF001122).withValues(alpha: 0.95),
            const Color(0xFF002233).withValues(alpha: 0.9),
            const Color(0xFF003344).withValues(alpha: 0.8),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF00FF88).withValues(alpha: 0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF88).withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
            blurRadius: 50,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NUTRITION ANALYSIS',
                style: TextStyle(
                  color: const Color(0xFF00FF88),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.8),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              Text(
                '${calories.toInt()} KCAL',
                style: TextStyle(
                  color: const Color(0xFF00E5FF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Animated typing text
          _buildTypingAnimation(),
          
          const SizedBox(height: 20),
          
          // Pie chart with rotating rings
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
              ),
              
              // Middle glow ring
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
              ),
              
              // Actual pie chart
              SizedBox(
                width: 160,
                height: 160,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 30,
                    sections: _calculateNutritionSections(widget.nutritionFacts),
                  ),
                ),
              ),
              
              // Center calories display
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00FF88).withValues(alpha: 0.2),
                      const Color(0xFF001122).withValues(alpha: 0.9),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${calories.toInt()}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: const Color(0xFF00FF88).withValues(alpha: 0.8),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'kcal',
                      style: TextStyle(
                        color: const Color(0xFF00FF88),
                        fontSize: 8,
                        shadows: [
                          Shadow(
                            color: const Color(0xFF00FF88).withValues(alpha: 0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('PROTEIN', AccessibleNutritionColors.protein, 
                widget.nutritionFacts['protein']?.toString() ?? '0'),
              _buildLegendItem('CARBS', AccessibleNutritionColors.carbs, 
                widget.nutritionFacts['carbs']?.toString() ?? '0'),
              _buildLegendItem('FAT', AccessibleNutritionColors.fat, 
                widget.nutritionFacts['fat']?.toString() ?? '0'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String value) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: color.withValues(alpha: 0.8),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _fadeAnimation]),
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Blurred background
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeModal,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 10 * _fadeAnimation.value,
                      sigmaY: 10 * _fadeAnimation.value,
                    ),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3 * _fadeAnimation.value),
                    ),
                  ),
                ),
              ),
              
              // Floating holographic card
              Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: GestureDetector(
                      onTap: _closeModal,
                      child: _buildModalContent(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}