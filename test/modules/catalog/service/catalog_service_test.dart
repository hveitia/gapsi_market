import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rekluti_test/modules/catalog/contract/catalog_remote_datasource.dart';
import 'package:rekluti_test/modules/catalog/contract/search_history_datasource.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';
import 'package:rekluti_test/modules/catalog/domain/product_page.dart';
import 'package:rekluti_test/modules/catalog/domain/search_term.dart';
import 'package:rekluti_test/modules/catalog/service/catalog_service.dart';
import 'package:rekluti_test/shared/errors/failure.dart';

class _MockRemote extends Mock implements CatalogRemoteDataSource {}

class _MockHistory extends Mock implements SearchHistoryDataSource {}

const Product _product = Product(
  id: '1',
  title: 'Nintendo Switch',
  currency: 'USD',
  price: 299.0,
);

ProductPage _page(int page, {List<Product> products = const <Product>[_product]}) =>
    ProductPage(products: products, page: page, totalResults: 860);

void main() {
  late _MockRemote remote;
  late _MockHistory history;
  late CatalogService service;

  setUp(() {
    remote = _MockRemote();
    history = _MockHistory();
    service = CatalogService(remote: remote, history: history);

    when(
      () => history.remember(any(), resultCount: any(named: 'resultCount')),
    ).thenAnswer((_) async {});
  });

  void answerWith(ProductPage page) {
    when(
      () => remote.search(
        keyword: any(named: 'keyword'),
        page: any(named: 'page'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) async => page);
  }

  group('search', () {
    test('passes the query and the cancellation token straight through', () async {
      answerWith(_page(2));
      final CancelToken token = CancelToken();

      await service.search(keyword: 'nintendo', page: 2, cancelToken: token);

      verify(
        () => remote.search(keyword: 'nintendo', page: 2, cancelToken: token),
      ).called(1);
    });

    test('records the term once the first page comes back', () async {
      answerWith(_page(1));

      await service.search(keyword: 'nintendo', page: 1);

      verify(() => history.remember('nintendo', resultCount: 860)).called(1);
    });

    // Paging deeper is the same search. Recording it again would be noise.
    test('does not record the term again on later pages', () async {
      answerWith(_page(2));

      await service.search(keyword: 'nintendo', page: 2);

      verifyNever(
        () => history.remember(any(), resultCount: any(named: 'resultCount')),
      );
    });

    // A term that never returned anything does not belong in the history: the
    // chips would offer the user a search that already failed.
    test('does not record a term whose search failed', () async {
      when(
        () => remote.search(
          keyword: any(named: 'keyword'),
          page: any(named: 'page'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(const NetworkFailure());

      await expectLater(
        service.search(keyword: 'nintendo', page: 1),
        throwsA(isA<NetworkFailure>()),
      );
      verifyNever(
        () => history.remember(any(), resultCount: any(named: 'resultCount')),
      );
    });

    // The history is a convenience. Losing it must never cost the user the
    // results they were actually waiting for.
    test('still returns results when the history cannot be written', () async {
      answerWith(_page(1));
      when(
        () => history.remember(any(), resultCount: any(named: 'resultCount')),
      ).thenThrow(const StorageFailure());

      final ProductPage result = await service.search(
        keyword: 'nintendo',
        page: 1,
      );

      expect(result.products, hasLength(1));
    });

    test('records an empty search too, so the user sees it was tried', () async {
      answerWith(
        const ProductPage(products: <Product>[], page: 1, totalResults: 0),
      );

      await service.search(keyword: 'zapatos voladores', page: 1);

      verify(
        () => history.remember('zapatos voladores', resultCount: 0),
      ).called(1);
    });
  });

  group('history', () {
    test('reads the recent terms', () async {
      final SearchTerm term = SearchTerm(
        term: 'sony',
        searchedAt: DateTime(2026),
      );
      when(() => history.recent(limit: any(named: 'limit')))
          .thenAnswer((_) async => <SearchTerm>[term]);

      expect(await service.recentSearches(), <SearchTerm>[term]);
    });

    test('forgets and clears', () async {
      when(() => history.forget(any())).thenAnswer((_) async {});
      when(history.clear).thenAnswer((_) async {});

      await service.forgetSearch('sony');
      await service.clearSearches();

      verify(() => history.forget('sony')).called(1);
      verify(history.clear).called(1);
    });

    test('reports a storage problem when reading the history', () async {
      when(() => history.recent(limit: any(named: 'limit')))
          .thenThrow(StateError('disk'));

      await expectLater(
        service.recentSearches(),
        throwsA(isA<StorageFailure>()),
      );
    });
  });
}
