// lib/providers/riverpod/chat_state_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/chat/chat_state_service.dart';

// Provider for the chat state service
final chatStateServiceProvider = Provider<ChatStateService>((ref) {
  return ChatStateService();
});

// Provider for the current active chat ID
final activeChatProvider = StateProvider<String?>((ref) => null);

// Provider for managing chat state with automatic cleanup
final chatStateNotifierProvider =
    StateNotifierProvider<ChatStateNotifier, ChatState>((ref) {
      return ChatStateNotifier(ref.read(chatStateServiceProvider));
    });

class ChatState {
  final String? activeChatId;
  final bool isActive;

  const ChatState({this.activeChatId, this.isActive = false});

  ChatState copyWith({String? activeChatId, bool? isActive}) {
    return ChatState(
      activeChatId: activeChatId ?? this.activeChatId,
      isActive: isActive ?? this.isActive,
    );
  }
}

class ChatStateNotifier extends StateNotifier<ChatState> {
  final ChatStateService _chatStateService;

  ChatStateNotifier(this._chatStateService) : super(const ChatState());

  /// Enter a chat conversation
  Future<void> enterChat(String chatId) async {
    await _chatStateService.enterChat(chatId);
    state = state.copyWith(activeChatId: chatId, isActive: true);
  }

  /// Exit the current chat conversation
  Future<void> exitChat() async {
    await _chatStateService.exitChat();
    state = state.copyWith(activeChatId: null, isActive: false);
  }

  /// Update activity to keep session alive
  Future<void> updateActivity() async {
    if (state.isActive) {
      await _chatStateService.updateActivity();
    }
  }

  /// Handle app lifecycle changes
  Future<void> onAppPaused() async {
    await _chatStateService.onAppPaused();
    state = state.copyWith(isActive: false);
  }

  Future<void> onAppResumed() async {
    await _chatStateService.onAppResumed();
  }
}
