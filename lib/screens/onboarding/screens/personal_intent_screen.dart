import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/audio_reactive_waves.dart';
import '../components/floating_glowing_icon.dart';
import '../components/glowing_button.dart';
import '../components/onboarding_base_screen.dart';
import '../models/onboarding_models.dart';
import '../services/onboarding_audio_service.dart';
import '../components/animated_waves.dart';
import '../../../utils/translation_helper.dart';
import 'identity_setup_screen.dart';

class PersonalIntentScreen extends OnboardingBaseScreen {
  const PersonalIntentScreen({super.key});

  @override
  ConsumerState<PersonalIntentScreen> createState() => _PersonalIntentScreenState();
}

class _PersonalIntentScreenState extends OnboardingBaseScreenState<PersonalIntentScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _textController;
  
  Set<IntentType> selectedIntents = {};
  WavePersonality currentWavePersonality = WavePersonality.eco;
  
  final OnboardingAudioService _audioService = OnboardingAudioService();
  
  List<IntentOption> get intentOptions => [
    IntentOption(
      type: IntentType.eco,
      icon: Icons.eco,
      label: tr(context, 'intent_eco_label'),
      description: tr(context, 'intent_eco_description'),
      wavePersonality: WavePersonality.eco,
    ),
    IntentOption(
      type: IntentType.fitness,
      icon: Icons.fitness_center,
      label: tr(context, 'intent_fitness_label'),
      description: tr(context, 'intent_fitness_description'),
      wavePersonality: WavePersonality.fitness,
    ),
    IntentOption(
      type: IntentType.nutrition,
      icon: Icons.restaurant,
      label: tr(context, 'intent_nutrition_label'),
      description: tr(context, 'intent_nutrition_description'),
      wavePersonality: WavePersonality.wellness,
    ),
    IntentOption(
      type: IntentType.community,
      icon: Icons.people,
      label: tr(context, 'intent_community_label'),
      description: tr(context, 'intent_community_description'),
      wavePersonality: WavePersonality.community,
    ),
    IntentOption(
      type: IntentType.mindfulness,
      icon: Icons.self_improvement,
      label: tr(context, 'intent_mindfulness_label'),
      description: tr(context, 'intent_mindfulness_description'),
      wavePersonality: WavePersonality.mindfulness,
    ),
    IntentOption(
      type: IntentType.adventure,
      icon: Icons.terrain,
      label: tr(context, 'intent_adventure_label'),
      description: tr(context, 'intent_adventure_description'),
      wavePersonality: WavePersonality.adventure,
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _waveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    _textController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Start text animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _textController.forward();
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _updateWavePersonality() {
    if (selectedIntents.isNotEmpty) {
      final lastSelected = selectedIntents.last;
      final option = intentOptions.firstWhere((opt) => opt.type == lastSelected);
      setState(() {
        currentWavePersonality = option.wavePersonality;
      });
    }
  }

  void _onIntentTapped(IntentType intent) {
    setState(() {
      if (selectedIntents.contains(intent)) {
        selectedIntents.remove(intent);
      } else {
        selectedIntents.add(intent);
      }
    });
    _updateWavePersonality();
    HapticFeedback.lightImpact();
    
    // Play selection chime
    _audioService.playButtonSound();
  }


  void _continue() {
    // Play commitment chime for this important transition
    _audioService.playContinueSound();
    
    final userProfile = UserProfile(
      name: '', // Will be filled in next screen
      email: '', // Will be filled in next screen
      password: '', // Will be filled in next screen
      selectedIntents: selectedIntents,
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            IdentitySetupScreen(userProfile: userProfile),
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.3, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget buildScreenContent(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Adaptive Audio-Reactive Background Waves
          Positioned.fill(
            child: AudioReactiveWaves(
              intensity: selectedIntents.length / intentOptions.length * 0.8 + 0.2,
              personality: currentWavePersonality,
              enableAudioReactivity: true,
            ),
          ),
          
          
          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  
                  // Title
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - _textController.value)),
                        child: Opacity(
                          opacity: _textController.value,
                          child: Text(
                            tr(context, 'personal_intent_title'),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Subtitle
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - _textController.value)),
                        child: Opacity(
                          opacity: _textController.value,
                          child: Text(
                            tr(context, 'personal_intent_subtitle'),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 40),

                  // Intent Options Grid
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: intentOptions.length,
                    itemBuilder: (context, index) {
                      final option = intentOptions[index];
                      final isSelected = selectedIntents.contains(option.type);

                      return FloatingGlowingIcon(
                        icon: option.icon,
                        label: option.label,
                        description: option.description,
                        isSelected: isSelected,
                        color: option.color,
                        onTap: () => _onIntentTapped(option.type),
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  // Continue Button
                  AnimatedOpacity(
                    opacity: selectedIntents.isNotEmpty ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 300),
                    child: GlowingButton(
                      text: tr(context, 'continue_journey_button'),
                      onPressed: selectedIntents.isNotEmpty ? _continue : null,
                      glowIntensity: selectedIntents.length / intentOptions.length,
                      width: double.infinity,
                      height: 56,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}