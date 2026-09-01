import 'package:rekluti_test/modules/auth/domain/auth_result.dart';
import 'package:rekluti_test/modules/auth/domain/sign_in.dart';
import 'package:rekluti_test/modules/auth/domain/sign_up.dart';
import 'package:rekluti_test/modules/auth/domain/user.dart';

/// What the auth bloc is allowed to ask for.
///
/// The bloc depends on this abstraction, never on the SQLite implementation,
/// which is what lets it be tested against a stand in.
///
/// Expected outcomes come back as a result value; anything that genuinely went
/// wrong, such as storage being unavailable, is thrown as a `Failure`.
abstract interface class AuthContract {
  /// Registers a new account, rejecting an email that already exists.
  Future<SignUpResult> signUp(SignUp form);

  /// Verifies credentials and opens a session when they match.
  Future<SignInResult> signIn(SignIn credentials);

  /// The account of the open session, or `null` when nobody is signed in.
  ///
  /// Read on startup so a returning user is not asked to sign in again.
  Future<User?> currentUser();

  /// Closes the open session. Does nothing when there is none.
  Future<void> signOut();
}
