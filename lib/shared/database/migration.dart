import 'package:sqflite/sqflite.dart';

// Re-exported so a module writing a migration imports this contract alone,
// rather than needing to know which package the executor type comes from.
export 'package:sqflite/sqflite.dart' show DatabaseExecutor;

/// A single, forward-only step that moves the schema up one version.
///
/// Each module contributes its own migrations instead of a central file
/// declaring every table, so the module that owns a table also owns its DDL.
/// Registration happens once, where dependencies are wired.
///
/// Migrations are append-only: an already released step must never be edited,
/// because databases in the field have run it. Correcting a mistake means
/// adding a new migration after it.
typedef Migration = Future<void> Function(DatabaseExecutor db);
