import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography system: Plus Jakarta Sans for headlines/body, Manrope for labels.
class AppTypography {
  AppTypography._();

  // ─── Display ──────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 57,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    color: AppColors.onSurface,
    height: 1.12,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 45,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 36,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    height: 1.22,
  );

  // ─── Headline ─────────────────────────────────────────────
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    height: 1.33,
  );

  // ─── Title ────────────────────────────────────────────────
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    color: AppColors.onSurface,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.onSurface,
    height: 1.43,
  );

  // ─── Body ─────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.onSurface,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: AppColors.onSurface,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: AppColors.onSurfaceVariant,
    height: 1.33,
  );

  // ─── Label (Manrope — architectural / catalog feel) ───────
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.onSurface,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.onSurfaceVariant,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.onSurfaceVariant,
    height: 1.45,
  );
}
