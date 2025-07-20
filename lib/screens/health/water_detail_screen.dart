import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/lottie_water_widget.dart';
import '../../services/notification_service.dart';

class WaterDetailScreen extends StatefulWidget {
  final double currentWaterIntake;
  final Function(double) onWaterIntakeChanged;

  const WaterDetailScreen({
    super.key,
    required this.currentWaterIntake,
    required this.onWaterIntakeChanged,
  });

  @override
  State<WaterDetailScreen> createState() => _WaterDetailScreenState();
}

class _WaterDetailScreenState extends State<WaterDetailScreen> {
  late double _waterIntake;
  double _dailyLimit = 2.0; // Default 2000ml = 2.0L
  bool _isLoading = false;

  // Water reminder settings
  bool _remindersEnabled = false;
  String _reminderFrequency = '1'; // '1', '2', '3', or 'custom'
  int _customHours = 0;
  int _customMinutes = 0;

  @override
  void initState() {
    super.initState();
    _waterIntake = widget.currentWaterIntake;
    _loadWaterLimit();
    _loadReminderSettings();
  }

  Future<void> _loadWaterLimit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyLimit = prefs.getDouble('water_daily_limit') ?? 2.0;
    });
  }

  Future<void> _saveWaterLimit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('water_daily_limit', _dailyLimit);
  }

  Future<void> _loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _remindersEnabled = prefs.getBool('water_reminders_enabled') ?? false;
      _reminderFrequency = prefs.getString('water_reminder_frequency') ?? '1';
      _customHours = prefs.getInt('water_reminder_custom_hours') ?? 0;
      _customMinutes = prefs.getInt('water_reminder_custom_minutes') ?? 0;
    });
  }

  Future<void> _saveReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('water_reminders_enabled', _remindersEnabled);
    await prefs.setString('water_reminder_frequency', _reminderFrequency);
    await prefs.setInt('water_reminder_custom_hours', _customHours);
    await prefs.setInt('water_reminder_custom_minutes', _customMinutes);

    // Schedule or cancel water reminders based on settings
    await _scheduleWaterReminders();
  }

  Future<void> _scheduleWaterReminders() async {
    final notificationService = NotificationService();

    // Cancel existing water reminders
    await notificationService.cancelNotificationsByType('water_reminder');

    if (!_remindersEnabled) {
      return; // Don't schedule if disabled
    }

    try {
      // Calculate interval based on frequency setting
      Duration interval;
      switch (_reminderFrequency) {
        case '1':
          interval = const Duration(hours: 1);
          break;
        case '2':
          interval = const Duration(hours: 2);
          break;
        case '3':
          interval = const Duration(hours: 3);
          break;
        case 'custom':
          interval = Duration(hours: _customHours, minutes: _customMinutes);
          break;
        default:
          interval = const Duration(hours: 1);
      }

      // Don't schedule if interval is 0
      if (interval.inMinutes == 0) {
        return;
      }

      // Schedule multiple reminders throughout the day
      final now = DateTime.now();
      DateTime nextReminder = now.add(interval);

      // Schedule up to 12 reminders for the day
      for (int i = 0; i < 12; i++) {
        if (nextReminder.day != now.day) {
          break; // Stop if we've moved to the next day
        }

        await notificationService.scheduleWaterReminderAt(
          scheduledTime: nextReminder,
          title: '💧 Stay Hydrated!',
          body: 'Time for a glass of water. Your body will thank you!',
        );

        nextReminder = nextReminder.add(interval);
      }

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Water reminders scheduled every ${_getIntervalText()}'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Failed to schedule water reminders: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getIntervalText() {
    switch (_reminderFrequency) {
      case '1':
        return '1 hour';
      case '2':
        return '2 hours';
      case '3':
        return '3 hours';
      case 'custom':
        if (_customHours == 0 && _customMinutes == 0) {
          return 'Not set';
        } else if (_customMinutes == 0) {
          return '${_customHours}h';
        } else if (_customHours == 0) {
          return '${_customMinutes}min';
        } else {
          return '${_customHours}h ${_customMinutes}min';
        }
      default:
        return '1 hour';
    }
  }

  Future<void> _resetWaterIntake() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('water_intake', 0.0);

    setState(() {
      _waterIntake = 0.0;
      _isLoading = false;
    });

    widget.onWaterIntakeChanged(0.0);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.refresh, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Water intake reset to 0ml'),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _adjustWaterLimit(bool increase) {
    setState(() {
      if (increase && _dailyLimit < 10.0) {
        _dailyLimit += 0.25; // Increase by 250ml
      } else if (!increase && _dailyLimit > 2.0) {
        _dailyLimit -= 0.25; // Decrease by 250ml
      }
    });
    _saveWaterLimit();
  }

  void _toggleReminders(bool enabled) {
    setState(() {
      _remindersEnabled = enabled;
    });
    _saveReminderSettings();
  }

  void _setReminderFrequency(String frequency) {
    setState(() {
      _reminderFrequency = frequency;
    });
    _saveReminderSettings();
  }

  void _showCustomTimePicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int tempHours = _customHours;
        int tempMinutes = _customMinutes;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardColor(context),
              title: Text(
                'Custom Reminder Time',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                height: 200,
                child: Row(
                  children: [
                    // Hours selector
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Hours',
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListWheelScrollView.useDelegate(
                              itemExtent: 40,
                              onSelectedItemChanged: (index) {
                                setDialogState(() {
                                  tempHours = index;
                                });
                              },
                              controller: FixedExtentScrollController(
                                initialItem: tempHours,
                              ),
                              childDelegate: ListWheelChildBuilderDelegate(
                                builder: (context, index) {
                                  return Center(
                                    child: Text(
                                      '$index',
                                      style: TextStyle(
                                        color: AppTheme.textColor(context),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                },
                                childCount: 6, // 0-5 hours
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Minutes selector
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Minutes',
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListWheelScrollView.useDelegate(
                              itemExtent: 40,
                              onSelectedItemChanged: (index) {
                                setDialogState(() {
                                  tempMinutes = index * 5;
                                });
                              },
                              controller: FixedExtentScrollController(
                                initialItem: tempMinutes ~/ 5,
                              ),
                              childDelegate: ListWheelChildBuilderDelegate(
                                builder: (context, index) {
                                  return Center(
                                    child: Text(
                                      '${index * 5}',
                                      style: TextStyle(
                                        color: AppTheme.textColor(context),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                },
                                childCount:
                                    12, // 0-55 minutes in 5min increments
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.textColor(context)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _customHours = tempHours;
                      _customMinutes = tempMinutes;
                    });
                    _saveReminderSettings();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text(
                    'Set',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor(context),
          title: Text(
            'Reset Water Intake',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to reset your water intake to 0ml?',
            style: TextStyle(
              color: AppTheme.textColor(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetWaterIntake();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                'Reset',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final waterPercentage = _waterIntake / _dailyLimit;
    final isGoalReached = _waterIntake >= _dailyLimit;

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
          'Water Intake',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Water Card
            _buildHeroWaterCard(waterPercentage, isGoalReached),
            const SizedBox(height: 24),

            // Daily Limit Adjustment
            _buildDailyLimitCard(),
            const SizedBox(height: 24),

            // Water Reminders
            _buildRemindersCard(),
            const SizedBox(height: 24),

            // Reset Button
            _buildResetCard(),
            const SizedBox(height: 24),

            // WHO Recommendation
            _buildWHORecommendationCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroWaterCard(double waterPercentage, bool isGoalReached) {
    // Adjust percentage calculation for 0ml start
    final adjustedPercentage = _waterIntake / _dailyLimit;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isGoalReached
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.cyan.withValues(alpha: 0.2),
            isGoalReached
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.cyan.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGoalReached
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.cyan.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Large Water Animation
          LottieWaterWidget(
            width: 120,
            height: 120,
            waterLevel: adjustedPercentage.clamp(0.0, 1.0),
            isAnimating: false,
          ),
          const SizedBox(height: 20),

          // Current Intake
          Text(
            '${(_waterIntake * 1000).toInt()}ml',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Progress Text
          Text(
            '${((_waterIntake / _dailyLimit) * 100).toInt()}% of daily goal',
            style: TextStyle(
              color: isGoalReached ? Colors.green : Colors.cyan,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Goal Status
          if (isGoalReached) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Daily goal completed! 🎉',
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Goal: ${(_dailyLimit * 1000).toInt()}ml',
              style: TextStyle(
                color: AppTheme.textColor(context).withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDailyLimitCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Limit',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Decrease Button
              IconButton(
                onPressed:
                    _dailyLimit > 2.0 ? () => _adjustWaterLimit(false) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: _dailyLimit > 2.0 ? Colors.red : Colors.grey,
                iconSize: 32,
              ),

              // Current Limit Display
              Column(
                children: [
                  Text(
                    '${(_dailyLimit * 1000).toInt()}ml',
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_dailyLimit.toStringAsFixed(1)}L',
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              // Increase Button
              IconButton(
                onPressed:
                    _dailyLimit < 10.0 ? () => _adjustWaterLimit(true) : null,
                icon: const Icon(Icons.add_circle_outline),
                color: _dailyLimit < 10.0 ? Colors.green : Colors.grey,
                iconSize: 32,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Range Info
          Text(
            'Range: 2,000ml - 10,000ml (adjusts by 250ml)',
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 0.6),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Water Reminders',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Toggle Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enable Reminders',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Switch(
                value: _remindersEnabled,
                onChanged: _toggleReminders,
                activeColor: Colors.blue,
              ),
            ],
          ),

          if (_remindersEnabled) ...[
            const SizedBox(height: 20),
            Text(
              'Reminder Frequency',
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Frequency Options
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFrequencyChip('1', '1 Hour'),
                _buildFrequencyChip('2', '2 Hours'),
                _buildFrequencyChip('3', '3 Hours'),
                _buildFrequencyChip('custom', 'Custom'),
              ],
            ),

            if (_reminderFrequency == 'custom') ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _showCustomTimePicker,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Custom Time',
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _customHours == 0 && _customMinutes == 0
                                ? 'Not set'
                                : _customMinutes == 0
                                    ? '${_customHours}h'
                                    : _customHours == 0
                                        ? '${_customMinutes}min'
                                        : '${_customHours}h ${_customMinutes}min',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.edit,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You\'ll receive notifications to drink water throughout the day',
                      style: TextStyle(
                        color:
                            AppTheme.textColor(context).withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFrequencyChip(String value, String label) {
    final isSelected = _reminderFrequency == value;

    return GestureDetector(
      onTap: () => _setReminderFrequency(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.blue
                : AppTheme.textColor(context).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textColor(context),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildResetCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reset Water Intake',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reset your current water intake back to 0ml if needed.',
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _showResetConfirmation,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                _isLoading ? 'Resetting...' : 'Reset Water Intake',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWHORecommendationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'WHO Recommendation',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'The World Health Organization (WHO) generally recommends that adult men consume around 3.7 liters (15.5 cups) of fluids per day, and adult women around 2.7 liters (11.5 cups).',
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Water intake resets daily at midnight',
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
