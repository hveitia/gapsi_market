import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rekluti_test/configs/router/app_router.dart';
import 'package:rekluti_test/modules/auth/bloc/auth_bloc.dart';
import 'package:rekluti_test/modules/auth/bloc/auth_event.dart';
import 'package:rekluti_test/modules/auth/bloc/auth_state.dart';
import 'package:rekluti_test/modules/auth/domain/sign_in.dart';
import 'package:rekluti_test/modules/auth/domain/user.dart';
import 'package:rekluti_test/modules/auth/presenter/auth_routes.dart';
import 'package:rekluti_test/modules/auth/presenter/landing_view.dart';
import 'package:rekluti_test/modules/auth/presenter/sign_in_view.dart';
import 'package:rekluti_test/modules/auth/presenter/splash_view.dart';
import 'package:rekluti_test/modules/auth/presenter/widgets/auth_header_action.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

const User _user = User(id: 7, name: 'Hector', email: 'hector@correo.com');

void main() {
  // Never reach for a font over the network in a test: it would make the suite
  // depend on connectivity and slow every case down.
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(const AuthSessionRequested());
  });

  late _MockAuthBloc bloc;

  setUp(() => bloc = _MockAuthBloc());

  Future<void> pump(
    WidgetTester tester,
    AuthState state, {
    String at = AuthRoutePaths.splash,
    // A spinner never stops animating, so a screen showing one can only be
    // pumped a fixed number of times.
    bool settle = true,
  }) async {
    whenListen(bloc, const Stream<AuthState>.empty(), initialState: state);

    final GoRouter router = buildAppRouter(
      initialLocation: at,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutePaths.home,
          builder: (BuildContext context, GoRouterState state) =>
              const Scaffold(body: Text('catálogo')),
        ),
        ...authRoutes,
      ],
      redirect: (BuildContext context, GoRouterState routerState) =>
          authRedirect(bloc.state, routerState),
    );

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  group('the guard', () {
    testWidgets('holds on the splash while the session is unread', (
      WidgetTester tester,
    ) async {
      await pump(tester, const AuthUnknown(), at: AuthRoutePaths.landing);

      expect(find.byType(SplashView), findsOneWidget);
    });

    testWidgets('moves to the landing once the read finishes', (
      WidgetTester tester,
    ) async {
      await pump(tester, const AuthSignedOut());

      expect(find.byType(LandingView), findsOneWidget);
    });

    // Going back to a sign in form while already signed in would let someone
    // open a second session over the first.
    testWidgets('keeps a signed in user out of the auth screens', (
      WidgetTester tester,
    ) async {
      await pump(tester, const AuthSignedIn(_user), at: AuthRoutePaths.signIn);

      expect(find.byType(SignInView), findsNothing);
      expect(find.text('catálogo'), findsOneWidget);
    });

    // The catalogue works without an account, so a wall in front of it would be
    // friction with nothing behind it.
    testWidgets('lets a signed out user browse the catalogue', (
      WidgetTester tester,
    ) async {
      await pump(tester, const AuthSignedOut(), at: AppRoutePaths.home);

      expect(find.text('catálogo'), findsOneWidget);
    });
  });

  group('the sign in form', () {
    testWidgets('refuses to submit a malformed email', (
      WidgetTester tester,
    ) async {
      await pump(tester, const AuthSignedOut(), at: AuthRoutePaths.signIn);

      await tester.enterText(find.byType(TextFormField).first, 'sinarroba');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('El correo no tiene un formato válido'), findsOneWidget);
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('submits once every field passes', (WidgetTester tester) async {
      await pump(tester, const AuthSignedOut(), at: AuthRoutePaths.signIn);

      await tester.enterText(
        find.byType(TextFormField).first,
        'hector@correo.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'abcdefg1');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      verify(
        () => bloc.add(
          const AuthSignInSubmitted(
            SignIn(email: 'hector@correo.com', password: 'abcdefg1'),
          ),
        ),
      ).called(1);
    });

    // A second tap while the first request is in flight would open two
    // sessions, so the button has to be inert until it comes back.
    testWidgets('disables the button while a submission is in flight', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const AuthSignedOut(submission: FormInProgress()),
        at: AuthRoutePaths.signIn,
        settle: false,
      );

      final FilledButton button = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );

      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows what the service rejected', (WidgetTester tester) async {
      await pump(
        tester,
        const AuthSignedOut(
          submission: FormRejected(AuthFormError.invalidCredentials),
        ),
        at: AuthRoutePaths.signIn,
      );

      expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
    });
  });

  // The prompt is what gives a guest a way back, so it has to disappear the
  // moment there is a session and appear whenever there is not.
  group('the account control', () {
    Future<void> pumpPrompt(WidgetTester tester, AuthState state) async {
      whenListen(bloc, const Stream<AuthState>.empty(), initialState: state);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: bloc,
          child: MaterialApp.router(
            routerConfig: buildAppRouter(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutePaths.home,
                  builder: (BuildContext context, GoRouterState state) =>
                      const Scaffold(body: AuthHeaderAction()),
                ),
                ...authRoutes,
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('offers a way in while browsing as a guest', (
      WidgetTester tester,
    ) async {
      await pumpPrompt(tester, const AuthSignedOut());

      expect(find.text('Iniciar sesión'), findsOneWidget);
    });

    testWidgets('turns into the account once there is a session', (
      WidgetTester tester,
    ) async {
      await pumpPrompt(tester, const AuthSignedIn(_user));

      expect(find.text('Iniciar sesión'), findsNothing);
      expect(find.text('Hector'), findsOneWidget);
    });

    // Nothing should be offered until the stored session has been read, or the
    // invitation to sign in would flicker away in front of a returning user.
    testWidgets('offers nothing while the session is still unread', (
      WidgetTester tester,
    ) async {
      await pumpPrompt(tester, const AuthUnknown());

      expect(find.text('Iniciar sesión'), findsNothing);
      expect(find.text('Hector'), findsNothing);
    });

    // Signing out on the spot next to the greeting would end a session by
    // accident, so it lives behind a menu.
    testWidgets('signs out from the account menu', (
      WidgetTester tester,
    ) async {
      await pumpPrompt(tester, const AuthSignedIn(_user));

      await tester.tap(find.text('Hector'));
      await tester.pumpAndSettle();
      expect(find.text('Cerrar sesión'), findsOneWidget);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      verify(() => bloc.add(const AuthSignOutRequested())).called(1);
    });

    testWidgets('takes the guest back to the landing screen', (
      WidgetTester tester,
    ) async {
      await pumpPrompt(tester, const AuthSignedOut());

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(LandingView), findsOneWidget);
    });
  });
}
