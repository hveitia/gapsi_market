import 'package:equatable/equatable.dart';
import 'package:rekluti_test/modules/auth/domain/user.dart';

/// Why the backend rejected a submitted form.
///
/// Only outcomes the service can report. Field level problems, such as a
/// malformed email, never reach the bloc: the form validates those before
/// submitting.
enum AuthFormError { invalidCredentials, emailAlreadyRegistered, storage }

/// Where a form submission currently stands.
sealed class FormSubmission extends Equatable {
  const FormSubmission();

  @override
  List<Object?> get props => <Object?>[];
}

/// Nothing has been submitted.
final class FormIdle extends FormSubmission {
  const FormIdle();
}

/// A submission is in flight. The screen disables its button while this holds.
final class FormInProgress extends FormSubmission {
  const FormInProgress();
}

/// The submission came back rejected.
final class FormRejected extends FormSubmission {
  const FormRejected(this.reason);

  final AuthFormError reason;

  @override
  List<Object?> get props => <Object?>[reason];
}

/// Whether somebody is signed in.
///
/// Sealed, so the router's guard cannot forget a case. The form submission
/// lives inside the signed out state because that is the only state in which a
/// form can be on screen.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => <Object?>[];
}

/// The stored session has not been read yet.
///
/// The router holds navigation here so a returning user never sees the landing
/// screen flash before being let straight in.
final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

/// Nobody is signed in.
final class AuthSignedOut extends AuthState {
  const AuthSignedOut({this.submission = const FormIdle()});

  final FormSubmission submission;

  @override
  List<Object?> get props => <Object?>[submission];
}

/// [user] is signed in.
final class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.user);

  final User user;

  @override
  List<Object?> get props => <Object?>[user];
}
