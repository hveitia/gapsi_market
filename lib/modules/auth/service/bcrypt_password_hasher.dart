import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:rekluti_test/modules/auth/contract/password_hasher.dart';

/// [PasswordHasher] backed by bcrypt.
///
/// bcrypt is chosen over a general purpose digest such as SHA-256 precisely
/// because it is slow. A fast hash is a liability for passwords: commodity
/// hardware tries billions of SHA-256 candidates per second, while bcrypt's
/// cost factor keeps a single attempt in the tens of milliseconds and can be
/// raised as hardware improves. It also generates and embeds its own salt, so
/// salting cannot be forgotten.
class BcryptPasswordHasher implements PasswordHasher {
  const BcryptPasswordHasher({this.cost = _defaultCost});

  /// Work factor, as a power of two. Ten is the common default and lands
  /// around fifty milliseconds on a phone: unnoticeable once per login,
  /// ruinous a billion times over.
  static const int _defaultCost = 10;

  /// bcrypt only reads the first 72 bytes of a password.
  ///
  /// Anything past that is silently ignored, which would make two long
  /// passwords sharing a prefix interchangeable. Rather than truncate quietly,
  /// [hash] rejects the input.
  static const int maxPasswordBytes = 72;

  final int cost;

  @override
  String hash(String password) {
    final int byteLength = utf8.encode(password).length;
    if (byteLength > maxPasswordBytes) {
      throw ArgumentError.value(
        byteLength,
        'password',
        'Exceeds the $maxPasswordBytes bytes bcrypt can read',
      );
    }

    return BCrypt.hashpw(password, BCrypt.gensalt(logRounds: cost));
  }

  @override
  bool verify({required String password, required String hash}) {
    try {
      return BCrypt.checkpw(password, hash);
    } on Object {
      // A stored value that is not a valid bcrypt hash makes the package throw.
      // For the caller that is simply a login that did not match.
      return false;
    }
  }
}
