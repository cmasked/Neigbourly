import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/core/theme/app_colors.dart';
import 'package:neighborly/core/theme/app_typography.dart';
import 'package:neighborly/core/widgets/design_system.dart';
import 'package:neighborly/features/auth/providers/auth_provider.dart';
import 'package:neighborly/features/transactions/models/transaction.dart';
import 'package:neighborly/features/transactions/providers/transactions_provider.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final reviewsAsync = ref.watch(userReviewsProvider(user.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ─── Header ─────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Profile', style: AppTypography.headlineMedium),
              IconButton(
                onPressed: () => _showLogoutConfirm(context, ref),
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              ),
            ]),
            const SizedBox(height: 24),

            // ─── User Info Card ─────────────────────────────
            AmbientCard(
              padding: const EdgeInsets.all(24),
              child: Row(children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(child: Text(
                    user.firstName.substring(0, 1).toUpperCase(),
                    style: AppTypography.headlineLarge.copyWith(color: Colors.white),
                  )),
                ),
                const SizedBox(width: 20),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user.fullName, style: AppTypography.titleLarge),
                  const SizedBox(height: 4),
                  Text(user.email, style: AppTypography.bodySmall),
                  const SizedBox(height: 8),
                  Row(children: [
                    StatusBadge(status: user.role),
                    const SizedBox(width: 8),
                    StatusBadge(status: user.verificationStatus),
                  ]),
                ])),
              ]),
            ),
            const SizedBox(height: 24),

            // ─── Info tiles ─────────────────────────────────
            Row(children: [
              Expanded(child: _InfoTile(
                icon: Icons.phone_rounded, label: 'Phone',
                value: user.phone ?? 'Not set',
              )),
              const SizedBox(width: 12),
              Expanded(child: _InfoTile(
                icon: Icons.calendar_today_rounded, label: 'Member since',
                value: DateFormat('MMM yyyy').format(user.createdAt),
              )),
            ]),
            const SizedBox(height: 24),

            const ShelfDivider(),
            const SizedBox(height: 24),

            // ─── Reviews Section ────────────────────────────
            Text('Reviews Received', style: AppTypography.titleLarge),
            const SizedBox(height: 16),

            reviewsAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => Text('Error loading reviews: $e', style: AppTypography.bodySmall),
              data: (reviews) {
                if (reviews.isEmpty) return const AmbientCard(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No reviews yet', style: AppTypography.bodyMedium)),
                );

                final avgRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Average rating
                  AmbientCard(
                    padding: const EdgeInsets.all(20),
                    color: AppColors.primaryContainer.withOpacity(0.15),
                    child: Row(children: [
                      Text(avgRating.toStringAsFixed(1),
                        style: AppTypography.displaySmall.copyWith(color: AppColors.primary)),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: List.generate(5, (i) => Icon(
                          i < avgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 20, color: AppColors.warning,
                        ))),
                        Text('${reviews.length} review${reviews.length > 1 ? 's' : ''}',
                          style: AppTypography.labelSmall),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Review cards
                  ...reviews.map((review) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AmbientCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Row(children: List.generate(5, (i) => Icon(
                            i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 16, color: i < review.rating ? AppColors.warning : AppColors.outlineVariant,
                          ))),
                          Text(DateFormat('MMM dd, yyyy').format(review.createdAt),
                            style: AppTypography.labelSmall),
                        ]),
                        if (review.comment != null && review.comment!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(review.comment!, style: AppTypography.bodyMedium),
                        ],
                      ]),
                    ),
                  )),
                ]);
              },
            ),
          ]),
        ),
      ),
    );
  }

  void _showLogoutConfirm(BuildContext ctx, WidgetRef ref) {
    showDialog(context: ctx, builder: (ctx) => AlertDialog(
      title: const Text('Logout?'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () { Navigator.of(ctx).pop(); ref.read(authProvider.notifier).logout(); },
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Logout'),
        ),
      ],
    ));
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => AmbientCard(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 20, color: AppColors.primary),
      const SizedBox(height: 12),
      Text(label, style: AppTypography.labelSmall),
      const SizedBox(height: 4),
      Text(value, style: AppTypography.titleSmall),
    ]),
  );
}
