import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/animated_waves.dart';
import '../components/glowing_text_field.dart';
import '../components/glowing_button.dart';
import '../components/floating_glowing_icon.dart';
import '../components/onboarding_base_screen.dart';
import '../services/onboarding_audio_service.dart';
import '../models/onboarding_models.dart';
import '../../../utils/translation_helper.dart';
import 'activity_level_screen.dart';
import '../../../services/database/user_profile_service.dart';

class IdentitySetupScreen extends OnboardingBaseScreen {
  final UserProfile userProfile;

  const IdentitySetupScreen({
    super.key,
    required this.userProfile,
  });

  @override
  ConsumerState<IdentitySetupScreen> createState() => _IdentitySetupScreenState();
}

class _IdentitySetupScreenState extends OnboardingBaseScreenState<IdentitySetupScreen> {
  final OnboardingAudioService _audioService = OnboardingAudioService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String _selectedGender = '';

  List<GenderOption> get _genderOptions => [
    GenderOption(value: 'male', icon: Icons.man, label: tr(context, 'gender_male')),
    GenderOption(value: 'female', icon: Icons.woman, label: tr(context, 'gender_female')),
    GenderOption(value: 'prefer_not_to_say', icon: Icons.person, label: tr(context, 'gender_prefer_not_to_say')),
  ];

  bool get _isFormValid =>
      _nameController.text.isNotEmpty &&
      _usernameController.text.isNotEmpty &&
      _heightController.text.isNotEmpty &&
      _weightController.text.isNotEmpty &&
      _ageController.text.isNotEmpty &&
      _selectedGender.isNotEmpty;

  void _onGenderSelected(String gender) {
    setState(() {
      _selectedGender = gender;
    });
    HapticFeedback.lightImpact();
    _audioService.playButtonSound();
  }

  void _continue() async {
    _audioService.playContinueSound();

    // Validate username availability
    final username = _usernameController.text.trim();
    if (username.isNotEmpty) {
      try {
        final userProfileService = UserProfileService();
        final isAvailable = await userProfileService.isUsernameAvailable(username);

        if (!isAvailable && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(context, 'username_taken_error')),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint('Error checking username availability: $e');
        // Continue anyway - check during final save
      }
    }

    // Create updated profile with the user's name and username
    final updatedProfile = widget.userProfile.copyWith(
      name: _nameController.text.trim(),
      username: username,
    );

    // Navigate to activity level screen instead of completing
    if (mounted) {
      Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ActivityLevelScreen(userProfile: updatedProfile),
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
  }

  @override
  Widget buildScreenContent(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Adaptive waves continue from previous screen
          Positioned.fill(
            child: AnimatedWaves(
              intensity: 0.7,
              personality: widget.userProfile.dominantWavePersonality,
            ),
          ),
          
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  Text(
                    tr(context, 'identity_setup_title'),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    tr(context, 'identity_setup_subtitle'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 60),

                  // Personal Information
                  GlowingTextField(
                    label: tr(context, 'display_name_label'),
                    hint: tr(context, 'display_name_hint'),
                    controller: _nameController,
                  ),

                  GlowingTextField(
                    label: tr(context, 'username_label'),
                    hint: tr(context, 'username_hint'),
                    controller: _usernameController,
                  ),

                  // Physical Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: GlowingTextField(
                          label: tr(context, 'height_label'),
                          hint: tr(context, 'height_hint'),
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GlowingTextField(
                          label: tr(context, 'weight_label'),
                          hint: tr(context, 'weight_hint'),
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),

                  GlowingTextField(
                    label: tr(context, 'age_label'),
                    hint: tr(context, 'age_hint'),
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 40),

                  // Gender Selection
                  Text(
                    tr(context, 'gender_label'),
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _genderOptions.map((option) {
                      final isSelected = _selectedGender == option.value;
                      return FloatingGlowingIcon(
                        icon: option.icon,
                        label: option.label,
                        description: "",
                        isSelected: isSelected,
                        color: const Color(0xFF10B981),
                        onTap: () => _onGenderSelected(option.value),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 60),
                  
                  GlowingButton(
                    text: tr(context, 'continue_button'),
                    onPressed: _isFormValid ? _continue : null,
                    glowIntensity: _isFormValid ? 1.0 : 0.3,
                    width: double.infinity,
                    height: 56,
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

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}

// Helper classes for options
class GenderOption {
  final String value;
  final IconData icon;
  final String label;

  const GenderOption({
    required this.value,
    required this.icon,
    required this.label,
  });
}