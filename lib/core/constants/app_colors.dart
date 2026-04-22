import 'package:flutter/material.dart';

class AppColors {
  // --- BRAND COLORS ---
  // A refined, deeper red for light mode, and a brighter red for dark mode contrast
  static const Color primaryRedLight = Color(0xFFBC0100); 
  static const Color primaryRedDark = Color(0xFFFF0000); 
  static const Color primaryContainer = Color(0xFFEB0000); // Used for gradients

  // --- LIGHT THEME (The Editorial Intelligence) ---
  static const Color lightSurface = Color(0xFFF7F9FB); // Cool, breathable light gray
  static const Color lightSurfaceContainerLow = Color(0xFFF2F4F6); // Sectioning
  static const Color lightSurfaceContainerLowest = Color(0xFFFFFFFF); // Actionable Cards
  static const Color lightOnSurface = Color(0xFF191C1E); // Sophisticated dark slate text
  static const Color lightSecondaryTonal = Color(0xFF515F74); // Meta-information
  static const Color lightOutlineVariant = Color(0x26EBBBB4); // Ghost border (~15% opacity)
  
  // --- DARK THEME (Derived from Redline Brief Aesthetic) ---
  static const Color darkSurface = Color(0xFF121212); // Deep dark background
  static const Color darkSurfaceContainerLow = Color(0xFF1E1E1E); // Sectioning
  static const Color darkSurfaceContainerLowest = Color(0xFF242424); // Actionable Cards
  static const Color darkOnSurface = Color(0xFFE2E2E2); // Off-white text for readability
  static const Color darkSecondaryTonal = Color(0xFFA0AAB9); // Muted gray for meta
  static const Color darkOutlineVariant = Color(0x26FFFFFF); // Ghost border dark

  // --- SHARED UTILITY ---
  static const Color errorRed = Colors.redAccent;
  static const Color accentYellow = Color(0xFFFFD54F);

  // --- BACKWARDS-COMPATIBILITY ALIASES ---
  // Several UI files still reference older AppColors names. These aliases
  // keep those files working while preserving the new, clearer color names.
  static const Color primaryRed = primaryRedLight;
  static const Color background = lightSurface;
  static const Color cardBackground = lightSurfaceContainerLowest;
  static const Color buttonGrey = lightSurfaceContainerLow;
  static const Color textDark = lightOnSurface;
  static const Color textGrey = lightSecondaryTonal;
  static const Color textSecondary = lightSecondaryTonal;
  static const Color infoBackground = accentYellow;
  // --- Additional legacy names used across the app (auth + inputs)
  static const Color authBackground = lightSurface;
  static const Color textSubtext = lightSecondaryTonal;
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textLabel = lightSecondaryTonal;
  static const Color inputHintColor = lightSecondaryTonal;
  static const Color inputIconColor = lightSecondaryTonal;
  static const Color inputFillColor = lightSurfaceContainerLow;
}