import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/community/community_challenge.dart';
import '../../utils/logger.dart';

class ChallengeVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  String? get currentUserId => _auth.currentUser?.uid;

  /// Capture photo for challenge verification
  Future<File?> captureVerificationPhoto({
    ImageSource source = ImageSource.camera,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      Logger.error('Error capturing verification photo: $e');
      return null;
    }
  }

  /// Upload verification photo to Firebase Storage
  Future<String?> uploadVerificationPhoto({
    required File photoFile,
    required String challengeId,
    required String userId,
  }) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
      final Reference storageRef = _storage
          .ref()
          .child('challenge_verifications')
          .child(challengeId)
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(photoFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      Logger.info('Uploaded verification photo: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      Logger.error('Error uploading verification photo: $e');
      return null;
    }
  }

  /// Submit challenge verification with photo
  Future<bool> submitChallengeVerification({
    required String challengeId,
    required File photoFile,
    required String description,
    required int pointsEarned,
    String? teamId,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      // Upload photo first
      final String? photoUrl = await uploadVerificationPhoto(
        photoFile: photoFile,
        challengeId: challengeId,
        userId: currentUserId!,
      );

      if (photoUrl == null) {
        throw Exception('Failed to upload verification photo');
      }

      // Create verification document
      final verification = ChallengeVerification(
        id: _firestore.collection('temp').doc().id,
        challengeId: challengeId,
        userId: currentUserId!,
        teamId: teamId,
        photoUrl: photoUrl,
        description: description,
        pointsEarned: pointsEarned,
        timestamp: DateTime.now(),
        status: VerificationStatus.pending,
      );

      // Save verification to Firestore
      await _firestore
          .collection('challenge_verifications')
          .doc(verification.id)
          .set(verification.toFirestore());

      // Update user/team progress
      if (teamId != null) {
        await _updateTeamProgress(challengeId, teamId, currentUserId!, pointsEarned);
      } else {
        await _updateIndividualProgress(challengeId, currentUserId!, pointsEarned);
      }

      Logger.info('Submitted challenge verification: ${verification.id}');
      return true;
    } catch (e) {
      Logger.error('Error submitting challenge verification: $e');
      return false;
    }
  }

  /// Update individual progress
  Future<void> _updateIndividualProgress(String challengeId, String userId, int points) async {
    final challengeRef = _firestore.collection('community_challenges').doc(challengeId);

    await _firestore.runTransaction((transaction) async {
      final challengeDoc = await transaction.get(challengeRef);
      if (!challengeDoc.exists) throw Exception('Challenge not found');

      final challenge = CommunityChallenge.fromFirestore(challengeDoc);
      final newLeaderboard = Map<String, int>.from(challenge.leaderboard);
      newLeaderboard[userId] = (newLeaderboard[userId] ?? 0) + points;

      transaction.update(challengeRef, {
        'leaderboard': newLeaderboard,
      });
    });
  }

  /// Update team progress
  Future<void> _updateTeamProgress(String challengeId, String teamId, String userId, int points) async {
    final challengeRef = _firestore.collection('community_challenges').doc(challengeId);

    await _firestore.runTransaction((transaction) async {
      final challengeDoc = await transaction.get(challengeRef);
      if (!challengeDoc.exists) throw Exception('Challenge not found');

      final challenge = CommunityChallenge.fromFirestore(challengeDoc);

      // Update team scores
      final updatedTeams = challenge.teams.map((team) {
        if (team.id == teamId) {
          final newContributions = Map<String, int>.from(team.memberContributions);
          newContributions[userId] = (newContributions[userId] ?? 0) + points;

          return team.copyWith(
            totalScore: team.totalScore + points,
            memberContributions: newContributions,
          );
        }
        return team;
      }).toList();

      // Update team leaderboard
      final newTeamLeaderboard = Map<String, int>.from(challenge.teamLeaderboard);
      newTeamLeaderboard[teamId] = (newTeamLeaderboard[teamId] ?? 0) + points;

      transaction.update(challengeRef, {
        'teams': updatedTeams.map((team) => team.toFirestore()).toList(),
        'teamLeaderboard': newTeamLeaderboard,
      });
    });
  }

  /// Get user's verification history for a challenge
  Stream<List<ChallengeVerification>> getUserVerifications(String challengeId) {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('challenge_verifications')
        .where('challengeId', isEqualTo: challengeId)
        .where('userId', isEqualTo: currentUserId!)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChallengeVerification.fromFirestore(doc))
            .toList());
  }

  /// Get team verification history for a challenge
  Stream<List<ChallengeVerification>> getTeamVerifications(String challengeId, String teamId) {
    return _firestore
        .collection('challenge_verifications')
        .where('challengeId', isEqualTo: challengeId)
        .where('teamId', isEqualTo: teamId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChallengeVerification.fromFirestore(doc))
            .toList());
  }

  /// Delete photo file from device
  Future<void> deletePhotoFile(File photoFile) async {
    try {
      if (await photoFile.exists()) {
        await photoFile.delete();
      }
    } catch (e) {
      Logger.error('Error deleting photo file: $e');
    }
  }
}

/// Model for challenge verification
class ChallengeVerification {
  final String id;
  final String challengeId;
  final String userId;
  final String? teamId;
  final String photoUrl;
  final String description;
  final int pointsEarned;
  final DateTime timestamp;
  final VerificationStatus status;

  const ChallengeVerification({
    required this.id,
    required this.challengeId,
    required this.userId,
    this.teamId,
    required this.photoUrl,
    required this.description,
    required this.pointsEarned,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'challengeId': challengeId,
      'userId': userId,
      'teamId': teamId,
      'photoUrl': photoUrl,
      'description': description,
      'pointsEarned': pointsEarned,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.index,
    };
  }

  factory ChallengeVerification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeVerification(
      id: data['id'] ?? doc.id,
      challengeId: data['challengeId'] ?? '',
      userId: data['userId'] ?? '',
      teamId: data['teamId'],
      photoUrl: data['photoUrl'] ?? '',
      description: data['description'] ?? '',
      pointsEarned: data['pointsEarned'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: VerificationStatus.values[data['status'] ?? 0],
    );
  }
}

enum VerificationStatus {
  pending,
  approved,
  rejected,
}