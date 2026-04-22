import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_summary_app/core/constants/app_colors.dart';

class AppTheme {
  // --- TYPOGRAPHY ENGINE ---
  // Centralized typography to ensure "The Editorial Voice" across both themes
  static TextTheme _buildTextTheme(Color displayColor, Color bodyColor, Color metaColor) {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        color: displayColor,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.02, // Tighter premium feel
      ),
      headlineSmall: GoogleFonts.inter(
        color: displayColor,
        fontSize: 24, // 1.5rem
        fontWeight: FontWeight.bold,
        height: 1.2, // News headline feel
      ),
      bodyLarge: GoogleFonts.inter(
        color: bodyColor,
        fontSize: 16, // 1rem
        height: 1.6, // Generous line height for long reads
      ),
      bodyMedium: GoogleFonts.inter(
        color: bodyColor,
        fontSize: 14,
      ),
      labelSmall: GoogleFonts.inter(
        color: metaColor,
        letterSpacing: 0.05, // Metadata aesthetic
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // --- LIGHT THEME ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightSurface,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryRedLight,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
      ),
      textTheme: _buildTextTheme(
        AppColors.lightOnSurface, 
        AppColors.lightOnSurface, 
        AppColors.lightSecondaryTonal
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.primaryRedLight,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0, // Prevents Material 3 shadow on scroll
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurfaceContainerLowest,
        elevation: 0, // Zero default elevation to manually control "Ambient Light"
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRedLight,
          foregroundColor: Colors.white,
          elevation: 0, // Flat design preference
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Defined in Design.md
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceContainerLow, // "Understated Elegance"
        hintStyle: const TextStyle(color: AppColors.lightSecondaryTonal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // "No-Line" Rule
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryRedLight, width: 2), // 2px Ghost border
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // --- DARK THEME ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkSurface,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryRedDark,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
      ),
      textTheme: _buildTextTheme(
        AppColors.darkOnSurface, 
        AppColors.darkOnSurface, 
        AppColors.darkSecondaryTonal
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.primaryRedDark,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRedDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceContainerLow,
        hintStyle: const TextStyle(color: AppColors.darkSecondaryTonal),
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
          borderSide: const BorderSide(color: AppColors.primaryRedDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}