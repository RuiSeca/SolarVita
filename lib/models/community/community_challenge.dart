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
  final int targetValue;
  final String unit;
  final String icon;
  final List<String> participants;
  final Map<String, int> leaderboard;
  final String? prize;
  final List<ChallengeTeam> teams;
  final Map<String, int> teamLeaderboard;
  final int? maxTeamSize;
  final int? maxTeams;

  CommunityChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.mode = ChallengeMode.individual,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.targetValue,
    required this.unit,
    required this.icon,
    this.participants = const [],
    this.leaderboard = const {},
    this.prize,
    this.teams = const [],
    this.teamLeaderboard = const {},
    this.maxTeamSize,
    this.maxTeams,
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
      targetValue: data['targetValue'] ?? 0,
      unit: data['unit'] ?? '',
      icon: data['icon'] ?? '🎯',
      participants: List<String>.from(data['participants'] ?? []),
      leaderboard: Map<String, int>.from(data['leaderboard'] ?? {}),
      prize: data['prize'],
      teams: (data['teams'] as List<dynamic>?)?.map((teamData) =>
        ChallengeTeam.fromFirestore(Map<String, dynamic>.from(teamData))).toList() ?? [],
      teamLeaderboard: Map<String, int>.from(data['teamLeaderboard'] ?? {}),
      maxTeamSize: data['maxTeamSize'],
      maxTeams: data['maxTeams'],
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
      'targetValue': targetValue,
      'unit': unit,
      'icon': icon,
      'participants': participants,
      'leaderboard': leaderboard,
      'prize': prize,
      'teams': teams.map((team) => team.toFirestore()).toList(),
      'teamLeaderboard': teamLeaderboard,
      'maxTeamSize': maxTeamSize,
      'maxTeams': maxTeams,
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
}