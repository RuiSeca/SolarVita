import 'package:cloud_firestore/cloud_firestore.dart';

class Follow {
  final String id;
  final String followerId; // User who is following
  final String followingId; // User being followed
  final DateTime createdAt;
  final String? followerName;
  final String? followerUsername;
  final String? followerPhotoURL;
  final String? followingName;
  final String? followingUsername;
  final String? followingPhotoURL;

  Follow({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
    this.followerName,
    this.followerUsername,
    this.followerPhotoURL,
    this.followingName,
    this.followingUsername,
    this.followingPhotoURL,
  });

  factory Follow.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Follow(
      id: doc.id,
      followerId: data['followerId'] ?? '',
      followingId: data['followingId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      followerName: data['followerName'],
      followerUsername: data['followerUsername'],
      followerPhotoURL: data['followerPhotoURL'],
      followingName: data['followingName'],
      followingUsername: data['followingUsername'],
      followingPhotoURL: data['followingPhotoURL'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': Timestamp.fromDate(createdAt),
      'followerName': followerName,
      'followerUsername': followerUsername,
      'followerPhotoURL': followerPhotoURL,
      'followingName': followingName,
      'followingUsername': followingUsername,
      'followingPhotoURL': followingPhotoURL,
    };
  }
}