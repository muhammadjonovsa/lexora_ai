import 'package:flutter/material.dart';

class AppTheme {
  // Gradients & Styling details
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightCardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF4F46E5),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardColor: const Color(0xFFFFFFFF),
      dividerColor: const Color(0xFFE2E8F0),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4F46E5),
        secondary: Color(0xFF06B6D4),
        surface: Color(0xFFFFFFFF),
        error: Color(0xFFEF4444),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF0F172A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF334155), height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 4,
        shadowColor: const Color(0xFF0F172A).withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // Dark Theme Configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF6366F1),
      scaffoldBackgroundColor: const Color(0xFF0B0F19),
      cardColor: const Color(0xFF1E293B),
      dividerColor: const Color(0xFF334155),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6366F1),
        secondary: Color(0xFF22D3EE),
        surface: Color(0xFF1E293B),
        error: Color(0xFFF87171),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFF8FAFC),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
        titleTextStyle: TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFF8FAFC)),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFF8FAFC)),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFE2E8F0), height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF94A3B8), height: 1.4),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF818CF8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
