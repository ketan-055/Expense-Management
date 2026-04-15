import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';
import '../../core/month_names.dart';
import '../models/budget_entry.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../models/expense_query.dart';
import '../models/payment_method.dart';
import '../models/place.dart';
import '../models/udhaar_entry.dart';

/// SQLite singleton: schema, initialization, and CRUD for categories, places, budget, and expenses.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, AppConstants.databaseName);
    return openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await _createTablesV3(db);
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    await db.execute('PRAGMA foreign_keys = ON');
    if (oldVersion < 2) {
      await _createTablesLegacy(db);
    }
    if (oldVersion < 3) {
      await _migrateToV3(db);
    }
    if (oldVersion < 4) {
      await _createUdhaarTables(db);
    }
  }

  /// Original schema (v1/v2) without places.
  Future<void> _createTablesLegacy(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE COLLATE NOCASE,
  created_at INTEGER NOT NULL
);
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS budget (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  amount_rupees INTEGER NOT NULL,
  month_name TEXT NOT NULL,
  month_index INTEGER NOT NULL,
  year INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE(year, month_index)
);
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  amount_rupees INTEGER NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  payment_method TEXT NOT NULL,
  category_id INTEGER NOT NULL,
  expense_at INTEGER NOT NULL,
  FOREIGN KEY (category_id) REFERENCES categories (id)
);
''');
  }

  Future<void> _createTablesV3(Database db) async {
    await _createTablesLegacy(db);
    await db.execute('''
