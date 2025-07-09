// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:firebase_core/firebase_core.dart';

// Import Firebase options
import 'firebase_options.dart';

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
import 'providers/auth_provider.dart'; // Add this import
import 'theme/app_theme.dart';
import 'utils/translation_helper.dart';
import 'i18n/app_localizations.dart';

final logger = Logger('SolarVita');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up logging
  Logger.root.level = Level.ALL; // Change to Level.SEVERE in production
  Logger.root.onRecord.listen((record) {
    debugPrint(
        '[${record.level.name}] ${record.time}: ${record.loggerName}: ${record.message}');
  });

  await dotenv.load(fileName: ".env");

  final themeProvider = ThemeProvider();
  final languageProvider = LanguageProvider();
  final authProvider = AuthProvider(); // Add this

  await Future.wait([
    themeProvider.loadTheme(),
    languageProvider.loadLanguage(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: authProvider), // Add this
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
    return Consumer3<ThemeProvider, LanguageProvider, AuthProvider>(
      builder: (context, themeProvider, languageProvider, authProvider, _) {
        return MaterialApp(
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
          // Use AuthProvider to determine initial route
          home: authProvider.isAuthenticated
              ? const MainWrapper()
              : const WelcomeScreen(),
          routes: {
            '/main': (context) => const MainWrapper(),
          },
        );
      },
    );
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget currentScreen;
    switch (_currentIndex) {
      case 0:
        currentScreen = const DashboardScreen();
        break;
      case 1:
        currentScreen = ChangeNotifierProvider(
          create: (_) {
            logger.info("Creating new ExerciseProvider for SearchScreen");
            return ExerciseProvider();
          },
          child: const SearchScreen(),
        );
        break;
      case 2:
        currentScreen = const HealthScreen();
        break;
      case 3:
        currentScreen = const AIAssistantScreen();
        break;
      case 4:
        currentScreen = const ProfileScreen();
        break;
      default:
        currentScreen = const DashboardScreen();
    }

    return Scaffold(
      body: currentScreen,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
