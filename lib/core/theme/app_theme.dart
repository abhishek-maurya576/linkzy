import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2962FF);
  static const Color secondaryColor = Color(0xFF0039CB);
  static const Color accentColor = Color(0xFF82B1FF);
  
  // Dark theme colors
  static const Color darkBgColor = Color(0xFF1A1A2E);
  static const Color darkCardColor = Color(0xFF16213E);
  static const Color darkSurfaceColor = Color(0xFF0F3460);
  
  // Light theme colors
  static const Color lightBgColor = Color(0xFFF8F9FA);
  static const Color lightCardColor = Color(0xFFFFFFFF);
  static const Color lightSurfaceColor = Color(0xFFE9ECEF);

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBgColor,
    cardColor: darkCardColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: darkSurfaceColor,
      background: darkBgColor,
      error: Colors.redAccent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurfaceColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurfaceColor.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentColor,
      ),
    ),
  );
  
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightBgColor,
    cardColor: lightCardColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: lightSurfaceColor,
      background: lightBgColor,
      error: Colors.redAccent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurfaceColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      labelStyle: TextStyle(color: Colors.black.withOpacity(0.7)),
      hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
  );
} 