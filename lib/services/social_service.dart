import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/social_activity.dart';
import '../models/supporter.dart';
import '../models/support.dart';
import '../models/community_challenge.dart';
import '../models/privacy_settings.dart';
import 'firebase_push_notification_service.dart';

// Global callback to notify UI when supporter count changes
typedef SupporterCountChangeCallback = Future<void> Function();
SupporterCountChangeCallback? _globalSupporterCountCallback;

class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebasePushNotificationService _notificationService = FirebasePushNotificationService();

  String? get currentUserId => _auth.currentUser?.uid;

  // Static method to register UI refresh callback
  static void setSupporterCountChangeCallback(SupporterCountChangeCallback callback) {
    _globalSupporterCountCallback = callback;
  }

  // Method to trigger UI refresh when supporter count changes
  Future<void> _triggerSupporterCountRefresh() async {
    if (_globalSupporterCountCallback != null) {
      try {
        await _globalSupporterCountCallback!();
      } catch (e) {
        // Silent fail for UI refresh
      }
    }
  }

  // Activity Feed Methods
  Future<void> createActivity({
    required ActivityType type,
    required String title,
    required String description,
    PostVisibility? visibility,
    Map<String, dynamic>? metadata,
  }) async {
    if (currentUserId == null) {
      return;
    }

    final user = _auth.currentUser!;
    
    // Get user's default privacy setting if not specified
    final effectiveVisibility = visibility ?? await _getDefaultPostVisibility();
    
    final activity = SocialActivity(
      id: '',
      userId: currentUserId!,
      userName: user.displayName ?? 'Anonymous',
      userPhotoURL: user.photoURL,
      type: type,
      title: title,
      description: description,
      visibility: effectiveVisibility,
      metadata: metadata,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('activities').add(activity.toFirestore());
  }

  Stream<List<SocialActivity>> getSupportersActivityFeed({int limit = 10}) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // Simplified query to avoid complex index requirements
    return _firestore
        .collection('activities')
        .orderBy('createdAt', descending: true)
        .limit(limit * 2) // Get more to filter locally
        .snapshots()
        .asyncMap((snapshot) async {
          final activities = <SocialActivity>[];
          final supporterIds = await _getSupporterIds();
          
          for (final doc in snapshot.docs) {
            final activity = SocialActivity.fromFirestore(doc);
            
            // Filter based on visibility and supporterRequest
            if (_canViewActivity(activity, supporterIds)) {
              activities.add(activity);
            }
          }
          
          return activities;
        });
  }

  Stream<List<SocialActivity>> getCommunityFeed({int limit = 20}) {
    // Simplified query to avoid complex index requirements  
    return _firestore
        .collection('activities')
        .orderBy('createdAt', descending: true)
        .limit(limit * 2) // Get more to filter locally
        .snapshots()
        .map((snapshot) {
          final activities = snapshot.docs
              .map((doc) => SocialActivity.fromFirestore(doc))
              .where((activity) => 
                  activity.visibility == PostVisibility.community ||
                  activity.visibility == PostVisibility.public)
              .take(limit)
              .toList();
          return activities;
        });
  }

  Future<void> likeActivity(String activityId) async {
    if (currentUserId == null) {
      return;
    }

    final activityRef = _firestore.collection('activities').doc(activityId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(activityRef);
      if (!doc.exists) {
        return;
      }

      final likes = List<String>.from(doc.data()?['likes'] ?? []);
      
      if (likes.contains(currentUserId)) {
        likes.remove(currentUserId);
      } else {
        likes.add(currentUserId!);
      }

      transaction.update(activityRef, {'likes': likes});
    });
  }

  // Supporter Management Methods
  Future<void> sendSupporterRequest(String receiverId, {String? message}) async {
    if (currentUserId == null || currentUserId == receiverId) {
      return;
    }

    // Check if active supporterRequest already exists (supporterRequest + mutual supports)
    final hasActiveSupporter = await hasActiveSupporterRequest(receiverId);
    if (hasActiveSupporter) {
      throw Exception('Already supporters with this user');
    }
    
    // Check for pending supporter request
    final existingSupporterRequest = await _checkExistingSupporterRequest(receiverId);
    if (existingSupporterRequest?.status == SupporterRequestStatus.pending) {
      throw Exception('Supporter request already sent');
    }

    // Validate message length if provided
    if (message != null && message.length > 250) {
      throw Exception('Message cannot exceed 250 characters');
    }

    // Get user data for the supporterRequest
    final requesterDoc = await _firestore.collection('users').doc(currentUserId).get();
    final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
    
    if (!requesterDoc.exists || !receiverDoc.exists) {
      throw Exception('User not found');
    }
    
    final requesterData = requesterDoc.data()!;
    final receiverData = receiverDoc.data()!;

    final supporterRequest = {
      'requesterId': currentUserId!,
      'receiverId': receiverId,
      'status': SupporterRequestStatus.pending.index,
      'createdAt': Timestamp.now(),
      'requesterName': requesterData['displayName'] ?? '',
      'requesterUsername': requesterData['username'],
      'requesterPhotoURL': requesterData['photoURL'],
      'receiverName': receiverData['displayName'] ?? '',
      'receiverUsername': receiverData['username'],
      'receiverPhotoURL': receiverData['photoURL'],
      'message': message?.isNotEmpty == true ? message : null,
    };

    await _firestore.collection('supporterRequests').add(supporterRequest);
    
    // Send notification to receiver
    // Note: Notification will only be displayed if app is in background
    try {
      debugPrint('🤝 Sending support request notification to $receiverId');
      await _notificationService.sendSupportRequestNotification(
        receiverId: receiverId,
        requesterName: requesterData['displayName'] ?? 'Someone',
        message: message,
      );
      debugPrint('✅ Support request notification sent (will show only if app in background)');
    } catch (e) {
      debugPrint('❌ Support request notification failed: $e');
    }
  }

  Future<void> acceptSupporterRequest(String supporterRequestId) async {
    final supporterRequestDoc = await _firestore.collection('supporterRequests').doc(supporterRequestId).get();
    
    if (!supporterRequestDoc.exists) {
      throw Exception('Supporter request not found');
    }
    
    final supporterRequestData = supporterRequestDoc.data()!;
    final currentStatus = supporterRequestData['status'];
    final requesterId = supporterRequestData['requesterId'] as String;
    
    // Check if already accepted to prevent duplicates
    if (currentStatus == SupporterRequestStatus.accepted.index) {
      return; // Already accepted, do nothing
    }
    
    // Update the original supporterRequest request
    await _firestore.collection('supporterRequests').doc(supporterRequestId).update({
      'status': SupporterRequestStatus.accepted.index,
      'updatedAt': Timestamp.now(),
    });
    
    // Automatically create mutual support relationships between supporters
    try {
      // Create mutual support relationship (supportUser now handles both directions)
      final existingSupport = await _checkExistingSupport(requesterId);
      if (existingSupport == null) {
        await supportUser(requesterId); // This now creates BOTH relationships and updates BOTH counts
      }
      
      // Trigger UI refresh after supporter count changes
      await _triggerSupporterCountRefresh();
    } catch (e) {
      // If support creation fails, don't fail the entire supporter acceptance
    }
    
    // Send notification to requester
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _notificationService.sendSupportAcceptedNotification(
          requesterId: requesterId,
          acceptorName: currentUser.displayName ?? 'Someone',
        );
      }
    } catch (e) {
      // Continue even if notification fails
    }
  }

  Future<void> rejectSupporterRequest(String supporterRequestId) async {
    // Get requester info before deleting
    final supporterRequestDoc = await _firestore.collection('supporterRequests').doc(supporterRequestId).get();
    String? requesterId;
    
    if (supporterRequestDoc.exists) {
      final data = supporterRequestDoc.data()!;
      requesterId = data['requesterId'] as String?;
    }
    
    await _firestore.collection('supporterRequests').doc(supporterRequestId).delete();
    
    // Send notification to requester
    if (requesterId != null) {
      try {
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          await _notificationService.sendSupportRejectedNotification(
            requesterId: requesterId,
            rejectorName: currentUser.displayName ?? 'Someone',
          );
        }
      } catch (e) {
        // Continue even if notification fails
      }
    }
  }

  Stream<List<Supporter>> getSupporters() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // Show people who support me (like Instagram followers)
    return _firestore
        .collection('supporters')
        .where('supportedId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      final supporters = <Supporter>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final supporterId = data['supporterId'] as String;
          
          // Get supporter details from users collection
          final supporterDoc = await _firestore.collection('users').doc(supporterId).get();
          if (supporterDoc.exists) {
            final userData = supporterDoc.data() as Map<String, dynamic>;
            
            // Try to get displayName, fall back to email username, then username, then fallback
            String? displayNameNullable = userData['displayName'] as String?;
            String displayName;
            if (displayNameNullable == null || displayNameNullable.trim().isEmpty) {
              displayName = userData['email']?.toString().split('@').first ?? 
                           userData['username'] as String? ?? 
                           'User ${supporterId.substring(0, 8)}';
            } else {
              displayName = displayNameNullable;
            }
            
            final supporter = Supporter(
              userId: supporterId,
              displayName: displayName,
              username: userData['username'],
              photoURL: userData['photoURL'],
            );
            supporters.add(supporter);
          }
        } catch (e) {
          // Failed to fetch supporter data
        }
      }
      
      return supporters;
    });
  }

  Stream<List<Supporter>> getSupporting() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // Show people I support (like Instagram following)
    return _firestore
        .collection('supporters')
        .where('supporterId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      final supporting = <Supporter>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final supportedId = data['supportedId'] as String;
          
          // Get supported user details from users collection
          final supportedDoc = await _firestore.collection('users').doc(supportedId).get();
          if (supportedDoc.exists) {
            final userData = supportedDoc.data() as Map<String, dynamic>;
            final supported = Supporter(
              userId: supportedId,
              displayName: userData['displayName'] ?? 'Unknown User',
              username: userData['username'],
              photoURL: userData['photoURL'],
            );
            supporting.add(supported);
          }
        } catch (e) {
          // Failed to fetch supporting data
        }
      }
      
      return supporting;
    });
  }

  Stream<List<SupporterRequest>> getPendingSupporterRequests() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('supporterRequests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: SupporterRequestStatus.pending.index)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupporterRequest.fromFirestore(doc))
            .toList());
  }

  // Support Management Methods - Creates MUTUAL support relationship
  Future<void> supportUser(String userId) async {
    if (currentUserId == null || currentUserId == userId) {
      return;
    }

    try {
      // Check if already supporting
      final existingSupport = await _checkExistingSupport(userId);
      if (existingSupport != null) {
        throw Exception('Already supporting this user');
      }

      // Get user data for both users
      final supporterDoc = await _firestore.collection('users').doc(currentUserId).get();
      final supportingDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!supporterDoc.exists || !supportingDoc.exists) {
        throw Exception('User not found');
      }
      
      final supporterData = supporterDoc.data()!;
      final supportingData = supportingDoc.data()!;

      // Create support: current user → target user
      final support1 = {
        'supporterId': currentUserId!,
        'supportedId': userId,
        'createdAt': Timestamp.now(),
        'supporterName': supporterData['displayName'] ?? '',
        'supporterUsername': supporterData['username'],
        'supporterPhotoURL': supporterData['photoURL'],
        'supportedName': supportingData['displayName'] ?? '',
        'supportedUsername': supportingData['username'],
        'supportedPhotoURL': supportingData['photoURL'],
      };

      await _firestore.collection('supporters').add(support1);
      
      // Update supporter count for the user being supported
      await _incrementSupporterCount(userId);
      
      // Create MUTUAL support: target user → current user (if not exists)
      final reverseSupport = await _checkSupportFromUser(userId, currentUserId!);
      if (reverseSupport == null) {
        final support2 = {
          'supporterId': userId,
          'supportedId': currentUserId!,
          'createdAt': Timestamp.now(),
          'supporterName': supportingData['displayName'] ?? '',
          'supporterUsername': supportingData['username'],
          'supporterPhotoURL': supportingData['photoURL'],
          'supportedName': supporterData['displayName'] ?? '',
          'supportedUsername': supporterData['username'],
          'supportedPhotoURL': supporterData['photoURL'],
        };

        await _firestore.collection('supporters').add(support2);
        
        // Update supporter count for current user (they now have target user as supporter)
        await _incrementSupporterCount(currentUserId!);
      }
      
      // Notify UI to refresh (if available)
      _notifyUIRefresh();
      
      // Trigger UI refresh after supporter count changes
      await _triggerSupporterCountRefresh();
      
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unsupportUser(String userId) async {
    if (currentUserId == null) {
      return;
    }

    try {
      // MUTUAL DISCONNECTION: When one user removes support, both connections are broken
      // This ensures support relationships are always mutual and intentional
      
      // Remove current user's support of the target user
      final existingSupport = await _checkExistingSupport(userId);
      if (existingSupport != null) {
        await _firestore.collection('supporters').doc(existingSupport.id).delete();
        // Decrement the target user's supporter count (they lose current user as supporter)
        await _decrementSupporterCount(userId);
      }
      
      // Remove target user's support of the current user (mutual disconnection)
      final reverseSupport = await _checkSupportFromUser(userId, currentUserId!);
      if (reverseSupport != null) {
        await _firestore.collection('supporters').doc(reverseSupport.id).delete();
        // Decrement current user's supporter count (they lose target user as supporter)
        await _decrementSupporterCount(currentUserId!);
      }
      
      // Silent removal - no notification sent to the other user
      // This maintains privacy and avoids potential conflicts
      
      // Notify UI to refresh (if available)
      _notifyUIRefresh();
      
      // Trigger UI refresh after supporter count changes
      await _triggerSupporterCountRefresh();
      
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isSupporting(String userId) async {
    if (currentUserId == null || currentUserId == userId) {
      return false;
    }
    
    final existingSupport = await _checkExistingSupport(userId);
    return existingSupport != null;
  }

  Future<Support?> _checkExistingSupport(String supportedId) async {
    if (currentUserId == null) {
      return null;
    }
    
    try {
      final snapshot = await _firestore
          .collection('supporters')
          .where('supporterId', isEqualTo: currentUserId)
          .where('supportedId', isEqualTo: supportedId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return Support.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Helper method to check if a specific user supports another user
  Future<Support?> _checkSupportFromUser(String supporterId, String supportedId) async {
    try {
      final snapshot = await _firestore
          .collection('supporters')
          .where('supporterId', isEqualTo: supporterId)
          .where('supportedId', isEqualTo: supportedId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return Support.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Helper method to create a support relationship between any two users
  Future<void> _createSupportRelationship(String supporterId, String supportedId) async {
    try {
      // Get user data for both users
      final supporterDoc = await _firestore.collection('users').doc(supporterId).get();
      final supportingDoc = await _firestore.collection('users').doc(supportedId).get();
      
      if (!supporterDoc.exists || !supportingDoc.exists) {
        throw Exception('User not found');
      }
      
      final supporterData = supporterDoc.data()!;
      final supportingData = supportingDoc.data()!;

      final support = {
        'supporterId': supporterId,
        'supportedId': supportedId,
        'createdAt': Timestamp.now(),
        'supporterName': supporterData['displayName'] ?? '',
        'supporterUsername': supporterData['username'],
        'supporterPhotoURL': supporterData['photoURL'],
        'supportedName': supportingData['displayName'] ?? '',
        'supportedUsername': supportingData['username'],
        'supportedPhotoURL': supportingData['photoURL'],
      };

      await _firestore.collection('supporters').add(support);
      
      // Update supporter count for the user being supported
      await _incrementSupporterCount(supportedId);
      
      // Notify UI to refresh (if available)
      _notifyUIRefresh();
    } catch (e) {
      rethrow;
    }
  }


  Stream<List<Supporter>> getMySupporters() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('supporters')
        .where('supportedId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      final supporters = <Supporter>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final supporterId = data['supporterId'] as String;
        final supporterName = data['supporterName'] as String?;
        final supporterUsername = data['supporterUsername'] as String?;
        final supporterPhotoURL = data['supporterPhotoURL'] as String?;
        
        if (supporterName != null && supporterName.isNotEmpty) {
          supporters.add(Supporter(
            userId: supporterId,
            displayName: supporterName,
            username: supporterUsername,
            photoURL: supporterPhotoURL,
          ));
        } else {
          // Fallback: fetch from users collection
          try {
            final userDoc = await _firestore.collection('users').doc(supporterId).get();
            if (userDoc.exists) {
              supporters.add(Supporter.fromFirestore(userDoc));
            }
          } catch (e) {
            // Silently handle errors
          }
        }
      }
      
      return supporters;
    });
  }

  // Challenge Methods
  Stream<List<CommunityChallenge>> getActiveChallenges() {
    // Simplified query to avoid complex index requirements
    return _firestore
        .collection('challenges')
        .orderBy('startDate', descending: true)
        .limit(20) // Get more to filter locally
        .snapshots()
        .map((snapshot) {
          final challenges = snapshot.docs
              .map((doc) => CommunityChallenge.fromFirestore(doc))
              .where((challenge) => challenge.status == ChallengeStatus.active)
              .take(10)
              .toList();
          return challenges;
        });
  }

  Future<void> joinChallenge(String challengeId) async {
    if (currentUserId == null) {
      return;
    }

    final challengeRef = _firestore.collection('challenges').doc(challengeId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(challengeRef);
      if (!doc.exists) {
        return;
      }

      final participants = List<String>.from(doc.data()?['participants'] ?? []);
      
      if (!participants.contains(currentUserId)) {
        participants.add(currentUserId!);
        transaction.update(challengeRef, {'participants': participants});
      }
    });
  }

  Future<void> leaveChallenge(String challengeId) async {
    if (currentUserId == null) {
      return;
    }

    final challengeRef = _firestore.collection('challenges').doc(challengeId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(challengeRef);
      if (!doc.exists) {
        return;
      }

      final participants = List<String>.from(doc.data()?['participants'] ?? []);
      participants.remove(currentUserId);
      
      transaction.update(challengeRef, {'participants': participants});
    });
  }

  Future<void> updateChallengeProgress(String challengeId, int progress) async {
    if (currentUserId == null) {
      return;
    }

    final challengeRef = _firestore.collection('challenges').doc(challengeId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(challengeRef);
      if (!doc.exists) {
        return;
      }

      final leaderboard = Map<String, int>.from(doc.data()?['leaderboard'] ?? {});
      leaderboard[currentUserId!] = progress;
      
      transaction.update(challengeRef, {'leaderboard': leaderboard});
    });
  }

  // Search Users
  Future<List<Supporter>> searchUsers(String query) async {
    if (query.isEmpty) {
      return [];
    }

    final results = <Supporter>[];
    final addedUserIds = <String>{};
    final normalizedQuery = query.toLowerCase().trim();

    // Get all users and filter client-side for more reliable results
    // This is less efficient but more reliable for partial matching
    try {
      final snapshot = await _firestore
          .collection('users')
          .limit(100) // Reasonable limit for client-side filtering
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final username = (data['username'] as String?)?.toLowerCase() ?? '';
        final displayName = (data['displayName'] as String?)?.toLowerCase() ?? '';
        
        // Check if username or display name contains the query
        if ((username.contains(normalizedQuery) || displayName.contains(normalizedQuery)) && 
            doc.id != currentUserId && 
            !addedUserIds.contains(doc.id)) {
          
          final supporter = Supporter.fromFirestore(doc);
          results.add(supporter);
          addedUserIds.add(doc.id);
        }
      }
    } catch (e) {
      // Handle search errors silently
    }

    // Sort results by relevance (exact matches first, then starts with, then contains)
    results.sort((a, b) {
      final aUsername = a.username?.toLowerCase() ?? '';
      final aDisplayName = a.displayName.toLowerCase();
      final bUsername = b.username?.toLowerCase() ?? '';
      final bDisplayName = b.displayName.toLowerCase();
      
      // Exact matches first
      if (aUsername == normalizedQuery || aDisplayName == normalizedQuery) return -1;
      if (bUsername == normalizedQuery || bDisplayName == normalizedQuery) return 1;
      
      // Starts with query
      if (aUsername.startsWith(normalizedQuery) || aDisplayName.startsWith(normalizedQuery)) return -1;
      if (bUsername.startsWith(normalizedQuery) || bDisplayName.startsWith(normalizedQuery)) return 1;
      
      return 0;
    });

    return results.take(20).toList(); // Limit final results
  }

  Future<Supporter?> findUserByUsername(String username) async {
    if (username.isEmpty) {
      return null;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final supporter = Supporter.fromFirestore(snapshot.docs.first);
      return supporter.userId != currentUserId ? supporter : null;
    } catch (e) {
      return null;
    }
  }

  // Utility Methods
  Future<void> logWorkoutActivity({
    required String workoutName,
    required int duration,
    required int calories,
  }) async {
    await createActivity(
      type: ActivityType.workout,
      title: 'Completed $workoutName',
      description: '${duration}min workout • $calories calories burned',
      metadata: {
        'workoutName': workoutName,
        'duration': duration,
        'calories': calories,
      },
    );
  }

  Future<void> logMealActivity({
    required String mealName,
    required String mealType,
    required int calories,
  }) async {
    await createActivity(
      type: ActivityType.meal,
      title: 'Shared $mealType',
      description: '$mealName • $calories calories',
      metadata: {
        'mealName': mealName,
        'mealType': mealType,
        'calories': calories,
      },
    );
  }

  Future<void> logEcoActivity({
    required String action,
    required String impact,
  }) async {
    await createActivity(
      type: ActivityType.ecoAction,
      title: action,
      description: impact,
      metadata: {
        'action': action,
        'impact': impact,
      },
    );
  }

  // Helper method to check existing supporterRequest
  Future<SupporterRequest?> _checkExistingSupporterRequest(String otherUserId) async {
    if (currentUserId == null) {
      return null;
    }
    
    // Check for supporterRequest where current user is requester
    final snapshot1 = await _firestore
        .collection('supporterRequests')
        .where('requesterId', isEqualTo: currentUserId)
        .where('receiverId', isEqualTo: otherUserId)
        .limit(1)
        .get();
    
    if (snapshot1.docs.isNotEmpty) {
      final supporterRequest = SupporterRequest.fromFirestore(snapshot1.docs.first);
      return supporterRequest;
    }
    
    // Check for supporterRequest where current user is receiver
    final snapshot2 = await _firestore
        .collection('supporterRequests')
        .where('requesterId', isEqualTo: otherUserId)
        .where('receiverId', isEqualTo: currentUserId)
        .limit(1)
        .get();
    
    if (snapshot2.docs.isNotEmpty) {
      final supporterRequest = SupporterRequest.fromFirestore(snapshot2.docs.first);
      return supporterRequest;
    }
    
    return null;
  }

  // Helper method to get supporterRequest status
  Future<SupporterRequestStatus?> getSupporterRequestStatus(String otherUserId) async {
    final supporterRequest = await _checkExistingSupporterRequest(otherUserId);
    return supporterRequest?.status;
  }

  // Check if users have an active supporterRequest (accepted supporterRequest + mutual supports)
  Future<bool> hasActiveSupporterRequest(String otherUserId) async {
    final supporterRequest = await _checkExistingSupporterRequest(otherUserId);
    
    if (supporterRequest?.status != SupporterRequestStatus.accepted) {
      return false;
    }
    
    // Check if mutual supports still exist
    final iSupportThem = await isSupporting(otherUserId);
    final theySupportMe = await _checkSupportFromUser(otherUserId, currentUserId!);
    
    return iSupportThem && theySupportMe != null;
  }

  // Privacy Management Methods
  Future<PrivacySettings> getPrivacySettings() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final doc = await _firestore
        .collection('privacy_settings')
        .doc(currentUserId)
        .get();

    if (doc.exists) {
      return PrivacySettings.fromFirestore(doc);
    } else {
      // Create default privacy settings
      final defaultSettings = PrivacySettings(
        userId: currentUserId!,
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection('privacy_settings')
          .doc(currentUserId)
          .set(defaultSettings.toFirestore());
      return defaultSettings;
    }
  }

  Future<void> updatePrivacySettings(PrivacySettings settings) async {
    if (currentUserId == null) {
      return;
    }

    await _firestore
        .collection('privacy_settings')
        .doc(currentUserId)
        .set(settings.toFirestore());
  }

  Future<List<PublicProfile>> searchPublicProfiles(String query) async {
    if (query.isEmpty) {
      return [];
    }

    final snapshot = await _firestore
        .collection('public_profiles')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThan: '${query}z')
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => PublicProfile.fromFirestore(doc))
        .where((profile) => profile.userId != currentUserId)
        .toList();
  }

  Future<PublicProfile?> getPublicProfile(String userId) async {
    final doc = await _firestore
        .collection('public_profiles')
        .doc(userId)
        .get();

    if (doc.exists) {
      return PublicProfile.fromFirestore(doc);
    }
    return null;
  }

  // Private Helper Methods
  Future<PostVisibility> _getDefaultPostVisibility() async {
    try {
      final settings = await getPrivacySettings();
      return settings.defaultPostVisibility;
    } catch (e) {
      return PostVisibility.supportersOnly; // Safe default
    }
  }

  Future<List<String>> _getSupporterIds() async {
    if (currentUserId == null) {
      return [];
    }

    final snapshot = await _firestore
        .collection('supporterRequests')
        .where('status', isEqualTo: SupporterRequestStatus.accepted.index)
        .get();

    final supporterIds = <String>[];
    for (final doc in snapshot.docs) {
      final supporterRequest = SupporterRequest.fromFirestore(doc);
      if (supporterRequest.requesterId == currentUserId) {
        supporterIds.add(supporterRequest.receiverId);
      } else if (supporterRequest.receiverId == currentUserId) {
        supporterIds.add(supporterRequest.requesterId);
      }
    }

    return supporterIds;
  }

  bool _canViewActivity(SocialActivity activity, List<String> supporterIds) {
    // User can always see their own posts
    if (activity.userId == currentUserId) {
      return true;
    }

    switch (activity.visibility) {
      case PostVisibility.public:
        return true;
      case PostVisibility.community:
        return true; // All app users can see community posts
      case PostVisibility.supportersOnly:
        return supporterIds.contains(activity.userId);
    }
  }

  // Migration method to fix existing supporterRequests to have bidirectional supporting
  Future<void> migrateSupporterRequestsToMutualSupporting() async {
    if (currentUserId == null) {
      return;
    }

    try {
      // Get all accepted supporterRequests where current user is involved
      final supporterRequestsAsRequester = await _firestore
          .collection('supporterRequests')
          .where('requesterId', isEqualTo: currentUserId)
          .where('status', isEqualTo: SupporterRequestStatus.accepted.index)
          .get();

      final supporterRequestsAsReceiver = await _firestore
          .collection('supporterRequests')
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: SupporterRequestStatus.accepted.index)
          .get();

      final allSupporterRequests = [...supporterRequestsAsRequester.docs, ...supporterRequestsAsReceiver.docs];

      for (final supporterRequestDoc in allSupporterRequests) {
        final data = supporterRequestDoc.data();
        final requesterId = data['requesterId'] as String;
        final receiverId = data['receiverId'] as String;

        // Ensure requester supports receiver
        final requesterSupportsReceiver = await _checkSupportFromUser(requesterId, receiverId);
        if (requesterSupportsReceiver == null) {
          await _createSupportRelationship(requesterId, receiverId);
        }

        // Ensure receiver supports requester
        final receiverSupportsRequester = await _checkSupportFromUser(receiverId, requesterId);
        if (receiverSupportsRequester == null) {
          await _createSupportRelationship(receiverId, requesterId);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Debug method to check the current state of supporterRequests and supports
  Future<Map<String, dynamic>> debugRelationshipState() async {
    if (currentUserId == null) {
      return {'error': 'Not authenticated'};
    }

    try {
      // Get supporterRequests
      final supporterRequestsAsRequester = await _firestore
          .collection('supporterRequests')
          .where('requesterId', isEqualTo: currentUserId)
          .where('status', isEqualTo: SupporterRequestStatus.accepted.index)
          .get();

      final supporterRequestsAsReceiver = await _firestore
          .collection('supporterRequests')
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: SupporterRequestStatus.accepted.index)
          .get();

      // Get supports (current user supporting others)
      final supporting = await _firestore
          .collection('supporters')
          .where('supporterId', isEqualTo: currentUserId)
          .get();

      // Get supporters (others supporting current user)
      final supporters = await _firestore
          .collection('supporters')
          .where('supportedId', isEqualTo: currentUserId)
          .get();

      final result = {
        'currentUserId': currentUserId,
        'supporterRequests': {
          'asRequester': supporterRequestsAsRequester.docs.length,
          'asReceiver': supporterRequestsAsReceiver.docs.length,
          'total': supporterRequestsAsRequester.docs.length + supporterRequestsAsReceiver.docs.length,
        },
        'supports': {
          'supporting': supporting.docs.length,
          'supporters': supporters.docs.length,
        },
        'details': {
          'supporterRequests': [
            ...supporterRequestsAsRequester.docs.map((doc) => {
              'id': doc.id,
              'type': 'asRequester',
              'data': doc.data(),
            }),
            ...supporterRequestsAsReceiver.docs.map((doc) => {
              'id': doc.id,
              'type': 'asReceiver', 
              'data': doc.data(),
            }),
          ],
          'supporting': supporting.docs.map((doc) => {
            'id': doc.id,
            'data': doc.data(),
          }).toList(),
          'supporters': supporters.docs.map((doc) => {
            'id': doc.id,
            'data': doc.data(),
          }).toList(),
        }
      };

      return result;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Supporter Count Management Methods
  Future<void> _incrementSupporterCount(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(userRef);
        if (doc.exists) {
          final currentCount = doc.data()?['supportersCount'] ?? 0;
          transaction.update(userRef, {'supportersCount': currentCount + 1});
        }
      });
    } catch (e) {
      // Error incrementing supporter count
    }
  }

  Future<void> _decrementSupporterCount(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(userRef);
        if (doc.exists) {
          final currentCount = doc.data()?['supportersCount'] ?? 0;
          final newCount = (currentCount - 1).clamp(0, double.infinity).toInt();
          transaction.update(userRef, {'supportersCount': newCount});
        }
      });
    } catch (e) {
      // Error decrementing supporter count
    }
  }

  Future<int> getSupporterCount(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        
        // If supportersCount field doesn't exist, initialize it
        if (!data!.containsKey('supportersCount')) {
          // Count actual supporters
          final supportersSnapshot = await _firestore
              .collection('supporters')
              .where('supportedId', isEqualTo: userId)
              .get();
          
          final actualCount = supportersSnapshot.docs.length;
          
          // Update user document with correct count
          await _firestore.collection('users').doc(userId).update({
            'supportersCount': actualCount,
          });
          
          return actualCount;
        }
        
        return data['supportersCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getSupportingCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('supporters')
          .where('supporterId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // UI Refresh Notification - can be implemented by UI layer
  void _notifyUIRefresh() {
    // This can be connected to a global event bus or provider refresh
  }
  
  // Method to refresh supporter count for current user
  Future<void> refreshCurrentUserSupporterCount() async {
    if (currentUserId == null) {
      return;
    }
    
    try {
      // Get actual supporter count (people supporting current user)
      final supportersSnapshot = await _firestore
          .collection('supporters')
          .where('supportedId', isEqualTo: currentUserId)
          .get();
      
      final actualCount = supportersSnapshot.docs.length;
      
      // Update the user's document
      await _firestore.collection('users').doc(currentUserId).update({
        'supportersCount': actualCount,
      });
    } catch (e) {
      // Error refreshing current user supporter count
    }
  }

  // Migration method to initialize supportersCount for current user only
  Future<void> initializeSupportersCount() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      // Get current user document
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      
      if (!userDoc.exists) {
        throw Exception('Current user document not found');
      }
      
      final userData = userDoc.data()!;
      
      // Check if supportersCount field exists
      if (!userData.containsKey('supportersCount')) {
        // Count actual supporters for current user
        final supportersSnapshot = await _firestore
            .collection('supporters')
            .where('supportedId', isEqualTo: currentUserId)
            .get();
        
        final actualCount = supportersSnapshot.docs.length;
        
        // Update current user document with correct count
        await _firestore.collection('users').doc(currentUserId).update({
          'supportersCount': actualCount,
        });
      } else {
        // Force refresh the count even if field exists
        final supportersSnapshot = await _firestore
            .collection('supporters')
            .where('supportedId', isEqualTo: currentUserId)
            .get();
        
        final actualCount = supportersSnapshot.docs.length;
        
        await _firestore.collection('users').doc(currentUserId).update({
          'supportersCount': actualCount,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Method to clean up broken supporterRequests (optional - can be called periodically)
  Future<void> cleanupBrokenSupporterRequests() async {
    if (currentUserId == null) {
      return;
    }
    
    try {
      // Get all accepted supporterRequests for current user
      final supporterRequests = await _firestore
          .collection('supporterRequests')
          .where('status', isEqualTo: SupporterRequestStatus.accepted.index)
          .get();
      
      for (final doc in supporterRequests.docs) {
        final supporterRequest = SupporterRequest.fromFirestore(doc);
        final otherUserId = supporterRequest.requesterId == currentUserId 
            ? supporterRequest.receiverId 
            : supporterRequest.requesterId;
        
        // Check if mutual supports still exist
        final iSupportThem = await isSupporting(otherUserId);
        final theySupportMe = await _checkSupportFromUser(otherUserId, currentUserId!);
        
        // If mutual supports are broken, delete the supporterRequest record
        if (!iSupportThem || theySupportMe == null) {
          await _firestore.collection('supporterRequests').doc(doc.id).delete();
        }
      }
    } catch (e) {
      // Error cleaning up broken supporterRequests
    }
  }

  // Method to fix supporter count for any specific user (admin/debug use)
  Future<void> fixSupporterCountForUser(String userId) async {
    try {
      // Count actual supporters for the specified user
      final supportersSnapshot = await _firestore
          .collection('supporters')
          .where('supportedId', isEqualTo: userId)
          .get();
      
      final actualCount = supportersSnapshot.docs.length;
      
      // Update the user document with correct count
      await _firestore.collection('users').doc(userId).update({
        'supportersCount': actualCount,
      });
      
      debugPrint('✅ Fixed supporter count for user $userId: $actualCount');
    } catch (e) {
      debugPrint('❌ Error fixing supporter count for user $userId: $e');
      rethrow;
    }
  }

  // Method to check and fix supporter count for current user (safe to call anytime)
  Future<Map<String, dynamic>> checkAndFixMySuppoterCount() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      // Get current stored count
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final userData = userDoc.data();
      final storedCount = userData?['supportersCount'] ?? 0;
      
      // Get actual count
      final supportersSnapshot = await _firestore
          .collection('supporters')
          .where('supportedId', isEqualTo: currentUserId)
          .get();
      
      final actualCount = supportersSnapshot.docs.length;
      
      final result = {
        'userId': currentUserId,
        'storedCount': storedCount,
        'actualCount': actualCount,
        'wasFixed': false,
      };
      
      // Fix if mismatch
      if (storedCount != actualCount) {
        await _firestore.collection('users').doc(currentUserId).update({
          'supportersCount': actualCount,
        });
        result['wasFixed'] = true;
        
        // Notify UI to refresh (trigger any listeners)
        _notifyUIRefresh();
      }
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Auto-sync method that can be called periodically
  Future<bool> autoSyncSupporterCount() async {
    if (currentUserId == null) {
      return false;
    }
    
    try {
      final result = await checkAndFixMySuppoterCount();
      return result['wasFixed'] == true;
    } catch (e) {
      // Silent fail for auto-sync
      return false;
    }
  }
}