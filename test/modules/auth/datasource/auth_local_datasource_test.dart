import 'package:flutter_test/flutter_test.dart';
import 'package:rekluti_test/modules/auth/datasource/local/auth_local_datasource.dart';
import 'package:rekluti_test/modules/auth/datasource/local/auth_migrations.dart';
import 'package:rekluti_test/shared/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase database;
  late AuthLocalDataSource dataSource;

  setUp(() {
    database = AppDatabase(
      migrations: authMigrations,
      databaseFactory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    dataSource = SqliteAuthLocalDataSource(database);
  });

  tearDown(() => database.close());

  Future<StoredUser> insertHector() {
    return dataSource.insertUser(
      name: 'Hector',
      email: 'hector@correo.com',
      passwordHash: r'$2a$04$hash',
    );
  }

  group('users', () {
    test('stores a user and reads it back', () async {
      final StoredUser inserted = await insertHector();

      expect(inserted.id, greaterThan(0));
      expect(inserted.name, 'Hector');
      expect(inserted.passwordHash, r'$2a$04$hash');

      expect(await dataSource.findByEmail('hector@correo.com'), inserted);
    });

    // Someone who registers as Hector@Correo.com must not end up with a second
    // account when they later sign in as hector@correo.com.
    test('normalises the email so lookups ignore case and padding', () async {
      final StoredUser inserted = await insertHector();

      expect(inserted.email, 'hector@correo.com');
      expect(await dataSource.findByEmail('  HECTOR@Correo.COM '), inserted);
    });

    test('normalises on the way in as well', () async {
      final StoredUser inserted = await dataSource.insertUser(
        name: 'Ana',
        email: '  ANA@Correo.com  ',
        passwordHash: 'x',
      );

      expect(inserted.email, 'ana@correo.com');
    });

    test('returns null for an unknown email', () async {
      expect(await dataSource.findByEmail('nadie@correo.com'), isNull);
    });

    // The uniqueness rule belongs to the database, not to a check in Dart that
    // a future code path could forget to run.
    test('refuses a duplicated email at the schema level', () async {
      await insertHector();

      expect(insertHector, throwsA(isA<Object>()));
    });
  });

  group('session', () {
    test('has nobody signed in on a fresh database', () async {
      expect(await dataSource.sessionUser(), isNull);
    });

    test('opens a session and reads the signed in user back', () async {
      final StoredUser user = await insertHector();

      await dataSource.openSession(user.id);

      expect(await dataSource.sessionUser(), user);
    });

    // The schema allows a single session row, so signing in as someone else
    // replaces the session rather than leaving two of them behind.
    test('replaces the session instead of stacking a second one', () async {
      final StoredUser hector = await insertHector();
      final StoredUser ana = await dataSource.insertUser(
        name: 'Ana',
        email: 'ana@correo.com',
        passwordHash: 'x',
      );

      await dataSource.openSession(hector.id);
      await dataSource.openSession(ana.id);

      expect(await dataSource.sessionUser(), ana);
    });

    test('closes the session', () async {
      final StoredUser user = await insertHector();
      await dataSource.openSession(user.id);

      await dataSource.closeSession();

      expect(await dataSource.sessionUser(), isNull);
    });

    test('closing a session that was never open is harmless', () async {
      await expectLater(dataSource.closeSession(), completes);
    });
  });
}
