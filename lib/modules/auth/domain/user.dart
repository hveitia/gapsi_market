import 'package:equatable/equatable.dart';

/// An account as the rest of the app sees it.
///
/// Deliberately carries no credential material. The password hash never leaves
/// the service layer, so no screen, bloc or log statement can ever expose it,
/// even by accident.
class User extends Equatable {
  const User({required this.id, required this.name, required this.email});

  final int id;
  final String name;

  /// Normalised to lower case, the same form the account was stored under.
  final String email;

  @override
  List<Object?> get props => <Object?>[id, name, email];
}
