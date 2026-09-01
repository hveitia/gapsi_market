import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rekluti_test/modules/catalog/bloc/favorites_bloc.dart';
import 'package:rekluti_test/modules/catalog/bloc/favorites_event.dart';
import 'package:rekluti_test/modules/catalog/bloc/favorites_state.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_bloc.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_event.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_history_bloc.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_history_event.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_history_state.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_state.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';
import 'package:rekluti_test/modules/catalog/domain/search_term.dart';
import 'package:rekluti_test/modules/catalog/presenter/product_detail_view.dart';
import 'package:rekluti_test/modules/catalog/presenter/search_view.dart';
import 'package:rekluti_test/modules/catalog/presenter/widgets/favorite_heart.dart';
import 'package:rekluti_test/modules/catalog/presenter/widgets/product_card.dart';
import 'package:rekluti_test/modules/catalog/presenter/widgets/product_skeleton.dart';
import 'package:rekluti_test/shared/errors/failure.dart';

class _MockSearch extends MockBloc<SearchEvent, SearchState>
    implements SearchBloc {}

class _MockHistory extends MockBloc<SearchHistoryEvent, SearchHistoryState>
    implements SearchHistoryBloc {}

class _MockFavorites extends MockBloc<FavoritesEvent, FavoritesState>
    implements FavoritesBloc {}

Product product(String id, {String? description, double? price = 299}) =>
    Product(
      id: id,
      title: 'Nintendo Switch $id',
      currency: 'USD',
      price: price,
      description: description,
      rating: 4.8,
      reviewCount: 8700,
      productUrl: 'https://www.walmart.com/ip/$id',
    );

