import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rekluti_test/modules/catalog/contract/search_history_datasource.dart';
import 'package:rekluti_test/modules/catalog/datasource/local/catalog_migrations.dart';
import 'package:rekluti_test/modules/catalog/datasource/local/search_history_local_datasource.dart';
import 'package:rekluti_test/modules/catalog/domain/search_term.dart';
import 'package:rekluti_test/shared/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase database;
  late SearchHistoryDataSource history;

  AppDatabase open([String? path]) => AppDatabase(
    migrations: catalogMigrations,
    databaseFactory: databaseFactoryFfi,
    path: path ?? inMemoryDatabasePath,
  );

  setUp(() {
    database = open();
    history = SqliteSearchHistoryDataSource(database);
  });

  tearDown(() => database.close());

  List<String> termsOf(List<SearchTerm> entries) =>
      entries.map((SearchTerm e) => e.term).toList();

  test('returns the most recently searched term first', () async {
    await history.remember('sony');
    await history.remember('nintendo');
    await history.remember('computer');

    expect(termsOf(await history.recent()), <String>[
      'computer',
      'nintendo',
      'sony',
    ]);
  });

  // Searching the same word twice must move it to the top, not add a second
  // row. The design shows a list of chips; a repeated term would show twice.
  test('repeating a term moves it up instead of duplicating it', () async {
    await history.remember('sony');
    await history.remember('nintendo');
    await history.remember('sony');

    expect(termsOf(await history.recent()), <String>['sony', 'nintendo']);
  });

  test('treats the same word in another casing as the same term', () async {
    await history.remember('Sony');
    await history.remember('  SONY ');

    expect(termsOf(await history.recent()), <String>['sony']);
  });

  test('keeps the number of results reported for the term', () async {
    await history.remember('sony', resultCount: 860);

    expect((await history.recent()).single.resultCount, 860);
  });

  test('a later search updates the count of an existing term', () async {
    await history.remember('sony', resultCount: 860);
    await history.remember('sony', resultCount: 912);

    expect((await history.recent()).single.resultCount, 912);
  });

  test('never stores a blank term', () async {
    await history.remember('');
    await history.remember('   ');

    expect(await history.recent(), isEmpty);
  });

  test('honours the requested limit', () async {
    for (final String term in <String>['a', 'b', 'c', 'd']) {
      await history.remember(term);
    }

    expect(await history.recent(limit: 2), hasLength(2));
  });

  test('forgets a single term', () async {
    await history.remember('sony');
    await history.remember('nintendo');

    await history.forget('SONY');

    expect(termsOf(await history.recent()), <String>['nintendo']);
  });

  test('clears the whole history', () async {
    await history.remember('sony');
    await history.remember('nintendo');

    await history.clear();

    expect(await history.recent(), isEmpty);
  });

  // The exercise requires the history to outlive the app, so this is checked
  // against a real file rather than an in memory database.
  test('survives closing and reopening the database', () async {
    final Directory dir = await Directory.systemTemp.createTemp('gapsi_hist');
    final String path = '${dir.path}/app.db';

    final AppDatabase first = open(path);
    await SqliteSearchHistoryDataSource(first).remember('sony', resultCount: 7);
    await first.close();

    final AppDatabase second = open(path);
    final List<SearchTerm> entries = await SqliteSearchHistoryDataSource(
      second,
    ).recent();

    expect(termsOf(entries), <String>['sony']);
    expect(entries.single.resultCount, 7);

    await second.close();
    await dir.delete(recursive: true);
  });
}
