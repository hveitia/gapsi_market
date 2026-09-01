import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rekluti_test/shared/database/app_database.dart';
import 'package:rekluti_test/shared/database/migration.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Migration _createTable(String name, {List<String>? applied}) {
  return (DatabaseExecutor db) async {
    applied?.add(name);
    await db.execute('CREATE TABLE $name (id INTEGER PRIMARY KEY)');
  };
}

Future<bool> _tableExists(Database db, String name) async {
  final List<Map<String, Object?>> rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
    <Object?>[name],
  );
  return rows.isNotEmpty;
}

void main() {
  setUpAll(sqfliteFfiInit);

  AppDatabase buildDatabase(List<Migration> migrations, {String? path}) {
    return AppDatabase(
      migrations: migrations,
      databaseFactory: databaseFactoryFfi,
      path: path ?? inMemoryDatabasePath,
    );
  }

  test('derives the schema version from the number of migrations', () {
    expect(buildDatabase(<Migration>[]).schemaVersion, 0);
    expect(
      buildDatabase(<Migration>[_createTable('a'), _createTable('b')])
          .schemaVersion,
      2,
    );
  });

  test('runs every migration when creating a fresh database', () async {
    final List<String> applied = <String>[];
    final AppDatabase appDatabase = buildDatabase(<Migration>[
      _createTable('users', applied: applied),
      _createTable('search_history', applied: applied),
    ]);

    final Database db = await appDatabase.database;

    expect(applied, <String>['users', 'search_history']);
    expect(await _tableExists(db, 'users'), isTrue);
    expect(await _tableExists(db, 'search_history'), isTrue);

    await appDatabase.close();
  });

  // Every repository asks for the database independently, and several of them
  // do it at startup. A second connection would see its own transactions.
  test('opens a single connection for concurrent callers', () async {
    final AppDatabase appDatabase = buildDatabase(<Migration>[
      _createTable('users'),
    ]);

    final List<Database> results = await Future.wait<Database>(<Future<Database>>[
      appDatabase.database,
      appDatabase.database,
      appDatabase.database,
    ]);

    expect(identical(results[0], results[1]), isTrue);
    expect(identical(results[1], results[2]), isTrue);

    await appDatabase.close();
  });

  test('enables foreign key enforcement', () async {
    final AppDatabase appDatabase = buildDatabase(<Migration>[
      _createTable('users'),
    ]);

    final Database db = await appDatabase.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'PRAGMA foreign_keys',
    );

    expect(rows.first.values.first, 1);

    await appDatabase.close();
  });

  // Proves the mechanism a future module will rely on: shipping a new table
  // must not re-run the migrations that already went out.
  test('runs only the pending migrations when upgrading', () async {
    final Directory tempDir = await Directory.systemTemp.createTemp('gapsi_db');
    final String path = '${tempDir.path}/app.db';
    final List<String> applied = <String>[];

    final AppDatabase v1 = buildDatabase(<Migration>[
      _createTable('users', applied: applied),
    ], path: path);
    await v1.database;
    await v1.close();

    applied.clear();

    final AppDatabase v2 = buildDatabase(<Migration>[
      _createTable('users', applied: applied),
      _createTable('search_history', applied: applied),
    ], path: path);
    final Database db = await v2.database;

    expect(applied, <String>['search_history']);
    expect(await _tableExists(db, 'users'), isTrue);
    expect(await _tableExists(db, 'search_history'), isTrue);

    await v2.close();
    await tempDir.delete(recursive: true);
  });

  // A transient failure must not leave the instance permanently broken.
  test('allows retrying after a failed open', () async {
    bool shouldFail = true;
    final AppDatabase appDatabase = buildDatabase(<Migration>[
      (DatabaseExecutor db) async {
        if (shouldFail) {
          throw StateError('migration exploded');
        }
        await db.execute('CREATE TABLE users (id INTEGER PRIMARY KEY)');
      },
    ]);

    await expectLater(appDatabase.database, throwsA(isA<Object>()));

    shouldFail = false;
    final Database db = await appDatabase.database;

    expect(await _tableExists(db, 'users'), isTrue);

    await appDatabase.close();
  });
}
