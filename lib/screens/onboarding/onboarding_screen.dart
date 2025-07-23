import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../widgets/common/lottie_loading_widget.dart';
import '../../widgets/common/oriented_image.dart';
import 'personal_info_preferences_screen.dart';

final _logger = Logger('OnboardingScreen');

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final bool _isLoading = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to SolarVita',
      description: 'Your personal companion for fitness, health, and sustainable living.',
      image: 'assets/images/welcome_illustration.png',
    ),
    OnboardingPage(
      title: 'Track Your Fitness Journey',
      description: 'Monitor your workouts, set goals, and achieve your fitness objectives.',
      image: 'assets/images/fitness1.webp',
    ),
    OnboardingPage(
      title: 'Live Sustainably',
      description: 'Reduce your carbon footprint and make eco-friendly choices.',
      image: 'assets/images/fitness2.webp',
    ),
    OnboardingPage(
      title: 'Keep a Personal Diary',
      description: 'Document your progress, thoughts, and achievements.',
      image: 'assets/images/fitness3.webp',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _startPreferencesSetup();
    }
  }

  void _skipOnboarding() {
    _startPreferencesSetup();
  }

  void _startPreferencesSetup() {
    _logger.info('🚀 Starting preferences setup - navigating to PersonalInfoPreferencesScreen');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const PersonalInfoPreferencesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.info('🎯 OnboardingScreen build() called - current page: $_currentPage');
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
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
            child: OrientedImage(
              imageUrl: page.image,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
                        _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
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