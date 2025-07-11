// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:firebase_core/firebase_core.dart';

// Import Firebase options
import 'firebase_options.dart';
import 'services/notification_service.dart';

// Import your existing screens and providers
import 'screens/welcome/welcome_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/health/health_screen.dart';
import 'screens/ai_assistant/ai_assistant_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/exercise_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/user_profile_provider.dart';
import 'theme/app_theme.dart';
import 'utils/translation_helper.dart';
import 'i18n/app_localizations.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/common/app_loading_screen.dart';

final logger = Logger('SolarVita');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService().initialize();

  // Set up logging
  Logger.root.level = Level.ALL; // Change to Level.SEVERE in production
  Logger.root.onRecord.listen((record) {
    debugPrint(
        '[${record.level.name}] ${record.time}: ${record.loggerName}: ${record.message}');
  });

  await dotenv.load(fileName: ".env");

  final themeProvider = ThemeProvider();
  final languageProvider = LanguageProvider();
  final authProvider = AuthProvider();
  final userProfileProvider = UserProfileProvider();
  final exerciseProvider = ExerciseProvider();

  await Future.wait([
    themeProvider.loadTheme(),
    languageProvider.loadLanguage(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: userProfileProvider),
        ChangeNotifierProvider.value(value: exerciseProvider),
      ],
      child: const SolarVitaApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    themeProvider.notifyAfterLoad();
    languageProvider.notifyAfterLoad();
  });
}

class SolarVitaApp extends StatelessWidget {
  const SolarVitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer4<ThemeProvider, LanguageProvider, AuthProvider, UserProfileProvider>(
      builder: (context, themeProvider, languageProvider, authProvider, userProfileProvider, _) {
        // Create a unique key that changes when navigation state changes
        final navigationKey = '${authProvider.isAuthenticated}_${userProfileProvider.isLoading}_${userProfileProvider.userProfile?.uid}_${userProfileProvider.userProfile?.isOnboardingComplete}';
        
        return MaterialApp(
          key: ValueKey(navigationKey),
          title: 'SolarVita',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          locale: languageProvider.locale,
          supportedLocales: languageProvider.supportedLanguages
              .map((lang) => Locale(lang.code))
              .toList(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Use home with proper navigation
          home: _getInitialScreen(authProvider, userProfileProvider),
          routes: {
            '/main': (context) => const MainWrapper(),
            '/onboarding': (context) => const OnboardingScreen(),
          },
        );
      },
    );
  }

  Widget _getInitialScreen(AuthProvider authProvider, UserProfileProvider userProfileProvider) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    logger.info('🔍 [$timestamp] Navigation Debug - Auth: ${authProvider.isAuthenticated}, Loading: ${userProfileProvider.isLoading}, Profile: ${userProfileProvider.userProfile?.uid}, Onboarding: ${userProfileProvider.userProfile?.isOnboardingComplete}');
    
    if (!authProvider.isAuthenticated) {
      logger.info('➡️ [$timestamp] Showing WelcomeScreen (not authenticated)');
      return const WelcomeScreen();
    }
    
    if (userProfileProvider.isLoading) {
      logger.info('➡️ [$timestamp] Showing AppLoadingScreen (profile loading)');
      return const AppLoadingScreen(
        message: 'Loading your profile...',
      );
    }
    
    // Check if user profile exists and onboarding is complete
    final userProfile = userProfileProvider.userProfile;
    final isOnboardingComplete = userProfile?.isOnboardingComplete ?? false;
    
    if (userProfile == null || !isOnboardingComplete) {
      logger.info('➡️ [$timestamp] Showing OnboardingScreen (profile: ${userProfile?.uid}, onboarding: $isOnboardingComplete)');
      return const OnboardingScreen();
    }
    
    logger.info('➡️ [$timestamp] Showing MainWrapper (user setup complete)');
    return const MainWrapper();
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _screens = const [
      DashboardScreen(),
      SearchScreen(),
      HealthScreen(),
      AIAssistantScreen(),
      ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: _screens,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.colorScheme.surface,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: theme.hintColor,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: tr(context, 'nav_home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: tr(context, 'nav_search'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite),
            label: tr(context, 'nav_health'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat),
            label: tr(context, 'nav_solar_ai'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: tr(context, 'nav_profile'),
          ),
        ],
      ),
    );
  }
}
