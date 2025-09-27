import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  activityShare,
  image,
  video,
  audio,
  file,
  location,
  workout,
  achievement,
  system,
  mealShare,
  workoutShare,
  ecoTip,
  challengeInvite,
  smartSuggestion,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
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
  final MessageStatus status;
  final DateTime? editedAt;
  final String? replyToMessageId;
  final List<String> mediaUrls;
  final bool isDeleted;
  final List<String> readBy;
  final String senderName;
  final String? senderAvatarUrl;
  final Map<String, dynamic>? metadata; // For activity shares, image data, etc.

  const ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.conversationId,
    required this.content,
    required this.timestamp,
    required this.senderName,
    this.isRead = false,
    this.messageType = MessageType.text,
    this.status = MessageStatus.sent,
    this.editedAt,
    this.replyToMessageId,
    this.mediaUrls = const [],
    this.isDeleted = false,
    this.readBy = const [],
    this.senderAvatarUrl,
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
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      senderName: data['senderName'] ?? '',
      isRead: data['isRead'] ?? false,
      messageType: MessageType.values.firstWhere(
        (type) => type.name == data['messageType'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      replyToMessageId: data['replyToMessageId'],
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      isDeleted: data['isDeleted'] ?? false,
      readBy: List<String>.from(data['readBy'] ?? []),
      senderAvatarUrl: data['senderAvatarUrl'],
      metadata: data['metadata'],
    );
  }

  // Create from Map for cached data
  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    return ChatMessage(
      messageId: data['messageId'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      conversationId: data['conversationId'] ?? '',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] is String 
          ? DateTime.parse(data['timestamp'])
          : (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      senderName: data['senderName'] ?? '',
      isRead: data['isRead'] ?? false,
      messageType: MessageType.values.firstWhere(
        (type) => type.name == data['messageType'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      editedAt: data['editedAt'] != null 
          ? (data['editedAt'] is String 
              ? DateTime.parse(data['editedAt'])
              : (data['editedAt'] as Timestamp?)?.toDate())
          : null,
      replyToMessageId: data['replyToMessageId'],
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      isDeleted: data['isDeleted'] ?? false,
      readBy: List<String>.from(data['readBy'] ?? []),
      senderAvatarUrl: data['senderAvatarUrl'],
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
      'senderName': senderName,
      'isRead': isRead,
      'messageType': messageType.name,
      'status': status.name,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'replyToMessageId': replyToMessageId,
      'mediaUrls': mediaUrls,
      'isDeleted': isDeleted,
      'readBy': readBy,
      'senderAvatarUrl': senderAvatarUrl,
      'metadata': metadata,
    };
  }

  // Convert to Map for caching
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'conversationId': conversationId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'senderName': senderName,
      'isRead': isRead,
      'messageType': messageType.name,
      'status': status.name,
      'editedAt': editedAt?.toIso8601String(),
      'replyToMessageId': replyToMessageId,
      'mediaUrls': mediaUrls,
      'isDeleted': isDeleted,
      'readBy': readBy,
      'senderAvatarUrl': senderAvatarUrl,
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
    String? senderName,
    bool? isRead,
    MessageType? messageType,
    MessageStatus? status,
    DateTime? editedAt,
    String? replyToMessageId,
    List<String>? mediaUrls,
    bool? isDeleted,
    List<String>? readBy,
    String? senderAvatarUrl,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      senderName: senderName ?? this.senderName,
      isRead: isRead ?? this.isRead,
      messageType: messageType ?? this.messageType,
      status: status ?? this.status,
      editedAt: editedAt ?? this.editedAt,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      isDeleted: isDeleted ?? this.isDeleted,
      readBy: readBy ?? this.readBy,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isActivityShare => messageType == MessageType.activityShare;
  bool get isImage => messageType == MessageType.image;
  bool get isVideo => messageType == MessageType.video;
  bool get isAudio => messageType == MessageType.audio;
  bool get isFile => messageType == MessageType.file;
  bool get isLocation => messageType == MessageType.location;
  bool get isWorkout => messageType == MessageType.workout;
  bool get isAchievement => messageType == MessageType.achievement;
  bool get isSystem => messageType == MessageType.system;
  bool get isMealShare => messageType == MessageType.mealShare;
  bool get isWorkoutShare => messageType == MessageType.workoutShare;
  bool get isEcoTip => messageType == MessageType.ecoTip;
  bool get isChallengeInvite => messageType == MessageType.challengeInvite;
  bool get isSmartSuggestion => messageType == MessageType.smartSuggestion;
  bool get hasMedia => mediaUrls.isNotEmpty;
  bool get isEdited => editedAt != null;
  bool get isReply => replyToMessageId != null;
  bool get isShareType => isMealShare || isWorkoutShare || isActivityShare;
  bool get isAutomatedMessage => isEcoTip || isSmartSuggestion;
  
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