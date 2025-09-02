import 'package:cloud_firestore/cloud_firestore.dart';
import '../social/social_activity.dart';

class PrivacySettings {
  final String userId;
  final PostVisibility defaultPostVisibility;
  final bool showProfileInSearch;
  final bool allowFriendRequests;
  final bool showWorkoutStats;
  final bool showNutritionStats;
  final bool showEcoScore;
  final bool showAchievements;
  final bool allowChallengeInvites;
  final bool showStoryHighlights;
  final bool allowStoryViews;
  final bool showStoryViewers;
  final DateTime updatedAt;

  PrivacySettings({
    required this.userId,
    this.defaultPostVisibility = PostVisibility.supportersOnly,
    this.showProfileInSearch = true,
    this.allowFriendRequests = true,
    this.showWorkoutStats = true,
    this.showNutritionStats = false,
    this.showEcoScore = true,
    this.showAchievements = true,
    this.allowChallengeInvites = true,
    this.showStoryHighlights = true,
    this.allowStoryViews = true,
    this.showStoryViewers = true,
    required this.updatedAt,
  });

  factory PrivacySettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PrivacySettings(
      userId: doc.id,
      defaultPostVisibility:
          PostVisibility.values[(data['defaultPostVisibility'] is int
                  ? data['defaultPostVisibility']
                  : int.tryParse(
                      data['defaultPostVisibility']?.toString() ?? '0',
                    )) ??
              0],
      showProfileInSearch: data['showProfileInSearch'] ?? true,
      allowFriendRequests: data['allowFriendRequests'] ?? true,
      showWorkoutStats: data['showWorkoutStats'] ?? true,
      showNutritionStats: data['showNutritionStats'] ?? false,
      showEcoScore: data['showEcoScore'] ?? true,
      showAchievements: data['showAchievements'] ?? true,
      allowChallengeInvites: data['allowChallengeInvites'] ?? true,
      showStoryHighlights: data['showStoryHighlights'] ?? true,
      allowStoryViews: data['allowStoryViews'] ?? true,
      showStoryViewers: data['showStoryViewers'] ?? true,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'defaultPostVisibility': defaultPostVisibility.index,
      'showProfileInSearch': showProfileInSearch,
      'allowFriendRequests': allowFriendRequests,
      'showWorkoutStats': showWorkoutStats,
      'showNutritionStats': showNutritionStats,
      'showEcoScore': showEcoScore,
      'showAchievements': showAchievements,
      'allowChallengeInvites': allowChallengeInvites,
      'showStoryHighlights': showStoryHighlights,
      'allowStoryViews': allowStoryViews,
      'showStoryViewers': showStoryViewers,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  PrivacySettings copyWith({
    PostVisibility? defaultPostVisibility,
    bool? showProfileInSearch,
    bool? allowFriendRequests,
    bool? showWorkoutStats,
    bool? showNutritionStats,
    bool? showEcoScore,
    bool? showAchievements,
    bool? allowChallengeInvites,
    bool? showStoryHighlights,
    bool? allowStoryViews,
    bool? showStoryViewers,
  }) {
    return PrivacySettings(
      userId: userId,
      defaultPostVisibility:
          defaultPostVisibility ?? this.defaultPostVisibility,
      showProfileInSearch: showProfileInSearch ?? this.showProfileInSearch,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
      showWorkoutStats: showWorkoutStats ?? this.showWorkoutStats,
      showNutritionStats: showNutritionStats ?? this.showNutritionStats,
      showEcoScore: showEcoScore ?? this.showEcoScore,
      showAchievements: showAchievements ?? this.showAchievements,
      allowChallengeInvites:
          allowChallengeInvites ?? this.allowChallengeInvites,
      showStoryHighlights: showStoryHighlights ?? this.showStoryHighlights,
      allowStoryViews: allowStoryViews ?? this.allowStoryViews,
      showStoryViewers: showStoryViewers ?? this.showStoryViewers,
      updatedAt: DateTime.now(),
    );
  }
}

class PublicProfile {
  final String userId;
  final String displayName;
  final String? username;
  final String? photoURL;
  final String? fitnessLevel;
  final String? ecoScore;
  final int? totalWorkouts;
  final List<String> badges;
  final bool isVerified;
  final DateTime joinedAt;

  PublicProfile({
    required this.userId,
    required this.displayName,
    this.username,
    this.photoURL,
    this.fitnessLevel,
    this.ecoScore,
    this.totalWorkouts,
    this.badges = const [],
    this.isVerified = false,
    required this.joinedAt,
  });

  factory PublicProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PublicProfile(
      userId: doc.id,
      displayName: data['displayName'] ?? '',
      username: data['username'],
      photoURL: data['photoURL'],
      fitnessLevel: data['fitnessLevel'],
      ecoScore: data['ecoScore']?.toString(),
      totalWorkouts: data['totalWorkouts'],
      badges: List<String>.from(data['badges'] ?? []),
      isVerified: data['isVerified'] ?? false,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'username': username,
      'photoURL': photoURL,
      'fitnessLevel': fitnessLevel,
      'ecoScore': ecoScore,
      'totalWorkouts': totalWorkouts,
      'badges': badges,
      'isVerified': isVerified,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}
