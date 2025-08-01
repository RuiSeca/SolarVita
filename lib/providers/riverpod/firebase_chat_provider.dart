// lib/providers/riverpod/firebase_chat_provider.dart

import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../services/database/firebase_chat_service.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/chat_conversation.dart';
import 'offline_cache_provider.dart';

part 'firebase_chat_provider.g.dart';

// FIREBASE SERVICE PROVIDER

@riverpod
FirebaseChatService firebaseChatService(Ref ref) {
  return FirebaseChatService();
}

// STREAM PROVIDERS

@riverpod
Stream<List<ChatConversation>> userConversations(Ref ref) {
  final service = ref.watch(firebaseChatServiceProvider);

  return service
      .getUserConversations()
      .asyncMap((conversations) async {
        // Cache conversations when online
        if (ref.read(connectivityStatusProvider)) {
          await ref
              .read(cacheManagerProvider.notifier)
              .cacheChatConversations(conversations);
        }
        return conversations;
      })
      .handleError((error) async {
        // Fallback to cached data on error
        final cachedConversations = await ref.read(
          cachedChatConversationsProvider.future,
        );
        return cachedConversations ?? <ChatConversation>[];
      });
}

@riverpod
Stream<List<ChatMessage>> conversationMessages(
  Ref ref,
  String conversationId, {
  int limit = 50,
}) {
  final service = ref.watch(firebaseChatServiceProvider);

  return service
      .getConversationMessages(conversationId, limit: limit)
      .asyncMap((messages) async {
        // Cache messages when online
        if (ref.read(connectivityStatusProvider)) {
          await ref
              .read(cacheManagerProvider.notifier)
              .cacheChatMessages(conversationId, messages);
        }
        return messages;
      })
      .handleError((error) async {
        // Fallback to cached data on error
        final cachedMessages = await ref.read(
          cachedChatMessagesProvider(conversationId).future,
        );
        return cachedMessages ?? <ChatMessage>[];
      });
}

@riverpod
Stream<int> totalUnreadCount(Ref ref) {
  final service = ref.watch(firebaseChatServiceProvider);
  return service.getTotalUnreadCount();
}

@riverpod
Stream<List<String>> typingUsers(Ref ref, String conversationId) {
  final service = ref.watch(firebaseChatServiceProvider);
  return service.getTypingUsers(conversationId);
}

// FUTURE PROVIDERS

@riverpod
Future<ChatConversation> getOrCreateConversation(
  Ref ref, {
  required String otherUserId,
  bool isGroup = false,
  String? groupName,
  List<String>? additionalParticipants,
}) async {
  final service = ref.watch(firebaseChatServiceProvider);
  return service.getOrCreateConversation(
    otherUserId: otherUserId,
    isGroup: isGroup,
    groupName: groupName,
    additionalParticipants: additionalParticipants,
  );
}

@riverpod
Future<List<ChatMessage>> searchMessages(
  Ref ref, {
  required String conversationId,
  required String query,
  int limit = 20,
}) async {
  if (query.trim().isEmpty) return [];

  final service = ref.watch(firebaseChatServiceProvider);
  return service.searchMessages(
    conversationId: conversationId,
    query: query,
    limit: limit,
  );
}

// STATE MANAGEMENT PROVIDERS

