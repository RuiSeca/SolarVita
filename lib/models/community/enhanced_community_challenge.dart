import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallengeFrequency {
  daily,
  weekly,
  monthly,
  oneTime,
  seasonal
}

enum ChallengeDifficulty {
  beginner,
  intermediate,
  advanced,
  expert
}

enum ChallengeParticipationType {
  individual,      // Solo challenge
  team,           // Team-based challenge
  community,      // Entire community participates
  circle          // Supporter circle challenge
}

enum ChallengeRewardType {
  badge,
  coins,
  experience,
  title,
  avatar,
  realWorld
}

enum ChallengeType {
  fitness,
  nutrition,
  eco,
  wellness,
  social,
  learning,
}

enum ChallengeStatus {
  draft,
  upcoming,
  active,
  completed,
  cancelled,
}

class EnhancedCommunityChallenge {
  final String id;
  final String title;
  final String description;
  final String longDescription;
  final ChallengeType type;
  final ChallengeStatus status;
  final ChallengeFrequency frequency;
  final ChallengeDifficulty difficulty;
  final ChallengeParticipationType participationType;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? registrationDeadline;

  // Multi-metric support
  final List<ChallengeMetric> metrics;
  final Map<String, dynamic> rules;
  final List<ChallengeReward> rewards;

  // Social features
  final List<String> participants;
  final List<ChallengeTeam> teams;
  final Map<String, ChallengeProgress> leaderboard;
  final List<String> tags;
  final String? imageUrl;
  final String? sponsorInfo;

  // Engagement features
  final List<ChallengeMilestone> milestones;
  final Map<String, dynamic> communityGoals;
  final bool allowTeams;
  final int maxParticipants;
  final int minParticipants;

  // Analytics
  final ChallengeAnalytics analytics;

  EnhancedCommunityChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.longDescription,
    required this.type,
    required this.status,
    required this.frequency,
    required this.difficulty,
    required this.participationType,
    required this.startDate,
    required this.endDate,
    this.registrationDeadline,
    required this.metrics,
    this.rules = const {},
    this.rewards = const [],
    this.participants = const [],
    this.teams = const [],
    this.leaderboard = const {},
    this.tags = const [],
    this.imageUrl,
    this.sponsorInfo,
    this.milestones = const [],
    this.communityGoals = const {},
    this.allowTeams = false,
    this.maxParticipants = 1000,
    this.minParticipants = 1,
    required this.analytics,
  });

  factory EnhancedCommunityChallenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EnhancedCommunityChallenge(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      longDescription: data['longDescription'] ?? '',
      type: ChallengeType.values[data['type'] ?? 0],
      status: ChallengeStatus.values[data['status'] ?? 0],
      frequency: ChallengeFrequency.values[data['frequency'] ?? 3],
      difficulty: ChallengeDifficulty.values[data['difficulty'] ?? 0],
      participationType: ChallengeParticipationType.values[data['participationType'] ?? 0],
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      registrationDeadline: data['registrationDeadline'] != null
          ? (data['registrationDeadline'] as Timestamp?)?.toDate()
          : null,
      metrics: (data['metrics'] as List<dynamic>? ?? [])
          .map((m) => ChallengeMetric.fromMap(m))
          .toList(),
      rules: Map<String, dynamic>.from(data['rules'] ?? {}),
      rewards: (data['rewards'] as List<dynamic>? ?? [])
          .map((r) => ChallengeReward.fromMap(r))
          .toList(),
      participants: List<String>.from(data['participants'] ?? []),
      teams: (data['teams'] as List<dynamic>? ?? [])
          .map((t) => ChallengeTeam.fromMap(t))
          .toList(),
      leaderboard: (data['leaderboard'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, ChallengeProgress.fromMap(v))),
      tags: List<String>.from(data['tags'] ?? []),
      imageUrl: data['imageUrl'],
      sponsorInfo: data['sponsorInfo'],
      milestones: (data['milestones'] as List<dynamic>? ?? [])
          .map((m) => ChallengeMilestone.fromMap(m))
          .toList(),
      communityGoals: Map<String, dynamic>.from(data['communityGoals'] ?? {}),
      allowTeams: data['allowTeams'] ?? false,
      maxParticipants: data['maxParticipants'] ?? 1000,
      minParticipants: data['minParticipants'] ?? 1,
      analytics: ChallengeAnalytics.fromMap(data['analytics'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'longDescription': longDescription,
      'type': type.index,
      'status': status.index,
      'frequency': frequency.index,
      'difficulty': difficulty.index,
      'participationType': participationType.index,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'registrationDeadline': registrationDeadline != null
          ? Timestamp.fromDate(registrationDeadline!)
          : null,
      'metrics': metrics.map((m) => m.toMap()).toList(),
      'rules': rules,
      'rewards': rewards.map((r) => r.toMap()).toList(),
      'participants': participants,
      'teams': teams.map((t) => t.toMap()).toList(),
      'leaderboard': leaderboard.map((k, v) => MapEntry(k, v.toMap())),
      'tags': tags,
      'imageUrl': imageUrl,
      'sponsorInfo': sponsorInfo,
      'milestones': milestones.map((m) => m.toMap()).toList(),
      'communityGoals': communityGoals,
      'allowTeams': allowTeams,
      'maxParticipants': maxParticipants,
      'minParticipants': minParticipants,
      'analytics': analytics.toMap(),
    };
  }

  // Helper methods
  bool get canJoin {
    if (!isActive) return false;
    if (participants.length >= maxParticipants) return false;
    if (registrationDeadline != null && DateTime.now().isAfter(registrationDeadline!)) return false;
    return true;
  }

  bool get isActive => status == ChallengeStatus.active;
  bool get isUpcoming => status == ChallengeStatus.upcoming;
  bool get isCompleted => status == ChallengeStatus.completed;

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  double get overallProgress {
    if (communityGoals.isEmpty) return 0.0;

    double totalProgress = 0.0;
    int goalCount = 0;

    communityGoals.forEach((key, value) {
      if (value is Map<String, dynamic> && value.containsKey('current') && value.containsKey('target')) {
        final current = (value['current'] ?? 0).toDouble();
        final target = (value['target'] ?? 1).toDouble();
        totalProgress += (current / target).clamp(0.0, 1.0);
        goalCount++;
      }
    });

    return goalCount > 0 ? (totalProgress / goalCount * 100) : 0.0;
  }
}

