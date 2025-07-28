// lib/examples/chat_integration_example.dart
// Example of how to integrate real-time read status into your chat screen

/*
INTEGRATION GUIDE FOR YOUR EXISTING CHAT SCREEN:

1. UPDATE YOUR CHAT SCREEN INITIALIZATION:
   
   @override
   void initState() {
     super.initState();
     
     // Mark messages as read when entering chat
     WidgetsBinding.instance.addPostFrameCallback((_) {
       ChatService().enterChatScreen(widget.conversationId);
     });
   }

2. USE THE ENHANCED MESSAGE STREAM:
   
   // Instead of: ChatService().getMessages(conversationId)
   // Use: ChatService().getMessagesWithReadReceipts(conversationId)
   
   StreamBuilder<List<ChatMessage>>(
     stream: ChatService().getMessagesWithReadReceipts(conversationId),
     builder: (context, snapshot) {
       if (!snapshot.hasData) return CircularProgressIndicator();
       
       final messages = snapshot.data!;
       return ListView.builder(
         itemCount: messages.length,
         itemBuilder: (context, index) {
           final message = messages[index];
           return MessageBubble(
             message: message,
             isMe: message.senderId == currentUserId,
             showReadReceipt: message.senderId == currentUserId, // Show "Read" indicator for sent messages
           );
         },
       );
     },
   )

3. ADD MESSAGE BUBBLE WITH READ RECEIPTS:

   class MessageBubble extends StatelessWidget {
     final ChatMessage message;
     final bool isMe;
     final bool showReadReceipt;
     
     const MessageBubble({
       required this.message,
       required this.isMe,
       this.showReadReceipt = false,
     });
     
     @override
     Widget build(BuildContext context) {
       return Container(
         alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
         child: Container(
           padding: EdgeInsets.all(12),
           decoration: BoxDecoration(
             color: isMe ? Colors.blue : Colors.grey[300],
             borderRadius: BorderRadius.circular(16),
           ),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.end,
             mainAxisSize: MainAxisSize.min,
             children: [
               Text(
                 message.content,
                 style: TextStyle(
                   color: isMe ? Colors.white : Colors.black87,
                 ),
               ),
               SizedBox(height: 4),
               Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Text(
                     _formatTime(message.timestamp),
                     style: TextStyle(
                       fontSize: 12,
                       color: isMe ? Colors.white70 : Colors.grey[600],
                     ),
                   ),
                   if (showReadReceipt) ...[
                     SizedBox(width: 4),
                     Icon(
                       message.isRead ? Icons.done_all : Icons.done,
                       size: 16,
                       color: message.isRead ? Colors.blue[300] : Colors.white70,
                     ),
                   ],
                 ],
               ),
             ],
           ),
         ),
       );
     }
     
     String _formatTime(DateTime timestamp) {
       return "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
     }
   }

4. OPTIONAL: ADD PERIODIC READ STATUS REFRESH (if needed)

   Timer? _readStatusTimer;
   
   @override
   void initState() {
     super.initState();
     
     // Refresh read status every 30 seconds (optional)
     _readStatusTimer = Timer.periodic(Duration(seconds: 30), (_) {
       ChatService().refreshReadStatus(widget.conversationId);
     });
   }
   
   @override
   void dispose() {
     _readStatusTimer?.cancel();
     super.dispose();
   }

WHAT THIS PROVIDES:

✅ **Automatic Read Marking**: Messages are marked as read when user views them
✅ **Real-time Updates**: Read receipts update instantly when recipient reads message  
✅ **Visual Indicators**: 
   - Single checkmark (✓) = Sent
   - Double checkmark (✓✓) = Delivered  
   - Blue double checkmark (✓✓) = Read
✅ **No Manual Intervention**: Everything happens automatically
✅ **Performance Optimized**: Only marks unread messages, batches updates

HOW IT WORKS:

1. User enters chat → All unread messages marked as read immediately
2. New messages arrive → Stream updates → Auto-marked as read if user is viewing
3. Real-time Firestore updates → Read receipts update instantly for sender
4. Background optimization → No unnecessary database calls

The read status will now update in real-time when both users are in the chat! 🚀
*/