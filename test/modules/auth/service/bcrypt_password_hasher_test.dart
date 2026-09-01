import 'package:flutter_test/flutter_test.dart';
import 'package:rekluti_test/modules/auth/contract/password_hasher.dart';
import 'package:rekluti_test/modules/auth/service/bcrypt_password_hasher.dart';

void main() {
  // Cost 4 is bcrypt's minimum. Production uses the default; the tests only
  // need the algorithm to behave, not to be slow.
  const PasswordHasher hasher = BcryptPasswordHasher(cost: 4);

  test('never stores the password itself', () {
    const String password = 'abcdefg1';

    expect(hasher.hash(password), isNot(contains(password)));
  });

  // The salt is what stops two people who picked the same password from
  // sharing a hash, and what makes a precomputed table useless.
  test('produces a different hash every time it is called', () {
    const String password = 'abcdefg1';

    expect(hasher.hash(password), isNot(hasher.hash(password)));
  });

  test('accepts the password it hashed', () {
    const String password = 'Sup3rSecreta!';

    expect(
      hasher.verify(password: password, hash: hasher.hash(password)),
      isTrue,
    );
  });

  test('rejects any other password', () {
    final String hash = hasher.hash('abcdefg1');

    expect(hasher.verify(password: 'abcdefg2', hash: hash), isFalse);
    expect(hasher.verify(password: 'ABCDEFG1', hash: hash), isFalse);
    expect(hasher.verify(password: '', hash: hash), isFalse);
  });

  test('round trips passwords with accents and enye', () {
    const String password = 'contraseñ1';

    expect(
      hasher.verify(password: password, hash: hasher.hash(password)),
      isTrue,
    );
  });

  test('rejects a stored value that is not a bcrypt hash', () {
    expect(hasher.verify(password: 'abcdefg1', hash: 'not-a-hash'), isFalse);
    expect(hasher.verify(password: 'abcdefg1', hash: ''), isFalse);
  });

  // bcrypt only reads the first 72 bytes. Two long passwords sharing a prefix
  // would otherwise validate against each other without anyone noticing.
  test('refuses a password longer than bcrypt can actually read', () {
    final String tooLong = 'a1${'x' * 71}';

    expect(tooLong.length, greaterThan(BcryptPasswordHasher.maxPasswordBytes));
    expect(() => hasher.hash(tooLong), throwsArgumentError);
  });
}
