import 'package:flutter/material.dart';

/// Defines all available profile widgets that can be reordered
/// Note: Fixed widgets (header, supporter requests, story highlights) are not included
enum ProfileWidgetType {
  meals('meals', 'Today\'s Meals', Icons.restaurant_menu),
  userRoutine('user_routine', 'My Workout Routine', Icons.fitness_center),
  dailyGoals('daily_goals', 'Daily Goals', Icons.track_changes),
  weeklySummary('weekly_summary', 'Weekly Summary', Icons.bar_chart),
  actionGrid('action_grid', 'Quick Actions', Icons.dashboard),
  achievements('achievements', 'Achievements', Icons.emoji_events),
  ecoImpact('eco_impact', 'Eco Impact', Icons.eco);

  const ProfileWidgetType(this.key, this.displayName, this.icon);

  final String key;
  final String displayName;
  final IconData icon;

  static ProfileWidgetType fromKey(String key) {
    return ProfileWidgetType.values.firstWhere(
      (type) => type.key == key,
      orElse: () => ProfileWidgetType.dailyGoals,
    );
  }
}

/// Configuration for profile layout customization
class ProfileLayoutConfig {
  final List<ProfileWidgetType> widgetOrder;
  final Map<ProfileWidgetType, bool> widgetVisibility;
  final DateTime lastModified;
  final int version;

  const ProfileLayoutConfig({
    required this.widgetOrder,
    required this.widgetVisibility,
    required this.lastModified,
    this.version = 1,
  });

  /// Default layout for new users
  factory ProfileLayoutConfig.defaultLayout() {
    final defaultOrder = [
      ProfileWidgetType.meals,
      ProfileWidgetType.userRoutine,
      ProfileWidgetType.dailyGoals,
      ProfileWidgetType.weeklySummary,
      ProfileWidgetType.actionGrid,
      ProfileWidgetType.achievements,
      ProfileWidgetType.ecoImpact,
    ];

    final defaultVisibility = Map<ProfileWidgetType, bool>.fromEntries(
      ProfileWidgetType.values.map((type) => MapEntry(type, true)),
    );

    return ProfileLayoutConfig(
      widgetOrder: defaultOrder,
      widgetVisibility: defaultVisibility,
      lastModified: DateTime.now(),
    );
  }

  /// Get only visible widgets in order
  List<ProfileWidgetType> get visibleWidgets {
    return widgetOrder.where((type) => widgetVisibility[type] ?? true).toList();
  }

  /// Create a copy with new widget order
  ProfileLayoutConfig copyWithOrder(List<ProfileWidgetType> newOrder) {
    return ProfileLayoutConfig(
      widgetOrder: newOrder,
      widgetVisibility: widgetVisibility,
      lastModified: DateTime.now(),
      version: version,
    );
  }

  /// Create a copy with updated visibility
  ProfileLayoutConfig copyWithVisibility(ProfileWidgetType type, bool visible) {
    final newVisibility = Map<ProfileWidgetType, bool>.from(widgetVisibility);
    newVisibility[type] = visible;

    return ProfileLayoutConfig(
      widgetOrder: widgetOrder,
      widgetVisibility: newVisibility,
      lastModified: DateTime.now(),
      version: version,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'widgetOrder': widgetOrder.map((type) => type.key).toList(),
      'widgetVisibility': widgetVisibility.map(
        (type, visible) => MapEntry(type.key, visible),
      ),
      'lastModified': lastModified.toIso8601String(),
      'version': version,
    };
  }

  /// Create from JSON
  factory ProfileLayoutConfig.fromJson(Map<String, dynamic> json) {
    final savedWidgetOrder = (json['widgetOrder'] as List<dynamic>?)
        ?.cast<String>()
        .map(ProfileWidgetType.fromKey)
        .toList();

    final visibilityMap = json['widgetVisibility'] as Map<String, dynamic>?;
    final widgetVisibility = <ProfileWidgetType, bool>{};

    // Convert string keys back to enum keys
    if (visibilityMap != null) {
      for (final entry in visibilityMap.entries) {
        final type = ProfileWidgetType.fromKey(entry.key);
        widgetVisibility[type] = entry.value as bool? ?? true;
      }
    }

    // Ensure all widget types have visibility settings
    for (final type in ProfileWidgetType.values) {
      widgetVisibility.putIfAbsent(type, () => true);
    }

    // Merge existing order with new widgets for existing users
    List<ProfileWidgetType> finalWidgetOrder;
    if (savedWidgetOrder != null) {
      final defaultOrder = ProfileLayoutConfig.defaultLayout().widgetOrder;
      final existingTypes = savedWidgetOrder.toSet();
      final newTypes = defaultOrder.where((type) => !existingTypes.contains(type)).toList();
      
      // Add new widgets to the end of existing layout
      finalWidgetOrder = [...savedWidgetOrder, ...newTypes];
    } else {
      finalWidgetOrder = ProfileLayoutConfig.defaultLayout().widgetOrder;
    }

    return ProfileLayoutConfig(
      widgetOrder: finalWidgetOrder,
      widgetVisibility: widgetVisibility,
      lastModified: DateTime.tryParse(json['lastModified'] as String? ?? '') ?? 
          DateTime.now(),
      version: json['version'] as int? ?? 1,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProfileLayoutConfig) return false;

    return other.widgetOrder.toString() == widgetOrder.toString() &&
        other.widgetVisibility.toString() == widgetVisibility.toString() &&
        other.version == version;
  }

  @override
  int get hashCode {
    return widgetOrder.hashCode ^ 
           widgetVisibility.hashCode ^ 
           version.hashCode;
  }
}