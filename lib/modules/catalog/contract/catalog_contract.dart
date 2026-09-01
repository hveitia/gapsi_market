import 'package:dio/dio.dart';
import 'package:rekluti_test/modules/catalog/domain/product_page.dart';
import 'package:rekluti_test/modules/catalog/domain/search_term.dart';

/// What the search bloc is allowed to ask for.
///
/// The bloc depends on this abstraction, never on Dio or SQLite, which is what
/// lets the search and pagination rules be tested without either.
abstract interface class CatalogContract {
  /// One page of results for [keyword].
  ///
  /// Searching the first page also records the term in the history.
  Future<ProductPage> search({
    required String keyword,
    required int page,
    CancelToken? cancelToken,
  });

  /// The terms searched before, newest first.
  Future<List<SearchTerm>> recentSearches({int limit});

  /// Removes one term from the history.
  Future<void> forgetSearch(String term);

  /// Empties the history.
  Future<void> clearSearches();
}
