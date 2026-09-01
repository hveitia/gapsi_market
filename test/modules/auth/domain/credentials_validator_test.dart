import 'package:flutter_test/flutter_test.dart';
import 'package:rekluti_test/modules/auth/domain/credentials_validator.dart';

void main() {
  group('validateEmail', () {
    test('accepts the shapes people actually type', () {
      const List<String> valid = <String>[
        'a@b.com',
        'hector.veitia@correo.com.mx',
        'user+etiqueta@example.co',
        'nombre_apellido-1@sub.dominio.io',
      ];

      for (final String email in valid) {
        expect(
          CredentialsValidator.validateEmail(email),
          isNull,
          reason: 'expected "$email" to be valid',
        );
      }
    });

    test('trims surrounding whitespace before judging', () {
      expect(CredentialsValidator.validateEmail('  a@b.com  '), isNull);
    });

    test('reports an empty value apart from a malformed one', () {
      expect(
        CredentialsValidator.validateEmail(''),
        EmailValidationError.empty,
      );
      expect(
        CredentialsValidator.validateEmail('    '),
        EmailValidationError.empty,
      );
      expect(
        CredentialsValidator.validateEmail(null),
        EmailValidationError.empty,
      );
    });

    test('rejects addresses that cannot be delivered', () {
      const List<String> invalid = <String>[
        'sinarroba',
        'a@',
        '@b.com',
        'a@b', // no domain suffix
        'a@b..com', // empty label
        'a@-b.com', // label starts with a hyphen
        'hay espacio@b.com',
        'a@@b.com',
      ];

      for (final String email in invalid) {
        expect(
          CredentialsValidator.validateEmail(email),
          EmailValidationError.malformed,
          reason: 'expected "$email" to be rejected',
        );
      }
    });
  });

  group('validatePassword', () {
    test('accepts a password meeting every rule', () {
      expect(CredentialsValidator.validatePassword('abcdefg1'), isNull);
      expect(CredentialsValidator.validatePassword('Sup3rSecreta!'), isNull);
    });

    // A Spanish speaking user types accents and eñes; those are letters.
    test('counts non ascii letters as letters', () {
      expect(CredentialsValidator.validatePassword('contraseñ1'), isNull);
    });

    test('never trims: spaces are legitimate password characters', () {
      expect(CredentialsValidator.validatePassword('  abc1  '), isNull);
    });

    test('reports the first unmet rule', () {
      expect(
        CredentialsValidator.validatePassword(''),
        PasswordValidationError.empty,
      );
      expect(
        CredentialsValidator.validatePassword(null),
        PasswordValidationError.empty,
      );
      expect(
        CredentialsValidator.validatePassword('abc123'),
        PasswordValidationError.tooShort,
      );
      expect(
        CredentialsValidator.validatePassword('12345678'),
        PasswordValidationError.missingLetter,
      );
      expect(
        CredentialsValidator.validatePassword('abcdefgh'),
        PasswordValidationError.missingDigit,
      );
    });

    test('requires exactly the documented minimum length', () {
      expect(CredentialsValidator.minPasswordLength, 8);
      expect(
        CredentialsValidator.validatePassword('abcdef1'),
        PasswordValidationError.tooShort,
      );
      expect(CredentialsValidator.validatePassword('abcdefg1'), isNull);
    });
  });

  group('validateName', () {
    test('accepts a plausible name', () {
      expect(CredentialsValidator.validateName('Hector'), isNull);
      expect(CredentialsValidator.validateName('  Ana  '), isNull);
    });

    test('rejects an empty or single character name', () {
      expect(CredentialsValidator.validateName(''), NameValidationError.empty);
      expect(
        CredentialsValidator.validateName('   '),
        NameValidationError.empty,
      );
      expect(
        CredentialsValidator.validateName(null),
        NameValidationError.empty,
      );
      expect(
        CredentialsValidator.validateName('A'),
        NameValidationError.tooShort,
      );
    });
  });
}
