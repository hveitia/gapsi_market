import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rekluti_test/modules/auth/bloc/auth_bloc.dart';
import 'package:rekluti_test/modules/auth/bloc/auth_event.dart';
import 'package:rekluti_test/modules/auth/bloc/auth_state.dart';
import 'package:rekluti_test/modules/auth/contract/auth_contract.dart';
import 'package:rekluti_test/modules/auth/domain/auth_result.dart';
import 'package:rekluti_test/modules/auth/domain/sign_in.dart';
import 'package:rekluti_test/modules/auth/domain/sign_up.dart';
import 'package:rekluti_test/modules/auth/domain/user.dart';
import 'package:rekluti_test/shared/errors/failure.dart';

class _MockAuth extends Mock implements AuthContract {}

const User _user = User(id: 7, name: 'Hector', email: 'hector@correo.com');

const SignIn _credentials = SignIn(
  email: 'hector@correo.com',
  password: 'abcdefg1',
);

const SignUp _form = SignUp(
  name: 'Hector',
  email: 'hector@correo.com',
  password: 'abcdefg1',
);

void main() {
  late _MockAuth auth;

  setUpAll(() {
    registerFallbackValue(_credentials);
    registerFallbackValue(_form);
  });

  setUp(() => auth = _MockAuth());

  AuthBloc build() => AuthBloc(auth);

  group('AuthSessionRequested', () {
    blocTest<AuthBloc, AuthState>(
      'signs a returning user straight back in',
      setUp: () => when(auth.currentUser).thenAnswer((_) async => _user),
      build: build,
      act: (AuthBloc bloc) => bloc.add(const AuthSessionRequested()),
      expect: () => <AuthState>[const AuthSignedIn(_user)],
    );

    blocTest<AuthBloc, AuthState>(
      'lands on signed out when there is no stored session',
      setUp: () => when(auth.currentUser).thenAnswer((_) async => null),
      build: build,
      act: (AuthBloc bloc) => bloc.add(const AuthSessionRequested()),
      expect: () => <AuthState>[const AuthSignedOut()],
    );

    // Losing the session is not a reason to strand someone on a broken startup
    // screen. The worst case is one extra sign in.
    blocTest<AuthBloc, AuthState>(
      'falls back to signed out when the session cannot be read',
      setUp: () => when(auth.currentUser).thenThrow(const StorageFailure()),
      build: build,
      act: (AuthBloc bloc) => bloc.add(const AuthSessionRequested()),
      expect: () => <AuthState>[const AuthSignedOut()],
    );
  });

  group('AuthSignInSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'shows progress and then signs the user in',
      setUp: () => when(() => auth.signIn(any()))
          .thenAnswer((_) async => const SignInSucceeded(_user)),
      build: build,
      act: (AuthBloc bloc) => bloc.add(const AuthSignInSubmitted(_credentials)),
      expect: () => <AuthState>[
        const AuthSignedOut(submission: FormInProgress()),
        const AuthSignedIn(_user),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'reports invalid credentials without leaving the signed out state',
      setUp: () => when(() => auth.signIn(any()))
          .thenAnswer((_) async => const SignInInvalidCredentials()),
      build: build,
      act: (AuthBloc bloc) => bloc.add(const AuthSignInSubmitted(_credentials)),
      expect: () => <AuthState>[
        const AuthSignedOut(submission: FormInProgress()),
        const AuthSignedOut(
          submission: FormRejected(AuthFormError.invalidCredentials),
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'turns a storage failure into a rejected submission',
      setUp: () =>
          when(() => auth.signIn(any())).thenThrow(const StorageFailure()),
      build: build,
      act: (AuthBloc bloc) => bloc.add(const AuthSignInSubmitted(_credentials)),
      expect: () => <AuthState>[
        const AuthSignedOut(submission: FormInProgress()),
        const AuthSignedOut(submission: FormRejected(AuthFormError.storage)),
      ],
    );
  });

  group('AuthSignUpSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'signs the new account in',
      setUp: () => when(() => auth.signUp(any()))
          .thenAnswer((_) async => const SignUpSucceeded(_user)),
      build: build,
      act: (AuthBloc bloc) => bloc.add(const AuthSignUpSubmitted(_form)),
      expect: () => <AuthState>[
        const AuthSignedOut(submission: FormInProgress()),
        const AuthSignedIn(_user),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'reports an email that is already registered',
      setUp: () => when(() => auth.signUp(any()))
          .thenAnswer((_) async => const SignUpEmailAlreadyRegistered()),
      build: build,
      act: (AuthBloc bloc) => bloc.add(const AuthSignUpSubmitted(_form)),
      expect: () => <AuthState>[
        const AuthSignedOut(submission: FormInProgress()),
        const AuthSignedOut(
          submission: FormRejected(AuthFormError.emailAlreadyRegistered),
        ),
      ],
    );
  });

  group('AuthSignOutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'closes the session',
      setUp: () => when(auth.signOut).thenAnswer((_) async {}),
      build: build,
      seed: () => const AuthSignedIn(_user),
      act: (AuthBloc bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => <AuthState>[const AuthSignedOut()],
    );

    // The row may refuse to go, but this device is signed out either way.
    blocTest<AuthBloc, AuthState>(
      'signs out even when storage fails',
      setUp: () => when(auth.signOut).thenThrow(const StorageFailure()),
      build: build,
      seed: () => const AuthSignedIn(_user),
      act: (AuthBloc bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => <AuthState>[const AuthSignedOut()],
    );
  });
}
