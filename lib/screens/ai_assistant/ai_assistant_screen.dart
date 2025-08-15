// lib/screens/ai_assistant/ai_assistant_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/ai/ai_service.dart';
import '../../services/meal/nutritionix_service.dart';
import '../../models/user/user_context.dart';
import '../../models/food/food_analysis.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../exercise_history/exercise_history_screen.dart';
import '../health/meals/meal_plan_screen.dart';
import 'package:logger/logger.dart';
import '../../widgets/common/lottie_loading_widget.dart';
import '../avatar_store/avatar_store_screen.dart';
import '../../widgets/avatar_display.dart';
import '../../config/avatar_animations_config.dart';
import '../../providers/firebase/firebase_avatar_provider.dart';
import '../../services/avatars/avatar_controller_factory.dart';
import '../../services/avatars/universal_avatar_controller.dart';
import '../../services/avatars/avatar_interaction_manager.dart';
import '../../services/avatars/smart_avatar_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen>
    with TickerProviderStateMixin {
  final Logger _logger = Logger();
  final TextEditingController _messageController = TextEditingController();
  final List<Widget> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  bool _isAnalyzingFood = false;
  bool _userHasInteracted = false; // Track user interaction
  late final AIService _aiService;
  late final NutritionixService _nutritionixService;
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonAnimation;

  // Speech recognition
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _speechListening = false;
  String _recognizedText = '';

  // Universal avatar controller system
  UniversalAvatarController? _universalController;
  final GlobalKey<AvatarDisplayState> _headerAvatarKey = GlobalKey();
  final GlobalKey<AvatarDisplayState> _largeAvatarKey = GlobalKey();
  String? _lastInitializedAvatarId; // Track last initialized avatar to prevent duplicate initialization


  @override
  void initState() {
    super.initState();

    // Initialize avatar controller system after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeAvatarController();
    });

    // Initialize animation controllers
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _sendButtonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeOutBack),
    );

    // Listen to text changes
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText &&
          !_sendButtonController.isAnimating &&
          _sendButtonController.status != AnimationStatus.completed) {
        _sendButtonController.forward();
      } else if (!hasText &&
          !_sendButtonController.isAnimating &&
          _sendButtonController.status != AnimationStatus.dismissed) {
        _sendButtonController.reverse();
      }
    });
    try {
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
    } catch (e) {
      // Initialize with a placeholder service that provides basic responses
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
    _nutritionixService = NutritionixService();

    // Initialize speech recognition
    _initializeSpeech();

    // Add initial greeting message only if user hasn't interacted
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_userHasInteracted && _messages.isEmpty) {
        setState(() {
          _messages.insert(
            0,
            ChatMessage(text: tr(context, 'assistant_greeting'), isUser: false),
          );
        });
      }
    });
  }

  Future<void> _initializeAvatarController() async {
    if (!mounted) return;
    
    // Get current equipped avatar with debugging
    final firebaseAvatarState = ref.read(firebaseAvatarStateProvider).valueOrNull;
    final equippedAvatarId = firebaseAvatarState?.equippedAvatarId ?? 'mummy_coach';
    
    // Prevent duplicate initialization
    if (_lastInitializedAvatarId == equippedAvatarId) {
      _logger.i('🎯 AI Screen: Skipping duplicate initialization for: $equippedAvatarId');
      return;
    }
    
    _logger.i('🎯 AI Screen: Avatar controller initialization for: $equippedAvatarId');
    _logger.i('🎯 Firebase avatar state: ${firebaseAvatarState?.toString()}');
    
    // Update last initialized ID
    _lastInitializedAvatarId = equippedAvatarId;
    
    // SmartAvatarManager handles all avatar controller creation
    // AI screen only provides the header avatar keys, the controllers are managed by SmartAvatarManager
    _logger.i('🎯 AI Screen: Controllers managed by SmartAvatarManager, no local controller needed');
    
    // Add delay to ensure SmartAvatarManager controllers are registered
    await Future.delayed(const Duration(milliseconds: 200));
    
    // For quantum coach, get BOTH controllers (universal for Stage 0, quantum for cards)
    if (equippedAvatarId == 'quantum_coach') {
      final factory = AvatarControllerFactory();
      
      // Get universal controller for Stage 0 teleportation
      final universalController = factory.getController<UniversalAvatarController>('${equippedAvatarId}_ai_screen');
      _universalController = universalController;
      _logger.i('🌌 AI Screen: Universal controller for quantum Stage 0: ${universalController != null}');
      
      // Get quantum controller for card teleportation (use new ID)
      final quantumController = factory.getQuantumCoachController('quantum_coach_logic_only');
      _logger.i('🌌 AI Screen: Quantum controller for cards: ${quantumController != null}');
    } else {
      // For other avatars, get the universal controller
      final factory = AvatarControllerFactory();
      final universalController = factory.getController<UniversalAvatarController>('${equippedAvatarId}_ai_screen');
      _logger.i('🎯 AI Screen: Universal controller exists: ${universalController != null}');
      _universalController = universalController;
    }
    
    // Trigger rebuild to show correct avatar
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    
    // Avatar controllers are managed by SmartAvatarManager, not disposed here
    _universalController = null;
    _lastInitializedAvatarId = null;

    // Enhanced cleanup for speech recognition (especially for Huawei devices)
    try {
      if (_speechToText.isListening) {
        _speechToText.stop();
      }
      // Add a small delay for Huawei device cleanup
      Future.delayed(const Duration(milliseconds: 100), () {
        _speechToText.cancel();
      });
    } catch (e) {
      _logger.w('Error during speech recognition cleanup: $e');
    }

    super.dispose();
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    if (mounted) {
      setState(() {
        _userHasInteracted = true;
        try {
          _messages.insert(0, ChatMessage(text: text, isUser: true));
        } catch (e) {
          _logger.e('Error inserting message: $e');
        }
        _messageController.clear();
        _isTyping = true;
      });
    }

    // Analyze if the message contains keywords related to exercise history
    if (_containsExerciseHistoryKeywords(text.toLowerCase())) {
      _navigateToExerciseHistory(text);
      return;
    }

    // Analyze if the message contains keywords related to meals
    if (_containsMealKeywords(text.toLowerCase())) {
      _navigateToMealPlan(text);
      return;
    }

    // Send the text to the AI for a response using the new async method
    try {
      final response = await _aiService.generateResponseAsync(text);

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.insert(0, ChatMessage(text: response, isUser: false));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.insert(
            0,
            ChatMessage(
              text:
                  'Sorry, I encountered an issue. Let me try a different approach: ${_aiService.generateResponse(text)}',
              isUser: false,
            ),
          );
        });
      }
    }
  }

  bool _containsExerciseHistoryKeywords(String text) {
    // Check for exercise-related words
    final exerciseWords = [
      'exercise history',
      'workout history',
      'training history',
      'workout logs',
      'exercise logs',
      'my workouts',
      'my exercises',
      'training logs',
      'fitness history',
      'workout data',
      'exercise data',
      'workout records',
      'exercise records',
    ];

    // Check for navigation intent words
    final intentWords = [
      'open',
      'show',
      'view',
      'go to',
      'take me to',
      'navigate to',
      'display',
      'bring up',
      'access',
      'see',
      'check',
      'look at',
    ];

    final hasExerciseWord = exerciseWords.any(
      (word) => text.contains(word.toString()),
    );
    final hasIntentWord = intentWords.any(
      (word) => text.contains(word.toString()),
    );

    return hasExerciseWord && hasIntentWord;
  }

  bool _containsMealKeywords(String text) {
    // Check for meal-related words
    final mealWords = [
      'meal plan',
      'meal planner',
      'meals screen',
      'my meals',
      'meal planning',
      'food plan',
      'diet plan',
      'nutrition plan',
      'meal schedule',
      'eating plan',
      'my menu',
      'meal tracker',
      'food tracker',
    ];

    // Check for navigation intent words
    final intentWords = [
      'open',
      'show',
      'view',
      'go to',
      'take me to',
      'navigate to',
      'display',
      'bring up',
      'access',
      'see',
      'check',
      'look at',
    ];

    final hasMealWord = mealWords.any((word) => text.contains(word.toString()));
    final hasIntentWord = intentWords.any(
      (word) => text.contains(word.toString()),
    );

    return hasMealWord && hasIntentWord;
  }

  void _navigateToExerciseHistory(String query) {
    setState(() {
      _isTyping = false;
      _messages.insert(
        0,
        ChatMessage(
          text:
              "I'll open your exercise history for you! 💪 You can track your progress, view past workouts, and see your personal records there.",
          isUser: false,
        ),
      );
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ExerciseHistoryScreen(),
          ),
        );
      }
    });
  }

  void _navigateToMealPlan(String query) {
    setState(() {
      _isTyping = false;
      _messages.insert(
        0,
        ChatMessage(
          text:
              "Opening your meal plan now! 🍽️ You can view your planned meals, add new recipes, and track your nutrition there.",
          isUser: false,
        ),
      );
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MealPlanScreen()),
        );
      }
    });
  }

  Future<void> _analyzeFoodImage(File image) async {
    setState(() {
      _userHasInteracted = true;
      _isAnalyzingFood = true;
    });

    try {
      // Use the existing service with the correct method name
      final MultiIngredientAnalysis analysis = await _nutritionixService
          .analyzeFoodImageAdvanced(image);

      if (mounted) {
        setState(() {
          _isAnalyzingFood = false;
          _messages.insert(
            0,
            MultiIngredientFoodAnalysisMessage(
              analysis: analysis,
              onFavoriteToggle: _toggleFavorite,
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzingFood = false;

          // Show a more user-friendly error message based on the error type
          String errorMessage;
          if (e.toString().contains('No food detected')) {
            errorMessage = tr(context, 'no_food_detected');
          } else if (e.toString().contains('API key not valid')) {
            errorMessage = tr(context, 'api_key_invalid');
          } else if (e.toString().contains(
            'Failed to get FatSecret access token',
          )) {
            errorMessage = tr(context, 'fatsecret_auth_error');
          } else if (e.toString().contains('No nutritional data found')) {
            errorMessage = tr(context, 'no_nutritional_data');
          } else {
            errorMessage =
                "${tr(context, 'food_analysis_error')}: ${e.toString()}";
          }

          _messages.insert(0, ChatMessage(text: errorMessage, isUser: false));
        });
      }
    }
  }

  void _toggleFavorite(String foodId) {
    // Implementation for toggling favorites
    // Show feedback to user
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr(context, 'favorite_toggled'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for Firebase avatar state changes
    final firebaseAvatarState = ref.watch(firebaseAvatarStateProvider).valueOrNull;
    final currentEquippedId = firebaseAvatarState?.equippedAvatarId ?? 'mummy_coach';
    
    // Only reinitialize if avatar actually changed (prevent multiple calls)
    if (_lastInitializedAvatarId != currentEquippedId) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _initializeAvatarController();
      });
    }
    
    return SmartAvatarManager(
      screenId: 'ai_screen',
      legacyParameters: {
        'headerAvatarKey': _headerAvatarKey,
        'largeAvatarKey': _largeAvatarKey,
      },
      child: Scaffold(
        backgroundColor: AppTheme.surfaceColor(context),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    _buildHeader(),
                    if (!_userHasInteracted)
                      Expanded(
                        child: _buildActionButtons(),
                      ), // Show buttons until user interacts
                    if (_userHasInteracted) Expanded(child: _buildChatArea()),
                    _buildMessageInput(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surfaceColor(context)),
      child: Row(
        children: [
          // Avatar in header - dynamically show equipped avatar
          Consumer(
            builder: (context, ref, child) {
              // Use the new stable equipped avatar provider
              final equippedAvatar = ref.watch(equippedAvatarProvider);
              final avatarId = equippedAvatar?.avatarId ?? 'mummy_coach';
              
              _logger.i('🎯 Header building with stable equipped avatar: $avatarId');
              
              return _buildHeaderAvatar(avatarId);
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final equippedAvatar = ref.watch(equippedAvatarProvider);
                final avatarName = equippedAvatar?.name ?? 'AI Coach';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          avatarName,
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.purple.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            tr(context, 'status.new'),
                            style: TextStyle(
                              color: Colors.purple,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Ancient fitness wisdom meets modern AI',
                      style: TextStyle(
                        color: AppTheme.textColor(context).withAlpha(153),
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Store Icon Button
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AvatarStoreScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.store,
              color: Colors.white,
              size: 24,
            ),
            tooltip: 'Avatar Store',
          ),
        ],
      ),
    );
  }



  Widget _buildHeaderAvatar(String equippedAvatarId) {
    return _buildHeaderAvatarForType(equippedAvatarId);
  }

  Widget _buildHeaderAvatarForType(String avatarId) {
    // All avatars now use the universal controller with same interaction pattern
    return _buildUniversalHeaderAvatar(avatarId);
  }

  Widget _buildUniversalHeaderAvatar(String avatarId) {
    // For quantum coach, show interactive header (now uses universal controller for Stage 0)
    if (avatarId == 'quantum_coach') {
      _logger.i('🌌 Building interactive header for quantum coach (universal Stage 0)');
    }
    
    if (_universalController == null) {
      _logger.i('🎯 No universal controller, building static header for: $avatarId');
      return _buildStaticHeaderAvatar(avatarId);
    }
    
    _logger.i('🎯 Building interactive header for: $avatarId');
    return ValueListenableBuilder<bool>(
      valueListenable: _universalController!.showLargeAvatar,
      builder: (context, showLargeAvatar, child) {
        return GestureDetector(
          onTap: () {
            _logger.i('🎯 Header avatar tapped for: $avatarId');
            _logger.i('🎯 Universal controller exists: ${_universalController != null}');
            _logger.i('🎯 Universal controller type: ${_universalController?.avatarTypeString}');
            _universalController!.handleInteraction(AvatarInteractionType.singleTap);
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.purple.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: showLargeAvatar 
              ? null // Empty ring when avatar is teleported away
              : ClipOval(
                  child: AvatarDisplay(
                    key: _headerAvatarKey,
                    avatarId: avatarId, // Use actual equipped avatar ID
                    width: 50,
                    height: 50,
                    initialStage: AnimationStage.idle,
                    fit: BoxFit.cover,
                    preferEquipped: true, // Always show equipped avatar in AI screen
                  ),
                ),
          ),
        );
      },
    );
  }




  Widget _buildStaticHeaderAvatar(String avatarId) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: AvatarDisplay(
          key: _headerAvatarKey,
          avatarId: avatarId,
          width: 50,
          height: 50,
          initialStage: AnimationStage.idle,
          fit: BoxFit.cover,
          preferEquipped: true, // Always show equipped avatar in AI screen
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final List<Map<String, dynamic>> otherActions = [
      {
        'icon': Icons.directions_run,
        'label': tr(context, 'quick_action_workout'),
        'color': const Color(0xFF2196F3), // Material Blue
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
      {
        'icon': Icons.food_bank,
        'label': tr(context, 'quick_action_food_recognizer'),
        'color': AppColors.beige,
      },
    ];

    // Check if device is tablet (screen width > 600)
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Expanded(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isTablet ? 12 : 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Eco button centered on top - same width as individual grid buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Expanded(
                    flex: isTablet ? 1 : 2,
                    child: AspectRatio(
                      aspectRatio: isTablet ? 2.0 : 2.5,
                      child: _buildActionButton(
                        icon: Icons.eco,
                        label: tr(context, 'quick_action_eco'),
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 24),

              // Other action buttons in grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isTablet
                    ? 4
                    : 2, // 4 columns on tablet, 2 on phone
                mainAxisSpacing: isTablet ? 8 : 16,
                crossAxisSpacing: isTablet ? 8 : 16,
                childAspectRatio: isTablet
                    ? 2.0
                    : 2.5, // Smaller aspect ratio on tablet
                children: otherActions
                    .map(
                      (action) => _buildActionButton(
                        icon: action['icon'] as IconData,
                        label: action['label'] as String,
                        color: action['color'] as Color,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.textColor(context).withAlpha(26)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            _handleQuickAction(label);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
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
    // Create a stable list of widgets to display
    final List<Widget> displayItems = [];

    // Add typing/analyzing/listening indicator at the top (first item when reversed)
    if (_isTyping || _isAnalyzingFood || _speechListening) {
      if (_speechListening) {
        displayItems.add(
          VoiceListeningIndicator(recognizedText: _recognizedText),
        );
      } else if (_isAnalyzingFood) {
        displayItems.add(const FoodAnalyzingIndicator());
      } else {
        displayItems.add(const TypingIndicator());
      }
    }

    // Add messages in reverse order for chat display
    displayItems.addAll(_messages);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        key: ValueKey(_messages.length),
        controller: _scrollController,
        reverse: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: displayItems.length,
        itemBuilder: (context, index) {
          return displayItems[index];
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 16,
        left: 16,
        right: 16,
      ),
      constraints: const BoxConstraints(
        maxHeight: 200, // Prevent excessive height
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        border: Border(
          top: BorderSide(color: AppTheme.textColor(context).withAlpha(26)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Input row with attachment button
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment button outside input
              Container(
                margin: const EdgeInsets.only(right: 8, bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.textFieldBackground(context),
                      border: Border.all(
                        color: AppTheme.textColor(context).withAlpha(26),
                        width: 1,
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      offset: const Offset(0, -180),
                      position: PopupMenuPosition.over,
                      icon: Icon(
                        Icons.add,
                        color: AppTheme.textColor(context).withAlpha(128),
                        size: 20,
                      ),
                      onSelected: _handleAttachmentSelection,
                      itemBuilder: (context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'photos',
                          child: Row(
                            children: [
                              Icon(Icons.photo_library, color: Colors.blue),
                              const SizedBox(width: 12),
                              Text(tr(context, 'attach_photos')),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'camera',
                          child: Row(
                            children: [
                              Icon(Icons.camera_alt, color: Colors.green),
                              const SizedBox(width: 12),
                              Text(tr(context, 'attach_camera')),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'files',
                          child: Row(
                            children: [
                              Icon(Icons.attach_file, color: Colors.orange),
                              const SizedBox(width: 12),
                              Text(tr(context, 'attach_files')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Main input container
              Expanded(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: 50,
                    maxHeight: isTablet ? 120 : 100,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.textFieldBackground(context),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: AppTheme.textColor(context).withAlpha(26),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Text input
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          constraints: BoxConstraints(
                            maxHeight: isTablet ? 120 : 90, // Limit expansion
                          ),
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 16,
                            ),
                            maxLines: isTablet ? 4 : 3,
                            minLines: 1,
                            textInputAction: TextInputAction.send,
                            decoration: InputDecoration(
                              hintText: tr(context, 'input_placeholder'),
                              hintStyle: TextStyle(
                                color: AppTheme.textColor(
                                  context,
                                ).withAlpha(128),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: _handleSubmitted,
                          ),
                        ),
                      ),

                      // Microphone and Send buttons
                      Container(
                        margin: const EdgeInsets.only(right: 8, bottom: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Microphone button (shown when no text)
                            AnimatedBuilder(
                              animation: _sendButtonAnimation,
                              builder: (context, child) {
                                final microphoneOpacity =
                                    (1.0 - _sendButtonAnimation.value).clamp(
                                      0.0,
                                      1.0,
                                    );
                                final microphoneScale =
                                    (1.0 - _sendButtonAnimation.value).clamp(
                                      0.0,
                                      1.0,
                                    );
                                return Transform.scale(
                                  scale: microphoneScale,
                                  child: Opacity(
                                    opacity: microphoneOpacity,
                                    child:
                                        _messageController.text.trim().isEmpty
                                        ? Container(
                                            width: 32,
                                            height: 32,
                                            margin: const EdgeInsets.only(
                                              right: 2,
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                onTap: _handleVoiceInput,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: _speechListening
                                                        ? AppColors.primary
                                                              .withAlpha(51)
                                                        : AppTheme.textColor(
                                                            context,
                                                          ).withAlpha(26),
                                                  ),
                                                  child: Icon(
                                                    _speechListening
                                                        ? Icons.stop
                                                        : Icons.mic,
                                                    color: _speechListening
                                                        ? AppColors.primary
                                                        : AppTheme.textColor(
                                                            context,
                                                          ).withAlpha(128),
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                );
                              },
                            ),

                            // Send button (shown when there's text)
                            AnimatedBuilder(
                              animation: _sendButtonAnimation,
                              builder: (context, child) {
                                final sendOpacity = _sendButtonAnimation.value
                                    .clamp(0.0, 1.0);
                                final sendScale = _sendButtonAnimation.value
                                    .clamp(0.0, 1.0);
                                return Transform.scale(
                                  scale: sendScale,
                                  child: Opacity(
                                    opacity: sendOpacity,
                                    child:
                                        _messageController.text
                                            .trim()
                                            .isNotEmpty
                                        ? SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                onTap: () => _handleSubmitted(
                                                  _messageController.text,
                                                ),
                                                child: Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                  child: const Icon(
                                                    Icons.send,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _initializeSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          _logger.d('Speech status: $status');
          setState(() {
            _speechListening = status == 'listening';
          });

          // Auto-transfer text when speech recognition pauses or completes
          if (status == 'done' || status == 'notListening') {
            if (_recognizedText.isNotEmpty) {
              _logger.d(
                'Speech stopped, auto-transferring text: "$_recognizedText"',
              );
              _useRecognizedText();
            }
          }

          // Handle timeout more gracefully
          if (status == 'done') {
            _logger.d('Speech recognition completed normally');
            setState(() {
              _speechListening = false;
            });
          }
        },
        onError: (error) {
          _logger.e('Speech recognition error: $error');
          setState(() {
            _speechListening = false;
          });

          // Handle specific error cases for different devices
          if (error.errorMsg == 'error_busy') {
            _logger.w('Speech recognition was busy, stopping and resetting');
            _forceStopSpeechRecognition();

            // Show user-friendly message with reset option
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Voice recognition is busy. Tap "Reset" to fix this.',
                  ),
                  duration: Duration(seconds: 4),
                  backgroundColor: Colors.orange,
                  action: SnackBarAction(
                    label: 'Reset',
                    textColor: Colors.white,
                    onPressed: () {
                      _resetSpeechRecognition();
                    },
                  ),
                ),
              );
            }
          } else if (error.errorMsg == 'error_no_match') {
            _logger.w('Speech recognition could not understand the audio');

            // Show user-friendly message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Could not understand. Please speak clearly and try again.',
                  ),
                  duration: Duration(seconds: 3),
                  backgroundColor: Colors.orange,
                  action: SnackBarAction(
                    label: 'Try Again',
                    textColor: Colors.white,
                    onPressed: () {
                      // Restart speech recognition
                      Future.delayed(Duration(milliseconds: 500), () {
                        if (mounted && _speechEnabled) {
                          _handleVoiceInput();
                        }
                      });
                    },
                  ),
                ),
              );
            }
          } else if (error.errorMsg == 'error_speech_timeout') {
            _logger.w('Speech recognition timed out');

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'No speech detected. Please try speaking again.',
                  ),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } else {
            // Handle other errors generically
            _logger.w('Speech recognition error: ${error.errorMsg}');

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Voice input error. Please try again.'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      );
    } catch (e) {
      _logger.e('Failed to initialize speech recognition: $e');
      _speechEnabled = false;
    }
  }

  void _handleVoiceInput() async {
    try {
      // Check microphone permission
      final permissionStatus = await Permission.microphone.request();

      if (permissionStatus != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Microphone permission is required for voice input',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (!_speechEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Speech recognition not available'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Enhanced busy state handling
      if (_speechToText.isListening) {
        _logger.w('Speech recognition already active, forcing complete stop');
        await _forceStopSpeechRecognition();
        await Future.delayed(const Duration(milliseconds: 800)); // Extended delay
      }

      // Toggle listening state
      if (_speechListening) {
        _stopListening();
        if (_recognizedText.isNotEmpty) {
          _useRecognizedText();
        }
      } else {
        _startInlineListening();
      }
    } catch (e) {
      _logger.e('Voice input error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice input not available: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Dialog removed - using inline listening instead

  void _startInlineListening() async {
    if (!_speechEnabled) return;

    // Enhanced check for Huawei devices - force stop if busy
    if (_speechToText.isListening) {
      _logger.w(
        'Speech recognition is already listening, forcing stop for Huawei compatibility',
      );
      await _speechToText.stop();
      // Wait a moment for cleanup on Huawei devices
      await Future.delayed(const Duration(milliseconds: 500));
    }

    setState(() {
      _userHasInteracted = true;
      _recognizedText = '';
    });

    try {
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 45), // Reduced from 2 minutes
        pauseFor: const Duration(seconds: 4), // Reduced from 8 seconds
        listenOptions: SpeechListenOptions(partialResults: true),
        localeId: 'en_US',
        onSoundLevelChange: (level) {
          // Optional: Use sound level for visual feedback
        },
      );
    } catch (e) {
      _logger.e('Error starting speech recognition: $e');

      // Handle Huawei-specific error_busy with retry
      if (e.toString().contains('error_busy') && mounted) {
        _logger.w('Detected error_busy, attempting recovery for Huawei device');
        await _speechToText.stop();
        await Future.delayed(const Duration(seconds: 1));

        // Single retry attempt
        try {
          await _speechToText.listen(
            onResult: (result) {
              setState(() {
                _recognizedText = result.recognizedWords;
              });
            },
            listenFor: const Duration(seconds: 45), // Reduced from 2 minutes  
            pauseFor: const Duration(seconds: 4), // Reduced from 8 seconds
            listenOptions: SpeechListenOptions(partialResults: true),
            localeId: 'en_US',
          );
          return; // Success on retry
        } catch (retryError) {
          _logger.e('Retry also failed: $retryError');
        }
      }

      if (mounted) {
        setState(() {
          _speechListening = false;
        });

        String errorMessage = 'Error starting voice recognition';
        if (e.toString().contains('error_busy')) {
          errorMessage =
              'Voice recognition is busy. Please wait a moment and try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _stopListening() {
    if (_speechListening) {
      _speechToText.stop();
      setState(() {
        _speechListening = false;
      });
    }
  }

  Future<void> _forceStopSpeechRecognition() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
      await _speechToText.cancel();
      
      setState(() {
        _speechListening = false;
        _recognizedText = '';
      });
      
      _logger.d('Speech recognition force stopped and reset');
    } catch (e) {
      _logger.e('Error during force stop: $e');
    }
  }

  Future<void> _resetSpeechRecognition() async {
    try {
      _logger.d('Resetting speech recognition system');
      await _forceStopSpeechRecognition();
      
      // Reinitialize speech recognition
      await Future.delayed(const Duration(milliseconds: 1000));
      _initializeSpeech();
    } catch (e) {
      _logger.e('Error resetting speech recognition: $e');
    }
  }

  void _useRecognizedText() {
    if (_recognizedText.isNotEmpty) {
      final textToAdd = _recognizedText;
      _logger.d('Adding recognized text to input: "$textToAdd"');

      setState(() {
        _messageController.text = textToAdd;
      });

      // Clear recognized text after setting it
      _recognizedText = '';

      // Focus the text field so user can edit if needed
      _focusNode.requestFocus();
    } else {
      _logger.d('No recognized text to add');
    }
  }

  void _handleQuickAction(String action) async {
    setState(() {
      _userHasInteracted = true;
      _isTyping = true;
    });

    try {
      // Try Gemini first for more personalized responses
      final response = await _aiService.generateResponseAsync(
        'Give me a quick response about: $action',
      );

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.insert(0, ChatMessage(text: response, isUser: false));
        });
      }
    } catch (e) {
      _logger.e('Error in quick action: $e');

      // Fallback to the existing quick response system
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.insert(
            0,
            ChatMessage(
              text: _aiService.generateQuickResponse(action),
              isUser: false,
            ),
          );
        });
      }
    }
  }

  void _handleAttachmentSelection(String value) {
    switch (value) {
      case 'photos':
        _pickFromGallery();
        break;
      case 'camera':
        _takePhoto();
        break;
      case 'files':
        _handleFiles();
        break;
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null && mounted) {
        await _analyzeFoodImage(File(photo.path));
      }
    } catch (e) {
      _logger.e('Error taking photo', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr(context, 'camera_error'))));
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null && mounted) {
        await _analyzeFoodImage(File(image.path));
      }
    } catch (e) {
      _logger.e('Error picking image from gallery', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr(context, 'gallery_error'))));
      }
    }
  }

  void _handleFiles() {
    // Will be implemented for handling other file types
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 16,
              child: Icon(Icons.eco, color: AppColors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ] else ...[
            const SizedBox(width: 40),
          ],
          Expanded(
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
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 16,
              child: Icon(Icons.person, color: AppColors.white, size: 16),
            ),
          ] else ...[
            const SizedBox(width: 40),
          ],
        ],
      ),
    );
  }
}

class MultiIngredientFoodAnalysisMessage extends StatelessWidget {
  final MultiIngredientAnalysis analysis;
  final Function(String) onFavoriteToggle;

  const MultiIngredientFoodAnalysisMessage({
    super.key,
    required this.analysis,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 16,
            child: Icon(
              Icons.restaurant_menu,
              color: AppColors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.messageBubbleAI(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      analysis.image,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    analysis.primaryFood,
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    '${analysis.ingredients.length} ingredients detected',
                    style: TextStyle(
                      color: AppTheme.textColor(context).withAlpha(180),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Combined nutrition
                  Text(
                    'Combined Nutrition:',
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  _buildNutritionItem(
                    context,
                    tr(context, 'calories'),
                    '${analysis.combinedNutrition.totalCalories} kcal',
                    Icons.local_fire_department,
                    Colors.red,
                  ),
                  _buildNutritionItem(
                    context,
                    tr(context, 'protein'),
                    '${analysis.combinedNutrition.totalProtein}g',
                    Icons.fitness_center,
                    Colors.purple,
                  ),
                  _buildNutritionItem(
                    context,
                    tr(context, 'carbs'),
                    '${analysis.combinedNutrition.totalCarbs}g',
                    Icons.grain,
                    Colors.amber,
                  ),
                  _buildNutritionItem(
                    context,
                    tr(context, 'fat'),
                    '${analysis.combinedNutrition.totalFat}g',
                    Icons.opacity,
                    Colors.blue,
                  ),

                  const SizedBox(height: 12),

                  // Individual ingredients
                  Text(
                    'Detected Ingredients:',
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  ...analysis.ingredients.map(
                    (ingredient) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '• ${ingredient.name} (${ingredient.estimatedPortion.description})',
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  if (analysis.failedIngredients.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Could not analyze: ${analysis.failedIngredients.join(", ")}',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detection accuracy: ${(analysis.detectionAccuracy * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: AppTheme.textColor(context).withAlpha(180),
                          fontSize: 12,
                        ),
                      ),
                      IconButton(
                        onPressed: () => onFavoriteToggle(analysis.primaryFood),
                        icon: const Icon(Icons.favorite_border),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(color: AppTheme.textColor(context), fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class FoodAnalysisMessage extends StatelessWidget {
  final FoodAnalysis analysis;
  final bool isUser;

  const FoodAnalysisMessage({
    super.key,
    required this.analysis,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 16,
            child: Icon(
              Icons.restaurant_menu,
              color: AppColors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.messageBubbleAI(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (analysis.image != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: analysis.image != null
                          ? Image.file(
                              analysis.image!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              height: 180,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    analysis.foodName,
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tr(context, 'serving_size')}: ${analysis.servingSize}',
                    style: TextStyle(
                      color: AppTheme.textColor(context).withAlpha(180),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildNutritionItem(
                    context,
                    tr(context, 'calories'),
                    '${analysis.calories} kcal',
                    Icons.local_fire_department,
                    Colors.red,
                  ),
                  _buildNutritionItem(
                    context,
                    tr(context, 'protein'),
                    '${analysis.protein}g',
                    Icons.fitness_center,
                    Colors.purple,
                  ),
                  _buildNutritionItem(
                    context,
                    tr(context, 'carbs'),
                    '${analysis.carbs}g',
                    Icons.grain,
                    Colors.amber,
                  ),
                  _buildNutritionItem(
                    context,
                    tr(context, 'fat'),
                    '${analysis.fat}g',
                    Icons.opacity,
                    Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  if (analysis.ingredients.isNotEmpty) ...[
                    Text(
                      tr(context, 'ingredients'),
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      analysis.ingredients.join(', '),
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    analysis.healthRating >= 4
                        ? tr(context, 'healthy_food_rating')
                        : analysis.healthRating >= 2
                        ? tr(context, 'moderate_food_rating')
                        : tr(context, 'unhealthy_food_rating'),
                    style: TextStyle(
                      color: analysis.healthRating >= 4
                          ? Colors.green
                          : analysis.healthRating >= 2
                          ? Colors.orange
                          : Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(color: AppTheme.textColor(context), fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
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
            child: Icon(Icons.eco, color: AppColors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Text(
            tr(context, 'typing_indicator'),
            style: TextStyle(color: AppTheme.textColor(context)),
          ),
        ],
      ),
    );
  }
}

class FoodAnalyzingIndicator extends StatelessWidget {
  const FoodAnalyzingIndicator({super.key});

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
              Icons.restaurant_menu,
              color: AppColors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'analyzing_food_indicator'),
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
              const SizedBox(height: 4),
              const LottieLoadingWidget(width: 60, height: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class VoiceListeningIndicator extends StatelessWidget {
  final String recognizedText;

  const VoiceListeningIndicator({super.key, required this.recognizedText});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 16,
            child: AnimatedScale(
              scale: 1.2,
              duration: const Duration(milliseconds: 500),
              child: const Icon(Icons.mic, color: AppColors.white, size: 16),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.messageBubbleAI(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mic, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Listening...',
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (recognizedText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.textFieldBackground(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        recognizedText,
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      'Speak now...',
                      style: TextStyle(
                        color: AppTheme.textColor(context).withAlpha(128),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
