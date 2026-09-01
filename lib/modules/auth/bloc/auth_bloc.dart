import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rekluti_test/modules/auth/bloc/auth_event.dart';
import 'package:rekluti_test/modules/auth/bloc/auth_state.dart';
import 'package:rekluti_test/modules/auth/contract/auth_contract.dart';
import 'package:rekluti_test/modules/auth/domain/auth_result.dart';
import 'package:rekluti_test/modules/auth/domain/user.dart';
import 'package:rekluti_test/shared/errors/failure.dart';

/// Drives the session and the two authentication forms.
///
/// Depends on [AuthContract], never on the SQLite implementation, so it can be
/// tested against a stand in.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._auth) : super(const AuthUnknown()) {
    on<AuthSessionRequested>(_onSessionRequested);
    on<AuthSignInSubmitted>(_onSignInSubmitted);
    on<AuthSignUpSubmitted>(_onSignUpSubmitted);
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  final AuthContract _auth;

  Future<void> _onSessionRequested(
    AuthSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final User? user = await _auth.currentUser();
      emit(user == null ? const AuthSignedOut() : AuthSignedIn(user));
    } on Failure {
      // A session that cannot be read is not a reason to strand someone on a
      // broken startup screen. Treat it as signed out; the worst case is one
      // extra sign in.
      emit(const AuthSignedOut());
    }
  }

  Future<void> _onSignInSubmitted(
    AuthSignInSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthSignedOut(submission: FormInProgress()));

    try {
      final SignInResult result = await _auth.signIn(event.credentials);

      switch (result) {
        case SignInSucceeded(:final User user):
          emit(AuthSignedIn(user));
        case SignInInvalidCredentials():
          emit(
            const AuthSignedOut(
              submission: FormRejected(AuthFormError.invalidCredentials),
            ),
          );
      }
    } on Failure {
      emit(_storageRejection);
    }
  }

  Future<void> _onSignUpSubmitted(
    AuthSignUpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthSignedOut(submission: FormInProgress()));

    try {
      final SignUpResult result = await _auth.signUp(event.form);

      switch (result) {
        case SignUpSucceeded(:final User user):
          emit(AuthSignedIn(user));
        case SignUpEmailAlreadyRegistered():
          emit(
            const AuthSignedOut(
              submission: FormRejected(AuthFormError.emailAlreadyRegistered),
            ),
          );
      }
    } on Failure {
      emit(_storageRejection);
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _auth.signOut();
    } on Failure {
      // Whether or not the row could be deleted, this device is signed out.
    }
    emit(const AuthSignedOut());
  }

  static const AuthSignedOut _storageRejection = AuthSignedOut(
    submission: FormRejected(AuthFormError.storage),
  );
}
