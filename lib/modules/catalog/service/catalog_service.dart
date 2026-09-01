import 'package:dio/dio.dart';
import 'package:rekluti_test/modules/catalog/contract/catalog_contract.dart';
import 'package:rekluti_test/modules/catalog/contract/catalog_remote_datasource.dart';
import 'package:rekluti_test/modules/catalog/contract/search_history_datasource.dart';
import 'package:rekluti_test/modules/catalog/datasource/local/search_history_local_datasource.dart';
import 'package:rekluti_test/modules/catalog/domain/product_page.dart';
import 'package:rekluti_test/modules/catalog/domain/search_term.dart';
import 'package:rekluti_test/shared/errors/failure.dart';

/// Joins the catalogue service with the local search history.
///
/// The only place that knows a search has a side effect: it also remembers what
/// was searched for.
class CatalogService implements CatalogContract {
  const CatalogService({
    required CatalogRemoteDataSource remote,
    required SearchHistoryDataSource history,
  }) : _remote = remote,
       _history = history;

  final CatalogRemoteDataSource _remote;
  final SearchHistoryDataSource _history;

  @override
  Future<ProductPage> search({
    required String keyword,
    required int page,
    CancelToken? cancelToken,
  }) async {
    final ProductPage result = await _remote.search(
      keyword: keyword,
      page: page,
      cancelToken: cancelToken,
    );

    // Only the first page, and only once the request came back: paging deeper
    // is the same search, and a term whose search failed would offer the user
    // a query that never worked.
    if (page == 1) {
      await _remember(keyword, result.totalResults);
    }

    return result;
  }

  @override
  Future<List<SearchTerm>> recentSearches({
    int limit = SqliteSearchHistoryDataSource.defaultLimit,
  }) {
    return _guard(() => _history.recent(limit: limit));
  }

  @override
  Future<void> forgetSearch(String term) => _guard(() => _history.forget(term));

  @override
  Future<void> clearSearches() => _guard(_history.clear);

  /// Records the term, swallowing any storage problem.
  ///
  /// The history is a convenience. Failing to write it must never cost the user
  /// the results they were actually waiting for.
  Future<void> _remember(String keyword, int? resultCount) async {
    try {
      await _history.remember(keyword, resultCount: resultCount);
    } on Object {
      // Deliberately ignored: the results matter, the bookkeeping does not.
    }
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw StorageFailure(debugMessage: error.toString());
    }
  }
}
