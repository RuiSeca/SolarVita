import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/chat/chat_service.dart';
import '../../models/chat/chat_conversation.dart';
import '../../models/chat/chat_message.dart';

// Chat Service Provider
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

// User Conversations Stream Provider
final userConversationsProvider =
    StreamProvider.autoDispose<List<ChatConversation>>((ref) {
      final chatService = ref.watch(chatServiceProvider);
      return chatService.getUserConversations();
    });

// Specific Conversation Messages Provider
final conversationMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, conversationId) {
      final chatService = ref.watch(chatServiceProvider);
      return chatService.getMessages(conversationId);
    });

// Total Unread Count Provider
final totalUnreadCountProvider = StreamProvider.autoDispose<int>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getTotalUnreadCount();
});

// Chat Search Results Provider
final chatSearchProvider = FutureProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, query) {
      final chatService = ref.watch(chatServiceProvider);
      return chatService.searchMessages(query);
    });

// Selected Conversation State Provider
final selectedConversationProvider = StateProvider<String?>((ref) => null);

// Message Input State Provider
final messageInputProvider = StateProvider<String>((ref) => '');

// Chat UI State Provider
class ChatUIState {
  final bool isLoading;
  final String? error;
  final bool isTyping;

  const ChatUIState({
    this.isLoading = false,
    this.error,
    this.isTyping = false,
  });

  ChatUIState copyWith({bool? isLoading, String? error, bool? isTyping}) {
    return ChatUIState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

final chatUIStateProvider =
    StateNotifierProvider<ChatUIStateNotifier, ChatUIState>((ref) {
      return ChatUIStateNotifier();
    });

class ChatUIStateNotifier extends StateNotifier<ChatUIState> {
  ChatUIStateNotifier() : super(const ChatUIState());

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void setTyping(bool typing) {
    state = state.copyWith(isTyping: typing);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Chat Actions Provider
final chatActionsProvider = Provider<ChatActions>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  final chatUINotifier = ref.watch(chatUIStateProvider.notifier);

  return ChatActions(chatService, chatUINotifier);
});

class ChatActions {
  final ChatService _chatService;
  final ChatUIStateNotifier _uiNotifier;

  ChatActions(this._chatService, this._uiNotifier);

  Future<String?> getOrCreateConversation(String otherUserId) async {
    try {
      _uiNotifier.setLoading(true);
      _uiNotifier.clearError();

      final conversationId = await _chatService.getOrCreateConversation(
        otherUserId,
      );
      return conversationId;
    } catch (e) {
      _uiNotifier.setError('Failed to create conversation: $e');
      return null;
    } finally {
      _uiNotifier.setLoading(false);
    }
  }

  Future<bool> sendMessage(
    String conversationId,
    String receiverId,
    String content,
  ) async {
    try {
      _uiNotifier.setLoading(true);
      _uiNotifier.clearError();

      await _chatService.sendMessage(
        conversationId: conversationId,
        receiverId: receiverId,
        content: content,
      );
      return true;
    } catch (e) {
      _uiNotifier.setError('Failed to send message: $e');
      return false;
    } finally {
      _uiNotifier.setLoading(false);
    }
  }

  Future<bool> shareActivity(
    String conversationId,
    String receiverId,
    activity,
  ) async {
    try {
      _uiNotifier.setLoading(true);
      _uiNotifier.clearError();

      await _chatService.sendActivityShare(
        conversationId: conversationId,
        receiverId: receiverId,
        activity: activity,
      );
      return true;
    } catch (e) {
      _uiNotifier.setError('Failed to share activity: $e');
      return false;
    } finally {
      _uiNotifier.setLoading(false);
    }
  }

  Future<bool> markAsRead(String conversationId) async {
    try {
      await _chatService.markMessagesAsRead(conversationId);
      return true;
    } catch (e) {
      _uiNotifier.setError('Failed to mark as read: $e');
      return false;
    }
  }

  Future<bool> deleteConversation(String conversationId) async {
    try {
      _uiNotifier.setLoading(true);
      _uiNotifier.clearError();

      await _chatService.deleteConversation(conversationId);
      return true;
    } catch (e) {
      _uiNotifier.setError('Failed to delete conversation: $e');
      return false;
    } finally {
      _uiNotifier.setLoading(false);
    }
  }

  Future<bool> markAsUnread(String conversationId) async {
    try {
      await _chatService.markConversationAsUnread(conversationId);
      return true;
    } catch (e) {
      _uiNotifier.setError('Failed to mark as unread: $e');
      return false;
    }
  }

  Future<bool> archiveConversation(String conversationId) async {
    try {
      await _chatService.archiveConversation(conversationId);
      return true;
    } catch (e) {
      _uiNotifier.setError('Failed to archive conversation: $e');
      return false;
    }
  }

  Future<bool> unarchiveConversation(String conversationId) async {
    try {
      await _chatService.unarchiveConversation(conversationId);
      return true;
    } catch (e) {
      _uiNotifier.setError('Failed to unarchive conversation: $e');
      return false;
    }
  }

  Future<bool> refreshParticipantData(String conversationId) async {
    try {
      await _chatService.refreshParticipantData(conversationId);
      return true;
    } catch (e) {
      _uiNotifier.setError('Failed to refresh participant data: $e');
      return false;
    }
  }
}
