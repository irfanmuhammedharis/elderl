import 'package:flutter/material.dart';

/// App theme configuration
/// Senior-friendly with large fonts and high contrast
class AppTheme {
  AppTheme._();

  // Colors - High contrast for seniors
  static const Color primaryColor = Color(0xFF1565C0);
  static const Color secondaryColor = Color(0xFF43A047);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color emergencyColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFF57C00);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    
    // Large fonts for seniors
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 18),
      bodyMedium: TextStyle(fontSize: 16),
      bodySmall: TextStyle(fontSize: 14),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    ),
    
    // Large buttons for easy tapping
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    // Large input fields
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      labelStyle: const TextStyle(fontSize: 16),
      hintStyle: const TextStyle(fontSize: 16),
    ),
    
    // Card theme
    cardTheme: const CardThemeData(
      elevation: 2,
      margin: EdgeInsets.all(8),
    ),
    
    // AppBar theme
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),
    
    // Large fonts for seniors
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 18),
      bodyMedium: TextStyle(fontSize: 16),
      bodySmall: TextStyle(fontSize: 14),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      labelStyle: const TextStyle(fontSize: 16),
      hintStyle: const TextStyle(fontSize: 16),
    ),
    
    cardTheme: const CardThemeData(
      elevation: 2,
      margin: EdgeInsets.all(8),
    ),
    
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
