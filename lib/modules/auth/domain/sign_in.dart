import 'package:equatable/equatable.dart';

/// What the sign in form submits.
///
/// The password is plain text only for the instant it takes to verify it
/// against the stored hash. See [SignUp] for the same reasoning.
class SignIn extends Equatable {
  const SignIn({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => <Object?>[email, password];

  /// Never print credentials, not even in a debug build.
  @override
  String toString() => 'SignIn(email: $email)';
}
