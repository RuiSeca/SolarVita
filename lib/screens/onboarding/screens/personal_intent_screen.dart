import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/audio_reactive_waves.dart';
import '../components/floating_glowing_icon.dart';
import '../components/glowing_button.dart';
import '../models/onboarding_models.dart';
import '../services/onboarding_audio_service.dart';
import '../components/animated_waves.dart';
import 'identity_setup_screen.dart';

class PersonalIntentScreen extends StatefulWidget {
  const PersonalIntentScreen({super.key});

  @override
  State<PersonalIntentScreen> createState() => _PersonalIntentScreenState();
}

class _PersonalIntentScreenState extends State<PersonalIntentScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _textController;
  
  Set<IntentType> selectedIntents = {};
  WavePersonality currentWavePersonality = WavePersonality.eco;
  
  final OnboardingAudioService _audioService = OnboardingAudioService();
  
  final List<IntentOption> intentOptions = [
    IntentOption(
      type: IntentType.eco,
      icon: Icons.eco,
      label: "Eco-Living",
      description: "Sustainable practices",
      wavePersonality: WavePersonality.eco,
    ),
    IntentOption(
      type: IntentType.fitness,
      icon: Icons.fitness_center,
      label: "Fitness",
      description: "Physical wellness",
      wavePersonality: WavePersonality.fitness,
    ),
    IntentOption(
      type: IntentType.nutrition,
      icon: Icons.restaurant,
      label: "Nutrition",
      description: "Mindful eating",
      wavePersonality: WavePersonality.wellness,
    ),
    IntentOption(
      type: IntentType.community,
      icon: Icons.people,
      label: "Community",
      description: "Connect & share",
      wavePersonality: WavePersonality.community,
    ),
    IntentOption(
      type: IntentType.mindfulness,
      icon: Icons.self_improvement,
      label: "Mindfulness",
      description: "Mental wellness",
      wavePersonality: WavePersonality.mindfulness,
    ),
    IntentOption(
      type: IntentType.adventure,
      icon: Icons.terrain,
      label: "Adventure",
      description: "Outdoor exploration",
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
    _audioService.playChime(ChimeType.selection);
  }


  void _continue() {
    // Play commitment chime for this important transition
    _audioService.playChime(ChimeType.commitment);
    
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
  Widget build(BuildContext context) {
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  
                  // Title
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - _textController.value)),
                        child: Opacity(
                          opacity: _textController.value,
                          child: const Text(
                            "What Brings You Here?",
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
                          child: const Text(
                            "Select the paths that resonate with your journey",
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
                  
                  const SizedBox(height: 60),
                  
                  // Intent Options Grid
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.1,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
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
                  ),
                  
                  // Continue Button
                  AnimatedOpacity(
                    opacity: selectedIntents.isNotEmpty ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 300),
                    child: GlowingButton(
                      text: "Continue Your Journey",
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