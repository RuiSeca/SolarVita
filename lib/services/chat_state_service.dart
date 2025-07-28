// lib/services/chat_state_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ChatStateService {
  static final ChatStateService _instance = ChatStateService._internal();
  factory ChatStateService() => _instance;
  ChatStateService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _currentActiveChatId;
  DateTime? _lastActivityTime;
  
  // Track the currently active chat
  String? get currentActiveChatId => _currentActiveChatId;
  
  /// Set the user as actively viewing a specific chat
  Future<void> enterChat(String chatId) async {
    _currentActiveChatId = chatId;
    _lastActivityTime = DateTime.now();
    
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        // Store active chat state in Firestore for cross-device sync
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('chat_state')
            .doc('current')
            .set({
          'activeChatId': chatId,
          'lastActivity': FieldValue.serverTimestamp(),
          'isActive': true,
        });
        
        debugPrint('📱 Entered chat: $chatId');
      } catch (e) {
        debugPrint('❌ Failed to update chat state: $e');
      }
    }
  }
  
  /// Set the user as no longer actively viewing any chat
  Future<void> exitChat() async {
    final previousChatId = _currentActiveChatId;
    _currentActiveChatId = null;
    _lastActivityTime = null;
    
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        // Clear active chat state
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('chat_state')
            .doc('current')
            .set({
          'activeChatId': null,
          'lastActivity': FieldValue.serverTimestamp(),
          'isActive': false,
        });
        
        debugPrint('📱 Exited chat: $previousChatId');
      } catch (e) {
        debugPrint('❌ Failed to clear chat state: $e');
      }
    }
  }
  
  /// Check if a user is currently active in a specific chat
  Future<bool> isUserActiveInChat(String userId, String chatId) async {
    try {
      final chatStateDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_state')
          .doc('current')
          .get();
      
      if (!chatStateDoc.exists) return false;
      
      final data = chatStateDoc.data()!;
      final activeChatId = data['activeChatId'] as String?;
      final isActive = data['isActive'] as bool? ?? false;
      final lastActivity = data['lastActivity'] as Timestamp?;
      
      // Check if user is in the same chat and was active recently (within 30 seconds)
      if (activeChatId == chatId && isActive && lastActivity != null) {
        final timeDiff = DateTime.now().difference(lastActivity.toDate());
        return timeDiff.inSeconds < 30; // Consider active if last activity was within 30 seconds
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Error checking chat state: $e');
      return false; // Default to sending notification if we can't determine state
    }
  }
  
  /// Update activity timestamp to keep session alive
  Future<void> updateActivity() async {
    if (_currentActiveChatId == null) return;
    
    _lastActivityTime = DateTime.now();
    
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('chat_state')
            .doc('current')
            .update({
          'lastActivity': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Silent fail - not critical
      }
    }
  }
  
  /// Check if current user is in a specific chat (local check)
  bool isCurrentlyInChat(String chatId) {
    if (_currentActiveChatId != chatId) return false;
    if (_lastActivityTime == null) return false;
    
    // Consider active if last activity was within 10 seconds (for local checks)
    final timeDiff = DateTime.now().difference(_lastActivityTime!);
    return timeDiff.inSeconds < 10;
  }
  
  /// Clean up when app goes to background
  Future<void> onAppPaused() async {
    await exitChat();
  }
  
  /// Restore state when app comes to foreground (if needed)
  Future<void> onAppResumed() async {
    // Could restore state from Firestore if needed
  }
}