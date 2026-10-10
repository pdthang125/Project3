import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/expense_transaction.dart';
import '../../widgets/receipt_image.dart';
import '../../providers/expense_providers.dart';
import 'edit_transaction_screen.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final ExpenseTransaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppColors.categoryColor(transaction.category);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('Chi tiết giao dịch', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () => _navigateToEdit(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Receipt Image
            if (transaction.thumbnailPath != null)
              Container(
                width: double.infinity,
                height: 300,
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.glassBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: buildReceiptImage(
                    transaction.thumbnailPath!,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(color),
                  ),
                ),
              ),

            // Merchant Name
            _buildSection(
              'Tên cửa hàng',
              transaction.merchantName,
              Icons.store,
              color,
            ),

            // Amount
            _buildSection(
              'Số tiền',
              CurrencyFormatter.formatVND(transaction.totalAmount),
              Icons.payments,
              AppColors.success,
            ),

            // Category
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_categoryIcon(transaction.category), color: color, size: 22),
                    ),
                    const Gap(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Danh mục',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const Gap(4),
                          Text(
                            transaction.category,
                            style: TextStyle(
                              color: color,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Date
            _buildSection(
              'Ngày giao dịch',
              DateFormatter.toDMY(transaction.date),
              Icons.calendar_today,
              AppColors.primary,
            ),

            // Created At
            _buildSection(
              'Ngày tạo',
              '${DateFormatter.toDMY(transaction.createdAt)} (${DateFormatter.toRelative(transaction.createdAt)})',
              Icons.access_time,
              AppColors.textSecondary,
            ),

            // Raw OCR Text (if available)
            if (transaction.rawOcrText != null && transaction.rawOcrText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.text_fields, color: AppColors.textSecondary, size: 18),
                          Gap(8),
                          Text(
                            'Văn bản OCR',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Gap(12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          transaction.rawOcrText!,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const Gap(100),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const Gap(4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Color color) {
    return Container(
      color: color.withAlpha(20),
      child: Center(
        child: Icon(Icons.receipt, color: color.withAlpha(150), size: 64),
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'study':
        return Icons.school;
      case 'travel':
        return Icons.directions_car;
      case 'gear':
        return Icons.devices;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.receipt;
    }
  }

  Future<void> _navigateToEdit(BuildContext context, WidgetRef ref) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (ctx) => EditTransactionScreen(transaction: transaction),
      ),
    );

    if (updated == true) {
      ref.invalidate(transactionsProvider);
      ref.invalidate(categoryTotalsProvider);
      ref.invalidate(weeklySpendingProvider);
      if (context.mounted) {
        Navigator.pop(context, true); // Return to history with refresh signal
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Xóa giao dịch', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Bạn có chắc muốn xóa giao dịch "${transaction.merchantName}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.deleteTransaction(transaction);
      ref.invalidate(transactionsProvider);
      ref.invalidate(categoryTotalsProvider);
      ref.invalidate(weeklySpendingProvider);
      if (context.mounted) {
        Navigator.pop(context, true); // Return to history with refresh signal
      }
    }
  }
}
