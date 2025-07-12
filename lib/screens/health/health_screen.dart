import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import 'package:solar_vitas/utils/translation_helper.dart';
import 'meals/meal_plan_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> with TickerProviderStateMixin {
  double waterIntake = 0.25; // Start with 250ml
  late AnimationController _waterAnimationController;
  late AnimationController _rippleController;
  late AnimationController _waveController;
  late Map<String, AnimationController> _iconAnimationControllers;
  late Animation<double> _waterAnimation;
  late Animation<double> _waveAnimation;
  
  @override
  void initState() {
    super.initState();
    _waterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _waterAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _waterAnimationController, curve: Curves.easeInOut),
    );
    _waveAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.linear),
    );
    
    // Initialize animation controllers for each stat
    _iconAnimationControllers = {
      'steps': AnimationController(duration: const Duration(milliseconds: 1000), vsync: this),
      'active': AnimationController(duration: const Duration(milliseconds: 800), vsync: this),
      'calories': AnimationController(duration: const Duration(milliseconds: 1200), vsync: this),
      'sleep': AnimationController(duration: const Duration(milliseconds: 1500), vsync: this),
      'heart': AnimationController(duration: const Duration(milliseconds: 600), vsync: this),
    };
    
    _loadWaterIntake();
  }

  @override
  void dispose() {
    _waterAnimationController.dispose();
    _rippleController.dispose();
    _waveController.dispose();
    for (final controller in _iconAnimationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadWaterIntake() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastDate = prefs.getString('water_last_date') ?? '';
    
    if (lastDate != today) {
      // Reset for new day
      setState(() {
        waterIntake = 0.25;
      });
      await prefs.setString('water_last_date', today);
      await prefs.setDouble('water_intake', 0.25);
    } else {
      setState(() {
        waterIntake = prefs.getDouble('water_intake') ?? 0.25;
      });
    }
  }

  Future<void> _addWater() async {
    if (waterIntake < 2.0) {
      final prefs = await SharedPreferences.getInstance();
      final bool wasCompleted = waterIntake >= 2.0;
      
      setState(() {
        waterIntake = (waterIntake + 0.25).clamp(0.25, 2.0);
      });
      await prefs.setDouble('water_intake', waterIntake);
      
      _waterAnimationController.forward().then((_) {
        _waterAnimationController.reset();
      });
      
      // Check if goal was just completed
      if (!wasCompleted && waterIntake >= 2.0) {
        _rippleController.forward().then((_) {
          _rippleController.reset();
        });
        // Show completion message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.celebration, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Daily water goal completed! 🎉'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, 'fitness_profile'),
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildUserOverviewCard(context),
                const SizedBox(height: 20),
                _buildMealsSection(context),
                const SizedBox(height: 24),
                _buildStatsGrid(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserOverviewCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.2),
                AppColors.primary.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.1),
                spreadRadius: 0,
                blurRadius: 40,
                offset: const Offset(0, 2),
              ),
            ],
          ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: const DecorationImage(
                image: AssetImage(
                    'assets/images/health/health_profile/profile.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, 'solarvita_fitness'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr(context, 'eco_friendly_workouts'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '7',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                'day streak',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
        _buildHorizontalStatCard(
          context, 
          Icons.directions_walk, 
          '2,146', 
          'Steps', 
          'Daily walking goal', 
          0.7, 
          Colors.blue,
          'steps',
        ),
        const SizedBox(height: 12),
        _buildHorizontalStatCard(
          context, 
          Icons.directions_run, 
          '45min', 
          'Active Time', 
          'Eco-friendly workouts', 
          0.8, 
          Colors.green,
          'active',
        ),
        const SizedBox(height: 12),
        _buildHorizontalStatCard(
          context, 
          Icons.local_fire_department, 
          '320', 
          'Calories Burned', 
          'Energy used today', 
          0.6, 
          Colors.orange,
          'calories',
        ),
        const SizedBox(height: 12),
        _buildWaterHorizontalCard(context),
        const SizedBox(height: 12),
        _buildHorizontalStatCard(
          context, 
          Icons.bedtime, 
          '7.2h', 
          'Sleep Quality', 
          'Restful night tracking', 
          0.9, 
          Colors.indigo,
          'sleep',
        ),
        const SizedBox(height: 12),
        _buildHorizontalStatCard(
          context, 
          Icons.favorite, 
          '72 BPM', 
          'Heart Rate', 
          'Cardiovascular health', 
          0.85, 
          Colors.red,
          'heart',
        ),
        ],
      ),
    );
  }


  Widget _buildHorizontalStatCard(
    BuildContext context, 
    IconData icon, 
    String value, 
    String title, 
    String subtitle, 
    double progress, 
    Color iconColor,
    String statType,
  ) {
    return GestureDetector(
      onTap: () => _navigateWithAnimation(statType, iconColor),
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.textColor(context).withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
            child: Row(
              children: [
                // Animated Icon
                AnimatedBuilder(
                  animation: _iconAnimationControllers[statType]!,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        _getAnimationOffset(statType, _iconAnimationControllers[statType]!.value),
                        0,
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                value,
                                style: TextStyle(
                                  color: AppTheme.textColor(context),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(
                                color: iconColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            color: AppTheme.textColor(context).withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Progress indicator
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    value: progress,
                    backgroundColor: iconColor.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
      ),
    );
  }

  double _getAnimationOffset(String statType, double animationValue) {
    switch (statType) {
      case 'steps':
        // Walking animation - step by step
        return sin(animationValue * 4 * pi) * 8;
      case 'active':
        // Running animation - faster movement
        return sin(animationValue * 6 * pi) * 12;
      case 'calories':
        // Fire flickering
        return sin(animationValue * 8 * pi) * 4;
      case 'sleep':
        // Gentle floating like sleeping
        return sin(animationValue * 2 * pi) * 6;
      case 'heart':
        // Heart beat rhythm
        return animationValue < 0.5 
            ? sin(animationValue * 8 * pi) * 10
            : sin(animationValue * 2 * pi) * 3;
      default:
        return 0;
    }
  }

  Future<void> _navigateWithAnimation(String statType, Color color) async {
    // Start the witty animation
    await _iconAnimationControllers[statType]!.forward();
    
    // Navigate to detail page
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StatDetailPage(
            statType: statType,
            color: color,
          ),
        ),
      );
    }
    
    // Reset animation
    _iconAnimationControllers[statType]!.reset();
  }

  Widget _buildWaterHorizontalCard(BuildContext context) {
    final waterPercentage = (waterIntake - 0.25) / (2.0 - 0.25);
    
    return GestureDetector(
      onTap: _addWater,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyan.withValues(alpha: 0.15),
                  Colors.cyan.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: waterIntake >= 2.0 
                    ? Colors.green.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: waterIntake >= 2.0 
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.cyan.withValues(alpha: 0.1),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
                  spreadRadius: 0,
                  blurRadius: 40,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Water animation container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.cyan.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Water fill with waves
                      AnimatedBuilder(
                        animation: Listenable.merge([_waterAnimation, _waveAnimation]),
                        builder: (context, child) {
                          return Positioned(
                            bottom: 2,
                            left: 2,
                            right: 2,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CustomPaint(
                                size: Size(44, (44 * waterPercentage).clamp(0.0, 44)),
                                painter: WaterWavePainter(
                                  waterLevel: waterPercentage,
                                  waveOffset: _waveAnimation.value,
                                  containerHeight: 44,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Water drop icon overlay
                      Center(
                        child: Icon(
                          Icons.water_drop,
                          color: waterIntake >= 2.0 ? Colors.green : Colors.cyan,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(waterIntake * 1000).toInt()}ml',
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${((waterIntake / 2.0) * 100).toInt()}%',
                                style: TextStyle(
                                  color: waterIntake >= 2.0 ? Colors.green : Colors.cyan,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (waterIntake >= 2.0) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Water Intake',
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Tap to add 250ml • Goal: 2L',
                        style: TextStyle(
                          color: AppTheme.textColor(context).withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Progress indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: waterPercentage.clamp(0.0, 1.0),
                    backgroundColor: Colors.cyan.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      waterIntake >= 2.0 ? Colors.green : Colors.cyan,
                    ),
                    strokeWidth: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildMealsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'friendly_meals'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildMealPlanningCard(context),
      ],
    );
  }


  Widget _buildMealPlanningCard(BuildContext context) {
    return Container(
      width: double
          .infinity, // Makes the card expand to the full width of its parent
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: AssetImage('assets/images/health/meals/meal.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            tr(context, 'meal_planning'),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 2,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Plan healthy, eco-friendly meals that fuel your fitness journey and support sustainable living.',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              height: 1.3,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 2,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MealPlanScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                tr(context, 'explore_meals'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class StatItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final BuildContext context;

  const StatItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          tr(context, title),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          tr(context, subtitle),
          style: TextStyle(
            color: AppTheme.textColor(context).withValues(alpha: 153),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class WaterWavePainter extends CustomPainter {
  final double waterLevel;
  final double waveOffset;
  final double containerHeight;

  WaterWavePainter({
    required this.waterLevel,
    required this.waveOffset,
    required this.containerHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waterLevel <= 0) return;

    final waterHeight = size.height;
    final waveHeight = waterHeight * 0.1; // Wave amplitude
    final waveLength = size.width / 2; // Wave length

    // Create wave path
    final path = Path();
    path.moveTo(0, waterHeight);

    // Draw sine wave at the top of water
    for (double x = 0; x <= size.width; x += 1) {
      final waveY = sin((x / waveLength * 2 * pi) + waveOffset) * waveHeight;
      final y = (waterHeight - waveHeight) + waveY;
      if (x == 0) {
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Complete the path
    path.lineTo(size.width, waterHeight);
    path.lineTo(0, waterHeight);
    path.close();

    // Create gradient paint
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.cyan.withValues(alpha: 0.7),
          Colors.cyan.withValues(alpha: 0.9),
          Colors.cyan,
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw the water with waves
    canvas.drawPath(path, paint);

    // Add some sparkle effects
    final sparkleRandom = Random(42); // Fixed seed for consistent sparkles
    final sparklePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1;

    for (int i = 0; i < 3; i++) {
      final x = sparkleRandom.nextDouble() * size.width;
      final y = sparkleRandom.nextDouble() * waterHeight * 0.8;
      final sparkleOffset = sin(waveOffset + i) * 2;
      canvas.drawCircle(
        Offset(x + sparkleOffset, y),
        1 + sin(waveOffset + i) * 0.5,
        sparklePaint,
      );
    }
  }

  @override
  bool shouldRepaint(WaterWavePainter oldDelegate) {
    return oldDelegate.waterLevel != waterLevel ||
           oldDelegate.waveOffset != waveOffset;
  }
}

class StatDetailPage extends StatelessWidget {
  final String statType;
  final Color color;

  const StatDetailPage({
    super.key,
    required this.statType,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppTheme.textColor(context),
          ),
        ),
        title: Text(
          _getStatTitle(statType),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Hero card
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.3),
                        color.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getStatIcon(statType),
                        color: color,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getStatValue(statType),
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getStatSubtitle(statType),
                        style: TextStyle(
                          color: AppTheme.textColor(context).withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Details cards
            ..._getDetailCards(context, statType, color),
          ],
        ),
      ),
    );
  }

  String _getStatTitle(String statType) {
    switch (statType) {
      case 'steps': return 'Steps Tracking';
      case 'active': return 'Active Time';
      case 'calories': return 'Calories Burned';
      case 'sleep': return 'Sleep Quality';
      case 'heart': return 'Heart Rate';
      default: return 'Health Stats';
    }
  }

  IconData _getStatIcon(String statType) {
    switch (statType) {
      case 'steps': return Icons.directions_walk;
      case 'active': return Icons.directions_run;
      case 'calories': return Icons.local_fire_department;
      case 'sleep': return Icons.bedtime;
      case 'heart': return Icons.favorite;
      default: return Icons.analytics;
    }
  }

  String _getStatValue(String statType) {
    switch (statType) {
      case 'steps': return '2,146';
      case 'active': return '45min';
      case 'calories': return '320';
      case 'sleep': return '7.2h';
      case 'heart': return '72';
      default: return '0';
    }
  }

  String _getStatSubtitle(String statType) {
    switch (statType) {
      case 'steps': return 'steps today';
      case 'active': return 'active minutes';
      case 'calories': return 'calories burned';
      case 'sleep': return 'hours of sleep';
      case 'heart': return 'BPM average';
      default: return 'data points';
    }
  }

  List<Widget> _getDetailCards(BuildContext context, String statType, Color color) {
    return [
      _buildDetailCard(
        context,
        'Today\'s Goal',
        _getTodayGoal(statType),
        _getTodayProgress(statType),
        color,
      ),
      const SizedBox(height: 16),
      _buildDetailCard(
        context,
        'Weekly Average',
        _getWeeklyAverage(statType),
        _getWeeklyProgress(statType),
        color,
      ),
      const SizedBox(height: 16),
      _buildDetailCard(
        context,
        'This Month',
        _getMonthlyStats(statType),
        _getMonthlyProgress(statType),
        color,
      ),
    ];
  }

  Widget _buildDetailCard(BuildContext context, String title, String value, double progress, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textColor(context).withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTodayGoal(String statType) {
    switch (statType) {
      case 'steps': return '2,146 / 10,000';
      case 'active': return '45 / 60 min';
      case 'calories': return '320 / 500 cal';
      case 'sleep': return '7.2 / 8.0 hrs';
      case 'heart': return '72 BPM (Normal)';
      default: return 'N/A';
    }
  }

  double _getTodayProgress(String statType) {
    switch (statType) {
      case 'steps': return 0.21;
      case 'active': return 0.75;
      case 'calories': return 0.64;
      case 'sleep': return 0.9;
      case 'heart': return 0.85;
      default: return 0.0;
    }
  }

  String _getWeeklyAverage(String statType) {
    switch (statType) {
      case 'steps': return '8,423 avg/day';
      case 'active': return '52 min avg/day';
      case 'calories': return '387 cal avg/day';
      case 'sleep': return '7.5 hrs avg/night';
      case 'heart': return '74 BPM avg';
      default: return 'N/A';
    }
  }

  double _getWeeklyProgress(String statType) {
    switch (statType) {
      case 'steps': return 0.84;
      case 'active': return 0.87;
      case 'calories': return 0.77;
      case 'sleep': return 0.94;
      case 'heart': return 0.88;
      default: return 0.0;
    }
  }

  String _getMonthlyStats(String statType) {
    switch (statType) {
      case 'steps': return '248,690 total';
      case 'active': return '1,560 min total';
      case 'calories': return '11,610 cal total';
      case 'sleep': return '232.5 hrs total';
      case 'heart': return '73 BPM avg';
      default: return 'N/A';
    }
  }

  double _getMonthlyProgress(String statType) {
    switch (statType) {
      case 'steps': return 0.83;
      case 'active': return 0.78;
      case 'calories': return 0.74;
      case 'sleep': return 0.91;
      case 'heart': return 0.86;
      default: return 0.0;
    }
  }
}