void main() {
  setUpAll(() {
    registerFallbackValue(const SearchTermChanged('x'));
    registerFallbackValue(const SearchHistoryRequested());
    registerFallbackValue(const FavoritesRequested());
  });

  late _MockSearch search;
  late _MockHistory history;
  late _MockFavorites favorites;

  setUp(() {
    search = _MockSearch();
    history = _MockHistory();
    favorites = _MockFavorites();
    whenListen(
      favorites,
      const Stream<FavoritesState>.empty(),
      initialState: FavoritesLoaded(<Product>[]),
    );
    whenListen(
      history,
      const Stream<SearchHistoryState>.empty(),
      initialState: const SearchHistoryLoaded(<SearchTerm>[]),
    );
  });

  Future<void> pumpSearch(
    WidgetTester tester,
    SearchState state, {
    bool settle = true,
  }) async {
    whenListen(search, const Stream<SearchState>.empty(), initialState: state);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<SearchBloc>.value(value: search),
          BlocProvider<SearchHistoryBloc>.value(value: history),
          BlocProvider<FavoritesBloc>.value(value: favorites),
        ],
        child: MaterialApp(
          home: SearchView(
            onProductSelected: (BuildContext _, Product _) {},
          ),
        ),
      ),
    );
    settle ? await tester.pumpAndSettle() : await tester.pump();
  }

  group('the four states the exercise asks for', () {
    testWidgets('idle offers terms to try', (WidgetTester tester) async {
      await pumpSearch(tester, const SearchIdle());

      expect(find.text('Prueba con'), findsOneWidget);
      expect(find.text('nintendo'), findsWidgets);
    });

    testWidgets('loading shows placeholders, not a bare spinner', (
      WidgetTester tester,
    ) async {
      await pumpSearch(tester, const SearchLoading('nintendo'), settle: false);

      expect(find.byType(ProductSkeletonList), findsOneWidget);
    });

    testWidgets('results show title and price', (WidgetTester tester) async {
      await pumpSearch(
        tester,
        SearchResults(
          term: 'nintendo',
          products: <Product>[product('a'), product('b')],
          page: 1,
          totalResults: 860,
        ),
      );

      expect(find.byType(ProductCard), findsNWidgets(2));
      expect(find.text('Nintendo Switch a'), findsOneWidget);
      expect(find.text(r'$299.00'), findsWidgets);
      expect(find.textContaining('860 resultados'), findsOneWidget);
    });

    testWidgets('an empty search explains what to try', (
      WidgetTester tester,
    ) async {
      await pumpSearch(tester, const SearchEmpty('zapatos voladores'));

      expect(find.text('Sin resultados'), findsOneWidget);
      expect(find.textContaining('zapatos voladores'), findsOneWidget);
    });

    testWidgets('an error names what went wrong', (WidgetTester tester) async {
      await pumpSearch(
        tester,
        const SearchFailed(term: 'nintendo', failure: NetworkFailure()),
      );

      expect(find.text('Sin conexión'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  // The rule the exercise states outright, checked at the level the user sees.
  testWidgets('a failed page keeps the products on screen', (
    WidgetTester tester,
  ) async {
    await pumpSearch(
      tester,
      SearchResults(
        term: 'nintendo',
        products: <Product>[product('a'), product('b')],
        page: 2,
        pageLoad: const PageFailed(TimeoutFailure()),
      ),
    );

    expect(find.byType(ProductCard), findsNWidgets(2));
    expect(find.text('No se pudo cargar la página 3'), findsOneWidget);
    expect(find.text('Los resultados anteriores se conservan.'), findsOneWidget);
  });

  testWidgets('retrying a failed page asks the bloc, not the screen', (
    WidgetTester tester,
  ) async {
    await pumpSearch(
      tester,
      SearchResults(
        term: 'nintendo',
        products: <Product>[product('a')],
        page: 1,
        pageLoad: const PageFailed(TimeoutFailure()),
      ),
    );

    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    verify(() => search.add(const SearchRetryRequested())).called(1);
  });

  testWidgets('the end of the results is stated, not left blank', (
    WidgetTester tester,
  ) async {
    await pumpSearch(
      tester,
      SearchResults(
        term: 'nintendo',
        products: <Product>[product('a')],
        page: 3,
        hasReachedEnd: true,
      ),
    );

    expect(find.text('No hay más resultados'), findsOneWidget);
  });

  group('the detail screen', () {
    Future<void> pumpDetail(WidgetTester tester, Product value) async {
      await tester.pumpWidget(
        BlocProvider<FavoritesBloc>.value(
          value: favorites,
          child: MaterialApp(home: ProductDetailView(product: value)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows title, price and description', (
      WidgetTester tester,
    ) async {
      await pumpDetail(tester, product('a', description: 'Consola portátil'));

      expect(find.text('Nintendo Switch a'), findsOneWidget);
      expect(find.text(r'$299.00'), findsOneWidget);
      expect(find.text('Consola portátil'), findsOneWidget);
    });

    // About one product in six arrives with no description at all.
    testWidgets('says so when there is no description', (
      WidgetTester tester,
    ) async {
      await pumpDetail(tester, product('a'));

      expect(
        find.text('Este producto no incluye descripción.'),
        findsOneWidget,
      );
    });

    testWidgets('states plainly when there is no price', (
      WidgetTester tester,
    ) async {
      await pumpDetail(tester, product('a', price: null));

      expect(find.text('Precio no disponible'), findsOneWidget);
    });
  });

  group('the heart', () {
    testWidgets('offers to save a product that is not a favourite', (
      WidgetTester tester,
    ) async {
      await pumpSearch(
        tester,
        SearchResults(
          term: 'nintendo',
          products: <Product>[product('a')],
          page: 1,
        ),
      );

      await tester.tap(find.byType(FavoriteHeart));
      await tester.pump();

      verify(() => favorites.add(FavoriteToggled(product('a')))).called(1);
    });

    testWidgets('reads as pressed for one already saved', (
      WidgetTester tester,
    ) async {
      whenListen(
        favorites,
        const Stream<FavoritesState>.empty(),
        initialState: FavoritesLoaded(<Product>[product('a')]),
      );

      await pumpSearch(
        tester,
        SearchResults(
          term: 'nintendo',
          products: <Product>[product('a')],
          page: 1,
        ),
      );

      final Semantics node = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(FavoriteHeart),
              matching: find.byType(Semantics),
            )
            .first,
      );

      expect(node.properties.toggled, isTrue);
      expect(node.properties.label, 'Quitar de favoritos');
    });
  });

  // A guest must keep a way into the auth flow: choosing to browse without an
  // account should not be a one way door.
  group('the header slot', () {
    testWidgets('shows whatever the composition put there', (
      WidgetTester tester,
    ) async {
      whenListen(search, const Stream<SearchState>.empty(),
          initialState: const SearchIdle());

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: <BlocProvider<dynamic>>[
            BlocProvider<SearchBloc>.value(value: search),
            BlocProvider<SearchHistoryBloc>.value(value: history),
            BlocProvider<FavoritesBloc>.value(value: favorites),
          ],
          child: MaterialApp(
            home: SearchView(
              onProductSelected: (BuildContext _, Product _) {},
              headerAction: const Text('iniciar sesión'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('iniciar sesión'), findsOneWidget);
    });

    testWidgets('leaves the header alone when nothing was given', (
      WidgetTester tester,
    ) async {
      await pumpSearch(tester, const SearchIdle());

      expect(find.text('iniciar sesión'), findsNothing);
      expect(find.text('Hola, buenas compras'), findsOneWidget);
    });
  });
}
