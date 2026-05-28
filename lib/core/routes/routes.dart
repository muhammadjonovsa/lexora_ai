import 'package:flutter/material.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/presentation/auth_pages.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/editor/presentation/editor_page.dart';
import '../../features/ai_assistant/presentation/ai_chat_assistant.dart';
import '../../features/profile/presentation/profile_settings_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String editor = '/editor';
  static const String aiChat = '/ai-chat';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      case login:
        return _buildRoute(const LoginPage(), settings);
      case register:
        return _buildRoute(const RegisterPage(), settings);
      case forgotPassword:
        return _buildRoute(const ForgotPasswordPage(), settings);
      case dashboard:
        return _buildRoute(const DashboardPage(), settings);
      case editor:
        final docId = settings.arguments as String?;
        return _buildRoute(EditorPage(documentId: docId), settings);
      case aiChat:
        return _buildRoute(const AIChatAssistantPage(), settings);
      case profile:
        return _buildRoute(const ProfileSettingsPage(), settings);
      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  static PageRouteBuilder _buildRoute(Widget child, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        
        var fadeTween = Tween<double>(begin: 0.0, end: 1.0);
        var fadeAnimation = animation.drive(fadeTween);

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
