import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/app_constants.dart';

/// SQLite database helper – singleton
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, AppConstants.dbName);

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.transactionsTable} (
        id TEXT PRIMARY KEY,
        total_amount REAL NOT NULL,
        date TEXT NOT NULL,
        merchant_name TEXT NOT NULL,
        category TEXT NOT NULL,
        thumbnail_path TEXT,
        raw_ocr_text TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Seed default categories (metadata table)
    await db.execute('''
      CREATE TABLE ${AppConstants.categoriesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color_hex TEXT NOT NULL
      )
    ''');

    final categoryColors = {
      'Food': 'FFFF6B6B',
      'Study': 'FF74B9FF',
      'Travel': 'FFFFD93D',
      'Gear': 'FF6BCB77',
      'Entertainment': 'FFCC73F8',
      'Other': 'FF9898B8',
    };

    final batch = db.batch();
    categoryColors.forEach((name, color) {
      batch.insert(AppConstants.categoriesTable, {
        'name': name,
        'color_hex': color,
      });
    });
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
