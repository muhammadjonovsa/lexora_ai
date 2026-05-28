import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/routes/routes.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/profile/presentation/profile_settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enforce premium portrait orientation for beautiful consistent visual layouts
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Attempt Firebase Initialization gracefully (Zero blocker developer experience!)
  try {
    await Firebase.initializeApp();
    print("Firebase successfully initialized inside LexoraAI.");
  } catch (e) {
    print("Firebase Core not configured or missing configuration files: $e. "
        "LexoraAI will start in secure Offline Guest Mode fallback.");
  }

  // Load user selected Theme Mode from cache
  final prefs = await SharedPreferences.getInstance();
  final isDarkModeCached = prefs.getBool(AppConstants.keyDarkMode);
  
  ThemeMode initialThemeMode = ThemeMode.system;
  if (isDarkModeCached != null) {
    initialThemeMode = isDarkModeCached ? ThemeMode.dark : ThemeMode.light;
  }

  runApp(
    ProviderScope(
      overrides: [
        // Initialize or override states here if necessary
      ],
      child: LexoraApp(initialThemeMode: initialThemeMode),
    ),
  );
}

class LexoraApp extends ConsumerWidget {
  final ThemeMode initialThemeMode;

  const LexoraApp({
    Key? key,
    required this.initialThemeMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to theme state reactive changes
    final currentThemeMode = ref.watch(themeModeProvider);

    // Initialize the provider with cached theme on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(themeModeProvider) == ThemeMode.system && initialThemeMode != ThemeMode.system) {
        ref.read(themeModeProvider.notifier).state = initialThemeMode;
      }
    });

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // Theme settings
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: currentThemeMode,
      
      // Route management
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
