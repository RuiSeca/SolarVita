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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.grey.shade800.withValues(alpha: 0.3) : Colors.grey.shade300.withValues(alpha: 0.5),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 66,
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: isDark ? Colors.white : Colors.black,
              unselectedItemColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              selectedFontSize: 11,
              unselectedFontSize: 9,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: _currentIndex == 0 
                        ? BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: Icon(
                      _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                      size: 24,
                    ),
                  ),
                  label: tr(context, 'nav_home'),
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: _currentIndex == 1 
                        ? BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: Icon(
                      _currentIndex == 1 ? Icons.search : Icons.search_outlined,
                      size: 24,
                    ),
                  ),
                  label: tr(context, 'nav_search'),
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: _currentIndex == 2 
                        ? BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: Icon(
                      _currentIndex == 2 ? Icons.favorite : Icons.favorite_outline,
                      size: 24,
                    ),
                  ),
                  label: tr(context, 'nav_health'),
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: _currentIndex == 3 
                        ? BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: Icon(
                      _currentIndex == 3 ? Icons.chat_bubble : Icons.chat_bubble_outline,
                      size: 24,
                    ),
                  ),
                  label: tr(context, 'nav_solar_ai'),
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: _currentIndex == 4 
                        ? BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: Icon(
                      _currentIndex == 4 ? Icons.person : Icons.person_outline,
                      size: 24,
                    ),
                  ),
                  label: tr(context, 'nav_profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
