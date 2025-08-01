import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversation {
  final String conversationId;
  final List<String> participantIds;
  final Map<String, dynamic> participantData;
  final Map<String, String>? _participantNames;
  final Map<String, String?>? _participantPhotos;
  final String lastMessage;
  final DateTime lastMessageTime;
  final DateTime createdAt;
  final bool isGroup;
  final String? groupName;
  final String? groupAvatarUrl;
  final String? groupDescription;
  final List<String> adminIds;
  final Map<String, int> unreadCounts;
  final Map<String, dynamic> settings;
  final bool isActive;

  const ChatConversation({
    required this.conversationId,
    required this.participantIds,
    required this.participantData,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.createdAt,
    required this.isGroup,
    required this.unreadCounts,
    Map<String, String>? participantNames,
    Map<String, String?>? participantPhotos,
    this.groupName,
    this.groupAvatarUrl,
    this.groupDescription,
    this.adminIds = const [],
    this.settings = const {},
    this.isActive = true,
  }) : _participantNames = participantNames,
       _participantPhotos = participantPhotos;

  // Create from Firestore document
  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatConversation(
      conversationId: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantData: Map<String, dynamic>.from(data['participantData'] ?? {}),
      participantNames: data['participantNames'] != null 
          ? Map<String, String>.from(data['participantNames']) 
          : null,
      participantPhotos: data['participantPhotos'] != null 
          ? Map<String, String?>.from(data['participantPhotos']) 
          : null,
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isGroup: data['isGroup'] ?? false,
      groupName: data['groupName'],
      groupAvatarUrl: data['groupAvatarUrl'],
      groupDescription: data['groupDescription'],
      adminIds: List<String>.from(data['adminIds'] ?? []),
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      isActive: data['isActive'] ?? true,
    );
  }

  // Create from Map for cached data
  factory ChatConversation.fromMap(Map<String, dynamic> data) {
    return ChatConversation(
      conversationId: data['conversationId'] ?? '',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantData: Map<String, dynamic>.from(data['participantData'] ?? {}),
      participantNames: data['participantNames'] != null 
          ? Map<String, String>.from(data['participantNames']) 
          : null,
      participantPhotos: data['participantPhotos'] != null 
          ? Map<String, String?>.from(data['participantPhotos']) 
          : null,
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime'] is String 
          ? DateTime.parse(data['lastMessageTime'])
          : (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: data['createdAt'] is String 
          ? DateTime.parse(data['createdAt'])
          : (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isGroup: data['isGroup'] ?? false,
      groupName: data['groupName'],
      groupAvatarUrl: data['groupAvatarUrl'],
      groupDescription: data['groupDescription'],
      adminIds: List<String>.from(data['adminIds'] ?? []),
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> result = {
      'participantIds': participantIds,
      'participantData': participantData,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'createdAt': Timestamp.fromDate(createdAt),
      'isGroup': isGroup,
      'groupName': groupName,
      'groupAvatarUrl': groupAvatarUrl,
      'groupDescription': groupDescription,
      'adminIds': adminIds,
      'unreadCounts': unreadCounts,
      'settings': settings,
      'isActive': isActive,
    };
    
    if (_participantNames != null) {
      result['participantNames'] = _participantNames;
    }
    if (_participantPhotos != null) {
      result['participantPhotos'] = _participantPhotos;
    }
    
    return result;
  }

  // Convert to Map for caching
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> result = {
      'conversationId': conversationId,
      'participantIds': participantIds,
      'participantData': participantData,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isGroup': isGroup,
      'groupName': groupName,
      'groupAvatarUrl': groupAvatarUrl,
      'groupDescription': groupDescription,
      'adminIds': adminIds,
      'unreadCounts': unreadCounts,
      'settings': settings,
      'isActive': isActive,
    };
    
    if (_participantNames != null) {
      result['participantNames'] = _participantNames;
    }
    if (_participantPhotos != null) {
      result['participantPhotos'] = _participantPhotos;
    }
    
    return result;
  }

  // Copy with modifications
  ChatConversation copyWith({
    String? conversationId,
    List<String>? participantIds,
    Map<String, dynamic>? participantData,
    Map<String, String>? participantNames,
    Map<String, String?>? participantPhotos,
    String? lastMessage,
    DateTime? lastMessageTime,
    DateTime? createdAt,
    bool? isGroup,
    String? groupName,
    String? groupAvatarUrl,
    String? groupDescription,
    List<String>? adminIds,
    Map<String, int>? unreadCounts,
    Map<String, dynamic>? settings,
    bool? isActive,
  }) {
    return ChatConversation(
      conversationId: conversationId ?? this.conversationId,
      participantIds: participantIds ?? this.participantIds,
      participantData: participantData ?? this.participantData,
      participantNames: participantNames ?? _participantNames,
      participantPhotos: participantPhotos ?? _participantPhotos,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      createdAt: createdAt ?? this.createdAt,
      isGroup: isGroup ?? this.isGroup,
      groupName: groupName ?? this.groupName,
      groupAvatarUrl: groupAvatarUrl ?? this.groupAvatarUrl,
      groupDescription: groupDescription ?? this.groupDescription,
      adminIds: adminIds ?? this.adminIds,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      settings: settings ?? this.settings,
      isActive: isActive ?? this.isActive,
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
    if (isGroup && groupName != null) {
      return groupName!;
    }
    final otherId = getOtherParticipantId(currentUserId);
    
    // First check the dedicated participantNames field (new format)
    if (_participantNames != null && _participantNames.containsKey(otherId)) {
      final name = _participantNames[otherId];
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    
    // Fall back to participantData field (old format)
    final userData = participantData[otherId] as Map<String, dynamic>?;
    return userData?['displayName'] ?? 'Unknown User';
  }

  String? getOtherParticipantPhoto(String currentUserId) {
    if (isGroup && groupAvatarUrl != null) {
      return groupAvatarUrl;
    }
    final otherId = getOtherParticipantId(currentUserId);
    
    // First check the dedicated participantPhotos field (new format)
    if (_participantPhotos != null && _participantPhotos.containsKey(otherId)) {
      final photo = _participantPhotos[otherId];
      if (photo != null && photo.isNotEmpty) {
        return photo;
      }
    }
    
    // Fall back to participantData field (old format)
    final userData = participantData[otherId] as Map<String, dynamic>?;
    return userData?['photoURL'];
  }

  String getDisplayName(String currentUserId) {
    return getOtherParticipantName(currentUserId);
  }

  String? getDisplayPhoto(String currentUserId) {
    return getOtherParticipantPhoto(currentUserId);
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

  // Get participant names map
  Map<String, String> get participantNames {
    final Map<String, String> names = {};
    for (final participantId in participantIds) {
      final userData = participantData[participantId] as Map<String, dynamic>?;
      names[participantId] = userData?['displayName'] ?? 'Unknown User';
    }
    return names;
  }

  // Get participant photos map
  Map<String, String?> get participantPhotos {
    final Map<String, String?> photos = {};
    for (final participantId in participantIds) {
      final userData = participantData[participantId] as Map<String, dynamic>?;
      photos[participantId] = userData?['photoURL'];
    }
    return photos;
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