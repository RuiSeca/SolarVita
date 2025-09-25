import 'package:flutter/material.dart';
import '../models/audio_preference.dart';
import '../components/audio_reactive_waves.dart';
import '../components/animated_waves.dart';
import '../../../utils/translation_helper.dart';
import '../services/onboarding_audio_service.dart';
import 'intro_gateway_screen.dart';

class AudioPreferenceScreen extends StatefulWidget {
  const AudioPreferenceScreen({super.key});

  @override
  State<AudioPreferenceScreen> createState() => _AudioPreferenceScreenState();
}

class _AudioPreferenceScreenState extends State<AudioPreferenceScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  AudioPreference? _selectedPreference;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );

    // Start fade animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _selectPreference(AudioPreference preference) {
    if (_isNavigating) return;

    setState(() {
      _selectedPreference = preference;
    });

    // Small delay for visual feedback, then save and navigate
    Future.delayed(const Duration(milliseconds: 400), () {
      _saveAndContinue();
    });
  }

  void _saveAndContinue() async {
    if (_selectedPreference == null || _isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    try {
      // Save preference
      await AudioPreferences.setAudioPreference(_selectedPreference!);

      // Immediately update the audio service with the new preference
      await OnboardingAudioService().reloadUserPreference();

      // Navigate to onboarding
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const IntroGatewayScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving audio preference: $e');
      setState(() {
        _isNavigating = false;
      });
    }
  }

  Widget _buildPreferenceOption(AudioPreference preference) {
    final isSelected = _selectedPreference == preference;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: GestureDetector(
              onTap: () => _selectPreference(preference),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF10B981)
                        : Colors.white.withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isSelected
                        ? [
                            const Color(0xFF10B981).withValues(alpha: 0.2),
                            const Color(0xFF059669).withValues(alpha: 0.1),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.1),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    // Emoji icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFF10B981).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                      child: Center(
                        child: Text(
                          AudioPreferences.getEmoji(preference),
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AudioPreferences.getDisplayName(preference),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF10B981)
                                  : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AudioPreferences.getDescription(preference),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Selection indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : Colors.white.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        color: isSelected
                            ? const Color(0xFF10B981)
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background Waves
          const Positioned.fill(
            child: AudioReactiveWaves(
              intensity: 0.2,
              personality: WavePersonality.eco,
              enableAudioReactivity: false, // No audio playing yet
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Title Section
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              Text(
                                tr(context, 'enhance_your_journey'),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 16),

                              Text(
                                tr(context, 'choose_your_audio_experience'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  letterSpacing: 0.5,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 60),

                // Preference Options
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPreferenceOption(AudioPreference.full),
                      _buildPreferenceOption(AudioPreference.backgroundOnly),
                      _buildPreferenceOption(AudioPreference.silent),
                    ],
                  ),
                ),

                // Footer
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value * 0.7,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          tr(context, 'you_can_change_this_anytime'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.6),
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          // Loading overlay
          if (_isNavigating)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}