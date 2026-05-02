import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/core/theme/app_colors.dart';
import 'package:neighborly/core/theme/app_typography.dart';
import 'package:neighborly/core/widgets/design_system.dart';
import 'package:neighborly/core/network/dio_client.dart';
import 'package:neighborly/features/auth/providers/auth_provider.dart';
import 'package:neighborly/features/items/providers/items_provider.dart';
import 'package:neighborly/features/items/models/item.dart';
import 'package:neighborly/features/requests/providers/requests_provider.dart';
import 'package:intl/intl.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final _messageController = TextEditingController();
  bool _isRequesting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (range != null) {
      setState(() { _startDate = range.start; _endDate = range.end; });
    }
  }

  Future<void> _submitRequest(Item item) async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select rental dates')),
      );
      return;
    }
    setState(() => _isRequesting = true);
    try {
      await createRentalRequest(ref.read(dioProvider),
        itemId: item.id,
        startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
        proposedDailyRate: item.dailyRate,
        message: _messageController.text.isNotEmpty ? _messageController.text : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rental request sent! ✨')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(itemDetailProvider(widget.itemId));
    final user = ref.watch(currentUserProvider);
    final df = DateFormat('MMM dd');

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: itemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (item) {
          final isOwner = user?.id == item.ownerId;
          final days = (_startDate != null && _endDate != null)
              ? _endDate!.difference(_startDate!).inDays + 1 : 0;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300, pinned: true,
                backgroundColor: AppColors.surface,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: AppColors.surfaceContainerHigh,
                    child: item.hasImages
                        ? Image.network(item.primaryImage, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      CategoryChip(label: item.category),
                      const SizedBox(width: 8),
                      StatusBadge(status: item.status),
                    ]),
                    const SizedBox(height: 16),
                    Text(item.title, style: AppTypography.headlineMedium),
                    const SizedBox(height: 8),
                    Row(children: [
                      Text('₹${item.dailyRate.toStringAsFixed(0)}',
                          style: AppTypography.headlineSmall.copyWith(color: AppColors.primary)),
                      Text(' / day', style: AppTypography.bodyMedium),
                      if (item.weeklyRate != null) ...[
                        const SizedBox(width: 16),
                        Text('₹${item.weeklyRate!.toStringAsFixed(0)} / week',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
                      ],
                    ]),
                    if (item.depositRequired > 0) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.shield_outlined, size: 16, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text('Security deposit: ₹${item.depositRequired.toStringAsFixed(0)}',
                            style: AppTypography.labelMedium),
                      ]),
                    ],
                    const SizedBox(height: 24),
                    const ShelfDivider(),
                    const SizedBox(height: 16),
                    if (item.description != null && item.description!.isNotEmpty) ...[
                      Text('About this item', style: AppTypography.titleMedium),
                      const SizedBox(height: 8),
                      Text(item.description!, style: AppTypography.bodyMedium),
                      const SizedBox(height: 24),
                    ],
                    if (item.conditionDescription != null && item.conditionDescription!.isNotEmpty) ...[
                      Text('Condition', style: AppTypography.titleMedium),
                      const SizedBox(height: 8),
                      AmbientCard(
                        padding: const EdgeInsets.all(16),
                        color: AppColors.tertiaryContainer.withOpacity(0.5),
                        child: Text(item.conditionDescription!, style: AppTypography.bodySmall),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (!isOwner) ...[
                      const ShelfDivider(),
                      const SizedBox(height: 16),
                      Text('Request to Rent', style: AppTypography.titleLarge),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _pickDateRange,
                        child: AmbientCard(
                          padding: const EdgeInsets.all(16),
                          color: AppColors.surfaceContainerHighest,
                          child: Row(children: [
                            const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                            const SizedBox(width: 12),
                            (_startDate != null && _endDate != null)
                                ? Text('${df.format(_startDate!)} — ${df.format(_endDate!)} ($days days)',
                                    style: AppTypography.titleSmall)
                                : Text('Select dates', style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(controller: _messageController, maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Message to owner (optional)', alignLabelWithHint: true)),
                      if (days > 0) ...[
                        const SizedBox(height: 16),
                        AmbientCard(
                          padding: const EdgeInsets.all(20),
                          color: AppColors.primaryContainer.withOpacity(0.2),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('Estimated total', style: AppTypography.titleSmall),
                            Text('₹${(days * item.dailyRate).toStringAsFixed(0)}',
                                style: AppTypography.headlineSmall.copyWith(color: AppColors.primary)),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 24),
                      GradientPillButton(
                        label: 'Send Request', icon: Icons.send_rounded,
                        onPressed: _isRequesting ? null : () => _submitRequest(item),
                        isLoading: _isRequesting, width: double.infinity,
                      ),
                    ],
                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _placeholder() => const Center(
    child: Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.outlineVariant),
  );
}
