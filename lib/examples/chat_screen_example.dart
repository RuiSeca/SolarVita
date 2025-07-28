// lib/examples/chat_screen_example.dart
// Example of how to integrate chat state management into your chat screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/riverpod/chat_state_provider.dart';

class ChatScreenExample extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserId;
  
  const ChatScreenExample({
    super.key,
    required this.conversationId,
    required this.otherUserId,
  });

  @override
  ConsumerState<ChatScreenExample> createState() => _ChatScreenExampleState();
}

class _ChatScreenExampleState extends ConsumerState<ChatScreenExample> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    
    // Register app lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    // Enter chat when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatStateNotifierProvider.notifier).enterChat(widget.conversationId);
    });
  }

  @override
  void dispose() {
    // Exit chat when screen is closed
    ref.read(chatStateNotifierProvider.notifier).exitChat();
    
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        ref.read(chatStateNotifierProvider.notifier).onAppPaused();
        break;
      case AppLifecycleState.resumed:
        ref.read(chatStateNotifierProvider.notifier).onAppResumed();
        break;
      default:
        break;
    }
  }

  void _onUserActivity() {
    // Call this when user types, scrolls, or interacts with chat
    ref.read(chatStateNotifierProvider.notifier).updateActivity();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatStateNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        // Optional: Show active indicator
        actions: [
          if (chatState.isActive)
            Icon(Icons.circle, color: Colors.green, size: 12),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollNotification is ScrollUpdateNotification) {
                  _onUserActivity(); // Update activity on scroll
                }
                return false;
              },
              child: ListView(
                children: [
                  // Your messages here
                ],
              ),
            ),
          ),
          
          // Message input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (_) => _onUserActivity(), // Update activity on typing
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*
HOW TO INTEGRATE INTO YOUR EXISTING CHAT SCREEN:

1. Add the mixin and lifecycle observer:
   - `with WidgetsBindingObserver`
   - `WidgetsBinding.instance.addObserver(this);`

2. In initState():
   ```dart
   WidgetsBinding.instance.addPostFrameCallback((_) {
     ref.read(chatStateNotifierProvider.notifier).enterChat(conversationId);
   });
   ```

3. In dispose():
   ```dart
   ref.read(chatStateNotifierProvider.notifier).exitChat();
   ```

4. Add didChangeAppLifecycleState() method for app backgrounding

5. Call updateActivity() on user interactions:
   - When typing in text field
   - When scrolling message list
   - When tapping/interacting with chat

6. Deploy updated Firestore rules:
   ```bash
   firebase deploy --only firestore:rules
   ```
*/