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
import 'services/data_sync_service.dart';
import 'services/chat_notification_service.dart';

// Import your existing screens
import 'screens/welcome/welcome_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/health/health_screen.dart';
import 'screens/ai_assistant/ai_assistant_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'theme/app_theme.dart';
import 'i18n/app_localizations.dart';

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

void _setupNotificationNavigation(ChatNotificationService chatNotificationService) {
  // This would be implemented to handle navigation from notifications
  // For now, we'll just set up the basic structure
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Rive initialization is handled automatically

  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // Logging configured - remove debugPrint for production
  });

  // Initialize Firebase (graceful handling for test/CI environments)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    isFirebaseAvailable = true;
  } catch (e) {
    // Continue without Firebase for testing
  }

  // Initialize notification service (local notifications work without Firebase)
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
  } catch (e) {
    // Notification service initialization failed - continue without notifications
  }

  // Initialize chat notification service
  if (isFirebaseAvailable) {
    try {
      final chatNotificationService = ChatNotificationService();
      await chatNotificationService.initialize();
      
      // Set up navigation for notification taps
      _setupNotificationNavigation(chatNotificationService);
    } catch (e) {
      // Chat notification service initialization failed - continue without chat notifications
    }
  }

  // Initialize data sync service for Firebase integration
  if (isFirebaseAvailable) {
    try {
      final dataSyncService = DataSyncService();
      await dataSyncService.initializePrivacySettings();
      dataSyncService.startPeriodicSync();
    } catch (e) {
      // Data sync initialization failed - continue without sync
    }
  }

  // Load environment variables (optional for CI/CD)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env file not found, using environment variables from system
  }

  runApp(
    ProviderScope(
      child: const SolarVitaApp(),
    ),
  );
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
          supportedLocales:
              supportedLanguages.map((lang) => Locale(lang.code)).toList(),
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
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error loading app: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeScreen(WidgetRef ref, AsyncValue<User?> authState,
      AsyncValue<UserProfile?> userProfileAsync) {
    return authState.when(
      data: (user) {
        if (user == null) {
          return const WelcomeScreen();
        }

        return userProfileAsync.when(
          data: (userProfile) {
            if (userProfile == null) {
              return const CircularProgressIndicator();
            }

            if (!userProfile.isOnboardingComplete) {
              return const WelcomeScreen();
            }

            return const MainNavigationScreen();
          },
          loading: () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
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
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Authentication error: $error'),
        ),
      ),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety),
            label: 'Health',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assistant),
            label: 'Solar AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
