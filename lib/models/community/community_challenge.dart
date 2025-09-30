import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallengeType {
  fitness,
  nutrition,
  sustainability,
  community
}

enum ChallengeMode {
  individual,
  team,
  mixed
}

enum ChallengeStatus {
  upcoming,
  active,
  completed,
  cancelled
}

enum PrizeTier {
  top3,
  top5,
  top10,
  top15,
  top20
}

class CommunityGoal {
  final int targetValue;
  final String unit;
  final int currentProgress;
  final bool isReached;

  const CommunityGoal({
    required this.targetValue,
    required this.unit,
    required this.currentProgress,
    required this.isReached,
  });

  factory CommunityGoal.fromFirestore(Map<String, dynamic> data) {
    return CommunityGoal(
      targetValue: data['targetValue'] ?? 0,
      unit: data['unit'] ?? '',
      currentProgress: data['currentProgress'] ?? 0,
      isReached: data['isReached'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'targetValue': targetValue,
      'unit': unit,
      'currentProgress': currentProgress,
      'isReached': isReached,
    };
  }

  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    return (currentProgress / targetValue * 100).clamp(0.0, 100.0);
  }

  CommunityGoal copyWith({
    int? targetValue,
    String? unit,
    int? currentProgress,
    bool? isReached,
  }) {
    return CommunityGoal(
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      currentProgress: currentProgress ?? this.currentProgress,
      isReached: isReached ?? this.isReached,
    );
  }
}

class IndividualParticipant {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int score;
  final bool isEligible;
  final String? teamName;
  final bool meetMinimumRequirement;
  final DateTime lastActivity;

  const IndividualParticipant({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.score,
    required this.isEligible,
    this.teamName,
    required this.meetMinimumRequirement,
    required this.lastActivity,
  });

  factory IndividualParticipant.fromFirestore(Map<String, dynamic> data) {
    return IndividualParticipant(
      userId: data['userId'] ?? '',
      displayName: data['displayName'] ?? 'Unknown User',
      avatarUrl: data['avatarUrl'],
      score: data['score'] ?? 0,
      isEligible: data['isEligible'] ?? false,
      teamName: data['teamName'],
      meetMinimumRequirement: data['meetMinimumRequirement'] ?? false,
      lastActivity: (data['lastActivity'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'score': score,
      'isEligible': isEligible,
      'teamName': teamName,
      'meetMinimumRequirement': meetMinimumRequirement,
      'lastActivity': Timestamp.fromDate(lastActivity),
    };
  }

  IndividualParticipant copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    int? score,
    bool? isEligible,
    String? teamName,
    bool? meetMinimumRequirement,
    DateTime? lastActivity,
  }) {
    return IndividualParticipant(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      score: score ?? this.score,
      isEligible: isEligible ?? this.isEligible,
      teamName: teamName ?? this.teamName,
      meetMinimumRequirement: meetMinimumRequirement ?? this.meetMinimumRequirement,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }
}

class PrizeConfiguration {
  final String? communityPrize;
  final int minimumIndividualRequirement;
  final PrizeTier individualPrizeTier;
  final List<String> individualPrizes;
  final PrizeTier teamPrizeTier;
  final List<String> teamPrizes;
  final bool communityGoalRequired;

  const PrizeConfiguration({
    this.communityPrize,
    this.minimumIndividualRequirement = 1,
    this.individualPrizeTier = PrizeTier.top5,
    this.individualPrizes = const [],
    this.teamPrizeTier = PrizeTier.top5,
    this.teamPrizes = const [],
    this.communityGoalRequired = true,
  });

