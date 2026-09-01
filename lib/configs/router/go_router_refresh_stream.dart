import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapts a stream into the [Listenable] go_router wants for `refreshListenable`.
///
/// Without it the guard would only run on navigation, so signing in would leave
/// the user sitting on the form until they touched something.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<Object?> stream) {
    // Notify once up front so the router evaluates the guard against the
    // current value, not only against later changes.
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (Object? _) => notifyListeners(),
    );
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
