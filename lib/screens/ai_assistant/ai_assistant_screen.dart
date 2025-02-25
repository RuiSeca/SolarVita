import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../models/user_context.dart';
import '../../theme/app_theme.dart';
import 'package:solar_vitas/utils/translation_helper.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  late final AIService _aiService;

  @override
  void initState() {
    super.initState();
    _aiService = AIService(
      context: UserContext(
        preferredWorkoutDuration: 30,
        plasticBottlesSaved: 45,
        ecoScore: 85,
        carbonSaved: 12.5,
        mealCarbonSaved: 8.3,
        suggestedWorkoutTime: '8:00 AM',
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          text: text,
          isUser: true,
        ),
      );
      _messageController.clear();
      _isTyping = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _isTyping = false;
        _messages.insert(
          0,
          ChatMessage(
            text: _aiService.generateResponse(text),
            isUser: false,
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_messages.isEmpty) _buildActionButtons(),
            _buildChatArea(),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage('assets/images/solar_ai/AI_avatar.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'assistant_name'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                tr(context, 'assistant_subtitle'),
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(153),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final List<Map<String, dynamic>> actions = [
      {
        'icon': Icons.directions_run,
        'label': tr(context, 'quick_action_workout'),
        'color': const Color(0xFF2196F3), // Material Blue
      },
      {
        'icon': Icons.eco,
        'label': tr(context, 'quick_action_eco'),
        'color': AppColors.primary,
      },
      {
        'icon': Icons.restaurant_menu,
        'label': tr(context, 'quick_action_meal'),
        'color': const Color(0xFFFF9800), // Material Orange
      },
      {
        'icon': Icons.calendar_today,
        'label': tr(context, 'quick_action_schedule'),
        'color': AppColors.gold,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 2.5,
        children: actions
            .map((action) => _buildActionButton(
                  icon: action['icon'] as IconData,
                  label: action['label'] as String,
                  color: action['color'] as Color,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textColor(context).withAlpha(26),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleQuickAction(label),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatArea() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.builder(
          controller: _scrollController,
          reverse: true,
          itemCount: _messages.length + (_isTyping ? 1 : 0),
          itemBuilder: (context, index) {
            if (_isTyping && index == 0) {
              return const TypingIndicator();
            }
            return _messages[_isTyping ? index - 1 : index];
          },
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.only(
        top: 16,
        bottom: 16,
        right: 16,
        left: 8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        border: Border(
          top: BorderSide(color: AppTheme.textColor(context).withAlpha(26)),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.textColor(context).withAlpha(51),
                ),
              ),
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                offset: const Offset(0, -160),
                position: PopupMenuPosition.over,
                icon: Icon(
                  Icons.add,
                  color: AppTheme.textColor(context),
                  size: 20,
                ),
                onSelected: _handleAttachmentSelection,
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'photos',
                    child: Row(
                      children: [
                        const Icon(Icons.photo_library),
                        const SizedBox(width: 8),
                        Text(tr(context, 'attach_photos')),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'camera',
                    child: Row(
                      children: [
                        const Icon(Icons.camera_alt),
                        const SizedBox(width: 8),
                        Text(tr(context, 'attach_camera')),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'files',
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file),
                        const SizedBox(width: 8),
                        Text(tr(context, 'attach_files')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: AppTheme.textColor(context)),
              decoration: InputDecoration(
                hintText: tr(context, 'input_placeholder'),
                hintStyle: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(128),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.textFieldBackground(context),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: _handleSubmitted,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            onPressed: () => _handleSubmitted(_messageController.text),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.send, color: AppColors.white),
          ),
        ],
      ),
    );
  }

  void _handleQuickAction(String action) {
    String response = _aiService.generateQuickResponse(action);
    setState(() {
      _messages.insert(
        0,
        ChatMessage(text: response, isUser: false),
      );
    });
  }

  void _handleAttachmentSelection(String value) {
    switch (value) {
      case 'photos':
        _handlePhotos();
        break;
      case 'camera':
        _handleCamera();
        break;
      case 'files':
        _handleFiles();
        break;
    }
  }

  void _handlePhotos() {
    // Implement photo gallery selection
  }

  void _handleCamera() {
    // Will be implemented for food recognition feature
  }

  void _handleFiles() {
    // Implement file attachment handling
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 16,
              child: Icon(
                Icons.eco,
                color: AppColors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : AppTheme.messageBubbleAI(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? AppColors.white : AppTheme.textColor(context),
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 16,
            child: Icon(
              Icons.eco,
              color: AppColors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            tr(context, 'typing_indicator'),
            style: TextStyle(
              color: AppTheme.textColor(context),
            ),
          ),
        ],
      ),
    );
  }
}
