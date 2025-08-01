import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendshipStatus {
  pending,
  accepted,
  blocked
}

class Friendship {
  final String id;
  final String requesterId;
  final String receiverId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? requesterName;
  final String? requesterUsername;
  final String? requesterPhotoURL;
  final String? receiverName;
  final String? receiverUsername;
  final String? receiverPhotoURL;

  Friendship({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.requesterName,
    this.requesterUsername,
    this.requesterPhotoURL,
    this.receiverName,
    this.receiverUsername,
    this.receiverPhotoURL,
  });

  factory Friendship.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friendship(
      id: doc.id,
      requesterId: data['requesterId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      status: FriendshipStatus.values[(data['status'] is int ? data['status'] : int.tryParse(data['status']?.toString() ?? '0')) ?? 0],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp?)?.toDate() 
          : null,
      requesterName: data['requesterName'],
      requesterUsername: data['requesterUsername'],
      requesterPhotoURL: data['requesterPhotoURL'],
      receiverName: data['receiverName'],
      receiverUsername: data['receiverUsername'],
      receiverPhotoURL: data['receiverPhotoURL'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requesterId': requesterId,
      'receiverId': receiverId,
      'status': status.index,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'requesterName': requesterName,
      'requesterUsername': requesterUsername,
      'requesterPhotoURL': requesterPhotoURL,
      'receiverName': receiverName,
      'receiverUsername': receiverUsername,
      'receiverPhotoURL': receiverPhotoURL,
    };
  }
}

class Friend {
  final String userId;
  final String displayName;
  final String? username;
  final String? photoURL;
  final String? ecoScore;
  final Map<String, dynamic>? stats;
  final int? supportersCount;

  Friend({
    required this.userId,
    required this.displayName,
    this.username,
    this.photoURL,
    this.ecoScore,
    this.stats,
    this.supportersCount,
  });

  factory Friend.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friend(
      userId: doc.id,
      displayName: data['displayName'] ?? '',
      username: data['username'],
      photoURL: data['photoURL'],
      ecoScore: data['ecoScore']?.toString(),
      stats: data['stats'],
      supportersCount: data['supportersCount'],
    );
  }
}