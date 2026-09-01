import 'package:get_it/get_it.dart';
import 'package:rekluti_test/modules/auth/bloc/auth_bloc.dart';
import 'package:rekluti_test/modules/auth/contract/auth_contract.dart';
import 'package:rekluti_test/modules/auth/contract/password_hasher.dart';
import 'package:rekluti_test/modules/auth/datasource/local/auth_local_datasource.dart';
import 'package:rekluti_test/modules/auth/service/auth_service.dart';
import 'package:rekluti_test/modules/auth/service/bcrypt_password_hasher.dart';
import 'package:rekluti_test/shared/database/app_database.dart';

/// Everything the auth module needs registered, in one call.
///
/// The module declares its own wiring so the service locator never grows a
/// list of features; the composition root simply invokes this.
void registerAuthDependencies(GetIt injector) {
  injector.registerLazySingleton<PasswordHasher>(BcryptPasswordHasher.new);

  injector.registerLazySingleton<AuthLocalDataSource>(
    () => SqliteAuthLocalDataSource(injector<AppDatabase>()),
  );

  // Registered against the contract, not the implementation, so anything that
  // resolves it is free of SQLite.
  injector.registerLazySingleton<AuthContract>(
    () => AuthService(
      dataSource: injector<AuthLocalDataSource>(),
      hasher: injector<PasswordHasher>(),
    ),
  );

  injector.registerLazySingleton<AuthBloc>(
    () => AuthBloc(injector<AuthContract>()),
    dispose: (AuthBloc bloc) => bloc.close(),
  );
}
