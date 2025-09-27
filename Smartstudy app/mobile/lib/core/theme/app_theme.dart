import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color secondaryColor = Color(0xFF10B981); // Emerald
  static const Color accentColor = Color(0xFFF59E0B); // Amber
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color warningColor = Color(0xFFF97316); // Orange
  static const Color successColor = Color(0xFF22C55E); // Green
  static const Color infoColor = Color(0xFF3B82F6); // Blue

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF1F2937);
  static const Color lightOnBackground = Color(0xFF374151);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color darkOnSurface = Color(0xFFF9FAFB);
  static const Color darkOnBackground = Color(0xFFD1D5DB);

  // Text Styles
  static TextTheme get _textTheme => GoogleFonts.interTextTheme();

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        surface: lightBackground,
        onSurface: lightOnBackground,
      ),
      textTheme: _textTheme.copyWith(
        displayLarge: _textTheme.displayLarge?.copyWith(
          color: lightOnBackground,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: _textTheme.displayMedium?.copyWith(
          color: lightOnBackground,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: _textTheme.displaySmall?.copyWith(
          color: lightOnBackground,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: _textTheme.headlineLarge?.copyWith(
          color: lightOnBackground,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: _textTheme.headlineMedium?.copyWith(
          color: lightOnBackground,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: _textTheme.headlineSmall?.copyWith(
          color: lightOnBackground,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: _textTheme.titleLarge?.copyWith(
          color: lightOnBackground,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: _textTheme.titleMedium?.copyWith(
          color: lightOnBackground,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: _textTheme.titleSmall?.copyWith(
          color: lightOnBackground,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: _textTheme.bodyLarge?.copyWith(
          color: lightOnBackground,
        ),
        bodyMedium: _textTheme.bodyMedium?.copyWith(
          color: lightOnBackground,
        ),
        bodySmall: _textTheme.bodySmall?.copyWith(
          color: lightOnBackground,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightOnSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _textTheme.titleLarge?.copyWith(
          color: lightOnSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        surface: darkBackground,
        onSurface: darkOnBackground,
      ),
      textTheme: _textTheme.copyWith(
        displayLarge: _textTheme.displayLarge?.copyWith(
          color: darkOnBackground,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: _textTheme.displayMedium?.copyWith(
          color: darkOnBackground,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: _textTheme.displaySmall?.copyWith(
          color: darkOnBackground,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: _textTheme.headlineLarge?.copyWith(
          color: darkOnBackground,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: _textTheme.headlineMedium?.copyWith(
          color: darkOnBackground,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: _textTheme.headlineSmall?.copyWith(
          color: darkOnBackground,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: _textTheme.titleLarge?.copyWith(
          color: darkOnBackground,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: _textTheme.titleMedium?.copyWith(
          color: darkOnBackground,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: _textTheme.titleSmall?.copyWith(
          color: darkOnBackground,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: _textTheme.bodyLarge?.copyWith(
          color: darkOnBackground,
        ),
        bodyMedium: _textTheme.bodyMedium?.copyWith(
          color: darkOnBackground,
        ),
        bodySmall: _textTheme.bodySmall?.copyWith(
          color: darkOnBackground,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkOnSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _textTheme.titleLarge?.copyWith(
          color: darkOnSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
