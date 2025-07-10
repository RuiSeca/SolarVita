// lib/models/water_reminder_preferences.dart
import 'package:flutter/material.dart';

class WaterReminderPreferences {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int frequencyHours;
  final TimeOfDay quietStartTime;
  final TimeOfDay quietEndTime;
  final bool weekendDifferent;
  final TimeOfDay weekendStartTime;
  final TimeOfDay weekendEndTime;

  const WaterReminderPreferences({
    required this.startTime,
    required this.endTime,
    required this.frequencyHours,
    required this.quietStartTime,
    required this.quietEndTime,
    required this.weekendDifferent,
    required this.weekendStartTime,
    required this.weekendEndTime,
  });

  WaterReminderPreferences copyWith({
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? frequencyHours,
    TimeOfDay? quietStartTime,
    TimeOfDay? quietEndTime,
    bool? weekendDifferent,
    TimeOfDay? weekendStartTime,
    TimeOfDay? weekendEndTime,
  }) {
    return WaterReminderPreferences(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      frequencyHours: frequencyHours ?? this.frequencyHours,
      quietStartTime: quietStartTime ?? this.quietStartTime,
      quietEndTime: quietEndTime ?? this.quietEndTime,
      weekendDifferent: weekendDifferent ?? this.weekendDifferent,
      weekendStartTime: weekendStartTime ?? this.weekendStartTime,
      weekendEndTime: weekendEndTime ?? this.weekendEndTime,
    );
  }

  // Calculate how many reminders per day
  int get dailyReminderCount {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    final totalMinutes = endMinutes > startMinutes
        ? endMinutes - startMinutes
        : (24 * 60) - startMinutes + endMinutes;

    // Calculate number of reminders, accounting for quiet hours
    final reminderIntervalMinutes = frequencyHours * 60;
    final baseCount = (totalMinutes / reminderIntervalMinutes).floor();

    // Estimate reduction due to quiet hours
    final quietStartMinutes = quietStartTime.hour * 60 + quietStartTime.minute;
    final quietEndMinutes = quietEndTime.hour * 60 + quietEndTime.minute;
    final quietDuration = quietEndMinutes > quietStartMinutes
        ? quietEndMinutes - quietStartMinutes
        : (24 * 60) - quietStartMinutes + quietEndMinutes;

    final quietRemindersReduced =
        (quietDuration / reminderIntervalMinutes).floor();

    return (baseCount - quietRemindersReduced).clamp(1, 24);
  }

  // Get total daily water goal (assuming 250ml per reminder)
  int get dailyWaterGoal => dailyReminderCount * 250;

  // Check if preferences are valid
  bool get isValid {
    return frequencyHours >= 1 && frequencyHours <= 4 && dailyReminderCount > 0;
  }

  // Get a summary string for display
  String getSummaryText() {
    final startText = _formatTime(startTime);
    final endText = _formatTime(endTime);
    final quietText =
        '${_formatTime(quietStartTime)} - ${_formatTime(quietEndTime)}';

    return 'Active: $startText - $endText\n'
        'Every $frequencyHours hours\n'
        'Quiet: $quietText\n'
        '${weekendDifferent ? "Weekend schedule enabled" : "Same schedule daily"}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WaterReminderPreferences &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.frequencyHours == frequencyHours &&
        other.quietStartTime == quietStartTime &&
        other.quietEndTime == quietEndTime &&
        other.weekendDifferent == weekendDifferent &&
        other.weekendStartTime == weekendStartTime &&
        other.weekendEndTime == weekendEndTime;
  }

  @override
  int get hashCode {
    return Object.hash(
      startTime,
      endTime,
      frequencyHours,
      quietStartTime,
      quietEndTime,
      weekendDifferent,
      weekendStartTime,
      weekendEndTime,
    );
  }

  @override
  String toString() {
    return 'WaterReminderPreferences(${getSummaryText().replaceAll('\n', ', ')})';
  }
}
