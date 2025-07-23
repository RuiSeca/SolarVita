import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  activityShare,
  image,
}

class ChatMessage {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String conversationId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType messageType;
  final Map<String, dynamic>? metadata; // For activity shares, image data, etc.

  const ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.conversationId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.messageType = MessageType.text,
    this.metadata,
  });

  // Create from Firestore document
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatMessage(
      messageId: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      conversationId: data['conversationId'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      messageType: MessageType.values.firstWhere(
        (type) => type.name == data['messageType'],
        orElse: () => MessageType.text,
      ),
      metadata: data['metadata'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'conversationId': conversationId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'messageType': messageType.name,
      'metadata': metadata,
    };
  }

  // Copy with modifications
  ChatMessage copyWith({
    String? messageId,
    String? senderId,
    String? receiverId,
    String? conversationId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    MessageType? messageType,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      messageType: messageType ?? this.messageType,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isActivityShare => messageType == MessageType.activityShare;
  bool get isImage => messageType == MessageType.image;
  
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays == 0) {
      // Today - show time
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final minute = timestamp.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[timestamp.weekday - 1];
    } else {
      // Older - show date
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          messageId == other.messageId;

  @override
  int get hashCode => messageId.hashCode;

  @override
  String toString() {
    return 'ChatMessage{messageId: $messageId, senderId: $senderId, content: $content, timestamp: $timestamp}';
  }
}