// lib/screens/ai_assistant/ai_assistant_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/ai_service.dart';
import '../../services/nutritionix_service.dart';
import '../../models/user_context.dart';
import '../../models/food_analysis.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../exercise_history/exercise_history_screen.dart';
import '../health/meals/meal_plan_screen.dart';
import 'package:logger/logger.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final Logger _logger = Logger();
  final TextEditingController _messageController = TextEditingController();
  final List<Widget> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _isAnalyzingFood = false;
  bool _userHasInteracted = false; // Track user interaction
  late final AIService _aiService;
  late final NutritionixService _nutritionixService;

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
    _nutritionixService = NutritionixService();

    // Add initial greeting message
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
              text: tr(context, 'assistant_greeting'),
              isUser: false,
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _userHasInteracted = true;
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
          _messages.insert(
            0,
            ChatMessage(
              text: response,
              isUser: false,
            ),
          );
        });
      }
    } catch (e) {
      _logger.e('Error getting AI response: $e');

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
    final keywords = [
      'workout',
      'exercise',
      'history',
      'progress',
      'training',
      'logs',
      'weights',
      'personal record',
      'pr',
      'sets',
      'reps'
    ];
    return keywords.any((keyword) => text.contains(keyword));
  }

  bool _containsMealKeywords(String text) {
    final keywords = [
      'meal plan',
      'diet',
      'nutrition',
      'food plan',
      'eating schedule',
      'recipes',
      'healthy food',
      'menu',
      'meals'
    ];
    return keywords.any((keyword) => text.contains(keyword));
  }

  void _navigateToExerciseHistory(String query) {
    setState(() {
      _isTyping = false;
      _messages.insert(
        0,
        ChatMessage(
          text: tr(context, 'opening_exercise_history'),
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
          text: tr(context, 'opening_meal_plan'),
          isUser: false,
        ),
      );
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MealPlanScreen(),
          ),
        );
      }
    });
  }

  Future<void> _analyzeFoodImage(File image) async {
    setState(() {
      _userHasInteracted = true;
      _isAnalyzingFood = true;
      _messages.insert(
          0, ChatMessage(text: tr(context, 'analyzing_food'), isUser: false));
    });

    try {
      // Use the existing service with the correct method name
      final MultiIngredientAnalysis analysis =
          await _nutritionixService.analyzeFoodImageAdvanced(image);

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
      _logger.e('Failed to analyze food', e);
      if (mounted) {
        setState(() {
          _isAnalyzingFood = false;

          // Show a more user-friendly error message based on the error type
          String errorMessage;
          if (e.toString().contains('No food detected')) {
            errorMessage = tr(context, 'no_food_detected');
          } else if (e.toString().contains('API key not valid')) {
            errorMessage = tr(context, 'api_key_invalid');
          } else if (e
              .toString()
              .contains('Failed to get FatSecret access token')) {
            errorMessage = tr(context, 'fatsecret_auth_error');
          } else if (e.toString().contains('No nutritional data found')) {
            errorMessage = tr(context, 'no_nutritional_data');
          } else {
            errorMessage =
                "${tr(context, 'food_analysis_error')}: ${e.toString()}";
          }

          _messages.insert(
            0,
            ChatMessage(
              text: errorMessage,
              isUser: false,
            ),
          );
        });
      }
    }
  }

  void _toggleFavorite(String foodId) {
    // Implementation for toggling favorites
    _logger.d('Toggle favorite for food: $foodId');

    // Show feedback to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'favorite_toggled'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_userHasInteracted)
              _buildActionButtons(), // Show buttons until user interacts
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
          onTap: () {
            _handleQuickAction(label);
          },
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
          itemCount: _messages.length + (_isTyping || _isAnalyzingFood ? 1 : 0),
          itemBuilder: (context, index) {
            if ((_isTyping || _isAnalyzingFood) && index == 0) {
              return _isAnalyzingFood
                  ? const FoodAnalyzingIndicator()
                  : const TypingIndicator();
            }
            return _messages[
                (_isTyping || _isAnalyzingFood) ? index - 1 : index];
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

  void _handleQuickAction(String action) async {
    setState(() {
      _userHasInteracted = true;
      _isTyping = true;
    });

    try {
      // Try Gemini first for more personalized responses
      final response = await _aiService
          .generateResponseAsync('Give me a quick response about: $action');

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.insert(
            0,
            ChatMessage(text: response, isUser: false),
          );
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
                text: _aiService.generateQuickResponse(action), isUser: false),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'camera_error'))),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'gallery_error'))),
        );
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
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 14,
            ),
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
                      child: Image.file(
                        analysis.image!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
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
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 14,
            ),
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
                style: TextStyle(
                  color: AppTheme.textColor(context),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 100,
                child: LinearProgressIndicator(
                  backgroundColor: AppTheme.textColor(context).withAlpha(51),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
