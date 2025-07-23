import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversation {
  final String conversationId;
  final List<String> participantIds;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts;
  final Map<String, String> participantNames;
  final Map<String, String?> participantPhotos;

  const ChatConversation({
    required this.conversationId,
    required this.participantIds,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCounts,
    this.participantNames = const {},
    this.participantPhotos = const {},
  });

  // Create from Firestore document
  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatConversation(
      conversationId: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
      participantPhotos: Map<String, String?>.from(data['participantPhotos'] ?? {}),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCounts': unreadCounts,
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
    };
  }

  // Copy with modifications
  ChatConversation copyWith({
    String? conversationId,
    List<String>? participantIds,
    String? lastMessage,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCounts,
    Map<String, String>? participantNames,
    Map<String, String?>? participantPhotos,
  }) {
    return ChatConversation(
      conversationId: conversationId ?? this.conversationId,
      participantIds: participantIds ?? this.participantIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      participantNames: participantNames ?? this.participantNames,
      participantPhotos: participantPhotos ?? this.participantPhotos,
    );
  }

  // Helper methods
  String getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  String getOtherParticipantName(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantNames[otherId] ?? 'Unknown User';
  }

  String? getOtherParticipantPhoto(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantPhotos[otherId];
  }

  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  bool hasUnreadMessages(String userId) {
    return getUnreadCount(userId) > 0;
  }

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(lastMessageTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastMessageTime.day}/${lastMessageTime.month}/${lastMessageTime.year}';
    }
  }

  String getLastMessageTimeAgo() {
    return getTimeAgo();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatConversation &&
          runtimeType == other.runtimeType &&
          conversationId == other.conversationId;

  @override
  int get hashCode => conversationId.hashCode;

  @override
  String toString() {
    return 'ChatConversation{conversationId: $conversationId, participantIds: $participantIds, lastMessage: $lastMessage}';
  }
}