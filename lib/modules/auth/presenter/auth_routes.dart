import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rekluti_test/configs/router/app_router.dart';
import 'package:rekluti_test/modules/auth/bloc/auth_state.dart';
import 'package:rekluti_test/modules/auth/presenter/landing_view.dart';
import 'package:rekluti_test/modules/auth/presenter/sign_in_view.dart';
import 'package:rekluti_test/modules/auth/presenter/sign_up_view.dart';
import 'package:rekluti_test/modules/auth/presenter/splash_view.dart';

/// Locations owned by the auth module.
///
/// Declared here rather than alongside the app's own paths so the router
/// configuration never has to know that accounts exist.
abstract final class AuthRoutePaths {
  static const String splash = '/splash';
  static const String landing = '/landing';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';

  /// Locations that only make sense while signed out.
  static const Set<String> signedOutOnly = <String>{landing, signIn, signUp};
}

/// The screens this module contributes to the router.
final List<RouteBase> authRoutes = <RouteBase>[
  GoRoute(
    path: AuthRoutePaths.splash,
    builder: (BuildContext context, GoRouterState state) => const SplashView(),
  ),
  GoRoute(
    path: AuthRoutePaths.landing,
    builder: (BuildContext context, GoRouterState state) => const LandingView(),
  ),
  GoRoute(
    path: AuthRoutePaths.signIn,
    builder: (BuildContext context, GoRouterState state) => const SignInView(),
  ),
  GoRoute(
    path: AuthRoutePaths.signUp,
    builder: (BuildContext context, GoRouterState state) => const SignUpView(),
  ),
];

/// Where the session state says the user belongs, or `null` to stay put.
///
/// Browsing is deliberately open: a signed out user reaching the catalogue is
/// not redirected, because the exercise's search works without an account and a
/// wall there would be friction with nothing behind it. What the guard does
/// enforce is the two ends of the session.
String? authRedirect(AuthState state, GoRouterState routerState) {
  final String location = routerState.matchedLocation;
  final bool onSplash = location == AuthRoutePaths.splash;

  return switch (state) {
    // The stored session has not been read yet. Hold everything on the splash
    // so the landing screen never flashes in front of a returning user.
    AuthUnknown() => onSplash ? null : AuthRoutePaths.splash,

    // The read finished, so nobody stays on the splash. Both outcomes need a
    // way off it: leaving one of them without a destination is exactly how a
    // returning user ends up staring at it forever.
    AuthSignedOut() when onSplash => AuthRoutePaths.landing,
    AuthSignedIn() when onSplash => AppRoutePaths.home,

    // Signed in: the auth screens have nothing left to offer, and going back
    // to them would let someone sign in twice.
    AuthSignedIn() when AuthRoutePaths.signedOutOnly.contains(location) =>
      AppRoutePaths.home,

    _ => null,
  };
}
