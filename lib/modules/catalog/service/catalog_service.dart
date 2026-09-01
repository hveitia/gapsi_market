import 'package:dio/dio.dart';
import 'package:rekluti_test/modules/catalog/contract/catalog_cache_datasource.dart';
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
    required CatalogCacheDataSource cache,
    this.cacheTtl = defaultCacheTtl,
  }) : _remote = remote,
       _history = history,
       _cache = cache;

  /// How long a cached page is worth serving.
  ///
  /// The service takes eight to ten seconds to answer, so a repeated term is
  /// the difference between an instant list and a long wait. Twenty minutes is
  /// short enough that a price cannot drift far and long enough to cover the
  /// way the history invites the same search again.
  static const Duration defaultCacheTtl = Duration(minutes: 20);

  final CatalogRemoteDataSource _remote;
  final SearchHistoryDataSource _history;
  final CatalogCacheDataSource _cache;
  final Duration cacheTtl;

  @override
  Future<ProductPage> search({
    required String keyword,
    required int page,
    CancelToken? cancelToken,
  }) async {
    final ProductPage result = await _load(
      keyword: keyword,
      page: page,
      cancelToken: cancelToken,
    );

    // Only the first page, and only once the results came back: paging deeper
    // is the same search, and a term whose search failed would offer the user
    // a query that never worked. A cached answer still counts as searched.
    if (page == 1) {
      await _remember(keyword, result.totalResults);
    }

    return result;
  }

  /// A fresh cached page if there is one, otherwise the service.
  Future<ProductPage> _load({
    required String keyword,
    required int page,
    CancelToken? cancelToken,
  }) async {
    final ProductPage? cached = await _readCache(keyword, page);
    if (cached != null) {
      return cached;
    }

    final ProductPage fetched = await _remote.search(
      keyword: keyword,
      page: page,
      cancelToken: cancelToken,
    );

    // An empty page is not cached: it is how the end of the results is
    // recognised, and storing it would freeze that answer for twenty minutes.
    if (fetched.products.isNotEmpty) {
      await _writeCache(keyword, fetched);
    }

    return fetched;
  }

  /// Reading the cache can never break a search: a storage problem simply
  /// means the request goes out as it would have anyway.
  Future<ProductPage?> _readCache(String keyword, int page) async {
    try {
      return await _cache.read(term: keyword, page: page, maxAge: cacheTtl);
    } on Object {
      return null;
    }
  }

  Future<void> _writeCache(String keyword, ProductPage page) async {
    try {
      await _cache.write(term: keyword, page: page);
      // Pruning here rather than on a schedule keeps the table bounded without
      // anything having to remember to sweep it.
      await _cache.evictExpired(cacheTtl);
    } on Object {
      // The results were already delivered; failing to keep a copy costs
      // nothing but the next search's speed.
    }
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
