import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Gold accent — the primary interactive/highlight color.
const Color kGoldAccent = Color(0xFFE2C272);

/// Dark navy background — primary surface.
const Color kDarkNavy = Color(0xFF16213E);

/// Deeper navy — used for cards, containers, and secondary surfaces.
const Color kDeepNavy = Color(0xFF0D1520);

/// Returns the main dark [ThemeData] for DhikrAtWork.
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: kGoldAccent,
    brightness: Brightness.dark,
    surface: kDarkNavy,
    primary: kGoldAccent,
    onPrimary: kDeepNavy,
  );

  final baseTextTheme = GoogleFonts.interTextTheme(
    ThemeData(brightness: Brightness.dark).textTheme,
  );
  final arabicTextStyle = GoogleFonts.amiri(
    fontSize: 22,
    height: 1.8,
    letterSpacing: 0,
    color: colorScheme.onSurface,
  );

  final textTheme = baseTextTheme.copyWith(
    displayMedium: arabicTextStyle.copyWith(fontSize: 32, fontWeight: FontWeight.w600),
    displaySmall: arabicTextStyle.copyWith(fontSize: 26),
    headlineMedium: arabicTextStyle.copyWith(fontSize: 22),
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
    scaffoldBackgroundColor: kDarkNavy,

    appBarTheme: AppBarThemeData(
      backgroundColor: kDarkNavy,
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

    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: kDeepNavy,
      margin: EdgeInsets.zero,
    ),

    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: kDarkNavy,
      elevation: 6,
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: kGoldAccent,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicatorColor: kGoldAccent,
      dividerColor: colorScheme.outlineVariant,
    ),

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
        borderSide: BorderSide(color: kGoldAccent, width: 2),
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
      fillColor: kDeepNavy,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: WidgetStateProperty.all(true),
      radius: const Radius.circular(8),
      thickness: WidgetStateProperty.all(6),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: kDeepNavy,
      selectedColor: colorScheme.primaryContainer,
      labelStyle: GoogleFonts.inter(fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kGoldAccent,
      foregroundColor: kDeepNavy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return kGoldAccent;
          return kDeepNavy;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return kDeepNavy;
          return colorScheme.onSurface;
        }),
      ),
    ),
  );
}
