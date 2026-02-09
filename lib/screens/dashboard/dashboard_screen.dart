// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../dashboard/eco_tips/eco_tips_screen.dart';
import 'package:solar_vitas/theme/app_theme.dart';
import 'package:solar_vitas/utils/translation_helper.dart';
import '../../providers/riverpod/user_profile_provider.dart';
import '../../providers/riverpod/auth_provider.dart';
import '../../widgets/social/social_feed_tabs.dart';
import '../../widgets/common/oriented_image.dart';
import '../social/create_post_screen.dart';
import '../../providers/riverpod/scroll_controller_provider.dart';
import '../../widgets/pulse_background.dart';
import '../../services/health_alerts/pulse_color_manager.dart';
import '../../services/dashboard/dashboard_image_service.dart';
import '../../screens/onboarding/models/onboarding_models.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with TickerProviderStateMixin {
  List<String> _personalizedImages = [];
  String _mainSectionTitle = 'Explore Popular Workouts';
  String _quickSectionTitle = 'Quick Exercise Routines';
  bool _isLoadingImages = true;
  bool _isVitalsMode = false; // Toggle between Explore and Vitals view

  // Pulse color integration for categories
  Color _currentPulseColor = const Color(0xFF4CAF50);
  late AnimationController _pulseReflectionController;

  @override
  void initState() {
    super.initState();
    _initializeHealthSystem();
    _loadPersonalizedContent();
    _setupPulseColorListener();

    // Animation controller for pulse reflection - sync with breathing pulse (4 seconds)
    _pulseReflectionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseReflectionController.dispose();
    try {
      PulseColorManager.instance.removeListener(_onPulseColorChanged);
    } catch (e) {
      debugPrint('Error removing pulse color listener: $e');
    }
    super.dispose();
  }

  void _setupPulseColorListener() {
    try {
      final pulseManager = PulseColorManager.instance;
      pulseManager.addListener(_onPulseColorChanged);
      _currentPulseColor = pulseManager.currentColor;
    } catch (e) {
      debugPrint('Failed to setup pulse color listener: $e');
      _currentPulseColor = const Color(0xFF4CAF50);
    }
  }

  void _onPulseColorChanged() {
    try {
      final newColor = PulseColorManager.instance.currentColor;
      if (mounted && newColor != _currentPulseColor) {
        setState(() {
          _currentPulseColor = newColor;
        });
      }
    } catch (e) {
      debugPrint('Error updating pulse color: $e');
    }
  }

  Future<void> _initializeHealthSystem() async {
    try {
      final colorManager = PulseColorManager.instance;
      await colorManager.initialize(
        vsync: this,
      );
    } catch (e) {
      // Graceful fallback - breathing pulse will still work with default colors
      debugPrint('Health system initialization failed: $e');
    }
  }

  Future<void> _loadPersonalizedContent() async {
    try {
      final userProfile = ref.read(userProfileNotifierProvider).value;

      if (userProfile != null) {
        final images = await DashboardImageService.getPersonalizedImages(userProfile);

        if (mounted) {
          final mainTitle = DashboardImageService.getMainSectionTitle(context, userProfile.selectedIntents);
          final quickTitle = DashboardImageService.getQuickSectionTitle(context, userProfile.selectedIntents);

          setState(() {
            _personalizedImages = images;
            _mainSectionTitle = mainTitle;
            _quickSectionTitle = quickTitle;
            _isLoadingImages = false;
          });
        }
      } else {
        // Fallback for when user profile is not available yet
        if (mounted) {
          setState(() {
            _personalizedImages = [
              'assets/images/dashboard/hiit_fallback.webp',
              'assets/images/dashboard/abs.webp',
              'assets/images/dashboard/Fitness/Mixed/jump.webp',
            ];
            _isLoadingImages = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading personalized content: $e');
      if (mounted) {
        setState(() {
          _personalizedImages = [
            'assets/images/dashboard/hiit.webp',
            'assets/images/dashboard/abs.webp',
            'assets/images/dashboard/Fitness/Mixed/jump.webp',
          ];
          _isLoadingImages = false;
        });
      }
    }
  }

  Future<void> _loadPersonalizedContentForceRefresh() async {
    try {
      final userProfile = ref.read(userProfileNotifierProvider).value;

      if (userProfile != null) {
        debugPrint('🔄 Force refreshing dashboard images for user: ${userProfile.uid}');

        // Set loading state
        if (mounted) {
          setState(() {
            _isLoadingImages = true;
          });
        }

        // Force refresh images (clears cache and generates new set)
        final images = await DashboardImageService.forceRefreshImages(userProfile);

        debugPrint('🎯 Dashboard loaded new images after force refresh: $images');

        if (mounted) {
          final mainTitle = DashboardImageService.getMainSectionTitle(context, userProfile.selectedIntents);
          final quickTitle = DashboardImageService.getQuickSectionTitle(context, userProfile.selectedIntents);

          setState(() {
            _personalizedImages = images;
            _mainSectionTitle = mainTitle;
            _quickSectionTitle = quickTitle;
            _isLoadingImages = false;
          });
        }
      } else {
        debugPrint('⚠️ No user profile available for force refresh, using fallback');
        // Fallback for when user profile is not available yet
        if (mounted) {
          setState(() {
            _personalizedImages = [
              'assets/images/dashboard/hiit_fallback.webp',
              'assets/images/dashboard/abs.webp',
              'assets/images/dashboard/Fitness/Mixed/jump.webp',
            ];
            _isLoadingImages = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error force refreshing personalized content: $e');
      if (mounted) {
        setState(() {
          _personalizedImages = [
            'assets/images/dashboard/hiit.webp',
            'assets/images/dashboard/abs.webp',
            'assets/images/dashboard/Fitness/Mixed/jump.webp',
          ];
          _isLoadingImages = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Listen for user profile changes to reload personalized content
    ref.listen(userProfileNotifierProvider, (previous, next) {
      if (mounted && next.hasValue) {
        final prevProfile = previous?.value;
        final nextProfile = next.value;

        // Check if any personalization-affecting fields changed
        final intentsChanged = prevProfile?.selectedIntents != nextProfile?.selectedIntents;
        final genderChanged = prevProfile?.gender != nextProfile?.gender;
        final genderFromAdditionalDataChanged = prevProfile?.additionalData['gender'] != nextProfile?.additionalData['gender'];
        final ageChanged = prevProfile?.age != nextProfile?.age;

        if (intentsChanged || genderChanged || genderFromAdditionalDataChanged || ageChanged) {
          debugPrint('🔄 Dashboard detected profile changes, force refreshing images');
          if (intentsChanged) {
            debugPrint('Previous intents: ${prevProfile?.selectedIntents}');
            debugPrint('New intents: ${nextProfile?.selectedIntents}');
          }
          if (genderChanged) {
            debugPrint('Previous gender: ${prevProfile?.gender}');
            debugPrint('New gender: ${nextProfile?.gender}');
          }
          if (genderFromAdditionalDataChanged) {
            debugPrint('Previous gender (additionalData): ${prevProfile?.additionalData['gender']}');
            debugPrint('New gender (additionalData): ${nextProfile?.additionalData['gender']}');
          }
          if (ageChanged) {
            debugPrint('Previous age: ${prevProfile?.age}');
            debugPrint('New age: ${nextProfile?.age}');
          }

          // Immediately show loading state while refreshing
          setState(() {
            _isLoadingImages = true;
          });

          _loadPersonalizedContentForceRefresh();
        }
      }
    });

    // Get scroll controller directly in build method
    final scrollController = ref.read(scrollControllerNotifierProvider.notifier).getController('dashboard');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false, // Allow content to flow behind nav bar
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final userProfileAsync = ref.watch(
                      userProfileNotifierProvider,
                    );
                    final currentUser = ref.watch(currentUserProvider);

                    final userProfile = userProfileAsync.value;

                    String displayName =
                        userProfile?.displayName ??
                        currentUser?.displayName ??
                        'Fitness Enthusiast';

                    String? profileImageUrl =
                        userProfile?.photoURL ?? currentUser?.photoURL;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: profileImageUrl != null
                                    ? CachedNetworkImageProvider(
                                        profileImageUrl,
                                      )
                                    : null,
                                backgroundColor: AppTheme.textFieldBackground(
                                  context,
                                ),
                                child: profileImageUrl == null
                                    ? Icon(
                                        Icons.person,
                                        color: theme.iconTheme.color,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr(context, 'welcome'),
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(color: theme.hintColor),
                                    ),
                                    Text(
                                      displayName,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 19,
                                            color: AppTheme.textColor(context),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EcoTipsScreen(),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: theme.primaryColor.withAlpha(25),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            tr(context, 'eco_tips'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Dynamic Main Section with Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _isVitalsMode ? tr(context, 'your_vitals') : _mainSectionTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Context-aware toggle - shows destination mode
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isVitalsMode = !_isVitalsMode;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isVitalsMode
                              ? theme.primaryColor.withAlpha(25)
                              : _currentPulseColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isVitalsMode
                                ? theme.primaryColor.withAlpha(60)
                                : _currentPulseColor.withAlpha(60),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isVitalsMode ? Icons.explore : Icons.monitor_heart,
                              size: 16,
                              color: _isVitalsMode ? theme.primaryColor : _currentPulseColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isVitalsMode ? tr(context, 'explore') : tr(context, 'vitals'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _isVitalsMode ? theme.primaryColor : _currentPulseColor,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right,
                              size: 14,
                              color: _isVitalsMode ? theme.primaryColor : _currentPulseColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                
                // Conditional content based on mode
                if (!_isVitalsMode) ...[
                  // === EXPLORE VIEW ===
                  if (_isLoadingImages)
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: theme.cardColor.withAlpha(128),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(color: theme.primaryColor),
                      ),
                    )
                  else if (_personalizedImages.isNotEmpty)
                    Builder(
                      builder: (context) {
                        final userProfile = ref.read(userProfileNotifierProvider).value;
                        final intents = userProfile?.selectedIntents ?? <IntentType>{};
                        final titleKey = DashboardImageService.getActivityTitle(_personalizedImages.first, intents);
                        final authorKey = DashboardImageService.getActivityLabel(_personalizedImages.first, intents);

                        return _buildWorkoutCard(
                          title: tr(context, titleKey),
                          author: tr(context, authorKey),
                          isPremium: true,
                          color: Colors.green,
                          imagePath: _personalizedImages.first,
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  // Dynamic Quick Section
                  Text(
                    _quickSectionTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingImages)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: theme.cardColor.withAlpha(128),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(color: theme.primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: theme.cardColor.withAlpha(128),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(color: theme.primaryColor),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (_personalizedImages.length >= 2)
                    Builder(
                      builder: (context) {
                        final userProfile = ref.read(userProfileNotifierProvider).value;
                        final intents = userProfile?.selectedIntents ?? <IntentType>{};

                        final secondImagePath = _personalizedImages[1];
                        final thirdImagePath = _personalizedImages.length > 2
                            ? _personalizedImages[2]
                            : _personalizedImages[1];

                        final secondTitleKey = DashboardImageService.getActivityTitle(secondImagePath, intents);
                        final secondAuthorKey = DashboardImageService.getActivityLabel(secondImagePath, intents);
                        final thirdTitleKey = DashboardImageService.getActivityTitle(thirdImagePath, intents);
                        final thirdAuthorKey = DashboardImageService.getActivityLabel(thirdImagePath, intents);

                        return Row(
                          children: [
                            Expanded(
                              child: _buildExerciseCard(
                                title: tr(context, secondTitleKey),
                                author: tr(context, secondAuthorKey),
                                imagePath: secondImagePath,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildExerciseCard(
                                title: tr(context, thirdTitleKey),
                                author: tr(context, thirdAuthorKey),
                                imagePath: thirdImagePath,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  // Categories
                  Text(
                    tr(context, 'fitness_categories'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCategoryIcon(
                        Icons.fitness_center,
                        tr(context, 'gym'),
                        0,
                      ),
                      _buildCategoryIcon(
                        Icons.directions_run,
                        tr(context, 'hiit'),
                        1,
                      ),
                      _buildCategoryIcon(
                        Icons.forest,
                        tr(context, 'mindful'),
                        2,
                      ),
                      _buildCategoryIcon(
                        Icons.sports_volleyball,
                        tr(context, 'toned'),
                        3,
                      ),
                      _buildCategoryIcon(
                        Icons.local_drink_outlined,
                        tr(context, 'supplements'),
                        4,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Breathing Pulse Section
                  ScrollAwarePulseWithFly(
                    scrollController: scrollController,
                    height: 280,
                  ),

                  const SizedBox(height: 24),

                  // Social Feed Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor.withValues(alpha: 0.05),
                          theme.primaryColor.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.people, size: 20, color: theme.primaryColor),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr(context, 'from_the_community'),
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textColor(context),
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Connect, share, inspire',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textColor(context).withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreatePostScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.primaryColor,
                                  theme.primaryColor.withValues(alpha: 0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SocialFeedTabs(),
                ] else ...[
                  // === VITALS VIEW ===
                  // Weekly Streak Section
                  _buildWeeklyStreakCard(theme),
                  const SizedBox(height: 20),
                  
                  // Calorie Summary Cards
                  _buildCalorieCards(theme),
                  const SizedBox(height: 20),
                  
                  // Today's Health Stats
                  _buildHealthStatsCard(theme),
                  const SizedBox(height: 20),
                  
                  // Quick Actions
                  _buildVitalsQuickActions(theme),
                ],
                const SizedBox(height: 100), // Bottom padding for nav bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutCard({
    required String title,
    required String author,
    required bool isPremium,
    required Color color,
    required String imagePath,
  }) {
    return Container(
      height: 160,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withAlpha(77),
                BlendMode.darken,
              ),
              child: OrientedImage(
                imageUrl: imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 160,
              ),
            ),
            if (isPremium)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: FittedBox(
                    // Added FittedBox
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tr(context, 'upgrade'),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star, size: 16, color: Colors.black),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: SizedBox(
                // Added Container with width constraint
                width:
                    MediaQuery.of(context).size.width -
                    64, // Account for padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Added to minimize height
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14, // Reduced font size
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      author,
                      style: const TextStyle(
                        fontSize: 12, // Reduced font size
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard({
    required String title,
    required String author,
    required String imagePath,
  }) {
    return Container(
      height: 120,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withAlpha(77),
                BlendMode.darken,
              ),
              child: OrientedImage(
                imageUrl: imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 120,
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.star, size: 14, color: Colors.black),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    author,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(IconData icon, String label, int positionIndex) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final glassBase = isDarkMode ? Colors.white : Colors.black;
    final iconColor = isDarkMode ? Colors.white : Colors.black;
    final shadowColor = isDarkMode ? Colors.black : Colors.grey.shade400;

    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseReflectionController,
          builder: (context, child) {
            final animValue = _pulseReflectionController.value;

            // Calculate distance from center (index 2)
            final distanceFromCenter = (positionIndex - 2).abs();

            // Match the breathing pulse pattern - normal (same as pulse)
            // Reflection appears on INHALE (pulse expands), disappears on EXHALE
            double breathingValue;
            if (animValue <= 0.4) {
              // Inhale - reflection appears
              breathingValue = Curves.easeInOut.transform(animValue / 0.4);
            } else if (animValue <= 0.6) {
              // Hold - maximum reflection
              breathingValue = 1.0;
            } else {
              // Exhale - reflection disappears
              double exhaleProgress = (animValue - 0.6) / 0.4;
              breathingValue = 1.0 - Curves.easeInOut.transform(exhaleProgress);
            }

            // Intensity based on distance from center - stronger falloff
            // Center (index 2, distance 0) = 1.0 (100%)
            // Adjacent (index 1 or 3, distance 1) = 0.5 (50%)
            // Edges (index 0 or 4, distance 2) = 0.2 (20%)
            final intensityMultiplier = distanceFromCenter == 0
                ? 1.0
                : distanceFromCenter == 1
                    ? 0.5
                    : 0.2;

            // Final reflection intensity with breathing wave effect
            final reflectionIntensity = breathingValue * intensityMultiplier;

            return Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    glassBase.withValues(alpha: isDarkMode ? 0.2 : 0.06),
                    glassBase.withValues(alpha: isDarkMode ? 0.08 : 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: glassBase.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withValues(alpha: isDarkMode ? 0.8 : 0.4),
                    blurRadius: 20,
                    offset: Offset(0, isDarkMode ? 6 : 8),
                  ),
                  if (isDarkMode)
                    BoxShadow(
                      color: glassBase.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, -3),
                    ),
                  // Pulse color reflection glow - very subtle, only on exhale
                  BoxShadow(
                    color: _currentPulseColor.withValues(
                      alpha: (reflectionIntensity * 0.08) * (isDarkMode ? 1.0 : 0.5),
                    ),
                    blurRadius: 8 + (reflectionIntensity * 6),
                    offset: const Offset(0, 3),
                    spreadRadius: -3,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Pulse reflection shimmer overlay - subtle hint from bottom on exhale
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 24, // Only affect bottom quarter of icon
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              // Very subtle reflection at bottom edge only
                              _currentPulseColor.withValues(
                                alpha: (reflectionIntensity * 0.12) * (isDarkMode ? 1.0 : 0.5),
                              ),
                              // Quick fade to transparent
                              Colors.transparent,
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Icon
                  Center(
                    child: Icon(
                      icon,
                      color: iconColor.withValues(alpha: 0.9),
                      size: 24,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
      ],
    );
  }

  // === VITALS VIEW HELPER METHODS (FUTURISTIC DESIGN) ===

  Widget _buildWeeklyStreakCard(ThemeData theme) {
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final now = DateTime.now();
    final currentDayIndex = now.weekday % 7; // 0 = Sunday

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with subtitle
          Row(
            children: [
              Text(
                tr(context, 'weekly_progress'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
              Text(
                ' · Get toned!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textColor(context).withAlpha(120),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Day circles with achievement badges
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.textColor(context).withAlpha(8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final isCompleted = index < currentDayIndex;
                final isToday = index == currentDayIndex;
                return Column(
                  children: [
                    // Day letter
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isToday
                            ? _currentPulseColor
                            : AppTheme.textColor(context).withAlpha(100),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Achievement circle
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? LinearGradient(
                                colors: [
                                  _currentPulseColor,
                                  _currentPulseColor.withAlpha(180),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isCompleted
                            ? null
                            : isToday
                                ? _currentPulseColor.withAlpha(30)
                                : AppTheme.textColor(context).withAlpha(15),
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: _currentPulseColor, width: 2)
                            : null,
                        boxShadow: isCompleted
                            ? [
                                BoxShadow(
                                  color: _currentPulseColor.withAlpha(60),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(
                                Icons.local_fire_department,
                                color: Colors.white,
                                size: 20,
                              )
                            : isToday
                                ? Icon(
                                    Icons.local_fire_department,
                                    color: _currentPulseColor,
                                    size: 18,
                                  )
                                : null,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieCards(ThemeData theme) {
    // Two pill-shaped stat cards side by side
    return Row(
      children: [
        Expanded(
          child: _buildPillStatCard(
            theme,
            icon: Icons.schedule,
            mainText: '+2h 15m',
            subText: 'added to weekly goal',
            color: _currentPulseColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPillStatCard(
            theme,
            icon: Icons.local_fire_department,
            mainText: '1306/2000 Kcal',
            subText: 'burned this week',
            color: _currentPulseColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPillStatCard(
    ThemeData theme, {
    required IconData icon,
    required String mainText,
    required String subText,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mainText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
                Text(
                  subText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textColor(context).withAlpha(120),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStatsCard(ThemeData theme) {
    // Large gradient workout card like reference
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _currentPulseColor.withAlpha(220),
            _currentPulseColor.withAlpha(160),
            _currentPulseColor.withAlpha(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _currentPulseColor.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decoration circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: 20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workout title
                Text(
                  'Cardio: Core',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '125 Kcal',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withAlpha(200),
                  ),
                ),
                const SizedBox(height: 12),
                // Info pills
                Row(
                  children: [
                    _buildInfoPill('Exercises 16'),
                    const SizedBox(width: 8),
                    _buildInfoPill('Duration 25m'),
                  ],
                ),
                const SizedBox(height: 12),
                // Exercise thumbnails row
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildExerciseThumbnail(Icons.fitness_center, '16'),
                      _buildExerciseThumbnail(Icons.accessibility_new, '20'),
                      _buildExerciseThumbnail(Icons.sports_gymnastics, '60'),
                      _buildExerciseThumbnail(Icons.self_improvement, '28'),
                      _buildExerciseThumbnail(Icons.timer, '2:00'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildExerciseThumbnail(IconData icon, String reps) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 2),
          Text(
            reps,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsQuickActions(ThemeData theme) {
    // Large Start Workout button
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to workout
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _currentPulseColor,
              _currentPulseColor.withAlpha(200),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _currentPulseColor.withAlpha(100),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              tr(context, 'start_workout'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
