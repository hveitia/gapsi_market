import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:rekluti_test/shared/database/app_database.dart';
import 'package:rekluti_test/shared/database/app_migrations.dart';
import 'package:rekluti_test/shared/database/migration.dart';
import 'package:rekluti_test/shared/network/dio_client.dart';

/// The app wide service locator.
///
/// Blocs resolve their collaborators from here instead of constructing them,
/// which is what lets a test hand a bloc a fake without touching production
/// wiring.
final GetIt locator = GetIt.instance;

/// Registers everything the app needs to run.
///
/// Called once from `main`. Every override exists so tests can build an
/// isolated graph: pass a private [GetIt] and substitute whichever
/// collaborator the case under test cares about.
Future<void> configureDependencies({
  GetIt? getIt,
  List<Migration> migrations = appMigrations,
  AppDatabase? database,
  Dio? dio,
}) async {
  final GetIt injector = getIt ?? locator;

  // Lazy singletons: nothing is constructed until something asks for it, so
  // startup does not pay for a database connection the first screen may not
  // need.
  injector.registerLazySingleton<Dio>(() => dio ?? buildDioClient());

  injector.registerLazySingleton<AppDatabase>(
    () => database ?? AppDatabase(migrations: migrations),
    // Tied to the locator's lifetime so a reset releases the connection
    // instead of leaking an open handle.
    dispose: (AppDatabase instance) => instance.close(),
  );
}
