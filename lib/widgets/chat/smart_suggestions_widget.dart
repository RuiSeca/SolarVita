import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/chat/enhanced_chat_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';

class SmartSuggestionsWidget extends ConsumerStatefulWidget {
  final String conversationId;
  final String receiverId;
  final String lastMessage;
  final List<String> recentMessages;
  final Function(SmartSuggestion)? onSuggestionTap;

  const SmartSuggestionsWidget({
    super.key,
    required this.conversationId,
    required this.receiverId,
    required this.lastMessage,
    required this.recentMessages,
    this.onSuggestionTap,
  });

  @override
  ConsumerState<SmartSuggestionsWidget> createState() => _SmartSuggestionsWidgetState();
}

class _SmartSuggestionsWidgetState extends ConsumerState<SmartSuggestionsWidget>
    with SingleTickerProviderStateMixin {
  List<SmartSuggestion> _suggestions = [];
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _generateSuggestions();
  }

  @override
  void didUpdateWidget(SmartSuggestionsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lastMessage != widget.lastMessage) {
      _generateSuggestions();
    }
  }

  Future<void> _generateSuggestions() async {
    if (widget.lastMessage.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final chatService = EnhancedChatService();
    final suggestions = await chatService.generateSmartSuggestions(
      conversationId: widget.conversationId,
      lastMessage: widget.lastMessage,
      recentMessages: widget.recentMessages,
    );

    if (mounted) {
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });

      if (suggestions.isNotEmpty) {
        _animationController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tr(context, 'smart_suggestions'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return _buildSuggestionCard(suggestion, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            tr(context, 'generating_suggestions'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(SmartSuggestion suggestion, int index) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOutBack,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => _handleSuggestionTap(suggestion),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    suggestion.icon,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                suggestion.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSuggestionTap(SmartSuggestion suggestion) {
    widget.onSuggestionTap?.call(suggestion);

    // Handle different suggestion types
    switch (suggestion.type) {
      case SuggestionType.meal:
        _handleMealSuggestion(suggestion);
        break;
      case SuggestionType.workout:
        _handleWorkoutSuggestion(suggestion);
        break;
      case SuggestionType.ecoTip:
        _handleEcoTipSuggestion(suggestion);
        break;
      case SuggestionType.challenge:
        _handleChallengeSuggestion(suggestion);
        break;
      case SuggestionType.activity:
        _handleActivitySuggestion(suggestion);
        break;
    }

    // Hide suggestions after tap
    _animationController.reverse();
  }

  void _handleMealSuggestion(SmartSuggestion suggestion) {
    final actionType = suggestion.actionData['type'];

    switch (actionType) {
      case 'meal_recommendations':
        _showMealRecommendationsDialog();
        break;
      case 'meal_logging':
        _showMealLoggingDialog();
        break;
    }
  }

  void _handleWorkoutSuggestion(SmartSuggestion suggestion) {
    final actionType = suggestion.actionData['type'];

    switch (actionType) {
      case 'quick_workout':
        final duration = suggestion.actionData['duration'] ?? 15;
        _showQuickWorkoutDialog(duration);
        break;
      case 'partner_workout':
        _showPartnerWorkoutDialog();
        break;
    }
  }

  void _handleEcoTipSuggestion(SmartSuggestion suggestion) {
    final actionType = suggestion.actionData['type'];

    switch (actionType) {
      case 'eco_tip':
        _showEcoTipDialog();
        break;
      case 'carbon_footprint':
        _showCarbonFootprintDialog();
        break;
    }
  }

  void _handleChallengeSuggestion(SmartSuggestion suggestion) {
    _showActiveChallengesDialog();
  }

  void _handleActivitySuggestion(SmartSuggestion suggestion) {
    _showOutdoorActivitiesDialog();
  }

  // Dialog methods (simplified for demo)
  void _showMealRecommendationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🥗 Healthy Meal Ideas'),
        content: const Text(
          'Here are some nutritious meal suggestions based on your preferences and dietary goals.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showMealLoggingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📝 Log Your Meal'),
        content: const Text(
          'Track what you\'re eating to maintain your nutrition goals.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Log Meal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
        ],
      ),
    );
  }

  void _showQuickWorkoutDialog(int duration) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('⚡ $duration-Minute Workout'),
        content: Text(
          'Perfect for a busy day! This $duration-minute workout will get your heart pumping.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Start Workout'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
        ],
      ),
    );
  }

  void _showPartnerWorkoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🤝 Partner Workout'),
        content: const Text(
          'Working out together is more fun! Find partner exercises you can do together.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Find Workouts'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
        ],
      ),
    );
  }

  void _showEcoTipDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🌱 Today\'s Eco Tip'),
        content: const Text(
          'Small changes in your daily routine can make a big impact on the environment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Learn More'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showCarbonFootprintDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🌍 Carbon Footprint'),
        content: const Text(
          'Check your environmental impact and see how you can reduce your carbon footprint.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('View Impact'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showActiveChallengesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🏆 Active Challenges'),
        content: const Text(
          'Join a community challenge and compete with others to reach your goals!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Browse Challenges'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Interested'),
          ),
        ],
      ),
    );
  }

  void _showOutdoorActivitiesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🌞 Outdoor Activities'),
        content: const Text(
          'The weather looks great! Here are some outdoor activities you can enjoy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Find Activities'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay Inside'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}