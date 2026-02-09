// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Import Firebase options
import 'services/database/notification_service.dart';
import 'services/database/firebase_push_notification_service.dart';
import 'services/chat/data_sync_service.dart';
import 'services/chat/chat_notification_service.dart';
import 'services/user/strike_calculation_service.dart';
import 'services/avatars/avatar_config_loader.dart';
import 'services/firebase/firebase_initialization_service.dart';
import 'services/translation/firebase_translation_service.dart';
import 'services/database/story_service.dart';
import 'services/user/user_cache_manager.dart';

// Import your existing screens
import 'screens/login/login_screen.dart';
import 'screens/onboarding/onboarding_experience.dart';
import 'screens/onboarding/components/onboarding_base_screen.dart';
import 'screens/onboarding/services/onboarding_audio_service.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/health/health_screen.dart';
import 'screens/ai_assistant/ai_assistant_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/routine/routine_creation_screen.dart';
import 'screens/health/meals/meal_edit_screen.dart';
import 'screens/profile/settings/account/personal_info_screen.dart';
import 'widgets/common/lottie_loading_widget.dart';
import 'widgets/common/lottie_loading_widget.dart';
import 'widgets/common/futuristic_nav_bar.dart';
import 'widgets/common/fan_menu_fab.dart';
import 'widgets/splash/lottie_splash_screen.dart';
import 'theme/app_theme.dart';
import 'i18n/app_localizations.dart';
import 'utils/translation_helper.dart';

// Import Riverpod providers
import 'providers/riverpod/theme_provider.dart';
import 'providers/riverpod/language_provider.dart';
import 'providers/riverpod/user_profile_provider.dart';
import 'providers/riverpod/auth_provider.dart' as auth;
import 'providers/riverpod/scroll_controller_provider.dart';
import 'providers/riverpod/splash_provider.dart';
import 'providers/riverpod/initialization_provider.dart';
import 'models/user/user_profile.dart';

import 'firebase_options.dart';

// Global flag to track Firebase initialization
bool isFirebaseAvailable = false;

// Global navigator key for notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Use options for consistency
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Handle background message processing if needed
}

void _setupNotificationNavigation(
  ChatNotificationService chatNotificationService,
) {
  // This would be implemented to handle navigation from notifications
  // For now, we'll just set up the basic structure
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging first
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Load environment variables early (optional for CI/CD)
  // If .env is missing, you already handle it gracefully
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('.env file not found, using system environment variables.');
  }

  // Initialize user cache manager for proper account switching
  try {
    UserCacheManager().initialize();
    debugPrint('User cache manager initialized successfully');
  } catch (e, st) {
    debugPrint('User cache manager initialization failed: $e\n$st');
  }

  // ✅ Firebase MUST be initialized BEFORE runApp to prevent [core/no-app]
  try {
    // If your FirebaseInitializationService already does this internally,
    // it’s still safe to do it here (Firebase.initializeApp is idempotent
    // as long as options match).
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Now run your comprehensive service init (if it does extra setup)
    await FirebaseInitializationService.initialize();

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Try to sign in user anonymously for avatar system access (optional)
    try {
      final user = await FirebaseInitializationService.signInAnonymously();
      debugPrint('Firebase user initialized: ${user?.uid}');
    } catch (e) {
      debugPrint('Anonymous sign-in failed (continuing without it): $e');
    }

    // Initialize Firebase Push Notification Service
    try {
      final firebasePushService = FirebasePushNotificationService();
      await firebasePushService.initialize();
      debugPrint('Firebase Push Notification Service initialized successfully');
    } catch (e, st) {
      debugPrint(
        'Firebase Push Notification Service initialization failed: $e\n$st',
      );
    }

    isFirebaseAvailable = true;
  } catch (e, st) {
    isFirebaseAvailable = false;
    debugPrint('Firebase initialization error: $e\n$st');
    // Continue without Firebase for testing environments
  }

  // Initialize Avatar Configuration System
  try {
    await AvatarConfigLoader.loadConfiguration();
    debugPrint('Avatar configuration system initialized successfully');
  } catch (e, st) {
    debugPrint('Avatar configuration initialization failed: $e\n$st');
  }

  // Initialize Firebase Translation Service if Firebase is available
  if (isFirebaseAvailable) {
    try {
      final translationService = FirebaseTranslationService();
      await translationService.initialize();
      debugPrint('Firebase Translation Service initialized successfully');
    } catch (e, st) {
      debugPrint('Firebase Translation Service initialization failed: $e\n$st');
    }
  }

  // Initialize notification service (local notifications work without Firebase)
  NotificationService? notificationService;
  try {
    notificationService = NotificationService();
    await notificationService.initialize();
  } catch (e, st) {
    debugPrint('Notification service initialization failed: $e\n$st');
  }

  // Initialize strike calculation service for streak notifications
  if (notificationService != null) {
    try {
      final strikeService = StrikeCalculationService(
        notificationService.localNotifications,
      );
      await strikeService.initialize();
      debugPrint('Strike calculation service initialized successfully');
    } catch (e, st) {
      debugPrint('Strike calculation service initialization failed: $e\n$st');
    }
  }

  // Initialize Firebase push notification service if Firebase available
  if (isFirebaseAvailable) {
    try {
      final firebasePushNotificationService = FirebasePushNotificationService();
      await firebasePushNotificationService.initialize();
      debugPrint('Firebase push notification service init failed:');
    } catch (e, st) {
      debugPrint('Firebase push notification service init failed: $e\n$st');
    }
  }

  // Initialize chat notification service if Firebase available
  if (isFirebaseAvailable) {
    try {
      final chatNotificationService = ChatNotificationService();
      await chatNotificationService.initialize();

      // Setup navigation for notification taps
      _setupNotificationNavigation(chatNotificationService);
    } catch (e, st) {
      debugPrint('Chat notification service init failed: $e\n$st');
    }
  }

  // Initialize data sync service if Firebase available
  if (isFirebaseAvailable) {
    try {
      final dataSyncService = DataSyncService();
      await dataSyncService.initializePrivacySettings();
      dataSyncService.startPeriodicSync();
    } catch (e, st) {
      debugPrint('Data sync service init failed: $e\n$st');
    }
  }

  // Initialize story service cleanup if Firebase is available
  if (isFirebaseAvailable) {
    try {
      final storyService = StoryService();
      storyService.scheduleExpiredStoriesCleanup();
      debugPrint('Story service cleanup scheduled successfully');
    } catch (e, st) {
      debugPrint('Story service cleanup initialization failed: $e\n$st');
    }
  }

  // ✅ Now safe to start Flutter rendering
  runApp(const ProviderScope(child: SolarVitaApp()));
}

