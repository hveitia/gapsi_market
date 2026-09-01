import 'package:rekluti_test/modules/auth/contract/auth_contract.dart';
import 'package:rekluti_test/modules/auth/contract/password_hasher.dart';
import 'package:rekluti_test/modules/auth/datasource/local/auth_local_datasource.dart';
import 'package:rekluti_test/modules/auth/domain/auth_result.dart';
import 'package:rekluti_test/modules/auth/domain/sign_in.dart';
import 'package:rekluti_test/modules/auth/domain/sign_up.dart';
import 'package:rekluti_test/modules/auth/domain/user.dart';
import 'package:rekluti_test/shared/errors/failure.dart';

/// Authentication against the local database.
///
/// Sits between the bloc and storage: it is the only place that ever sees a
/// password in plain text and the only place that handles a stored hash.
class AuthService implements AuthContract {
  const AuthService({
    required AuthLocalDataSource dataSource,
    required PasswordHasher hasher,
  }) : _dataSource = dataSource,
       _hasher = hasher;

  final AuthLocalDataSource _dataSource;
  final PasswordHasher _hasher;

  @override
  Future<SignUpResult> signUp(SignUp form) {
    return _guard(() async {
      if (await _dataSource.findByEmail(form.email) != null) {
        return const SignUpEmailAlreadyRegistered();
      }

      final StoredUser stored = await _dataSource.insertUser(
        name: form.name,
        email: form.email,
        passwordHash: _hasher.hash(form.password),
      );

      // Registering already proved who they are; asking them to sign in again
      // right away would be ceremony.
      await _dataSource.openSession(stored.id);

      return SignUpSucceeded(_toUser(stored));
    });
  }

  @override
  Future<SignInResult> signIn(SignIn credentials) {
    return _guard(() async {
      final StoredUser? stored = await _dataSource.findByEmail(
        credentials.email,
      );

      if (stored == null) {
        _equaliseTiming(credentials.password);
        return const SignInInvalidCredentials();
      }

      final bool matches = _hasher.verify(
        password: credentials.password,
        hash: stored.passwordHash,
      );
      if (!matches) {
        return const SignInInvalidCredentials();
      }

      await _dataSource.openSession(stored.id);

      return SignInSucceeded(_toUser(stored));
    });
  }

  @override
  Future<User?> currentUser() {
    return _guard(() async {
      final StoredUser? stored = await _dataSource.sessionUser();
      return stored == null ? null : _toUser(stored);
    });
  }

  @override
  Future<void> signOut() => _guard(_dataSource.closeSession);

  /// Spends the same work a real verification would, so an unknown email does
  /// not answer faster than a known one.
  ///
  /// Refusing to say whether an address is registered is pointless if the
  /// response time says it anyway: hashing is deliberately slow, so returning
  /// early here would make the unknown case measurably quicker and turn the
  /// sign in form back into a way to enumerate accounts.
  void _equaliseTiming(String password) {
    try {
      _hasher.hash(password);
    } on ArgumentError {
      // An over long password cannot be hashed, so there is nothing to match.
    }
  }

  /// Drops the password hash on the way out of this layer.
  User _toUser(StoredUser stored) {
    return User(id: stored.id, name: stored.name, email: stored.email);
  }

  /// Turns anything storage throws into the [Failure] the contract promises.
  ///
  /// A `DatabaseException` reaching the bloc would force every caller to know
  /// which package backs persistence.
  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw StorageFailure(debugMessage: error.toString());
    }
  }
}
