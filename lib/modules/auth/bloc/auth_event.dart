import 'package:equatable/equatable.dart';
import 'package:rekluti_test/modules/auth/domain/sign_in.dart';
import 'package:rekluti_test/modules/auth/domain/sign_up.dart';

/// Everything that can happen to the authentication state.
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Restores the stored session, if any.
///
/// Dispatched once on startup so a returning user is not asked to sign in
/// again.
final class AuthSessionRequested extends AuthEvent {
  const AuthSessionRequested();
}

/// The sign in form was submitted.
final class AuthSignInSubmitted extends AuthEvent {
  const AuthSignInSubmitted(this.credentials);

  final SignIn credentials;

  @override
  List<Object?> get props => <Object?>[credentials];
}

/// The sign up form was submitted.
final class AuthSignUpSubmitted extends AuthEvent {
  const AuthSignUpSubmitted(this.form);

  final SignUp form;

  @override
  List<Object?> get props => <Object?>[form];
}

/// The user asked to close the session.
final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
