/// Why an email was rejected.
///
/// The validator reports a reason, not a message. Wording belongs to the
/// presentation layer, the same rule the failure model follows.
enum EmailValidationError { empty, malformed }

/// Which password rule was not met, in the order they are checked.
enum PasswordValidationError { empty, tooShort, missingLetter, missingDigit }

/// Why a name was rejected.
enum NameValidationError { empty, tooShort }

/// Validates the credentials entered on the sign in and sign up forms.
///
/// Pure functions with no dependency on Flutter, so the rules are tested
/// directly instead of through a widget.
abstract final class CredentialsValidator {
  /// Minimum accepted password length.
  static const int minPasswordLength = 8;

  /// Minimum accepted name length.
  static const int minNameLength = 2;

  /// Practical email syntax, taken from the WHATWG HTML specification for
  /// `<input type="email">`.
  ///
  /// Deliberately not RFC 5322: a fully compliant expression is unreadable and
  /// still cannot tell whether an address exists. Matching what browsers accept
  /// keeps the app consistent with what users are used to everywhere else.
  ///
  /// One departure from the specification: the domain must carry at least one
  /// dot, so `user@localhost` is rejected. This app only ever mails public
  /// addresses.
  static final RegExp _emailPattern = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+"
    r'@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
    r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
  );

  /// Any Unicode letter, so accented characters and `ñ` count.
  static final RegExp _letterPattern = RegExp(r'\p{L}', unicode: true);

  static final RegExp _digitPattern = RegExp(r'\d');

  /// Returns the reason [value] is not a usable email, or `null` if it is.
  ///
  /// Surrounding whitespace is trimmed first: it is almost always an artefact
  /// of pasting, never something the user meant to type.
  static EmailValidationError? validateEmail(String? value) {
    final String email = value?.trim() ?? '';

    if (email.isEmpty) {
      return EmailValidationError.empty;
    }
    if (!_emailPattern.hasMatch(email)) {
      return EmailValidationError.malformed;
    }
    return null;
  }

  /// Returns the first unmet password rule, or `null` if every rule passes.
  ///
  /// The value is never trimmed. A space is a legitimate password character,
  /// and silently dropping it would let a user set a password they can never
  /// type again.
  static PasswordValidationError? validatePassword(String? value) {
    final String password = value ?? '';

    if (password.isEmpty) {
      return PasswordValidationError.empty;
    }
    if (password.length < minPasswordLength) {
      return PasswordValidationError.tooShort;
    }
    if (!_letterPattern.hasMatch(password)) {
      return PasswordValidationError.missingLetter;
    }
    if (!_digitPattern.hasMatch(password)) {
      return PasswordValidationError.missingDigit;
    }
    return null;
  }

  /// Returns the reason [value] is not a usable name, or `null` if it is.
  static NameValidationError? validateName(String? value) {
    final String name = value?.trim() ?? '';

    if (name.isEmpty) {
      return NameValidationError.empty;
    }
    if (name.length < minNameLength) {
      return NameValidationError.tooShort;
    }
    return null;
  }
}
