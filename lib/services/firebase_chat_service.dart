// lib/services/firebase_chat_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logging/logging.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../services/firebase_push_notification_service.dart';

class FirebaseChatService {
  static final FirebaseChatService _instance = FirebaseChatService._internal();
  factory FirebaseChatService() => _instance;
  FirebaseChatService._internal();

  final _logger = Logger('FirebaseChatService');

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebasePushNotificationService _notificationService = FirebasePushNotificationService();

  static const String _conversationsCollection = 'conversations';
  static const String _messagesCollection = 'messages';
  static const String _usersCollection = 'users';

  /// Get all conversations for current user
  Stream<List<ChatConversation>> getUserConversations() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection(_conversationsCollection)
        .where('participantIds', arrayContains: currentUser.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final conversations = <ChatConversation>[];
      
      for (final doc in snapshot.docs) {
        try {
          final conversation = ChatConversation.fromFirestore(doc);
          
          // Check if participant data is missing or incomplete
          final enrichedConversation = await _enrichConversationWithParticipantData(conversation);
          conversations.add(enrichedConversation);
        } catch (e) {
          _logger.warning('Error parsing conversation ${doc.id}: $e');
        }
      }
      
      return conversations;
    });
  }

  /// Enrich conversation with participant data if missing
  Future<ChatConversation> _enrichConversationWithParticipantData(ChatConversation conversation) async {
    // Check if participant data is complete
    final participantData = Map<String, dynamic>.from(conversation.participantData);
    bool needsUpdate = false;
    
    for (final participantId in conversation.participantIds) {
      final userData = participantData[participantId] as Map<String, dynamic>?;
      if (userData == null || userData['displayName'] == null) {
        // Fetch missing participant data
        try {
          String displayName = 'User ${participantId.substring(0, 8)}';
          String? photoURL;
          String? username;
          
          // If this is the current user, prioritize Firebase Auth data
          final currentUser = _auth.currentUser;
          if (currentUser != null && participantId == currentUser.uid) {
            displayName = currentUser.displayName ?? '';
            photoURL = currentUser.photoURL;
            
            // Fallback to Firestore if Firebase Auth data is empty
            if (displayName.isEmpty) {
              final userDoc = await _firestore.collection(_usersCollection).doc(participantId).get();
              if (userDoc.exists) {
                final userDocData = userDoc.data()!;
                String? firestoreName = userDocData['displayName'] as String?;
                if (firestoreName != null && firestoreName.trim().isNotEmpty) {
                  displayName = firestoreName;
                } else {
                  displayName = currentUser.email?.split('@').first ?? 
                               userDocData['username'] as String? ?? 
                               'User ${participantId.substring(0, 8)}';
                }
                
                if (photoURL == null || photoURL.isEmpty) {
                  photoURL = userDocData['photoURL'] as String?;
                }
                username = userDocData['username'] as String?;
              }
            }
          } else {
            // For other participants, try to get comprehensive user data
            final userDoc = await _firestore.collection(_usersCollection).doc(participantId).get();
            if (userDoc.exists) {
              final userDocData = userDoc.data()!;
              
              // Try multiple fields for display name
              String? displayNameNullable = userDocData['displayName'] as String?;
              if (displayNameNullable == null || displayNameNullable.trim().isEmpty) {
                // Try other name fields
                displayNameNullable = userDocData['name'] as String? ?? 
                                    userDocData['fullName'] as String? ??
                                    userDocData['firstName'] as String?;
              }
              
              if (displayNameNullable != null && displayNameNullable.trim().isNotEmpty) {
                displayName = displayNameNullable;
              } else {
                // Fallback to email or username
                displayName = userDocData['email']?.toString().split('@').first ?? 
                             userDocData['username'] as String? ?? 
                             'User ${participantId.substring(0, 8)}';
              }
              
              // Try multiple fields for photo URL
              photoURL = userDocData['photoURL'] as String? ?? 
                        userDocData['avatarUrl'] as String? ?? 
                        userDocData['profilePicture'] as String?;
              
              username = userDocData['username'] as String?;
            }
          }
          
          participantData[participantId] = {
            'displayName': displayName,
            'photoURL': photoURL,
            'username': username,
          };
          needsUpdate = true;
        } catch (e) {
          _logger.warning('Error fetching participant data for $participantId: $e');
          // Fallback for missing user data
          participantData[participantId] = {
            'displayName': 'User ${participantId.substring(0, 8)}',
            'photoURL': null,
            'username': null,
          };
          needsUpdate = true;
        }
      }
    }
    
    // Update conversation in Firestore if needed
    if (needsUpdate) {
      try {
        await _firestore.collection(_conversationsCollection).doc(conversation.conversationId).update({
          'participantData': participantData,
        });
      } catch (e) {
        _logger.warning('Error updating conversation participant data: $e');
      }
    }
    
    // Return conversation with updated participant data
    return conversation.copyWith(participantData: participantData);
  }

  /// Get or create conversation between users
  Future<ChatConversation> getOrCreateConversation({
    required String otherUserId,
    bool isGroup = false,
    String? groupName,
    List<String>? additionalParticipants,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      final participantIds = isGroup
          ? [currentUser.uid, otherUserId, ...?additionalParticipants]
          : [currentUser.uid, otherUserId]..sort();

      // Check if conversation already exists
      final existingQuery = await _firestore
          .collection(_conversationsCollection)
          .where('participantIds', isEqualTo: participantIds)
          .where('isGroup', isEqualTo: isGroup)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        return ChatConversation.fromFirestore(existingQuery.docs.first);
      }

      // Get participant data
      final participantData = <String, dynamic>{};
      for (final participantId in participantIds) {
        String displayName = 'User ${participantId.substring(0, 8)}';
        String? photoURL;
        String? username;
        
        // If this is the current user, prioritize Firebase Auth data
        if (participantId == currentUser.uid) {
          displayName = currentUser.displayName ?? '';
          photoURL = currentUser.photoURL;
          
          // Fallback to Firestore if Firebase Auth data is empty
          if (displayName.isEmpty) {
            final userDoc = await _firestore.collection(_usersCollection).doc(participantId).get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              String? firestoreName = userData['displayName'] as String?;
              if (firestoreName != null && firestoreName.trim().isNotEmpty) {
                displayName = firestoreName;
              } else {
                displayName = currentUser.email?.split('@').first ?? 
                             userData['username'] as String? ?? 
                             'User ${participantId.substring(0, 8)}';
              }
              
              if (photoURL == null || photoURL.isEmpty) {
                photoURL = userData['photoURL'] as String?;
              }
              username = userData['username'] as String?;
            }
          }
        } else {
          // For other participants, try to get comprehensive user data
          final userDoc = await _firestore.collection(_usersCollection).doc(participantId).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            
            // Try multiple fields for display name
            String? displayNameNullable = userData['displayName'] as String?;
            if (displayNameNullable == null || displayNameNullable.trim().isEmpty) {
              // Try other name fields
              displayNameNullable = userData['name'] as String? ?? 
                                  userData['fullName'] as String? ??
                                  userData['firstName'] as String?;
            }
            
            if (displayNameNullable != null && displayNameNullable.trim().isNotEmpty) {
              displayName = displayNameNullable;
            } else {
              // Fallback to email or username
              displayName = userData['email']?.toString().split('@').first ?? 
                           userData['username'] as String? ?? 
                           'User ${participantId.substring(0, 8)}';
            }
            
            // Try multiple fields for photo URL
            photoURL = userData['photoURL'] as String? ?? 
                      userData['avatarUrl'] as String? ?? 
                      userData['profilePicture'] as String?;
            
            username = userData['username'] as String?;
          }
        }
        
        participantData[participantId] = {
          'displayName': displayName,
          'photoURL': photoURL,
          'username': username,
        };
      }

      // Create new conversation
      final conversationData = {
        'participantIds': participantIds,
        'participantData': participantData,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'isGroup': isGroup,
        'groupName': groupName,
        'groupAvatarUrl': null,
        'groupDescription': null,
        'adminIds': isGroup ? [currentUser.uid] : [],
        'unreadCounts': {for (final id in participantIds) id: 0},
        'settings': {},
        'isActive': true,
      };

      final docRef = await _firestore.collection(_conversationsCollection).add(conversationData);
      
      // Get the created conversation
      final conversationDoc = await docRef.get();
      return ChatConversation.fromFirestore(conversationDoc);
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  /// Get messages for a conversation
  Stream<List<ChatMessage>> getConversationMessages(String conversationId, {int limit = 50}) {
    return _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  /// Send a text message
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    return _sendMessage(
      conversationId: conversationId,
      content: content,
      messageType: MessageType.text,
      replyToMessageId: replyToMessageId,
      metadata: metadata,
    );
  }

  /// Send a message with media
  Future<ChatMessage> sendMediaMessage({
    required String conversationId,
    required List<File> mediaFiles,
    required MessageType messageType,
    String? content,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    // Upload media files
    final mediaUrls = <String>[];
    for (final file in mediaFiles) {
      final url = await _uploadMediaFile(file, messageType);
      mediaUrls.add(url);
    }

    return _sendMessage(
      conversationId: conversationId,
      content: content ?? '',
      messageType: messageType,
      mediaUrls: mediaUrls,
      replyToMessageId: replyToMessageId,
      metadata: metadata,
    );
  }

  /// Send location message
  Future<ChatMessage> sendLocationMessage({
    required String conversationId,
    required double latitude,
    required double longitude,
    String? locationName,
    String? replyToMessageId,
  }) async {
    final metadata = {
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
    };

    return _sendMessage(
      conversationId: conversationId,
      content: locationName ?? 'Location',
      messageType: MessageType.location,
      metadata: metadata,
      replyToMessageId: replyToMessageId,
    );
  }

  /// Send workout share message
  Future<ChatMessage> sendWorkoutMessage({
    required String conversationId,
    required Map<String, dynamic> workoutData,
    String? replyToMessageId,
  }) async {
    return _sendMessage(
      conversationId: conversationId,
      content: 'Shared a workout',
      messageType: MessageType.workout,
      metadata: workoutData,
      replyToMessageId: replyToMessageId,
    );
  }

  /// Send achievement message
  Future<ChatMessage> sendAchievementMessage({
    required String conversationId,
    required Map<String, dynamic> achievementData,
    String? replyToMessageId,
  }) async {
    return _sendMessage(
      conversationId: conversationId,
      content: 'Unlocked an achievement!',
      messageType: MessageType.achievement,
      metadata: achievementData,
      replyToMessageId: replyToMessageId,
    );
  }

  /// Internal method to send message
  Future<ChatMessage> _sendMessage({
    required String conversationId,
    required String content,
    required MessageType messageType,
    List<String>? mediaUrls,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      // Get conversation data
      final conversationDoc = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .get();

      if (!conversationDoc.exists) {
        throw Exception('Conversation not found');
      }

      final conversationData = conversationDoc.data()!;
      final participantIds = List<String>.from(conversationData['participantIds'] ?? []);
      final receiverId = participantIds.firstWhere(
        (id) => id != currentUser.uid,
        orElse: () => currentUser.uid,
      );

      // Get current user data - prioritize Firebase Auth data over Firestore data
      String senderName = currentUser.displayName ?? '';
      String? senderAvatarUrl = currentUser.photoURL;
      
      // If Firebase Auth doesn't have display name, try Firestore and fallbacks
      if (senderName.isEmpty) {
        final userDoc = await _firestore.collection(_usersCollection).doc(currentUser.uid).get();
        final userData = userDoc.data();
        
        String? firestoreName = userData?['displayName'] as String?;
        if (firestoreName != null && firestoreName.trim().isNotEmpty) {
          senderName = firestoreName;
        } else {
          // Final fallbacks
          senderName = currentUser.email?.split('@').first ?? 
                       userData?['username'] as String? ?? 
                       'User ${currentUser.uid.substring(0, 8)}';
        }
        
        // Use Firestore avatar if Firebase Auth doesn't have one
        if (senderAvatarUrl == null || senderAvatarUrl.isEmpty) {
          senderAvatarUrl = userData?['photoURL'] as String?;
        }
      }

      // Create message
      final messageData = {
        'senderId': currentUser.uid,
        'receiverId': receiverId,
        'conversationId': conversationId,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'senderName': senderName,
        'isRead': false,
        'messageType': messageType.name,
        'status': MessageStatus.sent.name,
        'editedAt': null,
        'replyToMessageId': replyToMessageId,
        'mediaUrls': mediaUrls ?? [],
        'isDeleted': false,
        'readBy': [],
        'senderAvatarUrl': senderAvatarUrl,
        'metadata': metadata,
      };

      // Save message
      final messageRef = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection(_messagesCollection)
          .add(messageData);

      // Update conversation
      final batch = _firestore.batch();
      
      // Update last message and timestamp
      batch.update(_firestore.collection(_conversationsCollection).doc(conversationId), {
        'lastMessage': _getDisplayContent(content, messageType),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts.$receiverId': FieldValue.increment(1),
      });

      await batch.commit();

      // Send push notification
      await _sendMessageNotification(
        userId: receiverId,
        senderName: senderName,
        content: _getDisplayContent(content, messageType),
        conversationId: conversationId,
      );

      // Get the created message
      final messageDoc = await messageRef.get();
      return ChatMessage.fromFirestore(messageDoc);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Upload media file to Firebase Storage
  Future<String> _uploadMediaFile(File file, MessageType messageType) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final folder = _getStorageFolder(messageType);
      final ref = _storage.ref().child('chat_media').child(folder).child(fileName);
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload media: $e');
    }
  }

  /// Get storage folder based on message type
  String _getStorageFolder(MessageType messageType) {
    switch (messageType) {
      case MessageType.image:
        return 'images';
      case MessageType.video:
        return 'videos';
      case MessageType.audio:
        return 'audio';
      case MessageType.file:
        return 'files';
      default:
        return 'misc';
    }
  }

  /// Get display content for last message
  String _getDisplayContent(String content, MessageType messageType) {
    switch (messageType) {
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.file:
        return '📎 File';
      case MessageType.location:
        return '📍 Location';
      case MessageType.workout:
        return '💪 Workout';
      case MessageType.achievement:
        return '🏆 Achievement';
      case MessageType.activityShare:
        return '📊 Activity';
      default:
        return content;
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String conversationId, String messageId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
        'isRead': true,
        'readBy': FieldValue.arrayUnion([currentUser.uid]),
      });

      // Reset unread count for current user
      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .update({
        'unreadCounts.${currentUser.uid}': 0,
      });
    } catch (e) {
      _logger.severe('Error marking message as read: $e');
    }
  }

  /// Mark all messages in conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Get unread messages
      final unreadMessages = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection(_messagesCollection)
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: currentUser.uid)
          .get();

      if (unreadMessages.docs.isEmpty) return;

      // Update messages in batch
      final batch = _firestore.batch();
      
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readBy': FieldValue.arrayUnion([currentUser.uid]),
        });
      }

      // Reset unread count
      batch.update(_firestore.collection(_conversationsCollection).doc(conversationId), {
        'unreadCounts.${currentUser.uid}': 0,
      });

      await batch.commit();
    } catch (e) {
      _logger.severe('Error marking conversation as read: $e');
    }
  }

  /// Edit message
  Future<ChatMessage> editMessage({
    required String conversationId,
    required String messageId,
    required String newContent,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      final messageRef = _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection(_messagesCollection)
          .doc(messageId);

      await messageRef.update({
        'content': newContent,
        'editedAt': FieldValue.serverTimestamp(),
      });

      final updatedDoc = await messageRef.get();
      return ChatMessage.fromFirestore(updatedDoc);
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  /// Delete message
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
    bool deleteForEveryone = false,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      final messageRef = _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection(_messagesCollection)
          .doc(messageId);

      if (deleteForEveryone) {
        await messageRef.update({
          'isDeleted': true,
          'content': 'This message was deleted',
          'mediaUrls': [],
        });
      } else {
        // Only delete for current user (implementation depends on requirements)
        await messageRef.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Get total unread messages count
  Stream<int> getTotalUnreadCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection(_conversationsCollection)
        .where('participantIds', arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final unreadCounts = Map<String, int>.from(data['unreadCounts'] ?? {});
        totalUnread += unreadCounts[currentUser.uid] ?? 0;
      }
      return totalUnread;
    });
  }

  /// Search messages in conversation
  Future<List<ChatMessage>> searchMessages({
    required String conversationId,
    required String query,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final messagesSnapshot = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection(_messagesCollection)
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThan: '${query}z')
          .orderBy('content')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return messagesSnapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error searching messages: $e');
      return [];
    }
  }

  /// Send push notification for new message
  Future<void> _sendMessageNotification({
    required String userId,
    required String senderName,
    required String content,
    required String conversationId,
  }) async {
    try {
      await _notificationService.sendNotificationToUser(
        userId: userId,
        title: senderName,
        body: content,
        type: NotificationType.chat,
        data: {
          'conversationId': conversationId,
          'type': 'chat_message',
        },
        actionUrl: '/chat/$conversationId',
      );
    } catch (e) {
      _logger.severe('Error sending message notification: $e');
    }
  }

  /// Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      final batch = _firestore.batch();

      // Delete all messages in conversation
      final messagesSnapshot = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection(_messagesCollection)
          .get();

      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete conversation
      batch.delete(_firestore.collection(_conversationsCollection).doc(conversationId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  /// Update typing status
  Future<void> updateTypingStatus({
    required String conversationId,
    required bool isTyping,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .update({
        'typingUsers.${currentUser.uid}': isTyping ? FieldValue.serverTimestamp() : FieldValue.delete(),
      });
    } catch (e) {
      _logger.fine('Error updating typing status: $e');
    }
  }

  /// Get typing users stream
  Stream<List<String>> getTypingUsers(String conversationId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return <String>[];

      final data = snapshot.data()!;
      final typingUsers = Map<String, dynamic>.from(data['typingUsers'] ?? {});
      final now = DateTime.now();
      
      // Filter out users who haven't typed in the last 3 seconds
      final activeTypingUsers = <String>[];
      for (final entry in typingUsers.entries) {
        final userId = entry.key;
        final timestamp = entry.value as Timestamp?;
        
        if (userId != currentUser.uid && 
            timestamp != null &&
            now.difference(timestamp.toDate()).inSeconds < 3) {
          activeTypingUsers.add(userId);
        }
      }
      
      return activeTypingUsers;
    });
  }
}