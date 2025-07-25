// lib/app_themes.dart
import 'package:flutter/material.dart';

class AppThemes {
  static const Color darkBlue = Color(0xFF0D1E4D);
  static const Color accentPink = Color(0xFFE91E63);
  static const Color emergencyRed = Color(0xFFD32F2F);
  static const Color tealGreen = Color(0xFF00897B);

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: darkBlue,
    scaffoldBackgroundColor: const Color(0xFFFDFDFD),
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBlue,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontFamily: 'Overpass Mono', color: Colors.white, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: darkBlue, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black54),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: darkBlue,
      brightness: Brightness.light,
      background: const Color(0xFFFDFDFD),
      surface: Colors.grey[200],
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: darkBlue,
    scaffoldBackgroundColor: const Color(0xFF121212),
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBlue,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontFamily: 'Overpass Mono', color: Colors.white, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: darkBlue,
      brightness: Brightness.dark,
      background: const Color(0xFF121212),
      surface: Colors.grey[800],
    ),
  );
}