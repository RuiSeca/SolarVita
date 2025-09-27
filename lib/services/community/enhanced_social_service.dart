import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/community/supporter_circle.dart';
import '../../models/community/enhanced_community_challenge.dart';
import '../database/firebase_push_notification_service.dart';

class EnhancedSocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebasePushNotificationService _notificationService =
      FirebasePushNotificationService();

  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== SUPPORTER CIRCLES ====================

  /// Create a new supporter circle
  Future<String> createSupporterCircle({
    required String name,
    required String description,
    required CircleType type,
    required CirclePrivacy privacy,
    List<String> tags = const [],
    String? imageUrl,
    Map<String, dynamic> settings = const {},
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final circle = SupporterCircle(
      id: '', // Will be set by Firestore
      name: name,
      description: description,
      type: type,
      privacy: privacy,
      creatorId: currentUserId!,
      createdAt: DateTime.now(),
      members: [
        CircleMember(
          userId: currentUserId!,
          displayName: _auth.currentUser?.displayName ?? 'User',
          photoURL: _auth.currentUser?.photoURL,
          role: CircleMemberRole.creator,
          joinedAt: DateTime.now(),
          lastActive: DateTime.now(),
        ),
      ],
      tags: tags,
      imageUrl: imageUrl,
      settings: {
        'maxMembers': 10,
        'requireApproval': privacy != CirclePrivacy.public,
        'allowMentoring': true,
        ...settings,
      },
      stats: CircleStats(lastUpdated: DateTime.now()),
    );

    try {
      final docRef = await _firestore
          .collection('supporterCircles')
          .add(circle.toFirestore());

      // Add circle to user's profile
      await _updateUserCircles(currentUserId!, docRef.id, isJoining: true);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create supporter circle: $e');
    }
  }

  /// Join a supporter circle
  Future<void> joinSupporterCircle(String circleId, {String? message}) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final circleDoc = await _firestore
          .collection('supporterCircles')
          .doc(circleId)
          .get();

      if (!circleDoc.exists) {
        throw Exception('Circle not found');
      }

      final circle = SupporterCircle.fromFirestore(circleDoc);

      // Check if user is already a member
      if (circle.members.any((m) => m.userId == currentUserId)) {
        throw Exception('Already a member of this circle');
      }

      // Check if circle is full
      if (circle.isFull) {
        throw Exception('Circle is full');
      }

      final newMember = CircleMember(
        userId: currentUserId!,
        displayName: _auth.currentUser?.displayName ?? 'User',
        photoURL: _auth.currentUser?.photoURL,
        role: CircleMemberRole.member,
        joinedAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      // Add member to circle
      await _firestore.collection('supporterCircles').doc(circleId).update({
        'members': FieldValue.arrayUnion([newMember.toMap()]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update user's circles
      await _updateUserCircles(currentUserId!, circleId, isJoining: true);

      // Send notification to circle creator
      await _notificationService.sendNotificationToUser(
        userId: circle.creatorId,
        title: 'New Circle Member',
        body: '${_auth.currentUser?.displayName ?? 'Someone'} joined your circle "${circle.name}"',
        type: NotificationType.social,
        data: {
          'type': 'circle_join',
          'circleId': circleId,
          'userId': currentUserId!,
        },
      );

    } catch (e) {
      throw Exception('Failed to join circle: $e');
    }
  }

  /// Leave a supporter circle
  Future<void> leaveSupporterCircle(String circleId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final circleDoc = await _firestore
          .collection('supporterCircles')
          .doc(circleId)
          .get();

      if (!circleDoc.exists) return; // Circle already doesn't exist

      final circle = SupporterCircle.fromFirestore(circleDoc);
      final member = circle.members.firstWhere(
        (m) => m.userId == currentUserId,
        orElse: () => throw Exception('Not a member of this circle'),
      );

      // Remove member from circle
      await _firestore.collection('supporterCircles').doc(circleId).update({
        'members': FieldValue.arrayRemove([member.toMap()]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update user's circles
      await _updateUserCircles(currentUserId!, circleId, isJoining: false);

      // If this was the creator and there are other members, transfer ownership
      if (member.role == CircleMemberRole.creator && circle.members.length > 1) {
        final newCreator = circle.members
            .where((m) => m.userId != currentUserId)
            .reduce((a, b) => a.joinedAt.isBefore(b.joinedAt) ? a : b);

        await _transferCircleOwnership(circleId, newCreator.userId);
      }

      // If circle becomes empty, delete it
      if (circle.members.length <= 1) {
        await _firestore.collection('supporterCircles').doc(circleId).delete();
      }

    } catch (e) {
      throw Exception('Failed to leave circle: $e');
    }
  }

  /// Get user's supporter circles
  Stream<List<SupporterCircle>> getUserSupporterCircles() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('supporterCircles')
        .where('members', arrayContainsAny: [
          {'userId': currentUserId}
        ])
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupporterCircle.fromFirestore(doc))
            .where((circle) => circle.members.any((m) => m.userId == currentUserId))
            .toList());
  }

  /// Discover public supporter circles
  Stream<List<SupporterCircle>> discoverSupporterCircles({
    CircleType? type,
    List<String> tags = const [],
    int limit = 20,
  }) {
    Query query = _firestore
        .collection('supporterCircles')
        .where('privacy', isEqualTo: CirclePrivacy.public.index);

    if (type != null) {
      query = query.where('type', isEqualTo: type.index);
    }

    return query
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupporterCircle.fromFirestore(doc))
            .where((circle) {
              // Filter by tags if provided
              if (tags.isNotEmpty) {
                return tags.any((tag) => circle.tags.contains(tag));
              }
              return true;
            })
            .toList());
  }

  /// Send encouragement to circle members
  Future<void> sendCircleEncouragement(
    String circleId,
    String message,
    {List<String>? targetMembers}
  ) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final circleDoc = await _firestore
          .collection('supporterCircles')
          .doc(circleId)
          .get();

      if (!circleDoc.exists) {
        throw Exception('Circle not found');
      }

      final circle = SupporterCircle.fromFirestore(circleDoc);

      // Verify user is a member
      if (!circle.members.any((m) => m.userId == currentUserId)) {
        throw Exception('Not a member of this circle');
      }

      final encouragementData = {
        'senderId': currentUserId,
        'senderName': _auth.currentUser?.displayName ?? 'Someone',
        'message': message,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'circleId': circleId,
      };

      // Add to circle's encouragement collection
      await _firestore
          .collection('supporterCircles')
          .doc(circleId)
          .collection('encouragements')
          .add(encouragementData);

      // Send notifications to target members or all members
      final recipients = targetMembers ??
          circle.members
              .where((m) => m.userId != currentUserId)
              .map((m) => m.userId)
              .toList();

      for (final recipientId in recipients) {
        await _notificationService.sendNotificationToUser(
          userId: recipientId,
          title: 'Circle Encouragement',
          body: '${_auth.currentUser?.displayName ?? 'Someone'} sent you encouragement in ${circle.name}',
          type: NotificationType.social,
          data: {
            'type': 'circle_encouragement',
            'circleId': circleId,
            'senderId': currentUserId!,
            'message': message,
          },
        );
      }

      // Update circle stats
      await _updateCircleStats(circleId, {'totalEncouragement': FieldValue.increment(1)});

    } catch (e) {
      throw Exception('Failed to send encouragement: $e');
    }
  }

  // ==================== ENHANCED COMMUNITY CHALLENGES ====================

  /// Create an enhanced community challenge
  Future<String> createEnhancedChallenge({
    required String title,
    required String description,
    required String longDescription,
    required ChallengeType type,
    required ChallengeFrequency frequency,
    required ChallengeDifficulty difficulty,
    required ChallengeParticipationType participationType,
    required DateTime startDate,
    required DateTime endDate,
    DateTime? registrationDeadline,
    required List<ChallengeMetric> metrics,
    Map<String, dynamic> rules = const {},
    List<ChallengeReward> rewards = const [],
    List<String> tags = const [],
    String? imageUrl,
    String? sponsorInfo,
    List<ChallengeMilestone> milestones = const [],
    Map<String, dynamic> communityGoals = const {},
    bool allowTeams = false,
    int maxParticipants = 1000,
    int minParticipants = 1,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final challenge = EnhancedCommunityChallenge(
      id: '', // Will be set by Firestore
      title: title,
      description: description,
      longDescription: longDescription,
      type: type,
      status: DateTime.now().isBefore(startDate)
          ? ChallengeStatus.upcoming
          : ChallengeStatus.active,
      frequency: frequency,
      difficulty: difficulty,
      participationType: participationType,
      startDate: startDate,
      endDate: endDate,
      registrationDeadline: registrationDeadline,
      metrics: metrics,
      rules: rules,
      rewards: rewards,
      tags: tags,
      imageUrl: imageUrl,
      sponsorInfo: sponsorInfo,
      milestones: milestones,
      communityGoals: communityGoals,
      allowTeams: allowTeams,
      maxParticipants: maxParticipants,
      minParticipants: minParticipants,
      analytics: ChallengeAnalytics(lastUpdated: DateTime.now()),
    );

    try {
      final docRef = await _firestore
          .collection('enhancedChallenges')
          .add(challenge.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create challenge: $e');
    }
  }

  /// Join an enhanced community challenge
  Future<void> joinEnhancedChallenge(String challengeId, {String? teamId}) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final challengeDoc = await _firestore
          .collection('enhancedChallenges')
          .doc(challengeId)
          .get();

      if (!challengeDoc.exists) {
        throw Exception('Challenge not found');
      }

      final challenge = EnhancedCommunityChallenge.fromFirestore(challengeDoc);

      if (!challenge.canJoin) {
        throw Exception('Cannot join this challenge');
      }

      // Check if user is already participating
      if (challenge.participants.contains(currentUserId)) {
        throw Exception('Already participating in this challenge');
      }

      final batch = _firestore.batch();

      // Add user to participants
      batch.update(challengeDoc.reference, {
        'participants': FieldValue.arrayUnion([currentUserId]),
      });

      // Initialize user progress
      final initialProgress = ChallengeProgress(
        userId: currentUserId!,
        metricProgress: Map.fromEntries(
          challenge.metrics.map((m) => MapEntry(m.id, 0.0)),
        ),
        lastUpdated: DateTime.now(),
      );

      batch.set(
        challengeDoc.reference
            .collection('progress')
            .doc(currentUserId),
        initialProgress.toMap(),
      );

      // If joining a team, update team membership
      if (teamId != null && challenge.allowTeams) {
        await _joinChallengeTeam(challengeId, teamId);
      }

      await batch.commit();

      // Update analytics
      await _updateChallengeAnalytics(challengeId, {
        'totalParticipants': FieldValue.increment(1),
        'activeParticipants': FieldValue.increment(1),
      });

    } catch (e) {
      throw Exception('Failed to join challenge: $e');
    }
  }

  /// Update challenge progress
  Future<void> updateChallengeProgress(
    String challengeId,
    String metricId,
    double value,
    {Map<String, dynamic>? additionalData}
  ) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final progressRef = _firestore
          .collection('enhancedChallenges')
          .doc(challengeId)
          .collection('progress')
          .doc(currentUserId);

      final progressDoc = await progressRef.get();

      if (!progressDoc.exists) {
        throw Exception('Not participating in this challenge');
      }

      final currentProgress = ChallengeProgress.fromMap(progressDoc.data()!);
      final updatedMetricProgress = Map<String, double>.from(currentProgress.metricProgress);
      updatedMetricProgress[metricId] = value;

      // Calculate overall score (average of all metric progress percentages)
      final challengeDoc = await _firestore
          .collection('enhancedChallenges')
          .doc(challengeId)
          .get();

      final challenge = EnhancedCommunityChallenge.fromFirestore(challengeDoc);
      double totalProgress = 0.0;
      int metricCount = 0;

      for (final metric in challenge.metrics) {
        final progress = updatedMetricProgress[metric.id] ?? 0.0;
        final percentage = (progress / metric.targetValue).clamp(0.0, 1.0);
        totalProgress += percentage;
        metricCount++;
      }

      final overallScore = metricCount > 0 ? (totalProgress / metricCount * 100) : 0.0;

      await progressRef.update({
        'metricProgress': updatedMetricProgress,
        'overallScore': overallScore,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
        if (additionalData != null) 'additionalData': additionalData,
      });

      // Check for milestone achievements
      await _checkMilestoneAchievements(challengeId, challenge, currentProgress);

    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }

  /// Get enhanced challenges
  Stream<List<EnhancedCommunityChallenge>> getEnhancedChallenges({
    ChallengeStatus? status,
    ChallengeType? type,
    ChallengeDifficulty? difficulty,
    int limit = 20,
  }) {
    Query query = _firestore.collection('enhancedChallenges');

    if (status != null) {
      query = query.where('status', isEqualTo: status.index);
    }

    if (type != null) {
      query = query.where('type', isEqualTo: type.index);
    }

    if (difficulty != null) {
      query = query.where('difficulty', isEqualTo: difficulty.index);
    }

    return query
        .orderBy('startDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EnhancedCommunityChallenge.fromFirestore(doc))
            .toList());
  }

  /// Get user's challenge progress
  Stream<ChallengeProgress?> getChallengeProgress(String challengeId) {
    if (currentUserId == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('enhancedChallenges')
        .doc(challengeId)
        .collection('progress')
        .doc(currentUserId)
        .snapshots()
        .map((doc) => doc.exists ? ChallengeProgress.fromMap(doc.data()!) : null);
  }

  // ==================== HELPER METHODS ====================

  Future<void> _updateUserCircles(String userId, String circleId, {required bool isJoining}) async {
    final userDoc = _firestore.collection('users').doc(userId);

    if (isJoining) {
      await userDoc.update({
        'supporterCircles': FieldValue.arrayUnion([circleId]),
      });
    } else {
      await userDoc.update({
        'supporterCircles': FieldValue.arrayRemove([circleId]),
      });
    }
  }

  Future<void> _transferCircleOwnership(String circleId, String newCreatorId) async {
    final circleRef = _firestore.collection('supporterCircles').doc(circleId);
    final circleDoc = await circleRef.get();

    if (!circleDoc.exists) return;

    final circle = SupporterCircle.fromFirestore(circleDoc);
    final updatedMembers = circle.members.map((member) {
      if (member.userId == newCreatorId) {
        return CircleMember(
          userId: member.userId,
          displayName: member.displayName,
          photoURL: member.photoURL,
          role: CircleMemberRole.creator,
          joinedAt: member.joinedAt,
          lastActive: member.lastActive,
          stats: member.stats,
          achievements: member.achievements,
          isActive: member.isActive,
        );
      }
      return member;
    }).toList();

    await circleRef.update({
      'creatorId': newCreatorId,
      'members': updatedMembers.map((m) => m.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> _updateCircleStats(String circleId, Map<String, dynamic> updates) async {
    await _firestore.collection('supporterCircles').doc(circleId).update({
      'stats.lastUpdated': Timestamp.fromDate(DateTime.now()),
      ...updates.map((key, value) => MapEntry('stats.$key', value)),
    });
  }

  Future<void> _joinChallengeTeam(String challengeId, String teamId) async {
    // Implementation for joining challenge teams
    // This would involve updating the team's member list
  }

  Future<void> _updateChallengeAnalytics(String challengeId, Map<String, dynamic> updates) async {
    await _firestore.collection('enhancedChallenges').doc(challengeId).update({
      'analytics.lastUpdated': Timestamp.fromDate(DateTime.now()),
      ...updates.map((key, value) => MapEntry('analytics.$key', value)),
    });
  }

  Future<void> _checkMilestoneAchievements(
    String challengeId,
    EnhancedCommunityChallenge challenge,
    ChallengeProgress progress
  ) async {
    // Implementation for checking and awarding milestone achievements
    // This would involve checking if user has reached any milestones
    // and updating their achievements accordingly
  }
}