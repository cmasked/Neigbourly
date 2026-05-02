import 'package:flutter/material.dart';

/// "The Curated Hearth" color system.
/// Warm, golden-hour inspired palette that rejects cold digital aesthetics.
class AppColors {
  AppColors._();

  // ─── Foundation Surfaces ──────────────────────────────────
  static const Color surface = Color(0xFFF6F1E9);
  static const Color surfaceBright = Color(0xFFFEF9F1);
  static const Color surfaceDim = Color(0xFFDFDACC);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF8F3EA);
  static const Color surfaceContainer = Color(0xFFF3EDE3);
  static const Color surfaceContainerHigh = Color(0xFFEDE8DC);
  static const Color surfaceContainerHighest = Color(0xFFE7E2D5);
  static const Color surfaceVariant = Color(0xFFE7E2D5);
  static const Color surfaceTint = Color(0xFF5A46D6);
  static const Color background = Color(0xFFF6F1E9);

  // ─── Primary (Muted Lavender) ─────────────────────────────
  static const Color primary = Color(0xFF5A46D6);
  static const Color primaryDim = Color(0xFF4E37CA);
  static const Color primaryContainer = Color(0xFFC1B9FF);
  static const Color primaryFixed = Color(0xFFC1B9FF);
  static const Color primaryFixedDim = Color(0xFFB3A9FF);
  static const Color onPrimary = Color(0xFFFCF7FF);
  static const Color onPrimaryContainer = Color(0xFF3614B4);
  static const Color onPrimaryFixed = Color(0xFF220087);
  static const Color onPrimaryFixedVariant = Color(0xFF4024BC);
  static const Color inversePrimary = Color(0xFF8E7FFF);

  // ─── Secondary ────────────────────────────────────────────
  static const Color secondary = Color(0xFF6153A2);
  static const Color secondaryDim = Color(0xFF554795);
  static const Color secondaryContainer = Color(0xFFE6DEFF);
  static const Color secondaryFixed = Color(0xFFE6DEFF);
  static const Color secondaryFixedDim = Color(0xFFD8CEFF);
  static const Color onSecondary = Color(0xFFFCF7FF);
  static const Color onSecondaryContainer = Color(0xFF544694);
  static const Color onSecondaryFixed = Color(0xFF413380);
  static const Color onSecondaryFixedVariant = Color(0xFF5E509E);

  // ─── Tertiary (Warm Beige / Wood) ─────────────────────────
  static const Color tertiary = Color(0xFF685E4E);
  static const Color tertiaryDim = Color(0xFF5C5243);
  static const Color tertiaryContainer = Color(0xFFFBECD8);
  static const Color tertiaryFixed = Color(0xFFFBECD8);
  static const Color tertiaryFixedDim = Color(0xFFEDDDCA);
  static const Color onTertiary = Color(0xFFFFF8F2);
  static const Color onTertiaryContainer = Color(0xFF615748);
  static const Color onTertiaryFixed = Color(0xFF4E4537);
  static const Color onTertiaryFixedVariant = Color(0xFF6C6152);

  // ─── Error ────────────────────────────────────────────────
  static const Color error = Color(0xFFAC3149);
  static const Color errorDim = Color(0xFF770326);
  static const Color errorContainer = Color(0xFFF76A80);
  static const Color onError = Color(0xFFFFF7F7);
  static const Color onErrorContainer = Color(0xFF68001F);

  // ─── Text & Outline ───────────────────────────────────────
  static const Color onSurface = Color(0xFF34322A);
  static const Color onSurfaceVariant = Color(0xFF625F55);
  static const Color onBackground = Color(0xFF34322A);
  static const Color outline = Color(0xFF7E7B70);
  static const Color outlineVariant = Color(0xFFB6B2A6);
  static const Color inverseSurface = Color(0xFF0F0E0A);
  static const Color inverseOnSurface = Color(0xFFA09C96);

  // ─── Semantic Aliases ─────────────────────────────────────
  static const Color success = Color(0xFF3D8B5E);
  static const Color warning = Color(0xFFD4A04A);
  static const Color info = primary;

  // ─── Gradient endpoints ───────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, primaryDim],
  );

  static const LinearGradient goldenHourOverlay = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x08FFE696),
      Color(0x0DFFB432),
    ],
  );
}
