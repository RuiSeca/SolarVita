import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../models/social_activity.dart';
import 'chat_notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatNotificationService _notificationService = ChatNotificationService();

  String? get currentUserId => _auth.currentUser?.uid;

  // Get or create conversation between two users
  Future<String> getOrCreateConversation(String otherUserId) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final participants = [currentUserId!, otherUserId]..sort();
    final conversationId = '${participants[0]}_${participants[1]}';
    
    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    final conversationDoc = await conversationRef.get();
    
    if (!conversationDoc.exists) {
      // Fetch participant information
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
      
      // Create new conversation with participant info
      await conversationRef.set({
        'participantIds': participants,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts': {
          participants[0]: 0,
          participants[1]: 0,
        },
        'participantNames': participantNames,
        'participantPhotos': participantPhotos,
      });
    } else {
      // Update participant info if conversation exists but names/photos are missing
      final data = conversationDoc.data()!;
      final participantNames = Map<String, String>.from(data['participantNames'] ?? {});
      final participantPhotos = Map<String, String?>.from(data['participantPhotos'] ?? {});
      
      bool needsUpdate = false;
      
      for (final userId in participants) {
        if (!participantNames.containsKey(userId) || participantNames[userId] == null) {
          try {
            final userDoc = await _firestore.collection('users').doc(userId).get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              participantNames[userId] = userData['displayName'] ?? 'Unknown User';
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
    
    // Add message to messages collection
    final messageRef = _firestore.collection('messages').doc();
    final message = ChatMessage(
      messageId: messageRef.id,
      senderId: currentUserId!,
      receiverId: receiverId,
      conversationId: conversationId,
      content: content,
      timestamp: DateTime.now(),
      messageType: messageType,
      metadata: metadata,
    );
    
    batch.set(messageRef, message.toFirestore());
    
    // Update conversation
    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    batch.update(conversationRef, {
      'lastMessage': content,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts.$receiverId': FieldValue.increment(1),
    });
    
    await batch.commit();
    
    // Send notification to the receiver
    try {
      final currentUserDoc = await _firestore.collection('users').doc(currentUserId!).get();
      final senderName = currentUserDoc.exists 
          ? (currentUserDoc.data()?['displayName'] ?? 'Someone')
          : 'Someone';
      
      await _notificationService.sendMessageNotification(
        receiverId: receiverId,
        senderName: senderName,
        messageContent: content.length > 50 ? '${content.substring(0, 50)}...' : content,
        conversationId: conversationId,
      );
    } catch (e) {
      // Don't fail the message sending if notification fails
      // Silent failure for notification issues
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

  // Get messages for a conversation
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
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
          
          // Reverse the list so oldest messages are first (newest at bottom)
          return messages.reversed.toList();
        });
  }

  // Get user's conversations
  Stream<List<ChatConversation>> getUserConversations() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatConversation.fromFirestore(doc))
            .toList());
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    if (currentUserId == null) return;

    final batch = _firestore.batch();
    
    // Update conversation unread count
    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    batch.update(conversationRef, {
      'unreadCounts.$currentUserId': 0,
    });
    
    // Mark individual messages as read
    final unreadMessages = await _firestore
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();
    
    for (final doc in unreadMessages.docs) {
      final message = ChatMessage.fromFirestore(doc);
      if (_belongsToConversation(message, conversationId)) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    
    await batch.commit();
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
    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    batch.delete(conversationRef);
    
    // Delete all messages in conversation
    final messages = await _firestore
        .collection('messages')
        .where('senderId', whereIn: _getConversationParticipants(conversationId))
        .where('receiverId', whereIn: _getConversationParticipants(conversationId))
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
  Future<List<ChatMessage>> searchMessages(String query, {String? conversationId}) async {
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
        .where((message) => conversationId == null || _belongsToConversation(message, conversationId))
        .toList();
  }

  // Mark conversation as unread
  Future<void> markConversationAsUnread(String conversationId) async {
    if (currentUserId == null) return;

    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    await conversationRef.update({
      'unreadCounts.$currentUserId': FieldValue.increment(1),
    });
  }

  // Archive conversation
  Future<void> archiveConversation(String conversationId) async {
    if (currentUserId == null) return;

    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    await conversationRef.update({
      'archived.$currentUserId': true,
      'archivedAt.$currentUserId': FieldValue.serverTimestamp(),
    });
  }

  // Unarchive conversation
  Future<void> unarchiveConversation(String conversationId) async {
    if (currentUserId == null) return;

    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    await conversationRef.update({
      'archived.$currentUserId': FieldValue.delete(),
      'archivedAt.$currentUserId': FieldValue.delete(),
    });
  }

  // Refresh participant data for a conversation
  Future<void> refreshParticipantData(String conversationId) async {
    final participants = _getConversationParticipants(conversationId);
    if (participants.isEmpty) return;

    final conversationRef = _firestore.collection('conversations').doc(conversationId);
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