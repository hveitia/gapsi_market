import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rekluti_test/app.dart';
import 'package:rekluti_test/configs/router/app_router.dart';
import 'package:rekluti_test/configs/router/app_routes.dart';
import 'package:rekluti_test/configs/router/go_router_refresh_stream.dart';
import 'package:rekluti_test/modules/auth/auth_module.dart';
import 'package:rekluti_test/modules/auth/bloc/auth_bloc.dart';
import 'package:rekluti_test/modules/auth/bloc/auth_event.dart';
import 'package:rekluti_test/modules/auth/datasource/local/auth_migrations.dart';
import 'package:rekluti_test/modules/auth/presenter/auth_routes.dart';
import 'package:rekluti_test/shared/database/app_migrations.dart';
import 'package:rekluti_test/shared/database/migration.dart';
import 'package:rekluti_test/shared/di/service_locator.dart';

/// Composition root.
///
/// The only file that knows the full list of features. Every module hands over
/// its migrations, its routes and its registrations, and they are assembled
/// here, which is what keeps `shared/` and `configs/` free of any feature.
Future<void> main() async {
  // Required before any plugin is touched: registering dependencies opens the
  // door to the SQLite platform channel.
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies(
    migrations: <Migration>[...appMigrations, ...authMigrations],
  );
  registerAuthDependencies(locator);

  final AuthBloc authBloc = locator<AuthBloc>()
    ..add(const AuthSessionRequested());

  final GoRouter router = buildAppRouter(
    initialLocation: AuthRoutePaths.splash,
    routes: <RouteBase>[...appRoutes, ...authRoutes],
    // Re-evaluates the guard whenever the session changes, so signing in moves
    // the user without any screen having to navigate.
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (BuildContext context, GoRouterState state) =>
        authRedirect(authBloc.state, state),
  );

  runApp(
    BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: GapsiMarketApp(router: router),
    ),
  );
}
