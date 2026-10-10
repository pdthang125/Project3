import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/receipt_image.dart';
import '../../../data/models/expense_transaction.dart';
import '../../../presentation/providers/expense_providers.dart';
import 'transaction_detail_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedFilter = 'All';
  final _categories = ['All', 'Food', 'Study', 'Travel', 'Gear', 'Entertainment', 'Other'];

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.backgroundDark,
            floating: true,
            title: const Text('History', style: TextStyle(fontWeight: FontWeight.w700)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(58),
              child: _CategoryFilterBar(
                categories: _categories,
                selected: _selectedFilter,
                onChanged: (cat) => setState(() => _selectedFilter = cat),
              ),
            ),
          ),

          transactionsAsync.when(
            data: (txns) {
              final filtered = _selectedFilter == 'All'
                  ? txns
                  : txns.where((t) => t.category == _selectedFilter).toList();

              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: AppColors.textMuted),
                        Gap(16),
                        Text('No receipts yet', style: TextStyle(color: AppColors.textSecondary)),
                        Gap(8),
                        Text('Scan a receipt to get started!',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final txn = filtered[index];
                    return _HistoryCard(
                      transaction: txn,
                      onTap: () => _navigateToDetail(txn),
                      onDelete: () => _deleteTransaction(txn),
                    );
                  },
                  childCount: filtered.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
            ),
          ),
          const SliverToBoxAdapter(child: Gap(100)),
        ],
      ),
    );
  }

  Future<void> _navigateToDetail(ExpenseTransaction txn) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (ctx) => TransactionDetailScreen(transaction: txn),
      ),
    );

    // Refresh if transaction was modified or deleted
    if (updated == true) {
      ref.invalidate(transactionsProvider);
      ref.invalidate(categoryTotalsProvider);
      ref.invalidate(weeklySpendingProvider);
    }
  }

  Future<void> _deleteTransaction(ExpenseTransaction txn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Delete Receipt', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Delete "${txn.merchantName}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.deleteTransaction(txn);
      ref.invalidate(transactionsProvider);
      ref.invalidate(categoryTotalsProvider);
      ref.invalidate(weeklySpendingProvider);
    }
  }
}

class _CategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onChanged;

  const _CategoryFilterBar({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = cat == selected;
          final color = cat == 'All' ? AppColors.primary : AppColors.categoryColor(cat);
          return GestureDetector(
            onTap: () => onChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? color.withAlpha(30) : AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : AppColors.glassBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? color : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ExpenseTransaction transaction;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.transaction,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(transaction.category);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Dismissible(
        key: Key(transaction.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error.withAlpha(30),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline, color: AppColors.error),
        ),
        onDismissed: (_) => onDelete(),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: transaction.thumbnailPath != null
                    ? buildReceiptImage(
                        transaction.thumbnailPath!,
                        width: 80,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _PlaceholderThumb(color: color),
                      )
                    : _PlaceholderThumb(color: color),
              ),
              const Gap(14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.merchantName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              transaction.category,
                              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Gap(8),
                          Text(
                            DateFormatter.toRelative(transaction.date),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Text(
                  CurrencyFormatter.formatVNDShort(transaction.totalAmount),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderThumb extends StatelessWidget {
  final Color color;
  const _PlaceholderThumb({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 88,
      color: color.withAlpha(20),
      child: Icon(Icons.receipt, color: color.withAlpha(150), size: 32),
    );
  }
}
