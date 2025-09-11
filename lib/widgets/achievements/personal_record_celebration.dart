import 'package:flutter/material.dart';
import '../../models/user/personal_record.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';

class PersonalRecordCelebration extends StatefulWidget {
  final PersonalRecord newRecord;
  final VoidCallback? onComplete;
  
  const PersonalRecordCelebration({
    super.key,
    required this.newRecord,
    this.onComplete,
  });

  @override
  State<PersonalRecordCelebration> createState() => _PersonalRecordCelebrationState();
}

class _PersonalRecordCelebrationState extends State<PersonalRecordCelebration>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _sparkleController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _startCelebration();
  }

  void _startCelebration() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _scaleController.forward();
    _sparkleController.forward();
    
    // Auto dismiss after 4 seconds
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      _dismissCelebration();
    }
  }

  void _dismissCelebration() {
    _slideController.reverse();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.8),
      child: GestureDetector(
        onTap: _dismissCelebration,
        child: Stack(
          children: [
            // Background sparkles
            ...List.generate(20, (index) => _buildSparkle(index)),
            
            // Main celebration card
            Center(
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildCelebrationCard(),
                ),
              ),
            ),
            
            // Dismiss hint
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Text(
                tr(context, 'tap_to_continue'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSparkle(int index) {
    final random = index * 0.1;
    final size = 4.0 + (random * 8);
    final left = (index * 37) % MediaQuery.of(context).size.width;
    final top = (index * 73) % MediaQuery.of(context).size.height;
    
    return AnimatedBuilder(
      animation: _sparkleAnimation,
      builder: (context, child) {
        return Positioned(
          left: left,
          top: top,
          child: Transform.scale(
            scale: _sparkleAnimation.value,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: _getRecordColor().withValues(alpha: 0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getRecordColor(),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCelebrationCard() {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _getRecordColor().withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trophy icon or Lottie animation
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _getRecordColor().withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getRecordIcon(),
              size: 40,
              color: _getRecordColor(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // "Personal Record!" text
          Text(
            tr(context, 'personal_record_achieved'),
            style: TextStyle(
              color: _getRecordColor(),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Exercise name
          Text(
            widget.newRecord.exerciseName,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Record details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getRecordColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getRecordTypeDisplay(),
                      style: TextStyle(
                        color: AppTheme.textColor(context).withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatRecordValue(),
                      style: TextStyle(
                        color: _getRecordColor(),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Achievement badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRecordColor(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getAchievementText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Motivational message
          Text(
            _getMotivationalMessage(),
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getRecordColor() {
    switch (widget.newRecord.recordType) {
      case 'Max Weight':
        return Colors.deepOrange;
      case 'Max Reps':
        return Colors.green;
      case 'Total Volume':
        return Colors.blue;
      case 'Max Distance':
        return Colors.purple;
      case 'Best Time':
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }

  IconData _getRecordIcon() {
    switch (widget.newRecord.recordType) {
      case 'Max Weight':
        return Icons.fitness_center;
      case 'Max Reps':
        return Icons.repeat;
      case 'Total Volume':
        return Icons.trending_up;
      case 'Max Distance':
        return Icons.straighten;
      case 'Best Time':
        return Icons.timer;
      default:
        return Icons.emoji_events;
    }
  }

  String _getRecordTypeDisplay() {
    return widget.newRecord.recordType;
  }

  String _formatRecordValue() {
    switch (widget.newRecord.recordType) {
      case 'Max Weight':
        return '${widget.newRecord.value.toStringAsFixed(1)} kg';
      case 'Total Volume':
        return '${widget.newRecord.value.toStringAsFixed(0)} kg';
      case 'Max Reps':
        return '${widget.newRecord.value.toInt()} reps';
      case 'Max Distance':
        return '${widget.newRecord.value.toStringAsFixed(1)} km';
      case 'Best Time':
        final minutes = (widget.newRecord.value / 60).floor();
        final seconds = (widget.newRecord.value % 60).floor();
        return '$minutes:${seconds.toString().padLeft(2, '0')}';
      default:
        return widget.newRecord.value.toStringAsFixed(1);
    }
  }

  String _getAchievementText() {
    final achievements = [
      tr(context, 'strength_unleashed'),
      tr(context, 'power_surge'),
      tr(context, 'new_heights'),
      tr(context, 'breakthrough'),
      tr(context, 'unstoppable'),
    ];
    return achievements[widget.newRecord.recordType.hashCode % achievements.length];
  }

  String _getMotivationalMessage() {
    final messages = [
      tr(context, 'pr_message_1'),
      tr(context, 'pr_message_2'),
      tr(context, 'pr_message_3'),
      tr(context, 'pr_message_4'),
    ];
    return messages[widget.newRecord.value.toInt() % messages.length];
  }
}

// Achievement badges widget for showing collected achievements
class AchievementBadgesWidget extends StatelessWidget {
  final List<PersonalRecord> records;
  final int maxDisplay;
  
  const AchievementBadgesWidget({
    super.key,
    required this.records,
    this.maxDisplay = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const SizedBox.shrink();
    }

    final recentRecords = records.take(maxDisplay).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                tr(context, 'recent_achievements'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentRecords.map((record) => _buildAchievementBadge(context, record)).toList(),
          ),
          
          if (records.length > maxDisplay) ...[
            const SizedBox(height: 8),
            Text(
              tr(context, 'and_more_achievements').replaceAll('{count}', '${records.length - maxDisplay}'),
              style: TextStyle(
                color: AppTheme.textColor(context).withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(BuildContext context, PersonalRecord record) {
    final color = _getBadgeColor(record.recordType);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getBadgeIcon(record.recordType),
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            record.recordType,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBadgeColor(String recordType) {
    switch (recordType) {
      case 'Max Weight':
        return Colors.deepOrange;
      case 'Max Reps':
        return Colors.green;
      case 'Total Volume':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }

  IconData _getBadgeIcon(String recordType) {
    switch (recordType) {
      case 'Max Weight':
        return Icons.fitness_center;
      case 'Max Reps':
        return Icons.repeat;
      case 'Total Volume':
        return Icons.trending_up;
      default:
        return Icons.emoji_events;
    }
  }
}