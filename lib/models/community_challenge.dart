import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallengeType {
  fitness,
  nutrition,
  sustainability,
  community
}

enum ChallengeStatus {
  upcoming,
  active,
  completed,
  cancelled
}

class CommunityChallenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final int targetValue;
  final String unit;
  final String icon;
  final List<String> participants;
  final Map<String, int> leaderboard;
  final String? prize;

  CommunityChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.targetValue,
    required this.unit,
    required this.icon,
    this.participants = const [],
    this.leaderboard = const {},
    this.prize,
  });

  factory CommunityChallenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityChallenge(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: ChallengeType.values[(data['type'] is int ? data['type'] : int.tryParse(data['type']?.toString() ?? '0')) ?? 0],
      status: ChallengeStatus.values[(data['status'] is int ? data['status'] : int.tryParse(data['status']?.toString() ?? '0')) ?? 0],
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      targetValue: data['targetValue'] ?? 0,
      unit: data['unit'] ?? '',
      icon: data['icon'] ?? '🎯',
      participants: List<String>.from(data['participants'] ?? []),
      leaderboard: Map<String, int>.from(data['leaderboard'] ?? {}),
      prize: data['prize'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type.index,
      'status': status.index,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'targetValue': targetValue,
      'unit': unit,
      'icon': icon,
      'participants': participants,
      'leaderboard': leaderboard,
      'prize': prize,
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
}