  factory PrizeConfiguration.fromFirestore(Map<String, dynamic> data) {
    return PrizeConfiguration(
      communityPrize: data['communityPrize'],
      minimumIndividualRequirement: data['minimumIndividualRequirement'] ?? 1,
      individualPrizeTier: PrizeTier.values[(data['individualPrizeTier'] as int?) ?? 1],
      individualPrizes: List<String>.from(data['individualPrizes'] ?? []),
      teamPrizeTier: PrizeTier.values[(data['teamPrizeTier'] as int?) ?? 1],
      teamPrizes: List<String>.from(data['teamPrizes'] ?? []),
      communityGoalRequired: data['communityGoalRequired'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'communityPrize': communityPrize,
      'minimumIndividualRequirement': minimumIndividualRequirement,
      'individualPrizeTier': individualPrizeTier.index,
      'individualPrizes': individualPrizes,
      'teamPrizeTier': teamPrizeTier.index,
      'teamPrizes': teamPrizes,
      'communityGoalRequired': communityGoalRequired,
    };
  }

  int get individualPrizeCount {
    switch (individualPrizeTier) {
      case PrizeTier.top3: return 3;
      case PrizeTier.top5: return 5;
      case PrizeTier.top10: return 10;
      case PrizeTier.top15: return 15;
      case PrizeTier.top20: return 20;
    }
  }

  int get teamPrizeCount {
    switch (teamPrizeTier) {
      case PrizeTier.top3: return 3;
      case PrizeTier.top5: return 5;
      case PrizeTier.top10: return 10;
      case PrizeTier.top15: return 15;
      case PrizeTier.top20: return 20;
    }
  }

  PrizeConfiguration copyWith({
    String? communityPrize,
    int? minimumIndividualRequirement,
    PrizeTier? individualPrizeTier,
    List<String>? individualPrizes,
    PrizeTier? teamPrizeTier,
    List<String>? teamPrizes,
    bool? communityGoalRequired,
  }) {
    return PrizeConfiguration(
      communityPrize: communityPrize ?? this.communityPrize,
      minimumIndividualRequirement: minimumIndividualRequirement ?? this.minimumIndividualRequirement,
      individualPrizeTier: individualPrizeTier ?? this.individualPrizeTier,
      individualPrizes: individualPrizes ?? this.individualPrizes,
      teamPrizeTier: teamPrizeTier ?? this.teamPrizeTier,
      teamPrizes: teamPrizes ?? this.teamPrizes,
      communityGoalRequired: communityGoalRequired ?? this.communityGoalRequired,
    );
  }
}

class ChallengeTeam {
  final String id;
  final String name;
  final String? description;
  final List<String> memberIds;
  final String captainId;
  final int totalScore;
  final DateTime createdAt;
  final String? avatarUrl;
  final Map<String, int> memberContributions;

  const ChallengeTeam({
    required this.id,
    required this.name,
    required this.memberIds,
    required this.captainId,
    required this.totalScore,
    required this.createdAt,
    this.description,
    this.avatarUrl,
    this.memberContributions = const {},
  });

  factory ChallengeTeam.fromFirestore(Map<String, dynamic> data) {
    return ChallengeTeam(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      memberIds: List<String>.from(data['memberIds'] ?? []),
      captainId: data['captainId'] ?? '',
      totalScore: data['totalScore'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      avatarUrl: data['avatarUrl'],
      memberContributions: Map<String, int>.from(data['memberContributions'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'memberIds': memberIds,
      'captainId': captainId,
      'totalScore': totalScore,
      'createdAt': Timestamp.fromDate(createdAt),
      'avatarUrl': avatarUrl,
      'memberContributions': memberContributions,
    };
  }

  ChallengeTeam copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? memberIds,
    String? captainId,
    int? totalScore,
    DateTime? createdAt,
    String? avatarUrl,
    Map<String, int>? memberContributions,
  }) {
    return ChallengeTeam(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      memberIds: memberIds ?? this.memberIds,
      captainId: captainId ?? this.captainId,
      totalScore: totalScore ?? this.totalScore,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      memberContributions: memberContributions ?? this.memberContributions,
    );
  }

  bool isCaptain(String userId) => captainId == userId;
  bool isMember(String userId) => memberIds.contains(userId);
  int get memberCount => memberIds.length;
  bool isFullForChallenge(int? maxSize) => maxSize != null && memberIds.length >= maxSize;
}

class CommunityChallenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeMode mode;
  final ChallengeStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final String icon;
  final String? imageUrl;
  final List<String> participants;
  final Map<String, int> leaderboard;
  final List<ChallengeTeam> teams;
  final Map<String, int> teamLeaderboard;
  final int? maxTeamSize;
  final int? maxTeams;

  // Enhanced Goal & Prize System
  final CommunityGoal communityGoal;
  final PrizeConfiguration prizeConfiguration;
  final Map<String, int> individualScores;
  final Map<String, bool> participantEligibility;

  CommunityChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.mode = ChallengeMode.individual,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.icon,
    this.imageUrl,
    this.participants = const [],
    this.leaderboard = const {},
    this.teams = const [],
    this.teamLeaderboard = const {},
    this.maxTeamSize,
    this.maxTeams,
    required this.communityGoal,
    required this.prizeConfiguration,
    this.individualScores = const {},
    this.participantEligibility = const {},
  });

