import 'package:rekluti_test/shared/database/migration.dart';

/// Every migration the app ships, in the exact order they must run.
///
/// This list is the single ordering authority; the DDL itself lives in the
/// module that owns the table, so adding a feature means appending its
/// migration here rather than editing a central schema file.
///
/// Append only. A released migration has already run on real devices, so
/// correcting one means adding a new step after it, never rewriting it.
const List<Migration> appMigrations = <Migration>[];
