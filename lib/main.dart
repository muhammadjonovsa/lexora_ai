import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes/routes.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/profile/presentation/profile_settings_page.dart';
import 'services/local_storage_service.dart';

void main() async {
  // Global crash protection shield
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Enforce premium portrait orientation for beautiful consistent visual layouts
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Safe initialization of local database (Hive)
    await LocalStorageService.init();

    // Load user selected Theme Mode from Hive local cache
    final isDarkModeCached = LocalStorageService.getSetting(AppConstants.keyDarkMode) as bool?;
    
    ThemeMode initialThemeMode = ThemeMode.system;
    if (isDarkModeCached != null) {
      initialThemeMode = isDarkModeCached ? ThemeMode.dark : ThemeMode.light;
    }

    // Set custom Flutter error hook to capture unhandled layout or rendering errors gracefully
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      print("Captured Flutter error: ${details.exception}");
    };

    runApp(
      ProviderScope(
        overrides: [
          // Initialize or override states here if necessary
        ],
        child: LexoraApp(initialThemeMode: initialThemeMode),
      ),
    );
  }, (Object error, StackTrace stack) {
    print("CRITICAL: Captured unhandled async/zoned exception: $error");
    print(stack);
    
    // In production, you could show a custom minimal fallback recovery UI here if the error happens during bootstrap.
  });
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