CREATE TABLE IF NOT EXISTS places (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE COLLATE NOCASE,
  created_at INTEGER NOT NULL
);
''');
    // Fresh v3 installs: recreate expenses with place_id — handled by onUpgrade only
    // For onCreate at v3, legacy tables may already exist from _createTablesLegacy without places.
    // Insert default place if missing, then ensure expenses has place_id.
    await _ensurePlacesAndExpensePlaceColumn(db);
    await _createUdhaarTables(db);
  }

  Future<void> _createUdhaarTables(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS udhaar_to_others (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  amount_rupees INTEGER NOT NULL,
  entry_at INTEGER NOT NULL
);
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS udhaar_from_me (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  amount_rupees INTEGER NOT NULL,
  entry_at INTEGER NOT NULL
);
''');
  }

  Future<void> _migrateToV3(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS places (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE COLLATE NOCASE,
  created_at INTEGER NOT NULL
);
''');
    await _ensurePlacesAndExpensePlaceColumn(db);
  }

  Future<void> _ensurePlacesAndExpensePlaceColumn(Database db) async {
    final placeRows = await db.query('places', limit: 1);
    int defaultPlaceId;
    if (placeRows.isEmpty) {
      defaultPlaceId = await db.insert('places', {
        'name': 'General',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      defaultPlaceId = placeRows.first['id']! as int;
    }

    final cols = await db.rawQuery('PRAGMA table_info(expenses)');
    final hasPlace = cols.any((c) => c['name'] == 'place_id');
    if (!hasPlace) {
      await db.execute('ALTER TABLE expenses ADD COLUMN place_id INTEGER');
      await db.rawUpdate(
        'UPDATE expenses SET place_id = ? WHERE place_id IS NULL',
        [defaultPlaceId],
      );
    }
  }

  // --- Categories ---

  Future<int> insertCategory(String name) async {
    final db = await database;
    final trimmed = name.trim();
    return db.insert(
      'categories',
      {
        'name': trimmed,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final rows = await db.query(
      'categories',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  // --- Places ---

  Future<int> insertPlace(String name) async {
    final db = await database;
    final trimmed = name.trim();
    return db.insert(
      'places',
      {
        'name': trimmed,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Place>> getAllPlaces() async {
    final db = await database;
    final rows = await db.query(
      'places',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Place.fromMap).toList();
  }

  // --- Budget ---

  Future<BudgetEntry?> getBudgetForMonth(int year, int monthIndex) async {
    final db = await database;
    final rows = await db.query(
      'budget',
      where: 'year = ? AND month_index = ?',
      whereArgs: [year, monthIndex],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BudgetEntry.fromMap(rows.first);
  }

  Future<void> upsertBudget({
    required int amountRupees,
    required int year,
    required int monthIndex,
  }) async {
    final db = await database;
    final monthName = monthShortName(monthIndex);
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = await db.update(
      'budget',
      {
        'amount_rupees': amountRupees,
        'month_name': monthName,
        'updated_at': now,
      },
      where: 'year = ? AND month_index = ?',
      whereArgs: [year, monthIndex],
    );
    if (updated == 0) {
      await db.insert('budget', {
        'amount_rupees': amountRupees,
        'month_name': monthName,
        'month_index': monthIndex,
        'year': year,
        'updated_at': now,
      });
    }
  }

  // --- Expenses ---

  Future<int> insertExpense(ExpenseDraft draft) async {
    final db = await database;
    return db.insert('expenses', draft.toMap());
  }

  Future<void> updateExpense(int id, ExpenseDraft draft) async {
    final db = await database;
    await db.update(
      'expenses',
      draft.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> sumExpenseRupeesForMonth(int year, int monthIndex) async {
    final db = await database;
    final start = DateTime(year, monthIndex, 1);
    final end = monthIndex == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, monthIndex + 1, 1);
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;
    final result = await db.rawQuery(
      '''
SELECT IFNULL(SUM(amount_rupees), 0) AS s FROM expenses
WHERE expense_at >= ? AND expense_at < ?
''',
      [startMs, endMs],
    );
    final raw = result.first['s'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 0;
  }

  ExpenseItem _rowToExpenseItem(Map<String, Object?> m) {
    return ExpenseItem(
      id: m['id']! as int,
      amountRupees: m['amount_rupees']! as int,
      title: m['title']! as String,
      description: m['description'] as String?,
      paymentMethod: PaymentMethod.fromDb(m['payment_method']! as String),
      categoryName: m['category_name']! as String,
      placeName: m['place_name']! as String,
      categoryId: m['category_id']! as int,
      placeId: m['place_id']! as int,
      expenseAt: DateTime.fromMillisecondsSinceEpoch(m['expense_at']! as int),
    );
  }

  /// Filtered list within [scopeYear]/[scopeMonth]. [limit] null = no limit. [limit] 0 returns empty.
  Future<List<ExpenseItem>> queryExpenses(ExpenseQuery q) async {
    if (q.limit != null && q.limit! <= 0) {
      return [];
    }
    final db = await database;
    final where = <String>['1 = 1'];
    final args = <Object?>[];

    final lastDayInMonth = DateTime(q.scopeYear, q.scopeMonth + 1, 0).day;
    if (q.filterDay != null) {
      final day = q.filterDay!.clamp(1, lastDayInMonth);
      final start = DateTime(q.scopeYear, q.scopeMonth, day);
      final end = start.add(const Duration(days: 1));
      where.add('e.expense_at >= ? AND e.expense_at < ?');
      args.addAll([start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);
    } else {
      final monthStart = DateTime(q.scopeYear, q.scopeMonth, 1);
      final monthEnd = q.scopeMonth == 12
          ? DateTime(q.scopeYear + 1, 1, 1)
          : DateTime(q.scopeYear, q.scopeMonth + 1, 1);
      where.add('e.expense_at >= ? AND e.expense_at < ?');
      args.addAll([
        monthStart.millisecondsSinceEpoch,
        monthEnd.millisecondsSinceEpoch,
      ]);
    }
    if (q.categoryId != null) {
      where.add('e.category_id = ?');
      args.add(q.categoryId);
    }
    if (q.placeId != null) {
      where.add('e.place_id = ?');
      args.add(q.placeId);
    }
    if (q.paymentMethodDb != null) {
      where.add('e.payment_method = ?');
      args.add(q.paymentMethodDb);
    }
    if (q.hasAmountFilter) {
      where.add('e.amount_rupees >= ? AND e.amount_rupees <= ?');
      args.addAll([q.amountMin!, q.amountMax!]);
    }

    var sql = '''
SELECT e.id AS id,
       e.amount_rupees AS amount_rupees,
       e.title AS title,
       e.description AS description,
       e.payment_method AS payment_method,
       e.expense_at AS expense_at,
       e.category_id AS category_id,
       e.place_id AS place_id,
       c.name AS category_name,
       pl.name AS place_name
FROM expenses e
INNER JOIN categories c ON c.id = e.category_id
INNER JOIN places pl ON pl.id = e.place_id
WHERE ${where.join(' AND ')}
ORDER BY e.expense_at DESC, e.id DESC
''';

    if (q.limit != null) {
      sql += ' LIMIT ${q.limit}';
    }

    final rows = await db.rawQuery(sql, args);
    return rows.map(_rowToExpenseItem).toList();
  }

  /// All expenses in a calendar month (ordered newest first).
  Future<List<ExpenseItem>> getExpensesForMonth(
    int year,
    int monthIndex,
  ) async {
    final db = await database;
    final start = DateTime(year, monthIndex, 1);
    final end = monthIndex == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, monthIndex + 1, 1);
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;
    final rows = await db.rawQuery(
      '''
SELECT e.id AS id,
       e.amount_rupees AS amount_rupees,
       e.title AS title,
       e.description AS description,
       e.payment_method AS payment_method,
       e.expense_at AS expense_at,
       e.category_id AS category_id,
       e.place_id AS place_id,
       c.name AS category_name,
       pl.name AS place_name
FROM expenses e
INNER JOIN categories c ON c.id = e.category_id
INNER JOIN places pl ON pl.id = e.place_id
WHERE e.expense_at >= ? AND e.expense_at < ?
ORDER BY e.expense_at DESC, e.id DESC
''',
      [startMs, endMs],
    );
    return rows.map(_rowToExpenseItem).toList();
  }

  // --- Udhaar (borrowed / lent) ---

  Future<int> insertUdhaarToOthers({
    required String name,
    required int amountRupees,
    required DateTime entryAt,
  }) async {
    final db = await database;
    return db.insert('udhaar_to_others', {
      'name': name.trim(),
      'amount_rupees': amountRupees,
      'entry_at': entryAt.millisecondsSinceEpoch,
    });
  }

  Future<int> insertUdhaarFromMe({
    required String name,
    required int amountRupees,
    required DateTime entryAt,
  }) async {
    final db = await database;
    return db.insert('udhaar_from_me', {
      'name': name.trim(),
      'amount_rupees': amountRupees,
      'entry_at': entryAt.millisecondsSinceEpoch,
    });
  }

  Future<List<UdhaarEntry>> getUdhaarToOthers({required bool nameAscending}) async {
    final db = await database;
    final rows = await db.query(
      'udhaar_to_others',
      orderBy: 'name COLLATE NOCASE ${nameAscending ? 'ASC' : 'DESC'}',
    );
    return rows.map(UdhaarEntry.fromMap).toList();
  }

  Future<List<UdhaarEntry>> getUdhaarFromMe({required bool nameAscending}) async {
    final db = await database;
    final rows = await db.query(
      'udhaar_from_me',
      orderBy: 'name COLLATE NOCASE ${nameAscending ? 'ASC' : 'DESC'}',
    );
    return rows.map(UdhaarEntry.fromMap).toList();
  }

  Future<int> sumUdhaarToOthers() async {
    final db = await database;
    final r = await db.rawQuery(
      'SELECT IFNULL(SUM(amount_rupees), 0) AS s FROM udhaar_to_others',
    );
    final raw = r.first['s'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 0;
  }

  Future<int> sumUdhaarFromMe() async {
    final db = await database;
    final r = await db.rawQuery(
      'SELECT IFNULL(SUM(amount_rupees), 0) AS s FROM udhaar_from_me',
    );
    final raw = r.first['s'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 0;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
