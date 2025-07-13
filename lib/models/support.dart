import 'package:cloud_firestore/cloud_firestore.dart';

class Support {
  final String id;
  final String supporterId; // User who is supporting
  final String supportedId; // User being supported
  final DateTime createdAt;
  final String? supporterName;
  final String? supporterUsername;
  final String? supporterPhotoURL;
  final String? supportedName;
  final String? supportedUsername;
  final String? supportedPhotoURL;

  Support({
    required this.id,
    required this.supporterId,
    required this.supportedId,
    required this.createdAt,
    this.supporterName,
    this.supporterUsername,
    this.supporterPhotoURL,
    this.supportedName,
    this.supportedUsername,
    this.supportedPhotoURL,
  });

  factory Support.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Support(
      id: doc.id,
      supporterId: data['supporterId'] ?? '',
      supportedId: data['supportedId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      supporterName: data['supporterName'],
      supporterUsername: data['supporterUsername'],
      supporterPhotoURL: data['supporterPhotoURL'],
      supportedName: data['supportedName'],
      supportedUsername: data['supportedUsername'],
      supportedPhotoURL: data['supportedPhotoURL'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'supporterId': supporterId,
      'supportedId': supportedId,
      'createdAt': Timestamp.fromDate(createdAt),
      'supporterName': supporterName,
      'supporterUsername': supporterUsername,
      'supporterPhotoURL': supporterPhotoURL,
      'supportedName': supportedName,
      'supportedUsername': supportedUsername,
      'supportedPhotoURL': supportedPhotoURL,
    };
  }
}