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

// Import your existing screens
import 'screens/welcome/welcome_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/health/health_screen.dart';
import 'screens/ai_assistant/ai_assistant_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'widgets/common/lottie_loading_widget.dart';
import 'widgets/common/bottom_nav_bar.dart';
import 'widgets/splash/video_splash_screen.dart';
import 'theme/app_theme.dart';
import 'i18n/app_localizations.dart';

// Import Riverpod providers
import 'providers/riverpod/theme_provider.dart';
import 'providers/riverpod/language_provider.dart';
import 'providers/riverpod/user_profile_provider.dart';
import 'providers/riverpod/auth_provider.dart' as auth;
import 'providers/riverpod/scroll_controller_provider.dart';
import 'providers/riverpod/splash_provider.dart';
import 'providers/riverpod/initialization_provider.dart';
import 'models/user/user_profile.dart';

// Global flag to track Firebase initialization
bool isFirebaseAvailable = false;

// Global navigator key for notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message processing if needed
}

void _setupNotificationNavigation(
  ChatNotificationService chatNotificationService,
) {
  // This would be implemented to handle navigation from notifications
  // For now, we'll just set up the basic structure
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show video splash immediately while everything else loads in background
  runApp(ProviderScope(child: const SolarVitaApp()));

  // Initialize logging first
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  try {
    // Initialize Firebase using our comprehensive initialization service
    await FirebaseInitializationService.initialize();
    
    // Sign in user anonymously for avatar system access
    final user = await FirebaseInitializationService.signInAnonymously();
    debugPrint('Firebase user initialized: ${user?.uid}');

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
    debugPrint('Firebase initialization error: $e\n$st');
    // Continue without Firebase for testing environments
  }

  // Initialize Avatar Configuration System
  try {
    await AvatarConfigLoader.loadConfiguration();
    debugPrint('Avatar configuration system initialized successfully');
  } catch (e, st) {
    debugPrint('Avatar configuration initialization failed: $e\n$st');
    // Continue without avatar system in case of errors
  }

  // Initialize Firebase Translation Service if Firebase is available
  if (isFirebaseAvailable) {
    try {
      final translationService = FirebaseTranslationService();
      await translationService.initialize();
      debugPrint('Firebase Translation Service initialized successfully');
    } catch (e, st) {
      debugPrint('Firebase Translation Service initialization failed: $e\n$st');
      // Continue without Firebase translations - static translations will still work
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
      debugPrint('Firebase push notification service initialized successfully');
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

  // Load environment variables (optional for CI/CD)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('.env file not found, using system environment variables.');
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

  // Google Maps service removed - no longer needed
}

class SolarVitaApp extends ConsumerWidget {
  const SolarVitaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the initialization state
    final initState = ref.watch(initializationNotifierProvider);
    final showSplash = ref.watch(splashNotifierProvider);
    
    // Always show video splash immediately, regardless of initialization status
    if (showSplash || initState.status == InitializationStatus.initializing) {
      return MaterialApp(
        title: 'SolarVita',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: VideoSplashScreen(
          onVideoEnd: () {
            // Only allow transition if initialization is complete
            if (initState.status == InitializationStatus.completed) {
              ref.read(splashNotifierProvider.notifier).completeSplash();
            }
          },
          duration: const Duration(seconds: 4), // Extended to ensure smooth init
        ),
      );
    }

    // Only show the full app once splash is complete
    final themeMode = ref.watch(themeNotifierProvider);
    final localeAsync = ref.watch(languageNotifierProvider);
    final supportedLanguages = ref.watch(supportedLanguagesProvider);
    final userProfileAsync = ref.watch(userProfileNotifierProvider);
    final authState = ref.watch(auth.authStateChangesProvider);

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
          supportedLocales: supportedLanguages
              .map((lang) => Locale(lang.code))
              .toList(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: _buildHomeScreen(ref, authState, userProfileAsync),
        );
      },
      loading: () => MaterialApp(
        title: 'SolarVita',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const Scaffold(
          backgroundColor: Colors.black, // Match splash screen
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

  Widget _buildHomeScreen(
    WidgetRef ref,
    AsyncValue<User?> authState,
    AsyncValue<UserProfile?> userProfileAsync,
  ) {
    return authState.when(
      data: (user) {
        if (user == null) {
          return const WelcomeScreen();
        }

        return userProfileAsync.when(
          data: (userProfile) {
            if (userProfile == null) {
              return const Scaffold(
                body: Center(child: LottieLoadingWidget(width: 80, height: 80)),
              );
            }

            if (!userProfile.isOnboardingComplete) {
              return const OnboardingScreen();
            }

            return const MainNavigationScreen();
          },
          loading: () => const Scaffold(
            body: Center(child: LottieLoadingWidget(width: 80, height: 80)),
          ),
          error: (error, stack) => Scaffold(
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
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: LottieLoadingWidget(width: 80, height: 80)),
      ),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Authentication error: $error'))),
    );
  }
}

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const DashboardScreen(),
    const SearchScreen(),
    const HealthScreen(),
    const AIAssistantScreen(),
    const ProfileScreen(),
  ];

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.dashboard, labelKey: 'nav_dashboard'),
    NavItem(icon: Icons.search, labelKey: 'nav_search'),
    NavItem(icon: Icons.health_and_safety, labelKey: 'nav_health'),
    NavItem(icon: Icons.assistant, labelKey: 'nav_solar_ai'),
    NavItem(icon: Icons.person, labelKey: 'nav_profile'),
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      // If tapping the same page, scroll to top
      _scrollToTop(index);
    } else {
      // Normal navigation
      setState(() {
        _selectedIndex = index;
      });
      _pageController.jumpToPage(index);
    }
  }

  void _scrollToTop(int pageIndex) {
    final scrollController = ref.read(scrollControllerNotifierProvider.notifier);
    switch (pageIndex) {
      case 0:
        scrollController.scrollToTop('dashboard');
        break;
      case 1:
        scrollController.scrollToTop('search');
        break;
      case 2:
        scrollController.scrollToTop('health');
        break;
      case 3:
        // Skip AI assistant - no scroll-to-top functionality
        break;
      case 4:
        scrollController.scrollToTop('profile');
        break;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: _navItems,
      ),
    );
  }
}
