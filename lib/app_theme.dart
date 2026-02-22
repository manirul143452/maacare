// ============================================================
//  MaaCare – App Theme
//  Soft pink/peach palette, Poppins font, rounded UI
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MaaColors {
  MaaColors._();

  static const Color pink = Color(0xFFFFB6C1);
  static const Color peach = Color(0xFFFFDAB9);
  static const Color lightBlue = Color(0xFFA7D8DE);
  static const Color gold = Color(0xFFFFD700);
  static const Color deepPink = Color(0xFFFF8FAB);
  static const Color softPurple = Color(0xFFE8D5F5);
  static const Color softGreen = Color(0xFFC1F0C1);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFFF9FB);
  static const Color textDark = Color(0xFF3D1A2E);
  static const Color textGrey = Color(0xFF8D6E7F);
  static const Color cardShadow = Color(0x1AFF8FAB);
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [pink, peach],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient calmGradient = LinearGradient(
    colors: [lightBlue, softPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFF0F5), Color(0xFFFFF5EC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFB347)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class MaaTheme {
  MaaTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: MaaColors.pink,
        brightness: Brightness.light,
        primary: MaaColors.pink,
        secondary: MaaColors.peach,
        surface: MaaColors.offWhite,
        error: MaaColors.error,
      ),
      scaffoldBackgroundColor: MaaColors.offWhite,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: MaaColors.textDark,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: MaaColors.textDark,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: MaaColors.textDark,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: MaaColors.textDark,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: MaaColors.textDark,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: MaaColors.textDark,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: MaaColors.textGrey,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: MaaColors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MaaColors.pink,
          foregroundColor: MaaColors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MaaColors.deepPink,
          side: const BorderSide(color: MaaColors.pink, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MaaColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: MaaColors.pink.withAlpha(100)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: MaaColors.pink.withAlpha(100)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: MaaColors.deepPink, width: 1.5),
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: MaaColors.textGrey,
        ),
      ),
      cardTheme: CardTheme(
        color: MaaColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadowColor: MaaColors.cardShadow,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: MaaColors.offWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: MaaColors.textDark,
        ),
        iconTheme: const IconThemeData(color: MaaColors.textDark),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: MaaColors.white,
        selectedItemColor: MaaColors.deepPink,
        unselectedItemColor: MaaColors.textGrey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: MaaColors.textDark,
        contentTextStyle: GoogleFonts.poppins(
          color: MaaColors.white,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
