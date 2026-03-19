# Phase 2: Dark Theme

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the app theme from light to dark navy + gold accent to match the spec aesthetic.

**Architecture:** Single file change. No dependencies on Phase 1. Can run in parallel with Phase 1.

**Spec:** `docs/superpowers/specs/2026-03-19-minimal-ui-redesign-design.md` — "Theme" section

**Validation:** `flutter analyze lib/app/theme.dart` — no issues.

---

## Task 2.1: Rewrite Theme to Dark Navy + Gold

**Files:**
- Modify: `lib/app/theme.dart`

- [ ] **Step 1: Read the current theme file**

Read `lib/app/theme.dart` to understand the current structure.

- [ ] **Step 2: Rewrite theme.dart**

Replace the entire `lib/app/theme.dart` with:

```dart
// lib/app/theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Gold accent — the primary interactive/highlight color.
const Color kGoldAccent = Color(0xFFE2C272);

/// Dark navy background — primary surface.
const Color kDarkNavy = Color(0xFF16213E);

/// Deeper navy — used for cards, containers, and secondary surfaces.
const Color kDeepNavy = Color(0xFF0D1520);

/// Returns the main dark [ThemeData] for DhikrAtWork.
///
/// Conventions:
/// - Material 3, dark mode.
/// - Gold accent (#E2C272) on dark navy (#16213E / #0D1520).
/// - Arabic text uses Amiri from google_fonts; Latin UI text uses Inter.
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: kGoldAccent,
    brightness: Brightness.dark,
    surface: kDarkNavy,
    primary: kGoldAccent,
    onPrimary: kDeepNavy,
  );

  // Build text theme: Inter for Latin UI, Amiri for Arabic body.
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
    // Used for large Arabic text display (dhikr arabic_text).
    displayMedium:
        arabicTextStyle.copyWith(fontSize: 32, fontWeight: FontWeight.w600),
    displaySmall: arabicTextStyle.copyWith(fontSize: 26),
    headlineMedium: arabicTextStyle.copyWith(fontSize: 22),
    // Standard Latin UI text inherits from Inter base.
    bodyLarge: GoogleFonts.inter(fontSize: 16, color: colorScheme.onSurface),
    bodyMedium: GoogleFonts.inter(fontSize: 14, color: colorScheme.onSurface),
    bodySmall:
        GoogleFonts.inter(fontSize: 12, color: colorScheme.onSurfaceVariant),
    labelLarge:
        GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium:
        GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall:
        GoogleFonts.inter(fontSize: 11, color: colorScheme.onSurfaceVariant),
    titleLarge:
        GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
    titleMedium:
        GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall:
        GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
  );

  return ThemeData(
    colorScheme: colorScheme,
    textTheme: textTheme,
    useMaterial3: true,
    scaffoldBackgroundColor: kDarkNavy,

    // AppBar — no elevation, navy background.
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

    // Card — subtle rounded surface on deep navy.
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: kDeepNavy,
      margin: EdgeInsets.zero,
    ),

    // Dialog.
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: kDarkNavy,
      elevation: 6,
    ),

    // Tab bar — gold active, muted inactive.
    tabBarTheme: TabBarThemeData(
      labelColor: kGoldAccent,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicatorColor: kGoldAccent,
      dividerColor: colorScheme.outlineVariant,
    ),

    // Input decoration — outlined style.
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

    // Scrollbar — always visible on desktop.
    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: WidgetStateProperty.all(true),
      radius: const Radius.circular(8),
      thickness: WidgetStateProperty.all(6),
    ),

    // Chip.
    chipTheme: ChipThemeData(
      backgroundColor: kDeepNavy,
      selectedColor: colorScheme.primaryContainer,
      labelStyle: GoogleFonts.inter(fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    // Divider.
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),

    // Floating action button.
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kGoldAccent,
      foregroundColor: kDeepNavy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // List tile.
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // SegmentedButton — used in period selector.
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
```

- [ ] **Step 3: Run analyze**

Run: `flutter analyze lib/app/theme.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/app/theme.dart
git commit -m "feat: switch to dark navy + gold accent theme"
```
