import 'package:rekluti_test/shared/database/migration.dart';

/// Schema owned by the catalog module.
final List<Migration> catalogMigrations = <Migration>[
  (DatabaseExecutor db) async {
    // Two rules live in this table.
    //
    // The term is UNIQUE, so a repeated search replaces its row instead of
    // adding a second one: deduplication is a property of the schema rather
    // than a check the writing code could forget.
    //
    // Recency is the AUTOINCREMENT id, not `searched_at`. Ordering by a wall
    // clock is fragile: two searches a few milliseconds apart tie, and the
    // clock can move backwards when the device corrects its time or changes
    // zone. AUTOINCREMENT only ever grows and never reuses a value, so the
    // order the user actually searched in is preserved. The timestamp stays
    // for display.
    await db.execute('''
      CREATE TABLE search_history (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        term         TEXT    NOT NULL UNIQUE,
        searched_at  INTEGER NOT NULL,
        result_count INTEGER
      )
    ''');
  },
];