  factory CommunityChallenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityChallenge(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: ChallengeType.values[(data['type'] is int ? data['type'] : int.tryParse(data['type']?.toString() ?? '0')) ?? 0],
      mode: ChallengeMode.values[(data['mode'] is int ? data['mode'] : int.tryParse(data['mode']?.toString() ?? '0')) ?? 0],
      status: ChallengeStatus.values[(data['status'] is int ? data['status'] : int.tryParse(data['status']?.toString() ?? '0')) ?? 0],
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      icon: data['icon'] ?? '🎯',
      imageUrl: data['imageUrl'],
      participants: List<String>.from(data['participants'] ?? []),
      leaderboard: Map<String, int>.from(data['leaderboard'] ?? {}),
      teams: (data['teams'] as List<dynamic>?)?.map((teamData) =>
        ChallengeTeam.fromFirestore(Map<String, dynamic>.from(teamData))).toList() ?? [],
      teamLeaderboard: Map<String, int>.from(data['teamLeaderboard'] ?? {}),
      maxTeamSize: data['maxTeamSize'],
      maxTeams: data['maxTeams'],
      communityGoal: CommunityGoal.fromFirestore(data['communityGoal'] ?? {}),
      prizeConfiguration: PrizeConfiguration.fromFirestore(data['prizeConfiguration'] ?? {}),
      individualScores: Map<String, int>.from(data['individualScores'] ?? {}),
      participantEligibility: Map<String, bool>.from(data['participantEligibility'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type.index,
      'mode': mode.index,
      'status': status.index,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'icon': icon,
      'imageUrl': imageUrl,
      'participants': participants,
      'leaderboard': leaderboard,
      'teams': teams.map((team) => team.toFirestore()).toList(),
      'teamLeaderboard': teamLeaderboard,
      'maxTeamSize': maxTeamSize,
      'maxTeams': maxTeams,
      'communityGoal': communityGoal.toFirestore(),
      'prizeConfiguration': prizeConfiguration.toFirestore(),
      'individualScores': individualScores,
      'participantEligibility': participantEligibility,
    };
  }

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  double get progressPercentage {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 100.0;
    
    final totalDuration = endDate.difference(startDate).inMilliseconds;
    final elapsed = now.difference(startDate).inMilliseconds;
    return (elapsed / totalDuration * 100).clamp(0.0, 100.0);
  }

  bool get isActive => status == ChallengeStatus.active;
  bool get canJoin => isActive && daysRemaining > 0;
  bool get isTeamBased => mode == ChallengeMode.team || mode == ChallengeMode.mixed;
  bool get isIndividualOnly => mode == ChallengeMode.individual;
  bool get acceptsTeams => mode == ChallengeMode.team || mode == ChallengeMode.mixed;
  bool get acceptsIndividuals => mode == ChallengeMode.individual || mode == ChallengeMode.mixed;

  int get teamCount => teams.length;
  bool get canCreateMoreTeams => maxTeams == null || teamCount < maxTeams!;

  ChallengeTeam? getTeamById(String teamId) {
    try {
      return teams.firstWhere((team) => team.id == teamId);
    } catch (e) {
      return null;
    }
  }

  ChallengeTeam? getUserTeam(String userId) {
    try {
      return teams.firstWhere((team) => team.isMember(userId));
    } catch (e) {
      return null;
    }
  }

  bool isUserInTeam(String userId) => getUserTeam(userId) != null;
  bool isUserTeamCaptain(String userId) {
    final userTeam = getUserTeam(userId);
    return userTeam?.isCaptain(userId) ?? false;
  }

  List<ChallengeTeam> get availableTeams {
    if (maxTeamSize == null) return teams;
    return teams.where((team) => !team.isFullForChallenge(maxTeamSize)).toList();
  }

  int getTotalParticipants() {
    if (isIndividualOnly) return participants.length;
    int teamParticipants = teams.fold(0, (total, team) => total + team.memberCount);
    return participants.length + teamParticipants;
  }

  // Enhanced Community Goal & Prize System Methods

  /// Returns current community goal progress as percentage
  double get communityGoalProgress => communityGoal.progressPercentage;

  /// Checks if community goal has been reached
  bool get isCommunityGoalReached => communityGoal.isReached;

  /// Gets individual score for a specific user
  int getIndividualScore(String userId) => individualScores[userId] ?? 0;

  /// Checks if a user meets the minimum individual requirement
  bool doesUserMeetMinimum(String userId) {
    final score = getIndividualScore(userId);
    return score >= prizeConfiguration.minimumIndividualRequirement;
  }

  /// Checks if a user is eligible for community prize
  bool isUserEligibleForCommunityPrize(String userId) {
    return participantEligibility[userId] ?? false;
  }

  /// Gets count of eligible participants for community prize
  int get eligibleParticipantsCount {
    return participantEligibility.values.where((eligible) => eligible).length;
  }

  /// Checks if all participants meet minimum requirements
  bool get allParticipantsMeetMinimum {
    final totalParticipants = getTotalParticipants();
    return eligibleParticipantsCount == totalParticipants && totalParticipants > 0;
  }

  /// Determines if community prizes should be awarded
  bool get shouldAwardCommunityPrizes {
    if (!prizeConfiguration.communityGoalRequired) return true;
    return isCommunityGoalReached && allParticipantsMeetMinimum;
  }

  /// Gets top individual performers (for individual leaderboard)
  List<MapEntry<String, int>> getTopIndividualPerformers() {
    final allIndividualScores = <String, int>{};

    // Add solo participants
    for (String userId in participants) {
      if (!isUserInTeam(userId)) {
        allIndividualScores[userId] = getIndividualScore(userId);
      }
    }

    // Add team members (their individual contributions)
    for (ChallengeTeam team in teams) {
      for (String userId in team.memberIds) {
        allIndividualScores[userId] = getIndividualScore(userId);
      }
    }

    var sortedEntries = allIndividualScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final prizeCount = prizeConfiguration.individualPrizeCount;
    return sortedEntries.take(prizeCount).toList();
  }

  /// Gets top team performers (for team leaderboard)
  List<MapEntry<String, int>> getTopTeamPerformers() {
    var sortedEntries = teamLeaderboard.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final prizeCount = prizeConfiguration.teamPrizeCount;
    return sortedEntries.take(prizeCount).toList();
  }

  /// Gets individual leaderboard position for a user (1-indexed, 0 if not found)
  int getIndividualLeaderboardPosition(String userId) {
    final topPerformers = getTopIndividualPerformers();
    for (int i = 0; i < topPerformers.length; i++) {
      if (topPerformers[i].key == userId) {
        return i + 1; // 1-indexed
      }
    }
    return 0; // Not in leaderboard
  }

  /// Gets team leaderboard position for a team (1-indexed, 0 if not found)
  int getTeamLeaderboardPosition(String teamId) {
    final topTeams = getTopTeamPerformers();
    for (int i = 0; i < topTeams.length; i++) {
      if (topTeams[i].key == teamId) {
        return i + 1; // 1-indexed
      }
    }
    return 0; // Not in leaderboard
  }

  /// Gets prize for individual leaderboard position (1-indexed)
  String? getIndividualPrize(int position) {
    if (position < 1 || position > prizeConfiguration.individualPrizes.length) {
      return null;
    }
    return prizeConfiguration.individualPrizes[position - 1];
  }

  /// Gets prize for team leaderboard position (1-indexed)
  String? getTeamPrize(int position) {
    if (position < 1 || position > prizeConfiguration.teamPrizes.length) {
      return null;
    }
    return prizeConfiguration.teamPrizes[position - 1];
  }

  /// Creates a copy of the challenge with updated values
  CommunityChallenge copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeType? type,
    ChallengeMode? mode,
    ChallengeStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    String? icon,
    String? imageUrl,
    List<String>? participants,
    Map<String, int>? leaderboard,
    List<ChallengeTeam>? teams,
    Map<String, int>? teamLeaderboard,
    int? maxTeamSize,
    int? maxTeams,
    CommunityGoal? communityGoal,
    PrizeConfiguration? prizeConfiguration,
    Map<String, int>? individualScores,
    Map<String, bool>? participantEligibility,
  }) {
    return CommunityChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      participants: participants ?? this.participants,
      leaderboard: leaderboard ?? this.leaderboard,
      teams: teams ?? this.teams,
      teamLeaderboard: teamLeaderboard ?? this.teamLeaderboard,
      maxTeamSize: maxTeamSize ?? this.maxTeamSize,
      maxTeams: maxTeams ?? this.maxTeams,
      communityGoal: communityGoal ?? this.communityGoal,
      prizeConfiguration: prizeConfiguration ?? this.prizeConfiguration,
      individualScores: individualScores ?? this.individualScores,
      participantEligibility: participantEligibility ?? this.participantEligibility,
    );
  }
}