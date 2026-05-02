import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/core/theme/app_colors.dart';
import 'package:neighborly/core/theme/app_typography.dart';
import 'package:neighborly/core/widgets/design_system.dart';
import 'package:neighborly/features/auth/providers/auth_provider.dart';
import 'package:neighborly/features/items/providers/items_provider.dart';
import 'package:neighborly/features/items/models/item.dart';
import 'package:neighborly/features/items/views/item_detail_screen.dart';
import 'package:neighborly/features/items/views/new_item_screen.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();

  final _categories = [
    'All',
    'Electronics',
    'Books',
    'Sports',
    'Kitchen',
    'Tools',
    'Clothing',
    'Other',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final itemsAsync = ref.watch(itemsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ─── Header ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${user?.firstName ?? 'there'} 👋',
                              style: AppTypography.bodyLarge
                                  .copyWith(color: AppColors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 4),
                            Text('Discover nearby',
                                style: AppTypography.headlineMedium),
                          ],
                        ),
                        // Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              user?.firstName.substring(0, 1).toUpperCase() ?? '?',
                              style: AppTypography.titleLarge
                                  .copyWith(color: AppColors.onPrimaryContainer),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ─── Search Bar ─────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search items...',
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppColors.onSurfaceVariant),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onSubmitted: (_) {
                          // Trigger search
                          setState(() {});
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ─── Category Chips ─────────────────────
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          return CategoryChip(
                            label: cat,
                            isSelected: _selectedCategory == cat,
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),
                    const ShelfDivider(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ─── Item Grid ──────────────────────────────────
            itemsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: 'Failed to load',
                  subtitle: err.toString(),
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(itemsProvider),
                ),
              ),
              data: (items) {
                final filtered = _selectedCategory == 'All'
                    ? items
                    : items
                        .where((i) => i.category.toLowerCase() ==
                            _selectedCategory.toLowerCase())
                        .toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No items yet',
                      subtitle:
                          'Be the first to share something with your neighborhood!',
                      actionLabel: 'List an Item',
                      onAction: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NewItemScreen()),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 20,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ItemCard(item: filtered[index]),
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NewItemScreen()),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('List Item'),
        ),
      ),
    );
  }
}

// ─── Item Card with Ambient Shadow & hover effect ───────────

class _ItemCard extends StatelessWidget {
  final Item item;

  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ItemDetailScreen(itemId: item.id),
        ),
      ),
      child: AmbientCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: item.hasImages
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24)),
                        child: Image.network(
                          item.primaryImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const _PlaceholderIcon(),
                        ),
                      )
                    : const _PlaceholderIcon(),
              ),
            ),

            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.category,
                      style: AppTypography.labelSmall,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '₹${item.dailyRate.toStringAsFixed(0)}',
                          style: AppTypography.titleMedium
                              .copyWith(color: AppColors.primary),
                        ),
                        Text(
                          ' /day',
                          style: AppTypography.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 36,
        color: AppColors.onSurfaceVariant.withOpacity(0.3),
      ),
    );
  }
}
