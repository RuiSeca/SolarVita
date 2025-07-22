import 'package:cloud_firestore/cloud_firestore.dart';
import 'tribe.dart';

class TribeMember {
  final String id;
  final String tribeId;
  final String userId;
  final String userName;
  final String? userPhotoURL;
  final TribeMemberRole role;
  final DateTime joinedAt;
  final bool isActive;
  final Map<String, dynamic> stats;
  final DateTime? lastActivityAt;

  TribeMember({
    required this.id,
    required this.tribeId,
    required this.userId,
    required this.userName,
    this.userPhotoURL,
    this.role = TribeMemberRole.member,
    required this.joinedAt,
    this.isActive = true,
    this.stats = const {},
    this.lastActivityAt,
  });

  factory TribeMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TribeMember(
      id: doc.id,
      tribeId: data['tribeId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoURL: data['userPhotoURL'],
      role: TribeMemberRole.values[data['role'] ?? 0],
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      stats: Map<String, dynamic>.from(data['stats'] ?? {}),
      lastActivityAt: data['lastActivityAt'] != null 
          ? (data['lastActivityAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tribeId': tribeId,
      'userId': userId,
      'userName': userName,
      'userPhotoURL': userPhotoURL,
      'role': role.index,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isActive': isActive,
      'stats': stats,
      'lastActivityAt': lastActivityAt != null 
          ? Timestamp.fromDate(lastActivityAt!)
          : null,
    };
  }

  bool get isAdmin => role == TribeMemberRole.admin || role == TribeMemberRole.creator;
  bool get isCreator => role == TribeMemberRole.creator;

  String getRoleText() {
    switch (role) {
      case TribeMemberRole.creator:
        return 'Creator';
      case TribeMemberRole.admin:
        return 'Admin';
      case TribeMemberRole.member:
        return 'Member';
    }
  }

  String getRoleIcon() {
    switch (role) {
      case TribeMemberRole.creator:
        return '👑';
      case TribeMemberRole.admin:
        return '⭐';
      case TribeMemberRole.member:
        return '👤';
    }
  }

  String getJoinedTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(joinedAt);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Just joined';
    }
  }

  TribeMember copyWith({
    String? id,
    String? tribeId,
    String? userId,
    String? userName,
    String? userPhotoURL,
    TribeMemberRole? role,
    DateTime? joinedAt,
    bool? isActive,
    Map<String, dynamic>? stats,
    DateTime? lastActivityAt,
  }) {
    return TribeMember(
      id: id ?? this.id,
      tribeId: tribeId ?? this.tribeId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoURL: userPhotoURL ?? this.userPhotoURL,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
      stats: stats ?? this.stats,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }
}