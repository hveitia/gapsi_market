import 'package:rekluti_test/modules/auth/bloc/auth_state.dart';
import 'package:rekluti_test/modules/auth/domain/credentials_validator.dart';

/// Turns validation and submission outcomes into the words the user reads.
///
/// The wording lives here rather than in the domain, so the rules stay free of
/// any language and a future translation touches one file.
abstract final class AuthMessages {
  static String? email(EmailValidationError? error) {
    return switch (error) {
      null => null,
      EmailValidationError.empty => 'El correo es obligatorio',
      EmailValidationError.malformed => 'El correo no tiene un formato válido',
    };
  }

  static String? password(PasswordValidationError? error) {
    return switch (error) {
      null => null,
      PasswordValidationError.empty => 'La contraseña es obligatoria',
      PasswordValidationError.tooShort =>
        'Debe tener al menos ${CredentialsValidator.minPasswordLength} caracteres',
      PasswordValidationError.missingLetter => 'Debe incluir al menos una letra',
      PasswordValidationError.missingDigit => 'Debe incluir al menos un número',
    };
  }

  static String? name(NameValidationError? error) {
    return switch (error) {
      null => null,
      NameValidationError.empty => 'El nombre es obligatorio',
      NameValidationError.tooShort =>
        'Debe tener al menos ${CredentialsValidator.minNameLength} caracteres',
    };
  }

  static String submission(AuthFormError error) {
    return switch (error) {
      AuthFormError.invalidCredentials => 'Correo o contraseña incorrectos',
      AuthFormError.emailAlreadyRegistered => 'Ese correo ya tiene una cuenta',
      AuthFormError.storage =>
        'No se pudo completar la operación. Vuelve a intentarlo.',
    };
  }
}
