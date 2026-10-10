import 'package:cross_file/cross_file.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../data/datasources/transaction_datasource.dart';
import '../../data/models/expense_transaction.dart';
import '../../services/ocr/ocr_service.dart';

/// Repository: single source of truth for expense transactions
class TransactionRepository {
  TransactionRepository({
    TransactionDatasource? datasource,
    OcrService? ocrService,
  })  : _datasource = datasource ?? TransactionDatasource.instance,
        _ocrService = ocrService ?? OcrService.instance;

  final TransactionDatasource _datasource;
  final OcrService _ocrService;
  static const _uuid = Uuid();

  // ─── Read ─────────────────────────────────────────────────────────────────

  Future<List<ExpenseTransaction>> getAllTransactions() =>
      _datasource.getAll();

  Future<List<ExpenseTransaction>> getByCategory(String category) =>
      _datasource.getByCategory(category);

  Future<Map<String, double>> getCategoryTotals() =>
      _datasource.getCategoryTotals();

  Future<List<double>> getWeeklySpending({int weeks = 6}) =>
      _datasource.getWeeklySpending(weeks);

  // ─── Write ────────────────────────────────────────────────────────────────

  Future<ExpenseTransaction> saveTransaction({
    required double totalAmount,
    required DateTime date,
    required String merchantName,
    required String category,
    XFile? receiptImage,
    String? rawOcrText,
  }) async {
    final id = _uuid.v4();

    String? thumbnailPath;
    if (receiptImage != null) {
      thumbnailPath = await _ocrService.saveThumbnail(receiptImage, id);
    }

    final transaction = ExpenseTransaction(
      id: id,
      totalAmount: totalAmount,
      date: date,
      merchantName: merchantName,
      category: category,
      thumbnailPath: thumbnailPath,
      rawOcrText: rawOcrText,
      createdAt: DateTime.now(),
    );

    await _datasource.insert(transaction);
    return transaction;
  }

  Future<void> updateTransaction(ExpenseTransaction transaction) =>
      _datasource.update(transaction);

  Future<void> deleteTransaction(ExpenseTransaction transaction) async {
    await _ocrService.deleteThumbnail(transaction.thumbnailPath);
    await _datasource.delete(transaction.id);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  List<String> get availableCategories => AppConstants.defaultCategories;
}
