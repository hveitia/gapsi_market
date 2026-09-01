import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rekluti_test/app.dart';
import 'package:rekluti_test/configs/router/app_router.dart';

Future<void> pumpApp(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(GapsiMarketApp(router: router));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('boots into the initial route', (WidgetTester tester) async {
    await pumpApp(tester, buildAppRouter());

    expect(find.byType(Scaffold), findsOneWidget);
  });

  // Modules contribute their own routes instead of a central file importing
  // every screen, mirroring how they contribute database migrations.
  testWidgets('serves routes contributed by a module', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      buildAppRouter(
        initialLocation: '/products',
        routes: <RouteBase>[
          GoRoute(
            path: '/products',
            builder: (BuildContext context, GoRouterState state) =>
                const Scaffold(body: Text('product list')),
          ),
        ],
      ),
    );

    expect(find.text('product list'), findsOneWidget);
  });

  // A mistyped link must not drop the user on a blank screen with no way back.
  testWidgets('names the offending location when a route is unknown', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, buildAppRouter(initialLocation: '/nope'));

    expect(find.textContaining('/nope'), findsOneWidget);
  });
}
