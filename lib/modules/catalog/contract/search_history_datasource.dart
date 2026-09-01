import 'package:rekluti_test/modules/catalog/domain/search_term.dart';

/// Stores the words the user has searched for.
abstract interface class SearchHistoryDataSource {
  /// Records [term] as searched now, replacing any earlier entry for it.
  ///
  /// A blank term is ignored rather than stored.
  Future<void> remember(String term, {int? resultCount});

  /// The most recently searched terms, newest first.
  Future<List<SearchTerm>> recent({int limit});

  /// Removes a single term.
  Future<void> forget(String term);

  /// Removes every term.
  Future<void> clear();
}
