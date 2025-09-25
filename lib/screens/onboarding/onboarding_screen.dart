import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../widgets/common/lottie_loading_widget.dart';
import '../../widgets/common/oriented_image.dart';
import '../../providers/riverpod/auth_provider.dart';
import 'personal_info_preferences_screen.dart';
import 'services/onboarding_audio_service.dart';
import 'components/onboarding_base_screen.dart';

final _logger = Logger('OnboardingScreen');

class OnboardingScreen extends OnboardingBaseScreen {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends OnboardingBaseScreenState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final bool _isLoading = false;
  final OnboardingAudioService _audioService = OnboardingAudioService();
  bool _isNavigatingProgrammatically = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to SolarVita',
      description:
          'Your personal companion for fitness, health, and sustainable living.',
      image: 'assets/images/welcome_illustration.webp',
    ),
    OnboardingPage(
      title: 'Track Your Fitness Journey',
      description:
          'Monitor your workouts, set goals, and achieve your fitness objectives.',
      image: 'assets/images/fitness1.webp',
    ),
    OnboardingPage(
      title: 'Live Sustainably',
      description:
          'Reduce your carbon footprint and make eco-friendly choices.',
      image: 'assets/images/fitness2.webp',
    ),
    OnboardingPage(
      title: 'Keep a Personal Diary',
      description: 'Document your progress, thoughts, and achievements.',
      image: 'assets/images/fitness3.webp',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize audio service for sound effects
    _audioService.initialize();
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Don't dispose audio service here - it's managed globally by OnboardingExperience
    debugPrint('🎵 OnboardingScreen disposed - keeping audio service for other screens');
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      // Play continue sound for button navigation (not swipe sound)
      _audioService.playContinueSound();
      _isNavigatingProgrammatically = true;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Play continue sound for "Get Started" - final navigation action
      _audioService.playContinueSound();
      _startPreferencesSetup();
    }
  }

  void _skipOnboarding() {
    // Play button sound for skip action
    _audioService.playButtonSound();
    _startPreferencesSetup();
  }

  void _startPreferencesSetup() {
    _logger.info(
      '🚀 Starting preferences setup - navigating to PersonalInfoPreferencesScreen',
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const PersonalInfoPreferencesScreen(),
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.signOut();
      // Navigation will be handled automatically by the main app routing
    } catch (e) {
      _logger.severe('Logout failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sign out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text(
            'Are you sure you want to sign out? You can complete onboarding later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget buildScreenContent(BuildContext context) {
    _logger.info(
      '🎯 OnboardingScreen build() called - current page: $_currentPage',
    );
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: _showLogoutConfirmation,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign Out'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                // Play swipe sound ONLY for manual swipes, not programmatic navigation
                if (_currentPage != index && !_isNavigatingProgrammatically) {
                  debugPrint('🎵 Manual swipe detected - playing swipe sound');
                  _audioService.playSwipeSound();
                }

                // Reset the programmatic navigation flag
                _isNavigatingProgrammatically = false;

                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _buildPage(_pages[index]);
              },
            ),
          ),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: OrientedImage(imageUrl: page.image, fit: BoxFit.contain),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _currentPage == 0 ? null : _skipOnboarding,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: _currentPage == 0 ? Colors.transparent : null,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _nextPage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: LottieLoadingWidget(width: 20, height: 20),
                      )
                    : Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String image;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
  });
}
