import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/expense_transaction.dart';
import '../../services/database/database_helper.dart';

/// Data source for CRUD operations on expense transactions
class TransactionDatasource {
  TransactionDatasource._();
  static final TransactionDatasource instance = TransactionDatasource._();

  Future<Database> get _db async => DatabaseHelper.instance.database;

  // ─── CREATE ───────────────────────────────────────────────────────────────

  Future<void> insert(ExpenseTransaction transaction) async {
    final db = await _db;
    await db.insert(
      AppConstants.transactionsTable,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── READ ─────────────────────────────────────────────────────────────────

  Future<List<ExpenseTransaction>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.transactionsTable,
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map(ExpenseTransaction.fromMap).toList();
  }

  Future<List<ExpenseTransaction>> getByCategory(String category) async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.transactionsTable,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
    return maps.map(ExpenseTransaction.fromMap).toList();
  }

  Future<List<ExpenseTransaction>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.transactionsTable,
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map(ExpenseTransaction.fromMap).toList();
  }

  Future<ExpenseTransaction?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.transactionsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ExpenseTransaction.fromMap(maps.first);
  }

  // ─── Aggregations ─────────────────────────────────────────────────────────

  Future<Map<String, double>> getCategoryTotals() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT category, SUM(total_amount) as total
      FROM ${AppConstants.transactionsTable}
      GROUP BY category
      ORDER BY total DESC
    ''');
    return {
      for (final row in result)
        row['category'] as String: (row['total'] as num).toDouble(),
    };
  }

  /// Returns weekly spending for the last [weeks] weeks
  Future<List<double>> getWeeklySpending(int weeks) async {
    final db = await _db;
    final now = DateTime.now();
    final results = <double>[];

    for (int i = weeks - 1; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + i * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(total_amount), 0) as total
        FROM ${AppConstants.transactionsTable}
        WHERE date >= ? AND date <= ?
      ''', [
        DateTime(weekStart.year, weekStart.month, weekStart.day).toIso8601String(),
        DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59).toIso8601String(),
      ]);
      results.add((result.first['total'] as num).toDouble());
    }
    return results;
  }

  // ─── UPDATE ───────────────────────────────────────────────────────────────

  Future<void> update(ExpenseTransaction transaction) async {
    final db = await _db;
    await db.update(
      AppConstants.transactionsTable,
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete(
      AppConstants.transactionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAll() async {
    final db = await _db;
    await db.delete(AppConstants.transactionsTable);
  }
}