class SolarVitaApp extends ConsumerStatefulWidget {
  const SolarVitaApp({super.key});

  @override
  ConsumerState<SolarVitaApp> createState() => _SolarVitaAppState();
}

class _SolarVitaAppState extends ConsumerState<SolarVitaApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Stop audio when app is backgrounded or closed
      try {
        final audioService = OnboardingAudioService();
        audioService.fadeOutAmbient();
        debugPrint('🎵 App backgrounded/closed - audio stopped');
      } catch (e) {
        debugPrint('🔇 Error stopping audio on app lifecycle change: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the initialization state
    final initState = ref.watch(initializationNotifierProvider);
    final showSplash = ref.watch(splashNotifierProvider);

    // Always show video splash immediately, regardless of initialization status
    if (showSplash || initState.status == InitializationStatus.initializing) {
      debugPrint(
          '🎬 Showing splash screen - showSplash: $showSplash, initStatus: ${initState.status}');

      // Get locale and supported languages for splash screen localization
      final localeAsync = ref.watch(languageNotifierProvider);
      final supportedLanguages = ref.watch(supportedLanguagesProvider);

      return localeAsync.when(
        data: (locale) {
          return MaterialApp(
            title: 'SolarVita',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            locale: locale,
            supportedLocales:
                supportedLanguages.map((lang) => Locale(lang.code)).toList(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (systemLocale, supportedLocales) {
              // If system locale is supported, use it
              if (systemLocale != null) {
                final languageCode = systemLocale.languageCode;
                for (final supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == languageCode) {
                    debugPrint(
                        '🌍 Splash locale resolution: Using $languageCode (system locale match)');
                    return supportedLocale;
                  }
                }
              }

              // Fallback to English
              debugPrint(
                  '🌍 Splash locale resolution: Falling back to English');
              return const Locale('en');
            },
            home: LottieSplashScreen(
              onAnimationEnd: () {
                debugPrint(
                    '🎬 Animation ended - initStatus: ${initState.status}');
                // Only allow transition if initialization is complete
                if (initState.status == InitializationStatus.completed) {
                  debugPrint('🎬 Completing splash screen');
                  ref.read(splashNotifierProvider.notifier).completeSplash();
                } else {
                  debugPrint('🎬 Waiting for initialization to complete...');
                }
              },
            ),
          );
        },
        loading: () => MaterialApp(
          title: 'SolarVita',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const Scaffold(
            backgroundColor: Color(0xFF0d1117), // Match splash screen
            body: SizedBox.shrink(), // Invisible loading
          ),
        ),
        error: (error, stack) => MaterialApp(
          title: 'SolarVita',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const Scaffold(
            backgroundColor: Colors.black, // Match splash screen
            body: SizedBox.shrink(), // Invisible error state
          ),
        ),
      );
    }

    debugPrint('🎬 Splash complete, building main app');

    // Only show the full app once splash is complete
    final themeMode = ref.watch(themeNotifierProvider);
    final localeAsync = ref.watch(languageNotifierProvider);
    final supportedLanguages = ref.watch(supportedLanguagesProvider);
    final userProfileAsync = ref.watch(userProfileNotifierProvider);
    final authState = ref.watch(auth.authStateChangesProvider);

    debugPrint(
        '🏠 Provider states - auth: ${authState.toString()}, profile: ${userProfileAsync.toString()}');

    return localeAsync.when(
      data: (locale) {
        return MaterialApp(
          title: 'SolarVita',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          themeMode: themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          locale: locale,
          supportedLocales:
              supportedLanguages.map((lang) => Locale(lang.code)).toList(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (systemLocale, supportedLocales) {
            // If system locale is supported, use it
            if (systemLocale != null) {
              final languageCode = systemLocale.languageCode;
              for (final supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == languageCode) {
                  debugPrint(
                      '🌍 Locale resolution: Using $languageCode (system locale match)');
                  return supportedLocale;
                }
              }
            }

            // Fallback to English
            debugPrint('🌍 Locale resolution: Falling back to English');
            return const Locale('en');
          },
          home: _buildHomeScreen(ref, authState, userProfileAsync),
        );
      },
      loading: () => MaterialApp(
        title: 'SolarVita',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const Scaffold(
          backgroundColor: Color(0xFF0d1117), // Match splash screen
          body: SizedBox.shrink(), // Invisible loading
        ),
      ),
      error: (error, stack) => MaterialApp(
        title: 'SolarVita',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const Scaffold(
          backgroundColor: Color(0xFF0d1117), // Match splash screen
          body: SizedBox.shrink(), // Invisible error state
        ),
      ),
    );
  }

  Widget _buildHomeScreen(
    WidgetRef ref,
    AsyncValue<User?> authState,
    AsyncValue<UserProfile?> userProfileAsync,
  ) {
    debugPrint('🏠 Building home screen...');

    // Check if onboarding was interrupted during app lifecycle
    return FutureBuilder<bool>(
      future: OnboardingBaseScreenState.wasOnboardingInterrupted(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: LottieLoadingWidget(width: 80, height: 80)),
          );
        }

        final wasInterrupted = snapshot.data ?? false;
        if (wasInterrupted) {
          debugPrint('🏠 → Onboarding was interrupted, forcing login');
          // Clear the flag and force login
          OnboardingBaseScreenState.clearOnboardingInterrupted();
          return const LoginScreen();
        }

        return _buildHomeScreenFromAuth(ref, authState, userProfileAsync);
      },
    );
  }

  Widget _buildHomeScreenFromAuth(
    WidgetRef ref,
    AsyncValue<User?> authState,
    AsyncValue<UserProfile?> userProfileAsync,
  ) {
    return authState.when(
      data: (user) {
        debugPrint('🏠 Auth data: user = ${user?.email ?? 'null'}');
        if (user == null) {
          debugPrint('🏠 → Showing LoginScreen (no user)');
          return const LoginScreen();
        }

        debugPrint(
            '🏠 UserProfile async state: ${userProfileAsync.toString()}');
        return userProfileAsync.when(
          data: (userProfile) {
            debugPrint(
                '🏠 Profile data: ${userProfile?.email ?? 'null'}, onboardingComplete: ${userProfile?.isOnboardingComplete}');
            if (userProfile == null) {
              debugPrint('🏠 → Showing loading (null profile)');
              return const Scaffold(
                body: Center(child: LottieLoadingWidget(width: 80, height: 80)),
              );
            }

            if (!userProfile.isOnboardingComplete) {
              debugPrint(
                  '🏠 → Showing OnboardingExperience (incomplete onboarding)');
              // Clear any interrupted flag since we're starting fresh onboarding
              OnboardingBaseScreenState.clearOnboardingInterrupted();
              return const OnboardingExperience();
            }

            debugPrint(
                '🏠 → Showing MainNavigationScreen (onboarding complete)');
            return const MainNavigationScreen();
          },
          loading: () {
            debugPrint('🏠 → Showing loading (profile loading)');
            return const Scaffold(
              body: Center(child: LottieLoadingWidget(width: 80, height: 80)),
            );
          },
          error: (error, stack) {
            debugPrint('🏠 → Showing error screen: $error');
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error loading profile: $error'),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(userProfileNotifierProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () {
        debugPrint('🏠 → Showing loading (auth loading)');
        return const Scaffold(
          body: Center(child: LottieLoadingWidget(width: 80, height: 80)),
        );
      },
      error: (error, stack) {
        debugPrint('🏠 → Showing auth error: $error');
        return Scaffold(
            body: Center(child: Text('Authentication error: $error')));
      },
    );
  }
}

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // Scroll controllers for each tab
  late ScrollController _dashboardScrollController;
  late ScrollController _searchScrollController;
  late ScrollController _healthScrollController;
  late ScrollController _profileScrollController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize scroll controllers
    _dashboardScrollController = ScrollController();
    _searchScrollController = ScrollController();
    _healthScrollController = ScrollController();
    _profileScrollController = ScrollController();
  }

  final List<Widget> _pages = [
    const DashboardScreen(),
    const SearchScreen(),
    const AIAssistantScreen(),
    const HealthScreen(),
    const ProfileScreen(),
  ];



  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      // If tapping the same page, scroll to top
      _scrollToTop(index);
    } else {
      // Save current tab's scroll position before switching
      _saveCurrentScrollPosition();

      // Normal navigation
      setState(() {
        _selectedIndex = index;
      });
      _pageController.jumpToPage(index);
    }
  }

  void _saveCurrentScrollPosition() {
    final scrollController =
        ref.read(scrollControllerNotifierProvider.notifier);
    final tabKey = _getTabKey(_selectedIndex);
    if (tabKey != null) {
      scrollController.saveScrollPosition(tabKey);
    }
  }

  String? _getTabKey(int index) {
    switch (index) {
      case 0:
        return 'dashboard';
      case 1:
        return 'search';
      case 2:
        return null; // AI assistant (PULSE) doesn't need scroll memory
      case 3:
        return 'health';
      case 4:
        return 'profile';
      default:
        return null;
    }
  }

  void _scrollToTop(int pageIndex) {
    final scrollController =
        ref.read(scrollControllerNotifierProvider.notifier);
    switch (pageIndex) {
      case 0:
        scrollController.scrollToTop('dashboard');
        break;
      case 1:
        scrollController.scrollToTop('search');
        break;
      case 2:
        // Skip AI assistant - no scroll-to-top functionality
        break;
      case 3:
        scrollController.scrollToTop('health');
        break;
      case 4:
        scrollController.scrollToTop('profile');
        break;
    }
  }

  @override
  void dispose() {
    _saveCurrentScrollPosition(); // Save before disposing
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();

    // Dispose scroll controllers
    _dashboardScrollController.dispose();
    _searchScrollController.dispose();
    _healthScrollController.dispose();
    _profileScrollController.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Save scroll position when app is backgrounded
      _saveCurrentScrollPosition();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allow body content to flow behind the custom nav bar
      appBar: _buildAppBar(),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe gestures
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      floatingActionButton: _buildSmartFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: FuturisticNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    // No app bars for any tabs - Profile will handle its own scroll-aware header
    return null;
  }

  Widget? _buildSmartFAB() {
    // Only show the fan menu FAB on the Dashboard tab
    if (_selectedIndex == 0) {
      // Get the correct scroll controller from the provider
      final scrollController = ref
          .read(scrollControllerNotifierProvider.notifier)
          .getController('dashboard');

      return FanMenuFAB(
        scrollController: scrollController,
        // Let the FAB use its pulse color integration instead of forcing primaryColor
        heroTag: "dashboard_fan_fab",
        menuItems: [
          FanMenuItem(
            icon: Icons.fitness_center,
            label: tr(context, 'quick_workout'),
            color: Theme.of(context).primaryColor,
            onTap: _handleQuickWorkout,
          ),
          FanMenuItem(
            icon: Icons.restaurant,
            label: tr(context, 'add_food'),
            color: Colors.green,
            onTap: _handleAddFood,
          ),
          FanMenuItem(
            icon: Icons.edit,
            label: tr(context, 'edit_profile_info'),
            color: Colors.blueAccent,
            onTap: _handleEditProfile,
          ),
        ],
      );
    }

    // No FAB for other tabs - keeps them clean and focused
    return null;
  }

  void _handleQuickWorkout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RoutineCreationScreen(),
      ),
    );
  }

  void _handleAddFood() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MealEditScreen(),
      ),
    );
  }

  void _handleEditProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PersonalInfoScreen(),
      ),
    );
  }
}
