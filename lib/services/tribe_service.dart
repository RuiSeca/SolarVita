import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tribe.dart';
import '../models/tribe_member.dart';
import '../models/tribe_post.dart';

class TribeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Generate a unique invite code for private tribes
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Tribe CRUD Operations
  Future<String> createTribe({
    required String name,
    required String description,
    required TribeCategory category,
    String? customCategory,
    TribeVisibility visibility = TribeVisibility.public,
    String? coverImage,
    List<String> tags = const [],
    String? location,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final user = _auth.currentUser!;
    final inviteCode = visibility == TribeVisibility.private ? _generateInviteCode() : null;
    
    final tribe = Tribe(
      id: '', // Will be set by Firestore
      name: name,
      description: description,
      creatorId: currentUserId!,
      creatorName: user.displayName ?? 'Anonymous',
      adminIds: [currentUserId!], // Creator is also admin
      category: category,
      customCategory: customCategory,
      visibility: visibility,
      inviteCode: inviteCode,
      createdAt: DateTime.now(),
      coverImage: coverImage,
      memberCount: 1,
      tags: tags,
      location: location,
    );

    // Create the tribe
    final tribeRef = await _firestore.collection('tribes').add(tribe.toFirestore());
    
    // Add creator as member
    final member = TribeMember(
      id: '',
      tribeId: tribeRef.id,
      userId: currentUserId!,
      userName: user.displayName ?? 'Anonymous',
      userPhotoURL: user.photoURL,
      role: TribeMemberRole.creator,
      joinedAt: DateTime.now(),
    );
    
    await _firestore.collection('tribeMembers').add(member.toFirestore());
    
    return tribeRef.id;
  }

  Future<void> updateTribe(String tribeId, Map<String, dynamic> updates) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    // Verify user is admin/creator
    final isAdmin = await _isUserTribeAdmin(tribeId, currentUserId!);
    if (!isAdmin) throw Exception('Insufficient permissions');
    
    await _firestore.collection('tribes').doc(tribeId).update(updates);
  }

  Future<void> deleteTribe(String tribeId) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    // Verify user is creator
    final tribe = await getTribe(tribeId);
    if (tribe == null || tribe.creatorId != currentUserId) {
      throw Exception('Only tribe creator can delete the tribe');
    }
    
    // Delete all related data
    final batch = _firestore.batch();
    
    // Delete tribe
    batch.delete(_firestore.collection('tribes').doc(tribeId));
    
    // Delete all members
    final membersSnapshot = await _firestore
        .collection('tribeMembers')
        .where('tribeId', isEqualTo: tribeId)
        .get();
    
    for (final doc in membersSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    // Delete all posts
    final postsSnapshot = await _firestore
        .collection('tribePosts')
        .where('tribeId', isEqualTo: tribeId)
        .get();
    
    for (final doc in postsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  // Tribe Retrieval
  Future<Tribe?> getTribe(String tribeId) async {
    final doc = await _firestore.collection('tribes').doc(tribeId).get();
    return doc.exists ? Tribe.fromFirestore(doc) : null;
  }

  Stream<Tribe?> getTribeStream(String tribeId) {
    return _firestore
        .collection('tribes')
        .doc(tribeId)
        .snapshots()
        .map((doc) => doc.exists ? Tribe.fromFirestore(doc) : null);
  }

  // Tribe Discovery
  Stream<List<Tribe>> getPublicTribes({
    TribeCategory? category,
    String? searchQuery,
    int limit = 20,
  }) {
    Query query = _firestore
        .collection('tribes')
        .where('visibility', isEqualTo: TribeVisibility.public.index)
        .orderBy('memberCount', descending: true)
        .limit(limit);

    if (category != null) {
      query = query.where('category', isEqualTo: category.index);
    }

    return query.snapshots().map((snapshot) {
      final tribes = snapshot.docs
          .map((doc) => Tribe.fromFirestore(doc))
          .toList();
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        return tribes.where((tribe) =>
          tribe.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          tribe.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          tribe.tags.any((tag) => tag.toLowerCase().contains(searchQuery.toLowerCase()))
        ).toList();
      }
      
      return tribes;
    });
  }

  Stream<List<Tribe>> getMyTribes() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('tribeMembers')
        .where('userId', isEqualTo: currentUserId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((memberSnapshot) async {
      final tribeIds = memberSnapshot.docs
          .map((doc) => TribeMember.fromFirestore(doc).tribeId)
          .toList();
      
      if (tribeIds.isEmpty) return <Tribe>[];
      
      final tribesSnapshot = await _firestore
          .collection('tribes')
          .where(FieldPath.documentId, whereIn: tribeIds)
          .get();
      
      return tribesSnapshot.docs
          .map((doc) => Tribe.fromFirestore(doc))
          .toList();
    });
  }

  // Member Management
  Future<void> joinTribe(String tribeId, {String? inviteCode}) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final user = _auth.currentUser!;
    final tribe = await getTribe(tribeId);
    
    if (tribe == null) throw Exception('Tribe not found');
    
    // Check if already a member
    final existingMember = await _getTribeMember(tribeId, currentUserId!);
    if (existingMember != null) {
      if (existingMember.isActive) {
        throw Exception('Already a member of this tribe');
      } else {
        // Reactivate membership
        await _firestore
            .collection('tribeMembers')
            .doc(existingMember.id)
            .update({'isActive': true, 'joinedAt': Timestamp.now()});
        return;
      }
    }
    
    // Check private tribe access
    if (tribe.isPrivate) {
      if (inviteCode == null || inviteCode != tribe.inviteCode) {
        throw Exception('Invalid invite code');
      }
    }
    
    // Add as member
    final member = TribeMember(
      id: '',
      tribeId: tribeId,
      userId: currentUserId!,
      userName: user.displayName ?? 'Anonymous',
      userPhotoURL: user.photoURL,
      role: TribeMemberRole.member,
      joinedAt: DateTime.now(),
    );
    
    await _firestore.collection('tribeMembers').add(member.toFirestore());
    
    // Update tribe member count
    await _firestore.collection('tribes').doc(tribeId).update({
      'memberCount': FieldValue.increment(1),
    });
  }

  Future<void> leaveTribe(String tribeId) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final member = await _getTribeMember(tribeId, currentUserId!);
    if (member == null) throw Exception('Not a member of this tribe');
    
    if (member.isCreator) {
      throw Exception('Creator cannot leave the tribe. Delete the tribe instead.');
    }
    
    // Deactivate membership
    await _firestore.collection('tribeMembers').doc(member.id).update({
      'isActive': false,
    });
    
    // Update tribe member count
    await _firestore.collection('tribes').doc(tribeId).update({
      'memberCount': FieldValue.increment(-1),
    });
  }

  Future<void> removeMember(String tribeId, String userId) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    // Verify user is admin
    final isAdmin = await _isUserTribeAdmin(tribeId, currentUserId!);
    if (!isAdmin) throw Exception('Insufficient permissions');
    
    final member = await _getTribeMember(tribeId, userId);
    if (member == null) throw Exception('User is not a member');
    
    if (member.isCreator) {
      throw Exception('Cannot remove tribe creator');
    }
    
    // Remove member
    await _firestore.collection('tribeMembers').doc(member.id).delete();
    
    // Update tribe member count
    await _firestore.collection('tribes').doc(tribeId).update({
      'memberCount': FieldValue.increment(-1),
    });
  }

  Future<void> promoteMember(String tribeId, String userId) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    // Verify user is creator
    final tribe = await getTribe(tribeId);
    if (tribe == null || tribe.creatorId != currentUserId) {
      throw Exception('Only tribe creator can promote members');
    }
    
    final member = await _getTribeMember(tribeId, userId);
    if (member == null) throw Exception('User is not a member');
    
    await _firestore.collection('tribeMembers').doc(member.id).update({
      'role': TribeMemberRole.admin.index,
    });
    
    // Update tribe admin list
    await _firestore.collection('tribes').doc(tribeId).update({
      'adminIds': FieldValue.arrayUnion([userId]),
    });
  }

  // Tribe Members
  Stream<List<TribeMember>> getTribeMembers(String tribeId) {
    return _firestore
        .collection('tribeMembers')
        .where('tribeId', isEqualTo: tribeId)
        .where('isActive', isEqualTo: true)
        .orderBy('joinedAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TribeMember.fromFirestore(doc))
            .toList());
  }

  Future<TribeMember?> _getTribeMember(String tribeId, String userId) async {
    final snapshot = await _firestore
        .collection('tribeMembers')
        .where('tribeId', isEqualTo: tribeId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    
    return snapshot.docs.isNotEmpty 
        ? TribeMember.fromFirestore(snapshot.docs.first)
        : null;
  }

  Future<bool> _isUserTribeAdmin(String tribeId, String userId) async {
    final member = await _getTribeMember(tribeId, userId);
    return member?.isAdmin ?? false;
  }

  Future<bool> isUserTribeMember(String tribeId, String userId) async {
    final member = await _getTribeMember(tribeId, userId);
    return member?.isActive ?? false;
  }

  // Tribe Posts
  Future<String> createTribePost({
    required String tribeId,
    required String content,
    String? title,
    TribePostType type = TribePostType.text,
    List<String> imageUrls = const [],
    bool isAnnouncement = false,
    List<String> tags = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    // Verify user is member
    final isMember = await isUserTribeMember(tribeId, currentUserId!);
    if (!isMember) throw Exception('Must be a tribe member to post');
    
    final user = _auth.currentUser!;
    final post = TribePost(
      id: '',
      tribeId: tribeId,
      authorId: currentUserId!,
      authorName: user.displayName ?? 'Anonymous',
      authorPhotoURL: user.photoURL,
      type: type,
      content: content,
      title: title,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
      isAnnouncement: isAnnouncement,
      tags: tags,
      metadata: metadata,
    );
    
    final postRef = await _firestore.collection('tribePosts').add(post.toFirestore());
    return postRef.id;
  }

  Stream<List<TribePost>> getTribePosts(String tribeId, {int limit = 20}) {
    return _firestore
        .collection('tribePosts')
        .where('tribeId', isEqualTo: tribeId)
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TribePost.fromFirestore(doc))
            .toList());
  }

  Future<void> likeTribePost(String postId) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final postRef = _firestore.collection('tribePosts').doc(postId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(postRef);
      if (!doc.exists) return;
      
      final likes = List<String>.from(doc.data()?['likes'] ?? []);
      
      if (likes.contains(currentUserId)) {
        likes.remove(currentUserId);
      } else {
        likes.add(currentUserId!);
      }
      
      transaction.update(postRef, {'likes': likes});
    });
  }

  // Utility Methods
  Future<Tribe?> findTribeByInviteCode(String inviteCode) async {
    final snapshot = await _firestore
        .collection('tribes')
        .where('inviteCode', isEqualTo: inviteCode)
        .limit(1)
        .get();
    
    return snapshot.docs.isNotEmpty 
        ? Tribe.fromFirestore(snapshot.docs.first)
        : null;
  }

  // Get all categories for filtering
  static List<TribeCategory> getAllCategories() {
    return TribeCategory.values.where((cat) => cat != TribeCategory.custom).toList();
  }

  static String getCategoryDisplayName(TribeCategory category) {
    switch (category) {
      case TribeCategory.fitness:
        return 'Fitness & Workouts';
      case TribeCategory.eco:
        return 'Eco & Sustainability';
      case TribeCategory.nutrition:
        return 'Plant-Based Nutrition';
      case TribeCategory.mindfulness:
        return 'Mindfulness';
      case TribeCategory.cycling:
        return 'Cycling';
      case TribeCategory.running:
        return 'Running';
      case TribeCategory.yoga:
        return 'Yoga';
      case TribeCategory.zeroWaste:
        return 'Zero Waste';
      case TribeCategory.plantBased:
        return 'Plant-Based Living';
      case TribeCategory.custom:
        return 'Custom';
    }
  }

  // Activity Feed Integration
  Stream<List<TribePost>> getAllTribesActivityFeed({int limit = 20}) {
    if (currentUserId == null) {
      return Stream.value([]);
    }
    
    return getMyTribes().asyncMap((tribes) async {
      if (tribes.isEmpty) {
        return <TribePost>[];
      }
      
      final tribeIds = tribes.map((t) => t.id).toList();
      
      try {
        final snapshot = await _firestore
            .collection('tribePosts')
            .where('tribeId', whereIn: tribeIds)
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();
        
        final posts = snapshot.docs
            .map((doc) => TribePost.fromFirestore(doc))
            .toList();
        
        return posts;
      } catch (e) {
        return <TribePost>[];
      }
    }).handleError((error) {
      return <TribePost>[];
    });
  }
}