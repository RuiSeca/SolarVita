// Example showing how the scalable avatar system would be used

import 'package:flutter/material.dart';
import '../services/avatars/scalable_avatar_system.dart';

/// BEFORE: Manual avatar integration (current approach)
class OldAIAssistantScreen extends StatefulWidget {
  @override
  State<OldAIAssistantScreen> createState() => _OldAIAssistantScreenState();
}

class _OldAIAssistantScreenState extends State<OldAIAssistantScreen> {
  // Manual controller management
  late final MummyAvatarController _mummyController;
  late final QuantumCoachController _quantumController;
  final GlobalKey _headerAvatarKey = GlobalKey();
  final GlobalKey _largeAvatarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Manual initialization
    _mummyController = AvatarControllerFactory().createMummyController(
      avatarId: 'mummy_ai_screen',
      headerAvatarKey: _headerAvatarKey,
      largeAvatarKey: _largeAvatarKey,
    );
    _quantumController = AvatarControllerFactory().createQuantumCoachController(
      avatarId: 'quantum_coach_teleporter',
    );
  }

  @override
  void dispose() {
    // Manual cleanup
    AvatarControllerFactory().removeAvatar('mummy_ai_screen');
    AvatarControllerFactory().removeAvatar('quantum_coach_teleporter');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Column(children: [/* UI content */]),
          
          // Manual avatar positioning
          ValueListenableBuilder<bool>(
            valueListenable: _mummyController.showLargeAvatar,
            builder: (context, showLarge, child) {
              return Positioned(
                top: 16,
                left: 16,
                child: GestureDetector(
                  onTap: () => _mummyController.handleInteraction(AvatarInteractionType.singleTap),
                  child: Container(/* Mummy avatar */),
                ),
              );
            },
          ),
          
          ValueListenableBuilder(
            valueListenable: _quantumController.currentLocation,
            builder: (context, location, child) {
              return ValueListenableBuilder(
                valueListenable: _quantumController.isVisible,
                builder: (context, isVisible, child) {
                  if (location == CoachLocation.aiScreen && isVisible) {
                    return Positioned(
                      top: 200,
                      right: 20,
                      child: GestureDetector(
                        onTap: () => _quantumController.handleInteraction(AvatarInteractionType.singleTap),
                        child: Container(/* Quantum coach */),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// AFTER: Configuration-driven avatar system (scalable approach)
class NewAIAssistantScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Single wrapper handles ALL avatars automatically
    return AvatarScreenManager(
      screenId: 'ai_screen',
      child: Scaffold(
        body: Column(
          children: [
            // Your existing UI - no avatar code needed!
            Text('AI Assistant Content'),
            // All avatars are automatically added by AvatarScreenManager
          ],
        ),
      ),
    );
  }
}

/// CONFIGURATION: All avatar behavior defined in JSON/config
/// avatars_config.json:
/*
{
  "avatars": [
    {
      "id": "dragon_fire",
      "name": "Fire Dragon", 
      "type": "combat",
      "assetPath": "assets/rive/dragon.riv",
      "interactions": {
        "type": "combat_sequence",
        "attacks": ["fire_breath", "claw_swipe", "tail_whip"],
        "defense": ["shield", "dodge"]
      },
      "positioning": {
        "ai_screen": {
          "position": "floating",
          "coordinates": {"x": 100, "y": 150, "width": 120, "height": 120}
        }
      },
      "priority": 3,
      "isEnabled": true
    },
    {
      "id": "fairy_healer",
      "name": "Healing Fairy",
      "type": "support", 
      "assetPath": "assets/rive/fairy.riv",
      "interactions": {
        "type": "healing_sequence",
        "spells": ["heal", "regenerate", "protect"]
      },
      "positioning": {
        "ai_screen": {
          "position": "corner",
          "coordinates": {"x": -80, "y": 100, "width": 60, "height": 60, "anchor": "top_right"}
        }
      },
      "priority": 4,
      "isEnabled": false
    }
  ]
}
*/

/// APP INITIALIZATION: Load configuration once
class AppInitialization {
  static Future<void> initialize() async {
    final configManager = AvatarConfigurationManager();
    
    // Load from multiple sources
    await configManager.loadConfiguration(
      configPath: 'assets/config/avatars.json', // Local config
      // OR
      // apiEndpoint: 'https://api.yourgame.com/avatars/config', // Remote config
      // OR  
      // inlineConfig: {...} // Hardcoded config
    );
    
    // Configuration is now loaded for entire app!
  }
}

/// ADDING NEW AVATARS: Just add to config - no code changes!
/// Easy A/B testing, feature flags, user preferences
class AvatarFeatureManagement {
  // Enable/disable avatars remotely
  static Future<void> toggleAvatar(String avatarId, bool enabled) async {
    // Update config via API or local storage
    // No app update needed!
  }
  
  // A/B test different avatar behaviors
  static Future<void> setAvatarVariant(String avatarId, String variant) async {
    // Switch between different interaction patterns
  }
  
  // User preferences
  static Future<void> setUserAvatarPreferences(List<String> enabledAvatars) async {
    // Users can choose which avatars to show
  }
}

/// ANALYTICS AND MONITORING
class AvatarAnalytics {
  static void trackAvatarInteraction(String avatarId, String interactionType) {
    // Automatic analytics for all avatar interactions
  }
  
  static void trackAvatarPerformance(String avatarId, Duration loadTime) {
    // Monitor avatar loading performance
  }
}

/// MULTI-SCREEN SUPPORT: Avatars work across all screens automatically
class MealPlanScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AvatarScreenManager(
      screenId: 'meal_plan', // Different screen ID
      child: Scaffold(
        body: Column(
          children: [
            Text('Meal Plan Content'),
            // Avatars configured for this screen appear automatically!
          ],
        ),
      ),
    );
  }
}