/// Chat Actions State Notifier
@riverpod
class ChatActions extends _$ChatActions {
  final _logger = Logger('ChatActions');

  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<ChatMessage> sendTextMessage({
    required String conversationId,
    required String content,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(firebaseChatServiceProvider);
      final isOnline = ref.read(connectivityStatusProvider);

      if (isOnline) {
        final message = await service.sendMessage(
          conversationId: conversationId,
          content: content,
          replyToMessageId: replyToMessageId,
          metadata: metadata,
        );

        state = const AsyncValue.data(null);
        return message;
      } else {
        // Queue message for offline sync
        final messageData = {
          'conversationId': conversationId,
          'content': content,
          'replyToMessageId': replyToMessageId,
          'metadata': metadata,
          'messageType': 'text',
        };

        await ref
            .read(offlineSyncManagerProvider.notifier)
            .queueMessageSend(messageData);

        // Create a temporary message for UI
        final tempMessage = ChatMessage(
          messageId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'current_user', // This should be from auth
          receiverId: 'other_user',
          conversationId: conversationId,
          content: content,
          timestamp: DateTime.now(),
          senderName: 'You',
          status: MessageStatus.sending,
          replyToMessageId: replyToMessageId,
          metadata: metadata,
        );

        state = const AsyncValue.data(null);
        return tempMessage;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<ChatMessage> sendMediaMessage({
    required String conversationId,
    required List<File> mediaFiles,
    required MessageType messageType,
    String? content,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(firebaseChatServiceProvider);
      final message = await service.sendMediaMessage(
        conversationId: conversationId,
        mediaFiles: mediaFiles,
        messageType: messageType,
        content: content,
        replyToMessageId: replyToMessageId,
        metadata: metadata,
      );

      state = const AsyncValue.data(null);
      return message;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<ChatMessage> sendLocationMessage({
    required String conversationId,
    required double latitude,
    required double longitude,
    String? locationName,
    String? replyToMessageId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(firebaseChatServiceProvider);
      final message = await service.sendLocationMessage(
        conversationId: conversationId,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        replyToMessageId: replyToMessageId,
      );

      state = const AsyncValue.data(null);
      return message;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<ChatMessage> sendWorkoutMessage({
    required String conversationId,
    required Map<String, dynamic> workoutData,
    String? replyToMessageId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(firebaseChatServiceProvider);
      final message = await service.sendWorkoutMessage(
        conversationId: conversationId,
        workoutData: workoutData,
        replyToMessageId: replyToMessageId,
      );

      state = const AsyncValue.data(null);
      return message;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<ChatMessage> sendAchievementMessage({
    required String conversationId,
    required Map<String, dynamic> achievementData,
    String? replyToMessageId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(firebaseChatServiceProvider);
      final message = await service.sendAchievementMessage(
        conversationId: conversationId,
        achievementData: achievementData,
        replyToMessageId: replyToMessageId,
      );

      state = const AsyncValue.data(null);
      return message;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> markMessageAsRead(
    String conversationId,
    String messageId,
  ) async {
    try {
      final service = ref.read(firebaseChatServiceProvider);
      await service.markMessageAsRead(conversationId, messageId);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> markConversationAsRead(String conversationId) async {
    try {
      final service = ref.read(firebaseChatServiceProvider);
      await service.markConversationAsRead(conversationId);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<ChatMessage> editMessage({
    required String conversationId,
    required String messageId,
    required String newContent,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(firebaseChatServiceProvider);
      final message = await service.editMessage(
        conversationId: conversationId,
        messageId: messageId,
        newContent: newContent,
      );

      state = const AsyncValue.data(null);
      return message;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
    bool deleteForEveryone = false,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(firebaseChatServiceProvider);
      await service.deleteMessage(
        conversationId: conversationId,
        messageId: messageId,
        deleteForEveryone: deleteForEveryone,
      );

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(firebaseChatServiceProvider);
      await service.deleteConversation(conversationId);

      state = const AsyncValue.data(null);

      // Invalidate conversations list
      ref.invalidate(userConversationsProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateTypingStatus({
    required String conversationId,
    required bool isTyping,
  }) async {
    try {
      final service = ref.read(firebaseChatServiceProvider);
      await service.updateTypingStatus(
        conversationId: conversationId,
        isTyping: isTyping,
      );
    } catch (error) {
      // Typing status errors are not critical
      _logger.fine('Error updating typing status: $error');
    }
  }
}

// UTILITY PROVIDERS

/// Active conversations count
@riverpod
Future<int> activeConversationsCount(Ref ref) async {
  final conversationsAsync = ref.watch(userConversationsProvider);
  return conversationsAsync.when(
    data: (conversations) => conversations.where((c) => c.isActive).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
}

/// Get conversation by ID
@riverpod
Future<ChatConversation?> conversationById(
  Ref ref,
  String conversationId,
) async {
  final conversationsAsync = ref.watch(userConversationsProvider);
  return conversationsAsync.when(
    data: (conversations) => conversations
        .where((c) => c.conversationId == conversationId)
        .firstOrNull,
    loading: () => null,
    error: (_, __) => null,
  );
}

/// Get last message for conversation
@riverpod
Future<ChatMessage?> lastMessage(Ref ref, String conversationId) async {
  final messagesAsync = ref.watch(
    conversationMessagesProvider(conversationId, limit: 1),
  );
  return messagesAsync.when(
    data: (messages) => messages.isNotEmpty ? messages.first : null,
    loading: () => null,
    error: (_, __) => null,
  );
}

/// Check if user has unread messages
@riverpod
Future<bool> hasUnreadMessages(Ref ref) async {
  final unreadCount = await ref.watch(totalUnreadCountProvider.future);
  return unreadCount > 0;
}

/// Get conversation participants info
@riverpod
Future<List<Map<String, String>>> conversationParticipants(
  Ref ref,
  String conversationId,
) async {
  final conversation = await ref.watch(
    conversationByIdProvider(conversationId).future,
  );
  if (conversation == null) return [];

  return conversation.participantData.entries
      .map(
        (entry) => {
          'id': entry.key,
          'name': (entry.value['displayName'] as String?) ?? 'Unknown User',
          'avatar': (entry.value['photoURL'] as String?) ?? '',
          'username': (entry.value['username'] as String?) ?? '',
        },
      )
      .toList();
}

/// Typing indicator text
@riverpod
Future<String> typingIndicatorText(Ref ref, String conversationId) async {
  final typingUsers = await ref.watch(
    typingUsersProvider(conversationId).future,
  );
  final participants = await ref.watch(
    conversationParticipantsProvider(conversationId).future,
  );

  if (typingUsers.isEmpty) return '';

  final typingNames = typingUsers
      .map(
        (userId) => participants.firstWhere(
          (p) => p['id'] == userId,
          orElse: () => {'name': 'Someone'},
        )['name']!,
      )
      .toList();

  if (typingNames.isEmpty) return '';

  if (typingNames.length == 1) {
    return '${typingNames.first} is typing...';
  } else if (typingNames.length == 2) {
    return '${typingNames.first} and ${typingNames.last} are typing...';
  } else {
    return 'Multiple people are typing...';
  }
}

/// Message search results
@riverpod
class MessageSearchResults extends _$MessageSearchResults {
  @override
  AsyncValue<List<ChatMessage>> build() {
    return const AsyncValue.data([]);
  }

  Future<void> searchInConversation({
    required String conversationId,
    required String query,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final results = await ref.read(
        searchMessagesProvider(
          conversationId: conversationId,
          query: query,
          limit: limit,
        ).future,
      );

      state = AsyncValue.data(results);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearResults() {
    state = const AsyncValue.data([]);
  }
}

/// Auto-mark messages as read when conversation is active
@riverpod
class ConversationReadTracker extends _$ConversationReadTracker {
  @override
  void build() {
    // Track when user views conversations
  }

  void markConversationAsViewed(String conversationId) {
    // Auto-mark conversation as read after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      ref
          .read(chatActionsProvider.notifier)
          .markConversationAsRead(conversationId);
    });
  }
}

extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
