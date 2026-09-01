import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rekluti_test/configs/router/app_routes.dart';

/// Every location the app can navigate to.
///
/// Paths live as constants so navigation never depends on a string literal
/// typed twice.
abstract final class AppRoutePaths {
  static const String home = '/';
}

/// Builds the app's router.
///
/// [routes] defaults to [appRoutes] and is a parameter rather than a hard coded
/// list so each module can
/// contribute its own screens, the same way modules contribute their database
/// migrations. Nothing here has to import every feature.
GoRouter buildAppRouter({
  List<RouteBase>? routes,
  String initialLocation = AppRoutePaths.home,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: routes ?? appRoutes,
    errorBuilder: (BuildContext context, GoRouterState state) =>
        _RouteNotFoundScreen(location: state.uri.toString()),
  );
}

/// Shown when navigation lands on a location no route matches.
///
/// Without it go_router renders a bare error page, which in release leaves the
/// user stranded with no way back.
class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('No route found for $location'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(AppRoutePaths.home),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
