import 'package:cloud_firestore/cloud_firestore.dart';

enum CircleType {
  support,      // General mutual support
  fitness,      // Fitness-focused circle
  nutrition,    // Nutrition-focused circle
  sustainability, // Eco-focused circle
  family,       // Family circles
  professional  // Work/professional goals
}

enum CircleMemberRole {
  creator,     // Circle creator
  mentor,      // Experienced member who guides others
  member,      // Regular member
  mentee       // New member being guided
}

enum CirclePrivacy {
  public,      // Anyone can see and join
  private,     // Invite only
  discoverable // Can be found but requires approval
}

class SupporterCircle {
  final String id;
  final String name;
  final String description;
  final CircleType type;
  final CirclePrivacy privacy;
  final String creatorId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<CircleMember> members;
  final List<String> tags;
  final String? imageUrl;
  final Map<String, dynamic> settings;
  final CircleStats stats;
  final List<CircleGoal> goals;

  SupporterCircle({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.privacy,
    required this.creatorId,
    required this.createdAt,
    this.updatedAt,
    this.members = const [],
    this.tags = const [],
    this.imageUrl,
    this.settings = const {},
    required this.stats,
    this.goals = const [],
  });

  factory SupporterCircle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupporterCircle(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: CircleType.values[data['type'] ?? 0],
      privacy: CirclePrivacy.values[data['privacy'] ?? 0],
      creatorId: data['creatorId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp?)?.toDate()
          : null,
      members: (data['members'] as List<dynamic>? ?? [])
          .map((m) => CircleMember.fromMap(m))
          .toList(),
      tags: List<String>.from(data['tags'] ?? []),
      imageUrl: data['imageUrl'],
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      stats: CircleStats.fromMap(data['stats'] ?? {}),
      goals: (data['goals'] as List<dynamic>? ?? [])
          .map((g) => CircleGoal.fromMap(g))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.index,
      'privacy': privacy.index,
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'members': members.map((m) => m.toMap()).toList(),
      'tags': tags,
      'imageUrl': imageUrl,
      'settings': settings,
      'stats': stats.toMap(),
      'goals': goals.map((g) => g.toMap()).toList(),
    };
  }

  // Helper getters
  int get memberCount => members.length;
  bool get isFull => memberCount >= (settings['maxMembers'] ?? 10);
  List<CircleMember> get mentors => members.where((m) => m.role == CircleMemberRole.mentor).toList();
  List<CircleMember> get activeMembers => members.where((m) => m.isActive).toList();
}

class CircleMember {
  final String userId;
  final String displayName;
  final String? photoURL;
  final CircleMemberRole role;
  final DateTime joinedAt;
  final DateTime? lastActive;
  final Map<String, dynamic> stats;
  final List<String> achievements;
  final bool isActive;

  CircleMember({
    required this.userId,
    required this.displayName,
    this.photoURL,
    required this.role,
    required this.joinedAt,
    this.lastActive,
    this.stats = const {},
    this.achievements = const [],
    this.isActive = true,
  });

  factory CircleMember.fromMap(Map<String, dynamic> data) {
    return CircleMember(
      userId: data['userId'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      role: CircleMemberRole.values[data['role'] ?? 2], // Default to member
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: data['lastActive'] != null
          ? (data['lastActive'] as Timestamp?)?.toDate()
          : null,
      stats: Map<String, dynamic>.from(data['stats'] ?? {}),
      achievements: List<String>.from(data['achievements'] ?? []),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role.index,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'stats': stats,
      'achievements': achievements,
      'isActive': isActive,
    };
  }
}

class CircleStats {
  final int totalCheckIns;
  final int totalEncouragement;
  final double avgEngagement;
  final Map<String, int> weeklyActivity;
  final DateTime lastUpdated;

  CircleStats({
    this.totalCheckIns = 0,
    this.totalEncouragement = 0,
    this.avgEngagement = 0.0,
    this.weeklyActivity = const {},
    required this.lastUpdated,
  });

  factory CircleStats.fromMap(Map<String, dynamic> data) {
    return CircleStats(
      totalCheckIns: data['totalCheckIns'] ?? 0,
      totalEncouragement: data['totalEncouragement'] ?? 0,
      avgEngagement: (data['avgEngagement'] ?? 0.0).toDouble(),
      weeklyActivity: Map<String, int>.from(data['weeklyActivity'] ?? {}),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalCheckIns': totalCheckIns,
      'totalEncouragement': totalEncouragement,
      'avgEngagement': avgEngagement,
      'weeklyActivity': weeklyActivity,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

class CircleGoal {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final Map<String, dynamic> progress;
  final bool isCompleted;

  CircleGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    this.progress = const {},
    this.isCompleted = false,
  });

  factory CircleGoal.fromMap(Map<String, dynamic> data) {
    return CircleGoal(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      progress: Map<String, dynamic>.from(data['progress'] ?? {}),
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': Timestamp.fromDate(deadline),
      'progress': progress,
      'isCompleted': isCompleted,
    };
  }
}