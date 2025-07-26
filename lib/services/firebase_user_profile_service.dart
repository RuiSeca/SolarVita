// lib/services/firebase_user_profile_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logging/logging.dart';
import '../models/user_profile.dart';
import '../models/social_post.dart';

class FirebaseUserProfileService {
  static final FirebaseUserProfileService _instance = FirebaseUserProfileService._internal();
  factory FirebaseUserProfileService() => _instance;
  FirebaseUserProfileService._internal();

  final _logger = Logger('FirebaseUserProfileService');

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _usersCollection = 'users';
  static const String _postsCollection = 'social_posts';
  static const String _followersCollection = 'followers';
  static const String _followingCollection = 'following';
  static const String _savedPostsCollection = 'saved_posts';
  
  // Cache for performance
  UserProfile? _cachedProfile;
  String? _cachedUid;

  /// Get current user profile with enhanced social features
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _clearCache();
        return null;
      }

      // Return cached profile if valid
      if (_cachedProfile != null && _cachedUid == user.uid) {
        return _cachedProfile;
      }

      final doc = await _firestore.collection(_usersCollection).doc(user.uid).get();
      if (!doc.exists) {
        _clearCache();
        return null;
      }

      final profile = UserProfile.fromFirestore(doc);
      _cacheProfile(profile, user.uid);
      return profile;
    } catch (e) {
      _logger.severe('Error getting current user profile: $e');
      return null;
    }
  }

  /// Get user profile by ID with social stats
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (!doc.exists) return null;

      return UserProfile.fromFirestore(doc);
    } catch (e) {
      _logger.severe('Error getting user profile for $userId: $e');
      return null;
    }
  }

  /// Update user profile with enhanced data
  Future<UserProfile> updateUserProfile({
    String? displayName,
    String? username,
    String? bio,
    File? profileImage,
    Map<String, dynamic>? preferences,
    List<String>? interests,
    bool? isPublic,
    Map<String, dynamic>? additionalData,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      String? photoURL;
      
      // Upload profile image if provided
      if (profileImage != null) {
        photoURL = await _uploadProfileImage(user.uid, profileImage);
      }

      final updateData = <String, dynamic>{
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (displayName != null) updateData['displayName'] = displayName;
      if (username != null) updateData['username'] = username;
      if (bio != null) updateData['bio'] = bio;
      if (photoURL != null) updateData['photoURL'] = photoURL;
      if (preferences != null) updateData['preferences'] = preferences;
      if (interests != null) updateData['interests'] = interests;
      if (isPublic != null) updateData['isPublic'] = isPublic;
      if (additionalData != null) {
        updateData.addAll(additionalData);
      }

      await _firestore.collection(_usersCollection).doc(user.uid).update(updateData);
      
      // Clear cache to force refresh
      _clearCache();
      
      final updatedProfile = await getCurrentUserProfile();
      if (updatedProfile == null) throw Exception('Failed to get updated profile');
      
      return updatedProfile;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Upload profile image to Firebase Storage
  Future<String> _uploadProfileImage(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Get user's social statistics
  Future<Map<String, int>> getUserSocialStats(String userId) async {
    try {
      // Get posts count
      final postsQuery = await _firestore
          .collection(_postsCollection)
          .where('userId', isEqualTo: userId)
          .count()
          .get();
      
      // Get followers count
      final followersQuery = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_followersCollection)
          .count()
          .get();
      
      // Get following count
      final followingQuery = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_followingCollection)
          .count()
          .get();

      return {
        'postsCount': postsQuery.count ?? 0,
        'followersCount': followersQuery.count ?? 0,
        'followingCount': followingQuery.count ?? 0,
      };
    } catch (e) {
      _logger.severe('Error getting social stats: $e');
      return {
        'postsCount': 0,
        'followersCount': 0,
        'followingCount': 0,
      };
    }
  }

  /// Follow/Unfollow user
  Future<void> toggleFollowUser(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');
    
    final currentUserId = currentUser.uid;
    if (currentUserId == targetUserId) throw Exception('Cannot follow yourself');

    try {
      final batch = _firestore.batch();
      
      // Check if already following
      final followingDoc = await _firestore
          .collection(_usersCollection)
          .doc(currentUserId)
          .collection(_followingCollection)
          .doc(targetUserId)
          .get();

      if (followingDoc.exists) {
        // Unfollow
        batch.delete(_firestore
            .collection(_usersCollection)
            .doc(currentUserId)
            .collection(_followingCollection)
            .doc(targetUserId));
        
        batch.delete(_firestore
            .collection(_usersCollection)
            .doc(targetUserId)
            .collection(_followersCollection)
            .doc(currentUserId));
      } else {
        // Follow
        batch.set(_firestore
            .collection(_usersCollection)
            .doc(currentUserId)
            .collection(_followingCollection)
            .doc(targetUserId), {
          'followedAt': FieldValue.serverTimestamp(),
          'userId': targetUserId,
        });
        
        batch.set(_firestore
            .collection(_usersCollection)
            .doc(targetUserId)
            .collection(_followersCollection)
            .doc(currentUserId), {
          'followedAt': FieldValue.serverTimestamp(),
          'userId': currentUserId,
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to toggle follow status: $e');
    }
  }

  /// Check if current user is following target user
  Future<bool> isFollowingUser(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(currentUser.uid)
          .collection(_followingCollection)
          .doc(targetUserId)
          .get();
      
      return doc.exists;
    } catch (e) {
      _logger.severe('Error checking follow status: $e');
      return false;
    }
  }

  /// Get user's followers
  Stream<List<UserProfile>> getUserFollowers(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_followersCollection)
        .orderBy('followedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final followerIds = snapshot.docs.map((doc) => doc.data()['userId'] as String).toList();
      if (followerIds.isEmpty) return <UserProfile>[];

      final followers = <UserProfile>[];
      for (final followerId in followerIds) {
        final profile = await getUserProfile(followerId);
        if (profile != null) followers.add(profile);
      }
      return followers;
    });
  }

  /// Get user's following
  Stream<List<UserProfile>> getUserFollowing(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_followingCollection)
        .orderBy('followedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final followingIds = snapshot.docs.map((doc) => doc.data()['userId'] as String).toList();
      if (followingIds.isEmpty) return <UserProfile>[];

      final following = <UserProfile>[];
      for (final followingId in followingIds) {
        final profile = await getUserProfile(followingId);
        if (profile != null) following.add(profile);
      }
      return following;
    });
  }

  /// Get user's posts with pagination
  Stream<List<SocialPost>> getUserPosts(String userId, {int limit = 20}) {
    return _firestore
        .collection(_postsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SocialPost.fromFirestore(doc))
            .toList());
  }

  /// Get user's saved posts
  Stream<List<SocialPost>> getUserSavedPosts({int limit = 20}) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection(_usersCollection)
        .doc(currentUser.uid)
        .collection(_savedPostsCollection)
        .orderBy('savedAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      final postIds = snapshot.docs.map((doc) => doc.id).toList();
      if (postIds.isEmpty) return <SocialPost>[];

      final posts = <SocialPost>[];
      for (final postId in postIds) {
        final postDoc = await _firestore.collection(_postsCollection).doc(postId).get();
        if (postDoc.exists) {
          posts.add(SocialPost.fromFirestore(postDoc));
        }
      }
      return posts;
    });
  }

  /// Search users by username or display name
  Future<List<UserProfile>> searchUsers(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];

    try {
      final lowercaseQuery = query.toLowerCase();
      
      // Search by username
      final usernameQuery = await _firestore
          .collection(_usersCollection)
          .where('username', isGreaterThanOrEqualTo: lowercaseQuery)
          .where('username', isLessThan: '${lowercaseQuery}z')
          .limit(limit)
          .get();

      // Search by display name
      final displayNameQuery = await _firestore
          .collection(_usersCollection)
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: '${query}z')
          .limit(limit)
          .get();

      final results = <UserProfile>[];
      final seenIds = <String>{};

      // Combine results and remove duplicates
      for (final doc in [...usernameQuery.docs, ...displayNameQuery.docs]) {
        if (!seenIds.contains(doc.id)) {
          results.add(UserProfile.fromFirestore(doc));
          seenIds.add(doc.id);
        }
      }

      return results;
    } catch (e) {
      _logger.severe('Error searching users: $e');
      return [];
    }
  }

  /// Get recommended users to follow
  Future<List<UserProfile>> getRecommendedUsers({int limit = 10}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    try {
      // Get users the current user is not following
      final followingSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(currentUser.uid)
          .collection(_followingCollection)
          .get();

      final followingIds = followingSnapshot.docs.map((doc) => doc.id).toSet();
      followingIds.add(currentUser.uid); // Exclude self

      // Get random users (simplified approach)
      final usersSnapshot = await _firestore
          .collection(_usersCollection)
          .where('isPublic', isEqualTo: true)
          .limit(limit * 2) // Get more to filter out following
          .get();

      final recommendations = <UserProfile>[];
      for (final doc in usersSnapshot.docs) {
        if (!followingIds.contains(doc.id) && recommendations.length < limit) {
          recommendations.add(UserProfile.fromFirestore(doc));
        }
      }

      return recommendations;
    } catch (e) {
      _logger.severe('Error getting recommended users: $e');
      return [];
    }
  }

  /// Update user activity status
  Future<void> updateLastActive() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection(_usersCollection).doc(currentUser.uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.severe('Error updating last active: $e');
    }
  }

  /// Delete user account and all associated data
  Future<void> deleteUserAccount() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      final batch = _firestore.batch();
      final userId = currentUser.uid;

      // Delete user document
      batch.delete(_firestore.collection(_usersCollection).doc(userId));

      // Delete user's posts
      final postsSnapshot = await _firestore
          .collection(_postsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in postsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete followers/following relationships
      final followersSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_followersCollection)
          .get();
      
      for (final doc in followersSnapshot.docs) {
        batch.delete(doc.reference);
      }

      final followingSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_followingCollection)
          .get();
      
      for (final doc in followingSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Delete profile image from storage
      try {
        await _storage.ref().child('profile_images').child('$userId.jpg').delete();
      } catch (e) {
        // Image might not exist, ignore error
        _logger.info('Profile image deletion error (ignored): $e');
      }

      // Delete Firebase Auth user
      await currentUser.delete();
      
      _clearCache();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  /// Cache management
  void _cacheProfile(UserProfile profile, String uid) {
    _cachedProfile = profile;
    _cachedUid = uid;
  }

  void _clearCache() {
    _cachedProfile = null;
    _cachedUid = null;
  }

  void clearCache() => _clearCache();
}