import 'package:equatable/equatable.dart';

/// A word the user searched for, kept so it can be offered again.
class SearchTerm extends Equatable {
  const SearchTerm({
    required this.term,
    required this.searchedAt,
    this.resultCount,
  });

  /// Normalised to lower case, which is also how it is deduplicated.
  final String term;

  final DateTime searchedAt;

  /// How many matches the search reported, when it reported any.
  final int? resultCount;

  @override
  List<Object?> get props => <Object?>[term, searchedAt, resultCount];
}
