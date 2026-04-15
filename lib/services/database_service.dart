import '../data/database/database_helper.dart';

/// Application-facing database lifecycle. Add repositories or query methods here later.
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  final DatabaseHelper _helper = DatabaseHelper.instance;

  /// Opens the database file (creates it on first run).
  Future<void> init() async {
    await _helper.database;
  }
}
