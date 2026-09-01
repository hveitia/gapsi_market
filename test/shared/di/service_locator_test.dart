import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:rekluti_test/shared/database/app_database.dart';
import 'package:rekluti_test/shared/database/migration.dart';
import 'package:rekluti_test/shared/di/service_locator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Migration _createTable(String name) {
  return (DatabaseExecutor db) =>
      db.execute('CREATE TABLE $name (id INTEGER PRIMARY KEY)');
}

void main() {
  setUpAll(sqfliteFfiInit);

  late GetIt injector;

  setUp(() => injector = GetIt.asNewInstance());
  tearDown(() => injector.reset());

  AppDatabase testDatabase(List<Migration> migrations) {
    return AppDatabase(
      migrations: migrations,
      databaseFactory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
  }

  test('resolves Dio as a single shared instance', () async {
    await configureDependencies(getIt: injector);

    expect(identical(injector<Dio>(), injector<Dio>()), isTrue);
  });

  test('resolves AppDatabase as a single shared instance', () async {
    await configureDependencies(getIt: injector);

    expect(
      identical(injector<AppDatabase>(), injector<AppDatabase>()),
      isTrue,
    );
  });

  test('hands the registered migrations to AppDatabase', () async {
    await configureDependencies(
      getIt: injector,
      migrations: <Migration>[_createTable('a'), _createTable('b')],
    );

    expect(injector<AppDatabase>().schemaVersion, 2);
  });

  // Resetting the locator must release the connection, otherwise a reset in a
  // test suite or a logout flow would leak an open database handle.
  test('closes the database when the locator is reset', () async {
    await configureDependencies(
      getIt: injector,
      database: testDatabase(<Migration>[_createTable('users')]),
    );
    final Database db = await injector<AppDatabase>().database;
    expect(db.isOpen, isTrue);

    await injector.reset();

    expect(db.isOpen, isFalse);
  });

  test('lets tests substitute the collaborators it registers', () async {
    final Dio dio = Dio();
    final AppDatabase database = testDatabase(<Migration>[]);

    await configureDependencies(
      getIt: injector,
      dio: dio,
      database: database,
    );

    expect(identical(injector<Dio>(), dio), isTrue);
    expect(identical(injector<AppDatabase>(), database), isTrue);
  });
}
