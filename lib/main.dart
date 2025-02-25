import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'screens/welcome/welcome_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/health/health_screen.dart';
import 'screens/ai_assistant/ai_assistant_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/exercise_provider.dart';
import 'theme/app_theme.dart';
import 'utils/translation_helper.dart';
import 'i18n/app_localizations.dart';

final log = Logger('main');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.SEVERE; // Reduce logging verbosity during init
  Logger.root.onRecord.listen((record) {
    log.severe('${record.level.name}: ${record.time}: ${record.message}');
  });

  await dotenv.load(fileName: ".env");

  final themeProvider = ThemeProvider();
  final languageProvider = LanguageProvider();
  final exerciseProvider = ExerciseProvider();

  // Load data without notifying or excessive logging
  await Future.wait([
    themeProvider.loadTheme(), // Line 37
    languageProvider.loadLanguage(), // Line 38
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: exerciseProvider),
      ],
      child: const SolarVitaApp(),
    ),
  );

  // Notify after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    themeProvider.notifyAfterLoad(); // Line 55
    languageProvider.notifyAfterLoad(); // Line 56
  });
}

class SolarVitaApp extends StatelessWidget {
  const SolarVitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, _) {
        // Re-enable verbose logging after init if needed
        Logger.root.level = Level.ALL;
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
          home: const WelcomeScreen(),
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
  final List<Widget> _screens = [
    const DashboardScreen(),
    const SearchScreen(),
    const HealthScreen(),
    const AIAssistantScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: _screens[_currentIndex],
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