class ChallengeMetric {
  final String id;
  final String name;
  final String unit;
  final double targetValue;
  final double? minValue;
  final double? maxValue;
  final String trackingMethod; // manual, automatic, integration
  final Map<String, dynamic> config;

  ChallengeMetric({
    required this.id,
    required this.name,
    required this.unit,
    required this.targetValue,
    this.minValue,
    this.maxValue,
    this.trackingMethod = 'manual',
    this.config = const {},
  });

  factory ChallengeMetric.fromMap(Map<String, dynamic> data) {
    return ChallengeMetric(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      unit: data['unit'] ?? '',
      targetValue: (data['targetValue'] ?? 0).toDouble(),
      minValue: data['minValue']?.toDouble(),
      maxValue: data['maxValue']?.toDouble(),
      trackingMethod: data['trackingMethod'] ?? 'manual',
      config: Map<String, dynamic>.from(data['config'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'targetValue': targetValue,
      'minValue': minValue,
      'maxValue': maxValue,
      'trackingMethod': trackingMethod,
      'config': config,
    };
  }
}

class ChallengeReward {
  final String id;
  final String name;
  final String description;
  final ChallengeRewardType type;
  final Map<String, dynamic> value;
  final String? imageUrl;
  final List<String> criteria; // What needs to be achieved to get this reward

  ChallengeReward({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    this.imageUrl,
    this.criteria = const [],
  });

  factory ChallengeReward.fromMap(Map<String, dynamic> data) {
    return ChallengeReward(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: ChallengeRewardType.values[data['type'] ?? 0],
      value: Map<String, dynamic>.from(data['value'] ?? {}),
      imageUrl: data['imageUrl'],
      criteria: List<String>.from(data['criteria'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.index,
      'value': value,
      'imageUrl': imageUrl,
      'criteria': criteria,
    };
  }
}

class ChallengeTeam {
  final String id;
  final String name;
  final String? description;
  final List<String> memberIds;
  final String captainId;
  final Map<String, dynamic> stats;
  final DateTime createdAt;

  ChallengeTeam({
    required this.id,
    required this.name,
    this.description,
    required this.memberIds,
    required this.captainId,
    this.stats = const {},
    required this.createdAt,
  });

  factory ChallengeTeam.fromMap(Map<String, dynamic> data) {
    return ChallengeTeam(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      memberIds: List<String>.from(data['memberIds'] ?? []),
      captainId: data['captainId'] ?? '',
      stats: Map<String, dynamic>.from(data['stats'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'memberIds': memberIds,
      'captainId': captainId,
      'stats': stats,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class ChallengeProgress {
  final String userId;
  final Map<String, double> metricProgress;
  final double overallScore;
  final DateTime lastUpdated;
  final List<String> achievedMilestones;
  final Map<String, dynamic> additionalData;

  ChallengeProgress({
    required this.userId,
    this.metricProgress = const {},
    this.overallScore = 0.0,
    required this.lastUpdated,
    this.achievedMilestones = const [],
    this.additionalData = const {},
  });

  factory ChallengeProgress.fromMap(Map<String, dynamic> data) {
    return ChallengeProgress(
      userId: data['userId'] ?? '',
      metricProgress: Map<String, double>.from(
        (data['metricProgress'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v ?? 0).toDouble())),
      ),
      overallScore: (data['overallScore'] ?? 0).toDouble(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      achievedMilestones: List<String>.from(data['achievedMilestones'] ?? []),
      additionalData: Map<String, dynamic>.from(data['additionalData'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'metricProgress': metricProgress,
      'overallScore': overallScore,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'achievedMilestones': achievedMilestones,
      'additionalData': additionalData,
    };
  }
}

class ChallengeMilestone {
  final String id;
  final String title;
  final String description;
  final double threshold;
  final String metric;
  final List<ChallengeReward> rewards;
  final bool isAchieved;

  ChallengeMilestone({
    required this.id,
    required this.title,
    required this.description,
    required this.threshold,
    required this.metric,
    this.rewards = const [],
    this.isAchieved = false,
  });

  factory ChallengeMilestone.fromMap(Map<String, dynamic> data) {
    return ChallengeMilestone(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      threshold: (data['threshold'] ?? 0).toDouble(),
      metric: data['metric'] ?? '',
      rewards: (data['rewards'] as List<dynamic>? ?? [])
          .map((r) => ChallengeReward.fromMap(r))
          .toList(),
      isAchieved: data['isAchieved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'threshold': threshold,
      'metric': metric,
      'rewards': rewards.map((r) => r.toMap()).toList(),
      'isAchieved': isAchieved,
    };
  }
}

class ChallengeAnalytics {
  final int totalParticipants;
  final int activeParticipants;
  final double avgCompletionRate;
  final Map<String, int> participantsByRegion;
  final Map<String, double> metricAverages;
  final DateTime lastUpdated;

  ChallengeAnalytics({
    this.totalParticipants = 0,
    this.activeParticipants = 0,
    this.avgCompletionRate = 0.0,
    this.participantsByRegion = const {},
    this.metricAverages = const {},
    required this.lastUpdated,
  });

  factory ChallengeAnalytics.fromMap(Map<String, dynamic> data) {
    return ChallengeAnalytics(
      totalParticipants: data['totalParticipants'] ?? 0,
      activeParticipants: data['activeParticipants'] ?? 0,
      avgCompletionRate: (data['avgCompletionRate'] ?? 0).toDouble(),
      participantsByRegion: Map<String, int>.from(data['participantsByRegion'] ?? {}),
      metricAverages: Map<String, double>.from(
        (data['metricAverages'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v ?? 0).toDouble())),
      ),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalParticipants': totalParticipants,
      'activeParticipants': activeParticipants,
      'avgCompletionRate': avgCompletionRate,
      'participantsByRegion': participantsByRegion,
      'metricAverages': metricAverages,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}