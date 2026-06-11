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
  static const Color sipyBlue = Color(0xFF013DF5);
  static const Color sipyGreen = Color(0xFF97FC21);
  static const Color sipyOptionGreen = Color(0xFF8AEE02);
  static const Color sipyBackground = Color(0xFFFCF8FB);
  static const Color sipyOptionsBackground = Color(0xFFF5F4F3);
  static const Color sipyHeaderBackground = Color(0xFFFCFCFC);
  static const Color sipyInputFill = Color(0xFFF6F3F5);
  static const Color sipyInputBorder = Color(0xFFC4C5D9);
  static const Color sipyBodyText = Color(0xFF444656);
  static const Color sipyDarkText = Color(0xFF0A1F5C);
  static const Color sipyMutedText = Color(0xFF747688);
  static const Color sipyHintText = Color(0xFF6B7280);
  static const Color sipySoftGrey = Color(0xFFF6F5F4);
  static const Color sipyNeutralBar = Color(0xFFE5E1E4);
  static const Color sipyShadowBlue = Color(0xFF002CBA);
  static const Color sipyError = Color(0xFF93000A);
  static const Color sipyErrorBorder = Color(0xFFBA1A1A);
  static const Color sipyErrorFill = Color(0xFFFFDAD6);

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

class BdaFonts {
  static const String gotham = 'Gotham';
}

class BdaAssets {
  static const String sippyLogo = 'assets/sippy.png';
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
      fontFamily: BdaFonts.gotham,
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
