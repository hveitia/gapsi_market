import 'package:path/path.dart' as p;
import 'package:rekluti_test/shared/database/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Owns the app's single SQLite connection and its schema version.
///
/// SQLite serialises writes per connection, so opening the database more than
/// once means two connections that cannot see each other's open transactions.
/// Every repository goes through this class instead of calling `openDatabase`.
///
/// The class knows nothing about the tables it creates: [migrations] are
/// injected, which keeps schema ownership inside each module and lets tests
/// exercise the versioning with throwaway schemas.
class AppDatabase {
  AppDatabase({
    required List<Migration> migrations,
    DatabaseFactory? databaseFactory,
    String fileName = 'gapsi_market.db',
    String? path,
  }) : _migrations = List<Migration>.unmodifiable(migrations),
       _injectedFactory = databaseFactory,
       _fileName = fileName,
       _path = path;

  final List<Migration> _migrations;
  final DatabaseFactory? _injectedFactory;
  final String _fileName;
  final String? _path;

  Future<Database>? _opening;

  /// The version the schema is at, derived from the migrations registered.
  ///
  /// Deriving it removes the classic bug of adding a migration and forgetting
  /// to bump the constant, which silently skips the upgrade.
  int get schemaVersion => _migrations.length;

  /// The open connection, opening it on first use.
  ///
  /// Callers race at startup, so the pending [Future] is what gets cached, not
  /// the resolved [Database]: concurrent callers await the same open instead of
  /// each starting their own.
  Future<Database> get database {
    return _opening ??= _open().onError<Object>((
      Object error,
      StackTrace stackTrace,
    ) {
      // Do not cache a failed open, otherwise one transient error would keep
      // every later caller failing for the lifetime of the app.
      _opening = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  /// Closes the connection, if one was ever opened.
  Future<void> close() async {
    final Future<Database>? opening = _opening;
    if (opening == null) {
      return;
    }
    _opening = null;
    final Database db = await opening;
    await db.close();
  }

  DatabaseFactory get _factory => _injectedFactory ?? databaseFactory;

  Future<Database> _open() async {
    final String resolvedPath =
        _path ?? p.join(await _factory.getDatabasesPath(), _fileName);

    return _factory.openDatabase(
      resolvedPath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onConfigure(Database db) async {
    // SQLite ships with foreign key enforcement off. Without this, a delete
    // leaves orphan rows behind and the constraint is decorative.
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) {
    return _runMigrations(db, from: 0, to: version);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) {
    return _runMigrations(db, from: oldVersion, to: newVersion);
  }

  Future<void> _runMigrations(
    DatabaseExecutor db, {
    required int from,
    required int to,
  }) async {
    for (int version = from; version < to; version++) {
      await _migrations[version](db);
    }
  }
}
