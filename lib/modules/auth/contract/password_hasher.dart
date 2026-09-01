/// Turns a plain password into a value safe to store, and checks one against it.
///
/// An abstraction rather than a direct call to a package so the algorithm can
/// be replaced without touching the sign in and sign up flows, and so tests can
/// run against a cheap stand in instead of paying a deliberately slow hash.
abstract interface class PasswordHasher {
  /// Hashes [password] into a value that can be persisted.
  ///
  /// The result includes its own salt, so two calls with the same input return
  /// different values.
  String hash(String password);

  /// Whether [password] is the one that produced [hash].
  ///
  /// Returns `false` for a stored value that is not a valid hash rather than
  /// throwing: a corrupted row must read as a failed login, never as a crash.
  bool verify({required String password, required String hash});
}
