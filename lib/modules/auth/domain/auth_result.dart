import 'package:equatable/equatable.dart';
import 'package:rekluti_test/modules/auth/domain/user.dart';

/// Outcome of a sign up attempt.
///
/// A duplicated email is an expected answer, not an exceptional condition, so
/// it travels as a value rather than as a thrown failure. Exceptions stay
/// reserved for what genuinely went wrong, such as the database being
/// unavailable. Sealed, so handling it stays exhaustive.
sealed class SignUpResult extends Equatable {
  const SignUpResult();

  @override
  List<Object?> get props => <Object?>[];
}

final class SignUpSucceeded extends SignUpResult {
  const SignUpSucceeded(this.user);

  final User user;

  @override
  List<Object?> get props => <Object?>[user];
}

final class SignUpEmailAlreadyRegistered extends SignUpResult {
  const SignUpEmailAlreadyRegistered();
}

/// Outcome of a sign in attempt. See [SignUpResult] for the reasoning.
sealed class SignInResult extends Equatable {
  const SignInResult();

  @override
  List<Object?> get props => <Object?>[];
}

final class SignInSucceeded extends SignInResult {
  const SignInSucceeded(this.user);

  final User user;

  @override
  List<Object?> get props => <Object?>[user];
}

/// The email is unknown or the password does not match.
///
/// One case covers both on purpose: telling the two apart would let anyone
/// discover which emails have an account here.
final class SignInInvalidCredentials extends SignInResult {
  const SignInInvalidCredentials();
}
