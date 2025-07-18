// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import Firebase options
import 'firebase_options.dart';
import 'services/notification_service.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
        '[${record.level.name}] ${record.time}: ${record.loggerName}: ${record.message}');
  });

  // Initialize Firebase (graceful handling for test/CI environments)
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    isFirebaseAvailable = true;
    debugPrint("Firebase initialized successfully");
  } catch (e) {
    debugPrint("Firebase initialization failed (test environment): $e");
    // Continue without Firebase for testing
  }
  
  // Initialize notification service only if Firebase is working
  if (firebaseInitialized) {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
    } catch (e) {
      debugPrint("Notification service initialization failed: $e");
    }
  }

  // Load environment variables (optional for CI/CD)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env file not found, using environment variables from system
    debugPrint("No .env file found, using system environment variables");
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

  Widget _buildHomeScreen(WidgetRef ref, AsyncValue<User?> authState, AsyncValue<UserProfile?> userProfileAsync) {
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
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
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
            label: 'AI Assistant',
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

