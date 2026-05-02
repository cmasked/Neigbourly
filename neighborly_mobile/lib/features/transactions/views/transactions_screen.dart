import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/core/theme/app_colors.dart';
import 'package:neighborly/core/theme/app_typography.dart';
import 'package:neighborly/core/widgets/design_system.dart';
import 'package:neighborly/core/network/dio_client.dart';
import 'package:neighborly/features/auth/providers/auth_provider.dart';
import 'package:neighborly/features/transactions/models/transaction.dart';
import 'package:neighborly/features/transactions/providers/transactions_provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTxns = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 0), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Activity', style: AppTypography.headlineMedium),
              const SizedBox(height: 4),
              Text('Your transactions & payments', style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          )),
          const SizedBox(height: 16),
          Expanded(child: asyncTxns.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Error', subtitle: e.toString(),
              actionLabel: 'Retry', onAction: () => ref.invalidate(transactionsProvider)),
            data: (txns) {
              if (txns.isEmpty) return const EmptyState(
                icon: Icons.receipt_long_outlined, title: 'No activity yet',
                subtitle: 'Your confirmed rentals and payments will appear here');
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                itemCount: txns.length,
                itemBuilder: (ctx, i) => _TransactionCard(txn: txns[i]),
              );
            },
          )),
        ]),
      ),
    );
  }
}

