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

  @override
  void initState() {
    super.initState();
    _initializeHealthSystem();
    _loadPersonalizedContent();
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
        final mainTitle = DashboardImageService.getMainSectionTitle(userProfile.selectedIntents);
        final quickTitle = DashboardImageService.getQuickSectionTitle(userProfile.selectedIntents);

        if (mounted) {
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
              'assets/images/dashboard/hiit.webp',
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
        final mainTitle = DashboardImageService.getMainSectionTitle(userProfile.selectedIntents);
        final quickTitle = DashboardImageService.getQuickSectionTitle(userProfile.selectedIntents);

        debugPrint('🎯 Dashboard loaded new images after force refresh: $images');

        if (mounted) {
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
              'assets/images/dashboard/hiit.webp',
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
        final ageChanged = prevProfile?.age != nextProfile?.age;

        if (intentsChanged || genderChanged || ageChanged) {
          debugPrint('🔄 Dashboard detected profile changes, force refreshing images');
          if (intentsChanged) {
            debugPrint('Previous intents: ${prevProfile?.selectedIntents}');
            debugPrint('New intents: ${nextProfile?.selectedIntents}');
          }
          if (genderChanged) {
            debugPrint('Previous gender: ${prevProfile?.gender}');
            debugPrint('New gender: ${nextProfile?.gender}');
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

                // Dynamic Main Section
                Text(
                  _mainSectionTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),
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
                    ),
                    _buildCategoryIcon(
                      Icons.directions_run,
                      tr(context, 'hiit'),
                    ),
                    _buildCategoryIcon(Icons.forest, tr(context, 'mindful')),
                    _buildCategoryIcon(
                      Icons.sports_volleyball,
                      tr(context, 'toned'),
                    ),
                    _buildCategoryIcon(
                      Icons.local_drink_outlined,
                      tr(context, 'supplements'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Breathing Pulse Section with FIRST FLY transition
                ScrollAwarePulseWithFly(
                  scrollController: scrollController,
                  height: 280,
                ),

                const SizedBox(height: 24),

                // Social Feed Section with Tabs - Glassmorphism Design
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
                      // Plus button for creating posts - Enhanced design
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
                const SizedBox(height: 32), // Add bottom padding to ensure tabs are fully visible
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

  Widget _buildCategoryIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
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
}
