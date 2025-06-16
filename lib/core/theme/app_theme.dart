import 'package:flutter/material.dart';

class AppTheme {
  static const _lightPrimary = Color(0xFF6B8AFE); // Azul pastel
  static const _lightSecondary = Color(0xFFFF9A8B); // Rosa pastel
  static const _lightBackground = Color(0xFFF8F9FE); // Blanco suave
  static const _lightSurface = Colors.white;
  static const _lightError = Color(0xFFFF6B6B); // Rojo suave
  static const _lightSuccess = Color(0xFF4CAF50); // Verde suave
  static const _lightWarning = Color(0xFFFFB74D); // Naranja suave

  static const _darkPrimary = Color(0xFF8BA4FF); // Azul pastel más claro
  static const _darkSecondary = Color(0xFFFFB5A8); // Rosa pastel más claro
  static const _darkBackground = Color(0xFF1A1B1E); // Gris muy oscuro
  static const _darkSurface = Color(0xFF2C2D31); // Gris oscuro
  static const _darkError = Color(0xFFFF8A8A); // Rojo suave más claro
  static const _darkSuccess = Color(0xFF81C784); // Verde suave más claro
  static const _darkWarning = Color(0xFFFFCC80); // Naranja suave más claro

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: _lightPrimary,
      secondary: _lightSecondary,
      background: _lightBackground,
      surface: _lightSurface,
      error: _lightError,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: const Color(0xFF1A1B1E),
      onSurface: const Color(0xFF1A1B1E),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: _lightBackground,
    cardTheme: CardTheme(
      color: _lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFFE2E8F0).withOpacity(0.5),
          width: 1,
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightBackground,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: _lightPrimary),
      titleTextStyle: TextStyle(
        color: _lightPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: _lightPrimary.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _lightPrimary,
        side: BorderSide(
          color: _lightPrimary.withOpacity(0.5),
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _lightPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _lightPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _lightError, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _darkSurface,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: _darkPrimary,
      secondary: _darkSecondary,
      background: _darkBackground,
      surface: _darkSurface,
      error: _darkError,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: _darkBackground,
    cardTheme: CardTheme(
      color: _darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _darkBackground,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: _darkPrimary),
      titleTextStyle: const TextStyle(
        color: _darkPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: _darkPrimary.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkPrimary,
        side: BorderSide(
          color: _darkPrimary.withOpacity(0.5),
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _darkPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _darkPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _darkError, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _lightSurface,
      contentTextStyle: const TextStyle(color: Colors.black),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
} 
