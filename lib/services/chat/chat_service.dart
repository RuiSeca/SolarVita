import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/chat_conversation.dart';
import '../../models/social/social_activity.dart';
import '../database/firebase_push_notification_service.dart';
import 'chat_encryption_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebasePushNotificationService _notificationService =
      FirebasePushNotificationService();
  final ChatEncryptionService _encryptionService = ChatEncryptionService();

  String? get currentUserId => _auth.currentUser?.uid;

  /// Initialize encryption for current user (call once during user registration/login)
  Future<void> initializeEncryption() async {
    try {
      await _encryptionService.initializeUserKeys();
      debugPrint('✅ Chat encryption initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize chat encryption: $e');
      // Don't throw - allow chat to work without encryption for now
    }
  }

  // Get or create conversation between two users
  Future<String> getOrCreateConversation(String otherUserId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final participants = [currentUserId!, otherUserId]..sort();
    final conversationId = '${participants[0]}_${participants[1]}';

    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);
    final conversationDoc = await conversationRef.get();

    if (!conversationDoc.exists) {
      // Fetch participant information
      final participantNames = <String, String>{};
      final participantPhotos = <String, String?>{};

      for (final userId in participants) {
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            participantNames[userId] =
                userData['displayName'] ?? 'Unknown User';
            participantPhotos[userId] = userData['photoURL'];
          } else {
            participantNames[userId] = 'Unknown User';
            participantPhotos[userId] = null;
          }
        } catch (e) {
          // If we can't fetch user data, use defaults
          participantNames[userId] = 'Unknown User';
          participantPhotos[userId] = null;
        }
      }

      // Generate and store conversation encryption key
      try {
        debugPrint('🔐 Setting up encryption for conversation...');
        final conversationKey = _encryptionService.generateConversationKey();
        debugPrint('✅ Conversation key generated');

        // Encrypt key for both participants
        debugPrint('🔑 Fetching public keys for participants...');
        final currentUserPublicKey = await _encryptionService.fetchUserPublicKey(currentUserId!);
        debugPrint('✅ Current user public key fetched');

        final otherUserPublicKey = await _encryptionService.fetchUserPublicKey(otherUserId);
        debugPrint('✅ Other user public key fetched');

        final encryptedKeyForCurrentUser = await _encryptionService.encryptKeyForUser(
          conversationKey,
          currentUserPublicKey,
        );
        final encryptedKeyForOtherUser = await _encryptionService.encryptKeyForUser(
          conversationKey,
          otherUserPublicKey,
        );
        debugPrint('✅ Conversation keys encrypted for both users');

        // Store conversation key locally
        await _encryptionService.storeConversationKey(conversationId, conversationKey);
        debugPrint('✅ Conversation key stored locally');

        // Create new conversation with encryption keys
        await conversationRef.set({
          'participantIds': participants,
          'lastMessage': '[Encrypted]',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCounts': {participants[0]: 0, participants[1]: 0},
          'participantNames': participantNames,
          'participantPhotos': participantPhotos,
          'encryptedKeys': {
            currentUserId!: encryptedKeyForCurrentUser,
            otherUserId: encryptedKeyForOtherUser,
          },
        });

        debugPrint('✅ Conversation encryption keys generated and stored');
      } catch (e, stackTrace) {
        debugPrint('❌ Failed to set up encryption for conversation: $e');
        debugPrint('Stack trace: $stackTrace');
        // Fallback: create conversation without encryption
        await conversationRef.set({
          'participantIds': participants,
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCounts': {participants[0]: 0, participants[1]: 0},
          'participantNames': participantNames,
          'participantPhotos': participantPhotos,
        });
      }
    } else {
      // Conversation exists - retrieve encryption key
      try {
        final data = conversationDoc.data()!;
        final encryptedKeys = data['encryptedKeys'] as Map<String, dynamic>?;

        if (encryptedKeys != null && encryptedKeys.containsKey(currentUserId)) {
          // Decrypt and store conversation key locally
          final encryptedKeyForCurrentUser = encryptedKeys[currentUserId!] as String;
          final conversationKey = await _encryptionService.decryptConversationKey(
            encryptedKeyForCurrentUser,
          );
          await _encryptionService.storeConversationKey(conversationId, conversationKey);
          debugPrint('✅ Conversation encryption key retrieved and stored');
        } else {
          debugPrint('⚠️ No encryption keys found for existing conversation');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to retrieve conversation encryption key: $e');
      }

      // Update participant info if conversation exists but names/photos are missing
      final data = conversationDoc.data()!;
      final participantNames = Map<String, String>.from(
        data['participantNames'] ?? {},
      );
      final participantPhotos = Map<String, String?>.from(
        data['participantPhotos'] ?? {},
      );

      bool needsUpdate = false;

      for (final userId in participants) {
        if (!participantNames.containsKey(userId) ||
            participantNames[userId] == null) {
          try {
            final userDoc = await _firestore
                .collection('users')
                .doc(userId)
                .get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              participantNames[userId] =
                  userData['displayName'] ?? 'Unknown User';
              participantPhotos[userId] = userData['photoURL'];
              needsUpdate = true;
            }
          } catch (e) {
            participantNames[userId] = 'Unknown User';
            participantPhotos[userId] = null;
            needsUpdate = true;
          }
        }
      }

      if (needsUpdate) {
        await conversationRef.update({
          'participantNames': participantNames,
          'participantPhotos': participantPhotos,
        });
      }
    }

    return conversationId;
  }

  // Send a text message
  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();

    // Try to encrypt message
    String? encryptedContent;
    String? iv;
    String? signature;

    try {
      final encryptedMessage = await _encryptionService.encryptMessage(
        content,
        conversationId,
      );
      encryptedContent = encryptedMessage.encryptedContent;
      iv = encryptedMessage.iv;
      signature = encryptedMessage.signature;
      debugPrint('✅ Message encrypted successfully');
    } catch (e) {
      debugPrint('⚠️ Failed to encrypt message: $e');
      // Continue without encryption
    }

    // Add message to messages collection
    final messageRef = _firestore.collection('messages').doc();
    final message = ChatMessage(
      messageId: messageRef.id,
      senderId: currentUserId!,
      receiverId: receiverId,
      conversationId: conversationId,
      content: content,
      timestamp: DateTime.now(),
      senderName:
          'Current User', // Gets actual name from UserProfile in notification
      messageType: messageType,
      metadata: metadata,
      encryptedContent: encryptedContent,
      iv: iv,
      signature: signature,
    );

    batch.set(messageRef, message.toFirestore());

    // Update conversation
    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);
    batch.update(conversationRef, {
      'lastMessage': encryptedContent != null ? '[Encrypted]' : content,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts.$receiverId': FieldValue.increment(1),
    });

    await batch.commit();

    // Send notification to the receiver
    // Note: Notification will only be displayed if app is in background
    try {
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .get();
      final senderName = currentUserDoc.exists
          ? (currentUserDoc.data()?['displayName'] ?? 'Someone')
          : 'Someone';

      debugPrint(
        '💬 Sending message notification to $receiverId from $senderName',
      );
      await _notificationService.sendMessageNotification(
        receiverId: receiverId,
        senderName: senderName,
        messagePreview: content.length > 50
            ? '${content.substring(0, 47)}...'
            : content,
        chatId: conversationId,
      );
      debugPrint(
        '✅ Message notification sent (will show only if app in background)',
      );
    } catch (e) {
      // Don't fail the message sending if notification fails
      debugPrint('❌ Message notification failed: $e');
    }
  }

  // Send activity share
  Future<void> sendActivityShare({
    required String conversationId,
    required String receiverId,
    required SocialActivity activity,
  }) async {
    final metadata = {
      'activityId': activity.id,
      'activityType': activity.type.name,
      'activityTitle': activity.title,
      'activityDescription': activity.description,
      'activityIcon': activity.getActivityIcon(),
    };

    await sendMessage(
      conversationId: conversationId,
      receiverId: receiverId,
      content: 'Shared an activity: ${activity.title}',
      messageType: MessageType.activityShare,
      metadata: metadata,
    );
  }

  // Get messages for a conversation with automatic read status management
  Stream<List<ChatMessage>> getMessages(String conversationId) {
    final participants = _getConversationParticipants(conversationId);
    if (participants.length != 2) return Stream.value([]);

    // Create a more efficient query by using conversationId field
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .asyncMap((snapshot) async {
          final messages = <ChatMessage>[];

          // Decrypt and process each message
          for (final doc in snapshot.docs) {
            final data = doc.data();
            String? decryptedContent;

            // Try to decrypt if message is encrypted
            if (data['encryptedContent'] != null) {
              try {
                final encryptedMessage = EncryptedMessage(
                  encryptedContent: data['encryptedContent'] as String,
                  iv: data['iv'] as String,
                  signature: data['signature'] as String,
                );

                decryptedContent = await _encryptionService.decryptMessage(
                  encryptedMessage,
                  conversationId,
                );
              } catch (e) {
                debugPrint('⚠️ Failed to decrypt message ${doc.id}: $e');
                decryptedContent = '[Decryption Failed]';
              }
            }

            messages.add(ChatMessage.fromFirestore(doc, decryptedContent));
          }

          // Automatically mark messages as read when they're loaded (only for received messages)
          await _autoMarkNewMessagesAsRead(conversationId, messages);

          // Reverse the list so oldest messages are first (newest at bottom)
          return messages.reversed.toList();
        });
  }

  // Enhanced message stream that provides real-time read receipts for senders
  Stream<List<ChatMessage>> getMessagesWithReadReceipts(String conversationId) {
    final participants = _getConversationParticipants(conversationId);
    if (participants.length != 2) return Stream.value([]);

    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .asyncMap((snapshot) async {
          final messages = <ChatMessage>[];

          // Decrypt and process each message
          for (final doc in snapshot.docs) {
            final data = doc.data();
            String? decryptedContent;

            // Try to decrypt if message is encrypted
            if (data['encryptedContent'] != null) {
              try {
                final encryptedMessage = EncryptedMessage(
                  encryptedContent: data['encryptedContent'] as String,
                  iv: data['iv'] as String,
                  signature: data['signature'] as String,
                );

                decryptedContent = await _encryptionService.decryptMessage(
                  encryptedMessage,
                  conversationId,
                );
              } catch (e) {
                debugPrint('⚠️ Failed to decrypt message ${doc.id}: $e');
                decryptedContent = '[Decryption Failed]';
              }
            }

            messages.add(ChatMessage.fromFirestore(doc, decryptedContent));
          }

          // Auto-mark received messages as read
          await _autoMarkNewMessagesAsRead(conversationId, messages);

          // Return messages with current read status (real-time updates)
          return messages.reversed.toList();
        });
  }

  // Automatically mark new messages as read when viewing the chat
  Future<void> _autoMarkNewMessagesAsRead(
    String conversationId,
    List<ChatMessage> messages,
  ) async {
    if (currentUserId == null) return;

    try {
      final unreadMessages = messages
          .where(
            (message) => message.receiverId == currentUserId && !message.isRead,
          )
          .toList();

      if (unreadMessages.isNotEmpty) {
        debugPrint('📖 Auto-marking ${unreadMessages.length} messages as read');

        final batch = _firestore.batch();

        // Mark individual messages as read
        for (final message in unreadMessages) {
          final messageRef = _firestore
              .collection('messages')
              .doc(message.messageId);
          batch.update(messageRef, {'isRead': true});
        }

        // Update conversation unread count
        final conversationRef = _firestore
            .collection('conversations')
            .doc(conversationId);
        batch.update(conversationRef, {'unreadCounts.$currentUserId': 0});

        await batch.commit();
        debugPrint('✅ Auto-marked messages as read successfully');
      }
    } catch (e) {
      debugPrint('❌ Failed to auto-mark messages as read: $e');
    }
  }

  // Get user's conversations
  Stream<List<ChatConversation>> getUserConversations() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatConversation.fromFirestore(doc))
              .toList(),
        );
  }

  // Mark messages as read (call this when user enters chat screen)
  Future<void> markMessagesAsRead(String conversationId) async {
    if (currentUserId == null) return;

    try {
      debugPrint(
        '📖 Marking all messages as read for conversation: $conversationId',
      );

      final batch = _firestore.batch();

      // Update conversation unread count
      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);
      batch.update(conversationRef, {'unreadCounts.$currentUserId': 0});

      // Mark individual messages as read
      final unreadMessages = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      debugPrint('✅ Marked ${unreadMessages.docs.length} messages as read');
    } catch (e) {
      debugPrint('❌ Failed to mark messages as read: $e');
    }
  }

  // Call this when user enters a chat screen for immediate read status update
  Future<void> enterChatScreen(String conversationId) async {
    await markMessagesAsRead(conversationId);
  }

  // Call this method periodically or on user activity to keep read status current
  Future<void> refreshReadStatus(String conversationId) async {
    await markMessagesAsRead(conversationId);
  }

  // Get total unread count for user
  Stream<int> getTotalUnreadCount() {
    if (currentUserId == null) return Stream.value(0);

    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          int totalUnread = 0;
          for (final doc in snapshot.docs) {
            final conversation = ChatConversation.fromFirestore(doc);
            totalUnread += conversation.getUnreadCount(currentUserId!);
          }
          return totalUnread;
        });
  }

  // Helper methods
  List<String> _getConversationParticipants(String conversationId) {
    final parts = conversationId.split('_');
    return parts.length == 2 ? parts : [];
  }

  bool _belongsToConversation(ChatMessage message, String conversationId) {
    final participants = _getConversationParticipants(conversationId);
    return participants.contains(message.senderId) &&
        participants.contains(message.receiverId);
  }

  // Delete conversation (optional)
  Future<void> deleteConversation(String conversationId) async {
    final batch = _firestore.batch();

    // Delete conversation document
    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);
    batch.delete(conversationRef);

    // Delete all messages in conversation
    final messages = await _firestore
        .collection('messages')
        .where(
          'senderId',
          whereIn: _getConversationParticipants(conversationId),
        )
        .where(
          'receiverId',
          whereIn: _getConversationParticipants(conversationId),
        )
        .get();

    for (final doc in messages.docs) {
      final message = ChatMessage.fromFirestore(doc);
      if (_belongsToConversation(message, conversationId)) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }

  // Search messages (optional)
  Future<List<ChatMessage>> searchMessages(
    String query, {
    String? conversationId,
  }) async {
    Query messagesQuery = _firestore.collection('messages');

    if (conversationId != null) {
      final participants = _getConversationParticipants(conversationId);
      messagesQuery = messagesQuery
          .where('senderId', whereIn: participants)
          .where('receiverId', whereIn: participants);
    }

    final results = await messagesQuery
        .where('content', isGreaterThanOrEqualTo: query)
        .where('content', isLessThanOrEqualTo: '$query\uf8ff')
        .orderBy('content')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    return results.docs
        .map((doc) => ChatMessage.fromFirestore(doc))
        .where(
          (message) =>
              conversationId == null ||
              _belongsToConversation(message, conversationId),
        )
        .toList();
  }

  // Mark conversation as unread
  Future<void> markConversationAsUnread(String conversationId) async {
    if (currentUserId == null) return;

    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);
    await conversationRef.update({
      'unreadCounts.$currentUserId': FieldValue.increment(1),
    });
  }

  // Archive conversation
  Future<void> archiveConversation(String conversationId) async {
    if (currentUserId == null) return;

    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);
    await conversationRef.update({
      'archived.$currentUserId': true,
      'archivedAt.$currentUserId': FieldValue.serverTimestamp(),
    });
  }

  // Unarchive conversation
  Future<void> unarchiveConversation(String conversationId) async {
    if (currentUserId == null) return;

    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);
    await conversationRef.update({
      'archived.$currentUserId': FieldValue.delete(),
      'archivedAt.$currentUserId': FieldValue.delete(),
    });
  }

  // Refresh participant data for a conversation
  Future<void> refreshParticipantData(String conversationId) async {
    final participants = _getConversationParticipants(conversationId);
    if (participants.isEmpty) return;

    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);
    final participantNames = <String, String>{};
    final participantPhotos = <String, String?>{};

    for (final userId in participants) {
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          participantNames[userId] = userData['displayName'] ?? 'Unknown User';
          participantPhotos[userId] = userData['photoURL'];
        } else {
          participantNames[userId] = 'Unknown User';
          participantPhotos[userId] = null;
        }
      } catch (e) {
        // If we can't fetch user data, use defaults
        participantNames[userId] = 'Unknown User';
        participantPhotos[userId] = null;
      }
    }

    await conversationRef.update({
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
    });
  }
}
