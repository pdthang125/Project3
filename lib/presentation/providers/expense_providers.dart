import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense_transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../core/utils/receipt_parser.dart';

// ─── Repository Provider ──────────────────────────────────────────────────────

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

// ─── Transactions List ────────────────────────────────────────────────────────

final transactionsProvider =
    FutureProvider<List<ExpenseTransaction>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getAllTransactions();
});

// ─── Category Totals (for Pie Chart) ─────────────────────────────────────────

final categoryTotalsProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getCategoryTotals();
});

// ─── Weekly Spending (for Bar Chart) ─────────────────────────────────────────

final weeklySpendingProvider = FutureProvider<List<double>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getWeeklySpending(weeks: 6);
});

// ─── OCR / Review State ───────────────────────────────────────────────────────

class OcrState {
  final bool isProcessing;
  final String? imagePath;
  final ParsedReceiptData? parsedData;
  final String? error;

  const OcrState({
    this.isProcessing = false,
    this.imagePath,
    this.parsedData,
    this.error,
  });

  OcrState copyWith({
    bool? isProcessing,
    String? imagePath,
    ParsedReceiptData? parsedData,
    String? error,
  }) {
    return OcrState(
      isProcessing: isProcessing ?? this.isProcessing,
      imagePath: imagePath ?? this.imagePath,
      parsedData: parsedData ?? this.parsedData,
      error: error ?? this.error,
    );
  }
}

class OcrNotifier extends StateNotifier<OcrState> {
  OcrNotifier() : super(const OcrState());

  void setProcessing(bool value) =>
      state = state.copyWith(isProcessing: value);

  void setParsedData(String imagePath, ParsedReceiptData data) {
    state = state.copyWith(
      isProcessing: false,
      imagePath: imagePath,
      parsedData: data,
    );
  }

  void setError(String error) {
    state = state.copyWith(isProcessing: false, error: error);
  }

  void reset() => state = const OcrState();
}

final ocrProvider =
    StateNotifierProvider<OcrNotifier, OcrState>((ref) => OcrNotifier());