class _TransactionCard extends ConsumerWidget {
  final Transaction txn;
  const _TransactionCard({required this.txn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final df = DateFormat('MMM dd');
    final user = ref.watch(currentUserProvider);
    final isOwner = user?.id == txn.ownerId;
    final role = isOwner ? 'Lending' : 'Borrowing';

    // Determine next valid status transitions
    final nextStatus = _getNextStatus(txn.status, isOwner);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AmbientCard(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isOwner ? AppColors.tertiaryContainer : AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(isOwner ? Icons.upload_rounded : Icons.download_rounded,
                  size: 18, color: isOwner ? AppColors.onTertiaryFixed : AppColors.onSecondaryContainer),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(role, style: AppTypography.labelMedium),
                Text('#${txn.id.substring(0, 8)}', style: AppTypography.bodySmall),
              ]),
            ]),
            StatusBadge(status: txn.status),
          ]),
          const SizedBox(height: 16),

          // Dates & Rate
          Row(children: [
            _InfoPill(icon: Icons.calendar_today_rounded,
              text: '${df.format(txn.startDate)} — ${df.format(txn.endDate)}'),
            const SizedBox(width: 12),
            _InfoPill(icon: Icons.currency_rupee_rounded, text: '₹${txn.dailyRate.toStringAsFixed(0)}/day'),
          ]),
          const SizedBox(height: 12),

          // Financial summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: [
              _SummaryRow('Rental Fee', '₹${txn.totalRentalFee.toStringAsFixed(0)}'),
              const SizedBox(height: 6),
              _SummaryRow('Commission', '₹${txn.commissionAmount.toStringAsFixed(0)}'),
              if (txn.pickupAt != null) ...[
                const SizedBox(height: 6),
                _SummaryRow('Picked up', DateFormat('MMM dd, hh:mm a').format(txn.pickupAt!)),
              ],
              if (txn.returnAt != null) ...[
                const SizedBox(height: 6),
                _SummaryRow('Returned', DateFormat('MMM dd, hh:mm a').format(txn.returnAt!)),
              ],
            ]),
          ),

          // Actions
          if (nextStatus != null) ...[
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: GradientPillButton(
                label: _statusLabel(nextStatus),
                icon: _statusIcon(nextStatus),
                onPressed: () => _advance(context, ref, nextStatus),
              )),
              if (txn.status == 'completed') ...[
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _showReviewSheet(context, ref),
                  icon: const Icon(Icons.star_rounded),
                  label: const Text('Review'),
                )),
              ],
            ]),
          ],
          if (txn.status == 'completed' && nextStatus == null) ...[
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _showReviewSheet(context, ref),
                icon: const Icon(Icons.star_rounded),
                label: const Text('Leave Review'),
              )),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _showDisputeSheet(context, ref),
                icon: const Icon(Icons.flag_rounded),
                label: const Text('Dispute'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error)),
              )),
            ]),
          ],
        ]),
      ),
    );
  }

  String? _getNextStatus(String current, bool isOwner) {
    return switch (current) {
      'pending_payment' => 'confirmed',
      'confirmed' when isOwner => 'picked_up',
      'picked_up' when !isOwner => 'returned',
      _ => null,
    };
  }

  String _statusLabel(String status) => switch (status) {
    'confirmed' => 'Confirm Payment',
    'picked_up' => 'Mark Picked Up',
    'returned' => 'Mark Returned',
    _ => status.replaceAll('_', ' '),
  };

  IconData _statusIcon(String status) => switch (status) {
    'confirmed' => Icons.payment_rounded,
    'picked_up' => Icons.move_to_inbox_rounded,
    'returned' => Icons.assignment_return_rounded,
    _ => Icons.arrow_forward_rounded,
  };

  Future<void> _advance(BuildContext ctx, WidgetRef ref, String status) async {
    try {
      await updateTransactionStatus(ref.read(dioProvider), txn.id, status);
      ref.invalidate(transactionsProvider);
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Status updated to $status')));
    } catch (e) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showReviewSheet(BuildContext ctx, WidgetRef ref) {
    int rating = 5;
    final commentCtrl = TextEditingController();
    final user = ref.read(currentUserProvider);
    final revieweeId = user?.id == txn.ownerId ? txn.borrowerId : txn.ownerId;

    showModalBottomSheet(context: ctx, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Leave a Review', style: AppTypography.titleLarge),
          const SizedBox(height: 16),
          StatefulBuilder(builder: (ctx, ss) => Row(
            children: List.generate(5, (i) => IconButton(
              icon: Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: i < rating ? AppColors.warning : AppColors.outlineVariant, size: 36),
              onPressed: () => ss(() => rating = i + 1),
            )),
          )),
          const SizedBox(height: 12),
          TextFormField(controller: commentCtrl, maxLines: 3,
            decoration: const InputDecoration(labelText: 'Comment (optional)', alignLabelWithHint: true)),
          const SizedBox(height: 20),
          GradientPillButton(label: 'Submit Review', width: double.infinity,
            onPressed: () async {
              try {
                await createReview(ref.read(dioProvider),
                  transactionId: txn.id, revieweeId: revieweeId,
                  rating: rating, comment: commentCtrl.text.isNotEmpty ? commentCtrl.text : null);
                if (ctx.mounted) { Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Review submitted ⭐'))); }
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }),
        ]),
      ),
    );
  }

  void _showDisputeSheet(BuildContext ctx, WidgetRef ref) {
    final reasonCtrl = TextEditingController();
    showModalBottomSheet(context: ctx, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('File a Dispute', style: AppTypography.titleLarge),
          const SizedBox(height: 16),
          TextFormField(controller: reasonCtrl, maxLines: 4,
            decoration: const InputDecoration(labelText: 'Reason for dispute', alignLabelWithHint: true)),
          const SizedBox(height: 20),
          GradientPillButton(label: 'Submit Dispute', width: double.infinity, icon: Icons.flag_rounded,
            onPressed: () async {
              if (reasonCtrl.text.isEmpty) return;
              try {
                await fileDispute(ref.read(dioProvider),
                  transactionId: txn.id, reason: reasonCtrl.text);
                if (ctx.mounted) { Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Dispute filed'))); }
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }),
        ]),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon; final String text;
  const _InfoPill({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
      const SizedBox(width: 6),
      Text(text, style: AppTypography.labelSmall),
    ]),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label; final String value;
  const _SummaryRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: AppTypography.bodySmall),
    Text(value, style: AppTypography.labelMedium),
  ]);
}
