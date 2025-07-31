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
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/firebase_push_notification_service.dart';
import 'services/data_sync_service.dart';
import 'services/chat_notification_service.dart';
import 'services/strike_calculation_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

// Import your existing screens
import 'screens/welcome/welcome_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/health/health_screen.dart';
import 'screens/ai_assistant/ai_assistant_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'widgets/common/lottie_loading_widget.dart';
import 'theme/app_theme.dart';
import 'i18n/app_localizations.dart';
import 'utils/translation_helper.dart';

// Import Riverpod providers
import 'providers/riverpod/theme_provider.dart';
import 'providers/riverpod/language_provider.dart';
import 'providers/riverpod/user_profile_provider.dart';
import 'providers/riverpod/auth_provider.dart' as auth;
import 'models/user_profile.dart';

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

  // Initialize logging first
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  try {
    // Initialize Firebase once
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Activate Firebase App Check with appropriate providers
    try {
      await FirebaseAppCheck.instance.activate(
        // Use debug providers only in debug mode to avoid rate limiting
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
        // In production, you should use:
        // androidProvider: AndroidProvider.playIntegrity,
        // appleProvider: AppleProvider.appAttest,
      );
      
      // Only get token in debug mode to avoid unnecessary requests
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        final token = await FirebaseAppCheck.instance.getToken();
        debugPrint('[FirebaseAppCheck] Debug token available: ${token != null}');
      }
    } catch (e) {
      debugPrint('Firebase App Check initialization failed: $e');
      // Continue without App Check in case of errors
    }

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize Firebase Push Notification Service
    try {
      final firebasePushService = FirebasePushNotificationService();
      await firebasePushService.initialize();
      debugPrint('Firebase Push Notification Service initialized successfully');
    } catch (e, st) {
      debugPrint('Firebase Push Notification Service initialization failed: $e\n$st');
    }

    isFirebaseAvailable = true;
  } catch (e, st) {
    debugPrint('Firebase initialization error: $e\n$st');
    // Continue without Firebase for testing environments
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
      final strikeService = StrikeCalculationService(notificationService.localNotifications);
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

  // Google Maps service removed - no longer needed

  runApp(ProviderScope(child: const SolarVitaApp()));
}

class SolarVitaApp extends ConsumerWidget {
  const SolarVitaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the theme and language providers
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
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(
            child: LottieLoadingWidget(width: 80, height: 80)
          )
        ),
      ),
      error: (error, stack) => MaterialApp(
        home: Scaffold(body: Center(child: Text('Error loading app: $error'))),
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
                body: Center(
                  child: LottieLoadingWidget(width: 80, height: 80)
                )
              );
            }

            if (!userProfile.isOnboardingComplete) {
              return const OnboardingScreen();
            }

            return const MainNavigationScreen();
          },
          loading: () => const Scaffold(
            body: Center(
              child: LottieLoadingWidget(width: 80, height: 80)
            )
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
        body: Center(
          child: LottieLoadingWidget(width: 80, height: 80)
        )
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: AppTheme.navigationBackground(context),
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: tr(context, 'nav_dashboard'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search), 
            label: tr(context, 'nav_search')
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.health_and_safety),
            label: tr(context, 'nav_health'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assistant),
            label: tr(context, 'nav_solar_ai'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person), 
            label: tr(context, 'nav_profile')
          ),
        ],
      ),
    );
  }
}
