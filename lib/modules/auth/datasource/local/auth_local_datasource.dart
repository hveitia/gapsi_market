import 'package:equatable/equatable.dart';
import 'package:rekluti_test/shared/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

/// A user as it sits in the database, password hash included.
///
/// Separate from the domain `User` so the hash stops at the service boundary:
/// what the rest of the app receives simply has no field to leak.
class StoredUser extends Equatable {
  const StoredUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
  });

  final int id;
  final String name;
  final String email;
  final String passwordHash;

  @override
  List<Object?> get props => <Object?>[id, name, email, passwordHash];
}

/// Account storage for the auth module.
abstract interface class AuthLocalDataSource {
  /// The account registered under [email], or `null` if there is none.
  Future<StoredUser?> findByEmail(String email);

  /// Registers an account. Throws if the email is already taken.
  Future<StoredUser> insertUser({
    required String name,
    required String email,
    required String passwordHash,
  });

  /// Marks [userId] as the signed in account, replacing any open session.
  Future<void> openSession(int userId);

  /// The signed in account, or `null` when nobody is.
  Future<StoredUser?> sessionUser();

  /// Ends the open session. Does nothing when there is none.
  Future<void> closeSession();
}

/// [AuthLocalDataSource] on top of the app's SQLite connection.
class SqliteAuthLocalDataSource implements AuthLocalDataSource {
  const SqliteAuthLocalDataSource(this._database);

  static const String _usersTable = 'users';
  static const String _sessionTable = 'session';
  static const int _sessionRowId = 1;

  final AppDatabase _database;

  @override
  Future<StoredUser?> findByEmail(String email) async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      _usersTable,
      where: 'email = ?',
      whereArgs: <Object?>[_normalise(email)],
      limit: 1,
    );

    return rows.isEmpty ? null : _toStoredUser(rows.first);
  }

  @override
  Future<StoredUser> insertUser({
    required String name,
    required String email,
    required String passwordHash,
  }) async {
    final Database db = await _database.database;
    final String normalisedEmail = _normalise(email);

    final int id = await db.insert(_usersTable, <String, Object?>{
      'name': name.trim(),
      'email': normalisedEmail,
      'password_hash': passwordHash,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    return StoredUser(
      id: id,
      name: name.trim(),
      email: normalisedEmail,
      passwordHash: passwordHash,
    );
  }

  @override
  Future<void> openSession(int userId) async {
    final Database db = await _database.database;

    // The row id is fixed, so replacing it is what keeps a single session.
    await db.insert(_sessionTable, <String, Object?>{
      'id': _sessionRowId,
      'user_id': userId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<StoredUser?> sessionUser() async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT u.* FROM $_usersTable u '
      'INNER JOIN $_sessionTable s ON s.user_id = u.id '
      'WHERE s.id = ? LIMIT 1',
      <Object?>[_sessionRowId],
    );

    return rows.isEmpty ? null : _toStoredUser(rows.first);
  }

  @override
  Future<void> closeSession() async {
    final Database db = await _database.database;
    await db.delete(_sessionTable);
  }

  /// Emails are compared and stored in one canonical form, so the same address
  /// typed with different casing or padding always resolves to one account.
  String _normalise(String email) => email.trim().toLowerCase();

  StoredUser _toStoredUser(Map<String, Object?> row) {
    return StoredUser(
      id: row['id']! as int,
      name: row['name']! as String,
      email: row['email']! as String,
      passwordHash: row['password_hash']! as String,
    );
  }
}
