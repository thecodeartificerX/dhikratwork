// lib/app/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Earthy gold seed color — the central hue for the Islamic aesthetic palette.
const Color _kSeedColor = Color(0xFFB8860B); // DarkGoldenrod

/// Returns the main [ThemeData] for DhikrAtWork.
///
/// Conventions:
/// - Material 3 (default since Flutter 3.16, no explicit flag needed).
/// - All component themes use [*ThemeData] suffix classes per skill.
/// - Arabic text uses Amiri from google_fonts; Latin UI text uses Inter.
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _kSeedColor,
    brightness: Brightness.light,
  );

  // Build text theme: Inter for Latin UI, Amiri for Arabic body
  final baseTextTheme = GoogleFonts.interTextTheme();
  final arabicTextStyle = GoogleFonts.amiri(
    fontSize: 22,
    height: 1.8,
    letterSpacing: 0,
    color: colorScheme.onSurface,
  );

  final textTheme = baseTextTheme.copyWith(
    // Used for large Arabic text display (dhikr arabic_text)
    displayMedium: arabicTextStyle.copyWith(fontSize: 32, fontWeight: FontWeight.w600),
    displaySmall: arabicTextStyle.copyWith(fontSize: 26),
    headlineMedium: arabicTextStyle.copyWith(fontSize: 22),
    // Standard Latin UI text inherits from Inter base
    bodyLarge: GoogleFonts.inter(fontSize: 16, color: colorScheme.onSurface),
    bodyMedium: GoogleFonts.inter(fontSize: 14, color: colorScheme.onSurface),
    bodySmall: GoogleFonts.inter(fontSize: 12, color: colorScheme.onSurfaceVariant),
    labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: GoogleFonts.inter(fontSize: 11, color: colorScheme.onSurfaceVariant),
    titleLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
    titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
  );

  return ThemeData(
    colorScheme: colorScheme,
    textTheme: textTheme,
    useMaterial3: true,

    // AppBar — no elevation, surface-colored background
    appBarTheme: AppBarThemeData(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 2,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    ),

    // Card — subtle rounded surface
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colorScheme.surface,
      elevation: 6,
    ),

    // Tab bar
    tabBarTheme: TabBarThemeData(
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicatorColor: colorScheme.primary,
      dividerColor: colorScheme.outlineVariant,
    ),

    // Input decoration — outlined style
    inputDecorationTheme: InputDecorationThemeData(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // Navigation Rail (main window side nav)
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedIconTheme: IconThemeData(color: colorScheme.primary),
      unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      selectedLabelTextStyle: GoogleFonts.inter(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: GoogleFonts.inter(
        color: colorScheme.onSurfaceVariant,
        fontSize: 12,
      ),
      indicatorColor: colorScheme.primaryContainer,
      elevation: 0,
    ),

    // Scrollbar — always visible on desktop
    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: WidgetStateProperty.all(true),
      radius: const Radius.circular(8),
      thickness: WidgetStateProperty.all(6),
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.primaryContainer,
      labelStyle: GoogleFonts.inter(fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),

    // Floating action button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // List tile
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
