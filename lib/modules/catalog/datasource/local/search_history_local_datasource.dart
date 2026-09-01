import 'package:rekluti_test/modules/catalog/contract/search_history_datasource.dart';
import 'package:rekluti_test/modules/catalog/domain/search_term.dart';
import 'package:rekluti_test/shared/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

/// [SearchHistoryDataSource] on the app's SQLite connection.
class SqliteSearchHistoryDataSource implements SearchHistoryDataSource {
  const SqliteSearchHistoryDataSource(this._database);

  static const String _table = 'search_history';

  /// How many terms the history keeps by default.
  static const int defaultLimit = 20;

  final AppDatabase _database;

  @override
  Future<void> remember(String term, {int? resultCount}) async {
    final String normalised = _normalise(term);
    if (normalised.isEmpty) {
      return;
    }

    final Database db = await _database.database;
    // Replacing on conflict deletes the old row and inserts a new one, which
    // hands the term a fresh, higher id. That is what moves it back to the top
    // and refreshes its count in a single statement.
    await db.insert(_table, <String, Object?>{
      'term': normalised,
      'searched_at': DateTime.now().millisecondsSinceEpoch,
      'result_count': resultCount,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<SearchTerm>> recent({int limit = defaultLimit}) async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      _table,
      orderBy: 'id DESC',
      limit: limit,
    );

    return rows.map(_toSearchTerm).toList(growable: false);
  }

  @override
  Future<void> forget(String term) async {
    final Database db = await _database.database;
    await db.delete(
      _table,
      where: 'term = ?',
      whereArgs: <Object?>[_normalise(term)],
    );
  }

  @override
  Future<void> clear() async {
    final Database db = await _database.database;
    await db.delete(_table);
  }

  /// One canonical form, so the same word typed with different casing or
  /// padding is one entry rather than several.
  String _normalise(String term) => term.trim().toLowerCase();

  SearchTerm _toSearchTerm(Map<String, Object?> row) {
    return SearchTerm(
      term: row['term']! as String,
      searchedAt: DateTime.fromMillisecondsSinceEpoch(
        row['searched_at']! as int,
      ),
      resultCount: row['result_count'] as int?,
    );
  }
}
