import 'package:flutter/material.dart';

class BdaColors {
  static const Color navy = Color(0xFF00205B);
  static const Color red = Color(0xFFE4002B);
  static const Color gold = Color(0xFFFFB81C);
  static const Color lightBackground = Color(0xFFF0F2F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkGrey = Color(0xFF1E293B);
  static const Color lightGrey = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF00205B);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF4CAF50);

  static const Gradient redGradient = LinearGradient(
    colors: [Color(0xFFE4002B), Color(0xFFBA0023)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB81C), Color(0xFFE5A010)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient navyGradient = LinearGradient(
    colors: [Color(0xFF00205B), Color(0xFF00153D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class BdaTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: BdaColors.navy,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BdaColors.navy,
        primary: BdaColors.navy,
        secondary: BdaColors.red,
        tertiary: BdaColors.gold,
      ),
      scaffoldBackgroundColor: BdaColors.lightBackground,
      fontFamily: 'Assistant',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: BdaColors.textDark,
          fontWeight: FontWeight.w800,
          fontSize: 32,
        ),
        headlineMedium: TextStyle(
          color: BdaColors.textDark,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        titleLarge: TextStyle(
          color: BdaColors.textDark,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        bodyLarge: TextStyle(color: BdaColors.textDark, fontSize: 16),
        bodyMedium: TextStyle(color: BdaColors.textDark, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BdaColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BdaColors.lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BdaColors.lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BdaColors.red, width: 2),
        ),
        labelStyle: const TextStyle(
          color: BdaColors.navy,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
