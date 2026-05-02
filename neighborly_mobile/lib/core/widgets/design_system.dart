import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:neighborly/core/theme/app_colors.dart';
import 'package:neighborly/core/theme/app_typography.dart';

// ─── Gradient Pill Button (Primary CTA from DESIGN.md) ──────

class GradientPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const GradientPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed != null
              ? AppColors.primaryGradient
              : const LinearGradient(colors: [
                  Color(0xFFB6B2A6),
                  Color(0xFFA09C96),
                ]),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(100),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: AppColors.onPrimary, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: AppTypography.labelLarge
                              .copyWith(color: AppColors.onPrimary),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Ambient Shadow Card (Golden Hour shadows from DESIGN.md) ─

class AmbientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double borderRadius;

  const AmbientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // Primary ambient shadow (golden-hour tinted)
          BoxShadow(
            color: AppColors.onSurface.withOpacity(0.05),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
          // Subtle contact shadow
          BoxShadow(
            color: AppColors.onSurface.withOpacity(0.03),
            blurRadius: 8,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

// ─── Glass Container (Glassmorphism from DESIGN.md) ──────────

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blurAmount;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.blurAmount = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: AppColors.outlineVariant.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Category Chip (Ceramic tokens from DESIGN.md) ──────────

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer
              : AppColors.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected
                ? AppColors.onPrimaryContainer
                : AppColors.onTertiaryFixed,
          ),
        ),
      ),
    );
  }
}

// ─── Status Badge ───────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = _statusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  (Color, Color) _statusColors(String status) {
    return switch (status.toLowerCase()) {
      'pending' || 'pending_payment' => (const Color(0xFFD4A04A), const Color(0xFFFBECD8)),
      'accepted' || 'confirmed' || 'active' => (const Color(0xFF3D8B5E), const Color(0xFFDAF2E1)),
      'completed' || 'released' => (AppColors.primary, AppColors.primaryContainer.withOpacity(0.4)),
      'rejected' || 'cancelled' || 'overdue' || 'disputed' =>
        (AppColors.error, AppColors.errorContainer.withOpacity(0.3)),
      'in_escrow' || 'collected' => (const Color(0xFF2E7D9A), const Color(0xFFD0ECF5)),
      _ => (AppColors.onSurfaceVariant, AppColors.surfaceContainerHighest),
    };
  }
}

// ─── Empty State Widget ─────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 36, color: AppColors.onTertiaryContainer),
            ),
            const SizedBox(height: 24),
            Text(title, style: AppTypography.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              GradientPillButton(
                label: actionLabel!,
                onPressed: onAction,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Shelf Divider (stylistic anchor from DESIGN.md) ────────

class ShelfDivider extends StatelessWidget {
  const ShelfDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.tertiaryFixedDim,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
