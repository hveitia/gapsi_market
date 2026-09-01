import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_bloc.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_event.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_state.dart';
import 'package:rekluti_test/modules/catalog/contract/catalog_contract.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';
import 'package:rekluti_test/modules/catalog/domain/product_page.dart';
import 'package:rekluti_test/shared/errors/failure.dart';

class _MockCatalog extends Mock implements CatalogContract {}

Product product(String id) =>
    Product(id: id, title: 'Producto $id', currency: 'USD', price: 10);

ProductPage page(int number, List<String> ids, {int? maxPage}) => ProductPage(
  products: ids.map(product).toList(),
  page: number,
  maxPage: maxPage,
  totalResults: 860,
);

/// Short enough to keep the suite fast, long enough to prove the debounce runs.
const Duration debounce = Duration(milliseconds: 20);

void main() {
  late _MockCatalog catalog;

  setUp(() => catalog = _MockCatalog());

  SearchBloc build() => SearchBloc(catalog, debounce: debounce);

  void whenSearch({
    required int page,
    ProductPage? answer,
    Object? error,
    Duration delay = Duration.zero,
  }) {
    final When<Future<ProductPage>> stub = when(
      () => catalog.search(
        keyword: any(named: 'keyword'),
        page: page,
        cancelToken: any(named: 'cancelToken'),
      ),
    );
    if (error != null) {
      stub.thenAnswer((_) async {
        await Future<void>.delayed(delay);
        throw error;
      });
    } else {
      stub.thenAnswer((_) async {
        await Future<void>.delayed(delay);
        return answer!;
      });
    }
  }

  group('typing', () {
    // The exercise asks for no unnecessary requests while the term changes
    // quickly. Four keystrokes have to become one call.
    blocTest<SearchBloc, SearchState>(
      'collapses a burst of keystrokes into a single search',
      setUp: () => whenSearch(page: 1, answer: page(1, <String>['a'])),
      build: build,
      act: (SearchBloc bloc) => bloc
        ..add(const SearchTermChanged('n'))
        ..add(const SearchTermChanged('ni'))
        ..add(const SearchTermChanged('nin'))
        ..add(const SearchTermChanged('nintendo')),
      wait: debounce * 4,
      verify: (_) {
        // Counting every first page call, not just the one for the final term:
        // asserting on 'nintendo' alone would pass even with no debounce at all.
        verify(
          () => catalog.search(
            keyword: any(named: 'keyword'),
            page: 1,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);
        verifyNever(
          () => catalog.search(
            keyword: 'nin',
            page: 1,
            cancelToken: any(named: 'cancelToken'),
          ),
        );
      },
    );

    blocTest<SearchBloc, SearchState>(
      'shows the results once they arrive',
      setUp: () => whenSearch(page: 1, answer: page(1, <String>['a', 'b'])),
      build: build,
      act: (SearchBloc bloc) => bloc.add(const SearchTermChanged('nintendo')),
      wait: debounce * 4,
      expect: () => <Matcher>[
        isA<SearchLoading>(),
        isA<SearchResults>()
            .having((SearchResults s) => s.products, 'products', hasLength(2))
            .having((SearchResults s) => s.page, 'page', 1),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'reports a term that returned nothing',
      setUp: () => whenSearch(page: 1, answer: page(1, <String>[])),
      build: build,
      act: (SearchBloc bloc) =>
          bloc.add(const SearchTermChanged('zapatos voladores')),
      wait: debounce * 4,
      expect: () => <Matcher>[isA<SearchLoading>(), isA<SearchEmpty>()],
    );

    blocTest<SearchBloc, SearchState>(
      'reports a first page that failed',
      setUp: () => whenSearch(page: 1, error: const NetworkFailure()),
      build: build,
      act: (SearchBloc bloc) => bloc.add(const SearchTermChanged('nintendo')),
      wait: debounce * 4,
      expect: () => <Matcher>[
        isA<SearchLoading>(),
        isA<SearchFailed>().having(
          (SearchFailed s) => s.failure,
          'failure',
          isA<NetworkFailure>(),
        ),
      ],
    );

    // Cancellation is how a superseded search ends. It is normal control flow
    // and must never reach the user as an error.
    blocTest<SearchBloc, SearchState>(
      'never shows a cancelled search as an error',
      setUp: () => whenSearch(page: 1, error: const CancelledFailure()),
      build: build,
      act: (SearchBloc bloc) => bloc.add(const SearchTermChanged('nintendo')),
      wait: debounce * 4,
      expect: () => <Matcher>[isA<SearchLoading>()],
    );

    blocTest<SearchBloc, SearchState>(
      'emptying the field goes back to idle without searching',
      build: build,
      act: (SearchBloc bloc) => bloc.add(const SearchTermChanged('   ')),
      wait: debounce * 4,
      expect: () => <Matcher>[isA<SearchIdle>()],
      verify: (_) => verifyNever(
        () => catalog.search(
          keyword: any(named: 'keyword'),
          page: any(named: 'page'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ),
    );

    blocTest<SearchBloc, SearchState>(
      'does not search again for the term already on screen',
      setUp: () => whenSearch(page: 1, answer: page(1, <String>['a'])),
      build: build,
      seed: () => SearchResults(
        term: 'nintendo',
        products: <Product>[product('a')],
        page: 1,
      ),
      act: (SearchBloc bloc) => bloc.add(const SearchTermChanged('nintendo')),
      wait: debounce * 4,
      expect: () => <Matcher>[],
    );
  });

  group('paging', () {
    blocTest<SearchBloc, SearchState>(
      'appends the next page to what is already loaded',
      setUp: () => whenSearch(page: 2, answer: page(2, <String>['c', 'd'])),
      build: build,
      seed: () => SearchResults(
        term: 'nintendo',
        products: <Product>[product('a'), product('b')],
        page: 1,
      ),
      act: (SearchBloc bloc) => bloc.add(const SearchNextPageRequested()),
      expect: () => <Matcher>[
        isA<SearchResults>().having(
          (SearchResults s) => s.pageLoad,
          'pageLoad',
          isA<PageLoading>(),
        ),
        isA<SearchResults>()
            .having(
              (SearchResults s) => s.products.map((Product p) => p.id),
              'ids',
              <String>['a', 'b', 'c', 'd'],
            )
            .having((SearchResults s) => s.page, 'page', 2),
      ],
    );

    // Pages overlap in the real service: 14 of 45 products on page two were
    // already on page one.
    blocTest<SearchBloc, SearchState>(
      'never shows a product twice when pages overlap',
      setUp: () =>
          whenSearch(page: 2, answer: page(2, <String>['b', 'c', 'a', 'd'])),
      build: build,
      seed: () => SearchResults(
        term: 'nintendo',
        products: <Product>[product('a'), product('b')],
        page: 1,
      ),
      act: (SearchBloc bloc) => bloc.add(const SearchNextPageRequested()),
      skip: 1,
      expect: () => <Matcher>[
        isA<SearchResults>().having(
          (SearchResults s) => s.products.map((Product p) => p.id),
          'ids',
          <String>['a', 'b', 'c', 'd'],
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'stops asking once a page comes back empty',
      setUp: () => whenSearch(page: 2, answer: page(2, <String>[])),
      build: build,
      seed: () => SearchResults(
        term: 'nintendo',
        products: <Product>[product('a')],
        page: 1,
      ),
      act: (SearchBloc bloc) => bloc.add(const SearchNextPageRequested()),
      skip: 1,
      expect: () => <Matcher>[
        isA<SearchResults>().having(
          (SearchResults s) => s.hasReachedEnd,
          'hasReachedEnd',
          isTrue,
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'asks for nothing more once the end was reached',
      build: build,
      seed: () => SearchResults(
        term: 'nintendo',
        products: <Product>[product('a')],
        page: 3,
        hasReachedEnd: true,
      ),
      act: (SearchBloc bloc) => bloc.add(const SearchNextPageRequested()),
      expect: () => <Matcher>[],
      verify: (_) => verifyNever(
        () => catalog.search(
          keyword: any(named: 'keyword'),
          page: any(named: 'page'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ),
    );

    // A scroll near the bottom fires this event repeatedly.
    blocTest<SearchBloc, SearchState>(
      'asks for a page once even when scrolling fires repeatedly',
      setUp: () => whenSearch(
        page: 2,
        answer: page(2, <String>['c']),
        delay: const Duration(milliseconds: 30),
      ),
      build: build,
      seed: () => SearchResults(
        term: 'nintendo',
        products: <Product>[product('a')],
        page: 1,
      ),
      act: (SearchBloc bloc) => bloc
        ..add(const SearchNextPageRequested())
        ..add(const SearchNextPageRequested())
        ..add(const SearchNextPageRequested()),
      wait: const Duration(milliseconds: 120),
      verify: (_) => verify(
        () => catalog.search(
          keyword: 'nintendo',
          page: 2,
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(1),
    );

    blocTest<SearchBloc, SearchState>(
      'treats the reported ceiling as a cap',
      setUp: () => whenSearch(page: 2, answer: page(2, <String>['c'])),
      build: build,
      seed: () => SearchResults(
        term: 'nintendo',
        products: <Product>[product('a')],
        page: 1,
        maxPage: 2,
      ),
      act: (SearchBloc bloc) => bloc.add(const SearchNextPageRequested()),
      skip: 1,
      expect: () => <Matcher>[
        isA<SearchResults>().having(
          (SearchResults s) => s.hasReachedEnd,
          'hasReachedEnd',
          isTrue,
        ),
      ],
    );
  });

  group('a page that fails', () {
    // The rule the exercise states outright: a failing additional page must not
    // wipe out what the user already has.
    blocTest<SearchBloc, SearchState>(
      'keeps the loaded results and records the failure',
      setUp: () => whenSearch(page: 2, error: const TimeoutFailure()),
      build: build,
      seed: () => SearchResults(
        term: 'nintendo',
        products: <Product>[product('a'), product('b')],
        page: 1,
      ),
      act: (SearchBloc bloc) => bloc.add(const SearchNextPageRequested()),
      skip: 1,
      expect: () => <Matcher>[
        isA<SearchResults>()
            .having(
              (SearchResults s) => s.products,
              'products kept',
              hasLength(2),
            )
            .having(
              (SearchResults s) => s.pageLoad,
              'pageLoad',
              isA<PageFailed>(),
            )
            .having((SearchResults s) => s.page, 'page unchanged', 1),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'retries the page that failed',
      setUp: () => whenSearch(page: 2, answer: page(2, <String>['c'])),
      build: build,
      seed: () => SearchResults(
        term: 'nintendo',
        products: <Product>[product('a')],
        page: 1,
        pageLoad: const PageFailed(TimeoutFailure()),
      ),
      act: (SearchBloc bloc) => bloc.add(const SearchRetryRequested()),
      skip: 1,
      expect: () => <Matcher>[
        isA<SearchResults>()
            .having(
              (SearchResults s) => s.products.map((Product p) => p.id),
              'ids',
              <String>['a', 'c'],
            )
            .having((SearchResults s) => s.pageLoad, 'pageLoad', isA<PageIdle>()),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'retries a first page that failed',
      setUp: () => whenSearch(page: 1, answer: page(1, <String>['a'])),
      build: build,
      seed: () => const SearchFailed(
        term: 'nintendo',
        failure: NetworkFailure(),
      ),
      act: (SearchBloc bloc) => bloc.add(const SearchRetryRequested()),
      expect: () => <Matcher>[isA<SearchLoading>(), isA<SearchResults>()],
    );
  });
}
