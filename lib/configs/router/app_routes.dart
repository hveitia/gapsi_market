import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rekluti_test/configs/environment.dart';
import 'package:rekluti_test/configs/router/app_router.dart';

/// Every route the app exposes, in one list.
///
/// Modules append their own as they land, keeping each screen next to the
/// feature that owns it.
final List<RouteBase> appRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutePaths.home,
    builder: (BuildContext context, GoRouterState state) =>
        const _BootstrapScreen(),
  ),
];

/// Temporary landing screen, replaced by the auth module's landing view.
///
/// It reports whether the build received a RapidAPI key, which turns the most
/// likely setup mistake into something visible on first run instead of an
/// unauthorised response later on.
class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    final bool hasKey = EnvironmentConstants.hasRapidApiKey;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            hasKey
                ? 'Ready. RapidAPI key detected.'
                : 'Missing RapidAPI key. Run with '
                      '--dart-define=RAPIDAPI_KEY=<key>.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
