import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/community/community_challenge.dart';
import '../../services/database/firebase_push_notification_service.dart';
import '../../utils/logger.dart';

class CommunityChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebasePushNotificationService _notificationService = FirebasePushNotificationService();

  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== CHALLENGE MANAGEMENT ====================

  /// Get all active challenges
  Stream<List<CommunityChallenge>> getActiveChallenges() {
    return _firestore
        .collection('community_challenges')
        .where('status', isEqualTo: ChallengeStatus.active.index)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityChallenge.fromFirestore(doc))
            .toList());
  }

  /// Get challenges by type
  Stream<List<CommunityChallenge>> getChallengesByType(ChallengeType type) {
    return _firestore
        .collection('community_challenges')
        .where('type', isEqualTo: type.index)
        .where('status', isEqualTo: ChallengeStatus.active.index)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityChallenge.fromFirestore(doc))
            .toList());
  }

  /// Get user's participated challenges
  Stream<List<CommunityChallenge>> getUserChallenges(String userId) {
    return _firestore
        .collection('community_challenges')
        .where('participants', arrayContains: userId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityChallenge.fromFirestore(doc))
            .toList());
  }

  /// Create a new challenge
  Future<String> createChallenge(CommunityChallenge challenge) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final docRef = await _firestore
          .collection('community_challenges')
          .add(challenge.toFirestore());

      Logger.info('Created challenge: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      Logger.error('Error creating challenge: $e');
      rethrow;
    }
  }

  /// Join a challenge as individual
  Future<bool> joinChallengeAsIndividual(String challengeId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final challengeRef = _firestore.collection('community_challenges').doc(challengeId);

      await _firestore.runTransaction((transaction) async {
        final challengeDoc = await transaction.get(challengeRef);
        if (!challengeDoc.exists) throw Exception('Challenge not found');

        final challenge = CommunityChallenge.fromFirestore(challengeDoc);

        if (!challenge.acceptsIndividuals) {
          throw Exception('This challenge only accepts teams');
        }

        if (challenge.participants.contains(currentUserId!)) {
          throw Exception('Already participating in this challenge');
        }

        transaction.update(challengeRef, {
          'participants': FieldValue.arrayUnion([currentUserId!])
        });
      });

      // Send notification to other participants
      await _notifyParticipants(challengeId, 'New member joined the challenge!');

      Logger.info('User $currentUserId joined challenge $challengeId');
      return true;
    } catch (e) {
      Logger.error('Error joining challenge: $e');
      return false;
    }
  }

  // ==================== TEAM MANAGEMENT ====================

  /// Create a new team for a challenge
  Future<String> createTeam({
    required String challengeId,
    required String teamName,
    String? description,
    String? avatarUrl,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final challengeRef = _firestore.collection('community_challenges').doc(challengeId);

      return await _firestore.runTransaction((transaction) async {
        final challengeDoc = await transaction.get(challengeRef);
        if (!challengeDoc.exists) throw Exception('Challenge not found');

        final challenge = CommunityChallenge.fromFirestore(challengeDoc);

        if (!challenge.acceptsTeams) {
          throw Exception('This challenge does not accept teams');
        }

        if (!challenge.canCreateMoreTeams) {
          throw Exception('Maximum number of teams reached');
        }

        if (challenge.isUserInTeam(currentUserId!)) {
          throw Exception('User is already in a team for this challenge');
        }

        final teamId = _firestore.collection('temp').doc().id;
        final newTeam = ChallengeTeam(
          id: teamId,
          name: teamName,
          description: description,
          memberIds: [currentUserId!],
          captainId: currentUserId!,
          totalScore: 0,
          createdAt: DateTime.now(),
          avatarUrl: avatarUrl,
        );

        final updatedTeams = List<ChallengeTeam>.from(challenge.teams)..add(newTeam);

        transaction.update(challengeRef, {
          'teams': updatedTeams.map((team) => team.toFirestore()).toList(),
        });

        Logger.info('Created team $teamId for challenge $challengeId');
        return teamId;
      });
    } catch (e) {
      Logger.error('Error creating team: $e');
      rethrow;
    }
  }

  /// Join an existing team
  Future<bool> joinTeam(String challengeId, String teamId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final challengeRef = _firestore.collection('community_challenges').doc(challengeId);

      await _firestore.runTransaction((transaction) async {
        final challengeDoc = await transaction.get(challengeRef);
        if (!challengeDoc.exists) throw Exception('Challenge not found');

        final challenge = CommunityChallenge.fromFirestore(challengeDoc);

        if (challenge.isUserInTeam(currentUserId!)) {
          throw Exception('User is already in a team for this challenge');
        }

        final team = challenge.getTeamById(teamId);
        if (team == null) throw Exception('Team not found');

        if (team.isFullForChallenge(challenge.maxTeamSize)) {
          throw Exception('Team is full');
        }

        final updatedTeams = challenge.teams.map((t) {
          if (t.id == teamId) {
            return t.copyWith(
              memberIds: [...t.memberIds, currentUserId!],
            );
          }
          return t;
        }).toList();

        transaction.update(challengeRef, {
          'teams': updatedTeams.map((team) => team.toFirestore()).toList(),
        });

        // Notify team members
        await _notifyTeamMembers(teamId, challenge.title, 'New member joined your team!');
      });

      Logger.info('User $currentUserId joined team $teamId');
      return true;
    } catch (e) {
      Logger.error('Error joining team: $e');
      return false;
    }
  }

  /// Leave a team
  Future<bool> leaveTeam(String challengeId, String teamId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final challengeRef = _firestore.collection('community_challenges').doc(challengeId);

      await _firestore.runTransaction((transaction) async {
        final challengeDoc = await transaction.get(challengeRef);
        if (!challengeDoc.exists) throw Exception('Challenge not found');

        final challenge = CommunityChallenge.fromFirestore(challengeDoc);
        final team = challenge.getTeamById(teamId);

        if (team == null || !team.isMember(currentUserId!)) {
          throw Exception('User is not in this team');
        }

        List<ChallengeTeam> updatedTeams;

        if (team.memberCount == 1) {
          // Remove team if it's the last member
          updatedTeams = challenge.teams.where((t) => t.id != teamId).toList();
        } else {
          // Remove user from team
          final newMemberIds = team.memberIds.where((id) => id != currentUserId!).toList();
          String newCaptainId = team.captainId;

          // If the captain is leaving, assign a new captain
          if (team.isCaptain(currentUserId!)) {
            newCaptainId = newMemberIds.first;
          }

          updatedTeams = challenge.teams.map((t) {
            if (t.id == teamId) {
              return t.copyWith(
                memberIds: newMemberIds,
                captainId: newCaptainId,
              );
            }
            return t;
          }).toList();
        }

        transaction.update(challengeRef, {
          'teams': updatedTeams.map((team) => team.toFirestore()).toList(),
        });
      });

      Logger.info('User $currentUserId left team $teamId');
      return true;
    } catch (e) {
      Logger.error('Error leaving team: $e');
      return false;
    }
  }

  /// Update team progress
  Future<bool> updateTeamProgress(String challengeId, String teamId, String userId, int points) async {
    try {
      final challengeRef = _firestore.collection('community_challenges').doc(challengeId);

      await _firestore.runTransaction((transaction) async {
        final challengeDoc = await transaction.get(challengeRef);
        if (!challengeDoc.exists) throw Exception('Challenge not found');

        final challenge = CommunityChallenge.fromFirestore(challengeDoc);
        final team = challenge.getTeamById(teamId);

        if (team == null || !team.isMember(userId)) {
          throw Exception('User is not in this team');
        }

        final updatedTeams = challenge.teams.map((t) {
          if (t.id == teamId) {
            final newContributions = Map<String, int>.from(t.memberContributions);
            newContributions[userId] = (newContributions[userId] ?? 0) + points;

            return t.copyWith(
              totalScore: t.totalScore + points,
              memberContributions: newContributions,
            );
          }
          return t;
        }).toList();

        // Update team leaderboard
        final newTeamLeaderboard = Map<String, int>.from(challenge.teamLeaderboard);
        newTeamLeaderboard[teamId] = (newTeamLeaderboard[teamId] ?? 0) + points;

        transaction.update(challengeRef, {
          'teams': updatedTeams.map((team) => team.toFirestore()).toList(),
          'teamLeaderboard': newTeamLeaderboard,
        });
      });

      Logger.info('Updated team $teamId progress: +$points points');
      return true;
    } catch (e) {
      Logger.error('Error updating team progress: $e');
      return false;
    }
  }

  /// Get team leaderboard for a challenge
  Future<List<ChallengeTeam>> getTeamLeaderboard(String challengeId) async {
    try {
      final challengeDoc = await _firestore
          .collection('community_challenges')
          .doc(challengeId)
          .get();

      if (!challengeDoc.exists) return [];

      final challenge = CommunityChallenge.fromFirestore(challengeDoc);
      final teams = List<ChallengeTeam>.from(challenge.teams);

      // Sort by total score descending
      teams.sort((a, b) => b.totalScore.compareTo(a.totalScore));

      return teams;
    } catch (e) {
      Logger.error('Error getting team leaderboard: $e');
      return [];
    }
  }

  /// Get individual leaderboard for a challenge (solo + team members competing individually)
  Future<List<IndividualParticipant>> getIndividualLeaderboard(String challengeId) async {
    try {
      final challengeDoc = await _firestore
          .collection('community_challenges')
          .doc(challengeId)
          .get();

      if (!challengeDoc.exists) return [];

      final challenge = CommunityChallenge.fromFirestore(challengeDoc);
      final participants = <IndividualParticipant>[];

      // Get user profiles for display names and avatars
      final userProfiles = await _getUserProfiles(challenge.participants);

      // Add solo participants
      for (final userId in challenge.participants) {
        if (!challenge.isUserInTeam(userId)) {
          final userProfile = userProfiles[userId];
          final score = challenge.individualScores[userId] ?? 0;
          final isEligible = challenge.participantEligibility[userId] ?? false;
          final meetMinimumRequirement = score >= challenge.prizeConfiguration.minimumIndividualRequirement;

          participants.add(IndividualParticipant(
            userId: userId,
            displayName: userProfile?['displayName'] ?? 'Unknown User',
            avatarUrl: userProfile?['avatarUrl'],
            score: score,
            isEligible: isEligible,
            teamName: null,
            meetMinimumRequirement: meetMinimumRequirement,
            lastActivity: DateTime.now(), // TODO: Get from verification data
          ));
        }
      }

      // Add team members competing individually
      for (final team in challenge.teams) {
        for (final memberId in team.memberIds) {
          final userProfile = userProfiles[memberId];
          final score = challenge.individualScores[memberId] ?? 0;
          final isEligible = challenge.participantEligibility[memberId] ?? false;
          final meetMinimumRequirement = score >= challenge.prizeConfiguration.minimumIndividualRequirement;

          participants.add(IndividualParticipant(
            userId: memberId,
            displayName: userProfile?['displayName'] ?? 'Unknown User',
            avatarUrl: userProfile?['avatarUrl'],
            score: score,
            isEligible: isEligible,
            teamName: team.name,
            meetMinimumRequirement: meetMinimumRequirement,
            lastActivity: DateTime.now(), // TODO: Get from verification data
          ));
        }
      }

      // Sort by score descending
      participants.sort((a, b) => b.score.compareTo(a.score));

      return participants;
    } catch (e) {
      Logger.error('Error getting individual leaderboard: $e');
      return [];
    }
  }

  /// Helper method to get user profiles
  Future<Map<String, Map<String, dynamic>>> _getUserProfiles(List<String> userIds) async {
    final profiles = <String, Map<String, dynamic>>{};

    try {
      for (final userId in userIds) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          profiles[userId] = userDoc.data() ?? {};
        }
      }
    } catch (e) {
      Logger.error('Error getting user profiles: $e');
    }

    return profiles;
  }

  // ==================== NOTIFICATION HELPERS ====================

  Future<void> _notifyParticipants(String challengeId, String message) async {
    try {
      final challengeDoc = await _firestore
          .collection('community_challenges')
          .doc(challengeId)
          .get();

      if (challengeDoc.exists) {
        final challenge = CommunityChallenge.fromFirestore(challengeDoc);
        for (final participantId in challenge.participants) {
          if (participantId != currentUserId) {
            await _notificationService.sendNotificationToUser(
              userId: participantId,
              title: 'Challenge Update',
              body: message,
              type: NotificationType.challengeUpdate,
              data: {'challengeId': challengeId},
            );
          }
        }
      }
    } catch (e) {
      Logger.error('Error notifying participants: $e');
    }
  }

  Future<void> _notifyTeamMembers(String teamId, String challengeTitle, String message) async {
    // Implementation depends on how you want to handle team member notifications
    // For now, we'll skip the implementation as it requires additional setup
    Logger.info('Team notification: $message for team $teamId in challenge $challengeTitle');
  }

  // ==================== TEAM FORMATION METHODS ====================

  /// Get available teams for a challenge that accept new members
  Future<List<ChallengeTeam>> getAvailableTeamsForChallenge(String challengeId) async {
    try {
      final challengeDoc = await _firestore
          .collection('community_challenges')
          .doc(challengeId)
          .get();

      if (!challengeDoc.exists) return [];

      final challenge = CommunityChallenge.fromFirestore(challengeDoc);

      // Filter teams that are not full (assuming max 8 members per team)
      final availableTeams = challenge.teams
          .where((team) => team.memberIds.length < 8)
          .toList();

      return availableTeams;
    } catch (e) {
      Logger.error('Error getting available teams: $e');
      return [];
    }
  }

  /// Create team and join it
  Future<bool> createTeamAndJoin(ChallengeTeam team, String challengeId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final challengeRef = _firestore.collection('community_challenges').doc(challengeId);

      await _firestore.runTransaction((transaction) async {
        final challengeDoc = await transaction.get(challengeRef);
        if (!challengeDoc.exists) throw Exception('Challenge not found');

        final challenge = CommunityChallenge.fromFirestore(challengeDoc);

        if (!challenge.acceptsTeams) {
          throw Exception('This challenge does not accept teams');
        }

        if (!challenge.canCreateMoreTeams) {
          throw Exception('Maximum number of teams reached');
        }

        if (challenge.isUserInTeam(currentUserId!)) {
          throw Exception('User is already in a team for this challenge');
        }

        // Create new team with generated ID
        final teamId = _firestore.collection('temp').doc().id;
        final newTeam = ChallengeTeam(
          id: teamId,
          name: team.name,
          description: team.description,
          captainId: currentUserId!,
          memberIds: [currentUserId!, ...team.memberIds.where((id) => id != currentUserId!)],
          totalScore: team.totalScore,
          createdAt: DateTime.now(),
        );

        final updatedTeams = List<ChallengeTeam>.from(challenge.teams)..add(newTeam);

        transaction.update(challengeRef, {
          'teams': updatedTeams.map((t) => t.toFirestore()).toList(),
        });

        // If team has invited members, send notifications
        if (team.memberIds.length > 1) {
          for (final memberId in team.memberIds) {
            if (memberId != currentUserId!) {
              await _notificationService.sendNotificationToUser(
                userId: memberId,
                title: 'Team Invitation',
                body: 'You\'ve been invited to join team "${team.name}" for challenge "${challenge.title}"',
                type: NotificationType.challengeInvite,
                data: {'challengeId': challenge.id, 'teamId': teamId},
              );
            }
          }
        }
      });

      Logger.info('Created and joined team for challenge $challengeId');
      return true;
    } catch (e) {
      Logger.error('Error creating team and joining: $e');
      return false;
    }
  }

  /// Join an existing team
  Future<bool> joinExistingTeam(String challengeId, String teamId) async {
    return await joinTeam(challengeId, teamId);
  }

  /// Get user's participating challenges
  Stream<List<CommunityChallenge>> getUserParticipatingChallenges() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('community_challenges')
        .where('status', isEqualTo: ChallengeStatus.active.index)
        .snapshots()
        .map((snapshot) {
      final challenges = snapshot.docs
          .map((doc) => CommunityChallenge.fromFirestore(doc))
          .where((challenge) {
        // Check if user is in individual participants
        if (challenge.participants.contains(currentUserId!)) {
          return true;
        }

        // Check if user is in any team
        for (final team in challenge.teams) {
          if (team.memberIds.contains(currentUserId!)) {
            return true;
          }
        }

        return false;
      }).toList();

      return challenges;
    });
  }

  /// Get user's team for a specific challenge
  ChallengeTeam? getUserTeamForChallenge(CommunityChallenge challenge) {
    if (currentUserId == null) return null;

    for (final team in challenge.teams) {
      if (team.memberIds.contains(currentUserId!)) {
        return team;
      }
    }
    return null;
  }

  /// Check if user is participating in challenge (individual or team)
  bool isUserParticipating(CommunityChallenge challenge) {
    if (currentUserId == null) return false;

    // Check individual participation
    if (challenge.participants.contains(currentUserId!)) {
      return true;
    }

    // Check team participation
    for (final team in challenge.teams) {
      if (team.memberIds.contains(currentUserId!)) {
        return true;
      }
    }

    return false;
  }

  /// Update an existing challenge
  Future<void> updateChallenge(String challengeId, CommunityChallenge challenge) async {
    try {
      await _firestore
          .collection('community_challenges')
          .doc(challengeId)
          .update(challenge.toFirestore());

      Logger.info('Updated challenge: $challengeId');
    } catch (e) {
      Logger.error('Error updating challenge: $e');
      rethrow;
    }
  }

  /// Delete a challenge
  Future<void> deleteChallenge(String challengeId) async {
    try {
      await _firestore
          .collection('community_challenges')
          .doc(challengeId)
          .delete();

      Logger.info('Deleted challenge: $challengeId');
    } catch (e) {
      Logger.error('Error deleting challenge: $e');
      rethrow;
    }
  }
}