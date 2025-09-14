import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import '../dashboard/dashboard_screen.dart';
import 'services/onboarding_audio_service.dart';

/// Demo launcher to showcase the futuristic onboarding experience
/// This can be integrated into the main app's routing system
class OnboardingDemoLauncher extends StatefulWidget {
  const OnboardingDemoLauncher({super.key});

  @override
  State<OnboardingDemoLauncher> createState() => _OnboardingDemoLauncherState();
}

class _OnboardingDemoLauncherState extends State<OnboardingDemoLauncher> {
  final OnboardingAudioService _audioService = OnboardingAudioService();

  @override
  void initState() {
    super.initState();
    _initializeGlobalAudio();
  }

  void _initializeGlobalAudio() async {
    try {
      debugPrint('🎵 Initializing global audio for entire onboarding experience...');
      await _audioService.initialize();
      await _audioService.startAmbientTrack(fadeInDuration: const Duration(seconds: 2));
      debugPrint('🎵 Global audio started - will continue throughout onboarding');
    } catch (e) {
      debugPrint('🔇 Global audio initialization failed: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF10B981),
                  ),
                  child: const Icon(
                    Icons.wb_sunny,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                const Text(
                  'SolarVita Onboarding Demo',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                const Text(
                  'Experience the futuristic ceremonial onboarding flow',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 80),
                
                // Start Demo Button
                _buildDemoButton(
                  context,
                  title: 'Start Ceremonial Journey',
                  subtitle: 'Experience the full onboarding flow',
                  icon: Icons.auto_awesome,
                  color: const Color(0xFF10B981),
                  onPressed: () => _startOnboardingDemo(context),
                ),
                
                const SizedBox(height: 20),
                
                // Reset Demo Button
                _buildDemoButton(
                  context,
                  title: 'Reset Demo',
                  subtitle: 'Clear saved preferences',
                  icon: Icons.refresh,
                  color: const Color(0xFF3B82F6),
                  onPressed: () => _resetDemo(context),
                ),
                
                const SizedBox(height: 20),
                
                // Skip to Dashboard
                _buildDemoButton(
                  context,
                  title: 'Skip to Dashboard',
                  subtitle: 'Go directly to main app',
                  icon: Icons.dashboard,
                  color: const Color(0xFF8B5CF6),
                  onPressed: () => _goToDashboard(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.2),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startOnboardingDemo(BuildContext context) {
    // Reset first launch to trigger the onboarding flow
    _setFirstLaunch(true);
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      ),
    );
  }

  void _resetDemo(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    if (mounted) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content: Text('Demo preferences cleared!'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _goToDashboard(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const DashboardScreen(),
      ),
    );
  }

  void _setFirstLaunch(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('firstLaunch', value);
  }
}