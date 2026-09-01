import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rekluti_test/modules/auth/contract/password_hasher.dart';
import 'package:rekluti_test/modules/auth/datasource/local/auth_local_datasource.dart';
import 'package:rekluti_test/modules/auth/domain/auth_result.dart';
import 'package:rekluti_test/modules/auth/domain/sign_in.dart';
import 'package:rekluti_test/modules/auth/domain/sign_up.dart';
import 'package:rekluti_test/modules/auth/domain/user.dart';
import 'package:rekluti_test/modules/auth/service/auth_service.dart';
import 'package:rekluti_test/shared/errors/failure.dart';

class _MockDataSource extends Mock implements AuthLocalDataSource {}

class _MockHasher extends Mock implements PasswordHasher {}

const StoredUser _hector = StoredUser(
  id: 7,
  name: 'Hector',
  email: 'hector@correo.com',
  passwordHash: r'$2a$10$stored',
);

const SignUp _signUpForm = SignUp(
  name: 'Hector',
  email: 'hector@correo.com',
  password: 'abcdefg1',
);

const SignIn _signInForm = SignIn(
  email: 'hector@correo.com',
  password: 'abcdefg1',
);

void main() {
  late _MockDataSource dataSource;
  late _MockHasher hasher;
  late AuthService service;

  setUp(() {
    dataSource = _MockDataSource();
    hasher = _MockHasher();
    service = AuthService(dataSource: dataSource, hasher: hasher);

    when(() => dataSource.openSession(any())).thenAnswer((_) async {});
    when(() => dataSource.closeSession()).thenAnswer((_) async {});
    when(() => hasher.hash(any())).thenReturn(r'$2a$10$stored');
  });

  group('signUp', () {
    test('refuses an email that already has an account', () async {
      when(() => dataSource.findByEmail(any()))
          .thenAnswer((_) async => _hector);

      expect(await service.signUp(_signUpForm), isA<SignUpEmailAlreadyRegistered>());
      verifyNever(() => dataSource.insertUser(
            name: any(named: 'name'),
            email: any(named: 'email'),
            passwordHash: any(named: 'passwordHash'),
          ));
    });

    test('stores the hash and never the password itself', () async {
      when(() => dataSource.findByEmail(any())).thenAnswer((_) async => null);
      when(() => dataSource.insertUser(
            name: any(named: 'name'),
            email: any(named: 'email'),
            passwordHash: any(named: 'passwordHash'),
          )).thenAnswer((_) async => _hector);

      await service.signUp(_signUpForm);

      verify(() => hasher.hash('abcdefg1')).called(1);
      verify(() => dataSource.insertUser(
            name: 'Hector',
            email: 'hector@correo.com',
            passwordHash: r'$2a$10$stored',
          )).called(1);
    });

    test('signs the new account in and returns it without its hash', () async {
      when(() => dataSource.findByEmail(any())).thenAnswer((_) async => null);
      when(() => dataSource.insertUser(
            name: any(named: 'name'),
            email: any(named: 'email'),
            passwordHash: any(named: 'passwordHash'),
          )).thenAnswer((_) async => _hector);

      final SignUpResult result = await service.signUp(_signUpForm);

      expect(
        result,
        const SignUpSucceeded(
          User(id: 7, name: 'Hector', email: 'hector@correo.com'),
        ),
      );
      verify(() => dataSource.openSession(7)).called(1);
    });
  });

  group('signIn', () {
    test('accepts the matching password and opens a session', () async {
      when(() => dataSource.findByEmail(any()))
          .thenAnswer((_) async => _hector);
      when(() => hasher.verify(
            password: any(named: 'password'),
            hash: any(named: 'hash'),
          )).thenReturn(true);

      final SignInResult result = await service.signIn(_signInForm);

      expect(
        result,
        const SignInSucceeded(
          User(id: 7, name: 'Hector', email: 'hector@correo.com'),
        ),
      );
      verify(() => dataSource.openSession(7)).called(1);
    });

    test('rejects a password that does not match', () async {
      when(() => dataSource.findByEmail(any()))
          .thenAnswer((_) async => _hector);
      when(() => hasher.verify(
            password: any(named: 'password'),
            hash: any(named: 'hash'),
          )).thenReturn(false);

      expect(await service.signIn(_signInForm), isA<SignInInvalidCredentials>());
      verifyNever(() => dataSource.openSession(any()));
    });

    test('answers the same way for an email that has no account', () async {
      when(() => dataSource.findByEmail(any())).thenAnswer((_) async => null);

      expect(await service.signIn(_signInForm), isA<SignInInvalidCredentials>());
    });

    // Hiding the difference in the message is pointless if the response time
    // gives it away: hashing is slow, so skipping it when the email is unknown
    // would make that path measurably faster.
    test('spends the same hashing work when the email is unknown', () async {
      when(() => dataSource.findByEmail(any())).thenAnswer((_) async => null);

      await service.signIn(_signInForm);

      verify(() => hasher.hash('abcdefg1')).called(1);
    });
  });

  group('session', () {
    test('reports nobody signed in when there is no session', () async {
      when(dataSource.sessionUser).thenAnswer((_) async => null);

      expect(await service.currentUser(), isNull);
    });

    test('returns the signed in account without its hash', () async {
      when(dataSource.sessionUser).thenAnswer((_) async => _hector);

      expect(
        await service.currentUser(),
        const User(id: 7, name: 'Hector', email: 'hector@correo.com'),
      );
    });

    test('signing out closes the session', () async {
      await service.signOut();

      verify(dataSource.closeSession).called(1);
    });
  });

  // The contract promises that anything genuinely broken arrives as a Failure,
  // so a raw database exception must not reach the bloc.
  test('reports a storage problem as a StorageFailure', () async {
    when(() => dataSource.findByEmail(any())).thenThrow(StateError('disk'));

    await expectLater(
      service.signIn(_signInForm),
      throwsA(isA<StorageFailure>()),
    );
  });
}
