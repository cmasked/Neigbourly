import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/core/theme/app_colors.dart';
import 'package:neighborly/core/theme/app_typography.dart';
import 'package:neighborly/core/widgets/design_system.dart';
import 'package:neighborly/core/network/dio_client.dart';
import 'package:neighborly/features/requests/providers/requests_provider.dart';
import 'package:neighborly/features/requests/models/rental_request.dart';
import 'package:neighborly/features/transactions/providers/transactions_provider.dart';
import 'package:intl/intl.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});
  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 0), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Requests', style: AppTypography.headlineMedium),
              const SizedBox(height: 4),
              Text('Manage rental requests', style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          )),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
            child: TabBar(controller: _tabCtrl,
              indicator: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.onSurface.withOpacity(0.05), blurRadius: 8, spreadRadius: -2)]),
              indicatorSize: TabBarIndicatorSize.tab, dividerColor: Colors.transparent,
              labelStyle: AppTypography.labelLarge, unselectedLabelStyle: AppTypography.labelMedium,
              labelColor: AppColors.primary, unselectedLabelColor: AppColors.onSurfaceVariant,
              tabs: const [Tab(text: 'Incoming'), Tab(text: 'My Requests')],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: TabBarView(controller: _tabCtrl, children: [
            _IncomingTab(),
            _OutgoingTab(),
          ])),
        ]),
      ),
    );
  }
}

class _IncomingTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(incomingRequestsProvider);
    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Error', subtitle: e.toString(),
        actionLabel: 'Retry', onAction: () => ref.invalidate(incomingRequestsProvider)),
      data: (requests) {
        if (requests.isEmpty) return const EmptyState(
          icon: Icons.inbox_rounded, title: 'No incoming requests', subtitle: 'Requests on your items will appear here');
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
          itemCount: requests.length,
          itemBuilder: (ctx, i) => _RequestCard(request: requests[i], isIncoming: true),
        );
      },
    );
  }
}

class _OutgoingTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(myRequestsProvider);
    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Error', subtitle: e.toString()),
      data: (requests) {
        if (requests.isEmpty) return const EmptyState(
          icon: Icons.send_rounded, title: 'No requests yet', subtitle: 'Your rental requests will appear here');
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
          itemCount: requests.length,
          itemBuilder: (ctx, i) => _RequestCard(request: requests[i], isIncoming: false),
        );
      },
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final RentalRequest request;
  final bool isIncoming;
  const _RequestCard({required this.request, required this.isIncoming});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final df = DateFormat('MMM dd');
    final isPending = request.status == 'pending';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AmbientCard(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text('Request #${request.id.substring(0, 8)}', style: AppTypography.titleSmall)),
            StatusBadge(status: request.status),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 8),
            Text('${df.format(request.startDate)} — ${df.format(request.endDate)}', style: AppTypography.bodyMedium),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.currency_rupee_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('₹${request.proposedDailyRate.toStringAsFixed(0)} / day', style: AppTypography.titleSmall.copyWith(color: AppColors.primary)),
          ]),
          if (request.message != null && request.message!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(request.message!, style: AppTypography.bodySmall),
          ],
          if (request.hasCounter) ...[
            const SizedBox(height: 12),
            AmbientCard(
              padding: const EdgeInsets.all(12), color: AppColors.tertiaryContainer.withOpacity(0.5),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Counter Proposal', style: AppTypography.labelLarge.copyWith(color: AppColors.onTertiaryFixed)),
                const SizedBox(height: 4),
                Text('${df.format(request.counterStartDate!)} — ${df.format(request.counterEndDate!)} at ₹${request.counterDailyRate!.toStringAsFixed(0)}/day',
                  style: AppTypography.bodySmall),
                if (request.counterMessage != null) Text(request.counterMessage!, style: AppTypography.bodySmall),
              ]),
            ),
          ],
          if (isPending && isIncoming) ...[
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => _reject(context, ref),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error)),
                child: const Text('Reject'),
              )),
              const SizedBox(width: 12),
              Expanded(child: GradientPillButton(label: 'Accept',
                onPressed: () => _accept(context, ref))),
            ]),
          ],
          if (isPending && !isIncoming) ...[
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: OutlinedButton(
              onPressed: () => _cancel(context, ref),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error)),
              child: const Text('Cancel Request'),
            )),
          ],
        ]),
      ),
    );
  }

  Future<void> _accept(BuildContext ctx, WidgetRef ref) async {
    try {
      await acceptRequest(ref.read(dioProvider), request.id);
      ref.invalidate(incomingRequestsProvider);
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Request accepted ✓')));
    } catch (e) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _reject(BuildContext ctx, WidgetRef ref) async {
    try {
      await rejectRequest(ref.read(dioProvider), request.id);
      ref.invalidate(incomingRequestsProvider);
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Request rejected')));
    } catch (e) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _cancel(BuildContext ctx, WidgetRef ref) async {
    try {
      await cancelRequest(ref.read(dioProvider), request.id);
      ref.invalidate(myRequestsProvider);
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Request cancelled')));
    } catch (e) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
