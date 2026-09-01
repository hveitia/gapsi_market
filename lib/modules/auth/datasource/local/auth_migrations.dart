import 'package:rekluti_test/shared/database/migration.dart';

/// Schema owned by the auth module.
///
/// Registered with the app's migration list so this module brings its own
/// tables instead of a central schema file having to know about accounts.
final List<Migration> authMigrations = <Migration>[
  (DatabaseExecutor db) async {
    // The email is UNIQUE at the schema level rather than only checked in Dart:
    // the database is the one authority that no future code path can bypass.
    // Values are stored normalised, so uniqueness is case insensitive too.
    await db.execute('''
      CREATE TABLE users (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT    NOT NULL,
        email         TEXT    NOT NULL UNIQUE,
        password_hash TEXT    NOT NULL,
        created_at    INTEGER NOT NULL
      )
    ''');

    // At most one session can exist: the CHECK pins the table to a single row,
    // so an open session cannot silently become two. Deleting the account
    // takes its session with it.
    await db.execute('''
      CREATE TABLE session (
        id      INTEGER PRIMARY KEY CHECK (id = 1),
        user_id INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  },
];
