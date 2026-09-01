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

  // Appended, never merged into the migration above: that one has already run
  // on databases in existence, so correcting or extending it means adding a
  // step after it. The schema version is the length of this list, so it moves
  // on its own.
  (DatabaseExecutor db) async {
    // The whole product is stored, not just its id. The service offers no way
    // to fetch one product, so a favourite that kept only a reference could
    // never be rendered again. Keeping the fields means favourites also work
    // with no network at all.
    await db.execute('''
      CREATE TABLE favorites (
        id            TEXT    PRIMARY KEY,
        title         TEXT    NOT NULL,
        price         REAL,
        currency      TEXT    NOT NULL,
        image_url     TEXT,
        thumbnail_url TEXT,
        description   TEXT,
        rating        REAL,
        review_count  INTEGER,
        product_url   TEXT,
        saved_at      INTEGER NOT NULL
      )
    ''');
  },
];
