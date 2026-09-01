import 'package:equatable/equatable.dart';

/// What the sign up form submits.
///
/// Holds the password in plain text because that is the only moment it exists
/// in that form: the service hashes it immediately and this object is dropped.
/// It is never persisted, never logged and never leaves the module.
class SignUp extends Equatable {
  const SignUp({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  List<Object?> get props => <Object?>[name, email, password];

  /// Never print credentials, not even in a debug build.
  @override
  String toString() => 'SignUp(email: $email)';
}
