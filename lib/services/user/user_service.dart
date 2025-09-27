import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user/user_profile.dart';
import 'package:flutter/foundation.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profilePictureUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePictureUrl,
  });

  factory UserModel.fromUserProfile(UserProfile profile) {
    return UserModel(
      id: profile.uid,
      name: profile.displayName,
      email: profile.email,
      profilePictureUrl: profile.photoURL,
    );
  }
}

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<List<UserModel>> getUserSupporters() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      // Query for users who are supporting the current user
      final supportQuery = await _firestore
          .collection('supports')
          .where('supporteeId', isEqualTo: currentUser.uid)
          .get();

      final supporterIds = supportQuery.docs
          .map((doc) => doc.data()['supporterId'] as String)
          .toList();

      if (supporterIds.isEmpty) return [];

      // Get user profiles for supporters
      final List<UserModel> supporters = [];

      // Batch the queries to avoid too many individual requests
      const batchSize = 10;
      for (int i = 0; i < supporterIds.length; i += batchSize) {
        final batch = supporterIds.skip(i).take(batchSize).toList();
        final userQuery = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in userQuery.docs) {
          if (doc.exists) {
            final profile = UserProfile.fromFirestore(doc);
            supporters.add(UserModel.fromUserProfile(profile));
          }
        }
      }

      return supporters;
    } catch (e) {
      debugPrint('Error getting supporters: $e');
      return [];
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final queryLower = query.toLowerCase();

      // Search by display name
      final nameQuery = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: '${query}z')
          .limit(20)
          .get();

      // Search by email
      final emailQuery = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: queryLower)
          .where('email', isLessThan: '${queryLower}z')
          .limit(20)
          .get();

      // Search by username if available
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: queryLower)
          .where('username', isLessThan: '${queryLower}z')
          .limit(20)
          .get();

      final Map<String, UserModel> uniqueUsers = {};

      // Process all query results
      for (final querySnapshot in [nameQuery, emailQuery, usernameQuery]) {
        for (final doc in querySnapshot.docs) {
          if (doc.exists && doc.id != currentUser.uid) {
            final profile = UserProfile.fromFirestore(doc);
            final userModel = UserModel.fromUserProfile(profile);

            // Filter by query to ensure relevance
            if (userModel.name.toLowerCase().contains(queryLower) ||
                userModel.email.toLowerCase().contains(queryLower)) {
              uniqueUsers[userModel.id] = userModel;
            }
          }
        }
      }

      return uniqueUsers.values.toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final profile = UserProfile.fromFirestore(doc);
        return UserModel.fromUserProfile(profile);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user by id: $e');
      return null;
    }
  }

  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final List<UserModel> users = [];

      // Batch the queries to avoid too many individual requests
      const batchSize = 10;
      for (int i = 0; i < userIds.length; i += batchSize) {
        final batch = userIds.skip(i).take(batchSize).toList();
        final userQuery = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in userQuery.docs) {
          if (doc.exists) {
            final profile = UserProfile.fromFirestore(doc);
            users.add(UserModel.fromUserProfile(profile));
          }
        }
      }

      return users;
    } catch (e) {
      debugPrint('Error getting users by ids: $e');
      return [];
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      return await getUserById(currentUser.uid);
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }
}