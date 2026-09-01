import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Every location the app can navigate to.
///
/// Paths live as constants so navigation never depends on a string literal
/// typed twice.
abstract final class AppRoutePaths {
  static const String home = '/';
}

/// Builds the app's router.
///
/// [routes], [redirect] and [refreshListenable] are all parameters, so this
/// file never imports a feature: each module contributes its own screens and
/// its own rules, the same way it contributes its database migrations.
GoRouter buildAppRouter({
  required List<RouteBase> routes,
  String initialLocation = AppRoutePaths.home,
  Listenable? refreshListenable,
  GoRouterRedirect? redirect,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: routes,
    // Both are parameters so this file never imports a feature: the module that
    // owns the rule supplies it, and the composition root wires the two.
    refreshListenable: refreshListenable,
    redirect: redirect,
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
