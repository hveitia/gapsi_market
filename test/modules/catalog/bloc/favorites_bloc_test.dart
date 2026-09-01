import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rekluti_test/modules/catalog/bloc/favorites_bloc.dart';
import 'package:rekluti_test/modules/catalog/bloc/favorites_event.dart';
import 'package:rekluti_test/modules/catalog/bloc/favorites_state.dart';
import 'package:rekluti_test/modules/catalog/contract/favorites_contract.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';
import 'package:rekluti_test/shared/errors/failure.dart';

class _MockFavorites extends Mock implements FavoritesContract {}

Product product(String id) =>
    Product(id: id, title: 'Producto $id', currency: 'USD', price: 299);

void main() {
  late _MockFavorites favorites;

  setUpAll(() => registerFallbackValue(product('fallback')));

  setUp(() {
    favorites = _MockFavorites();
    when(() => favorites.addFavorite(any())).thenAnswer((_) async {});
    when(() => favorites.removeFavorite(any())).thenAnswer((_) async {});
  });

  FavoritesBloc build() => FavoritesBloc(favorites);

  void whenStored(List<Product> products) {
    when(favorites.favorites).thenAnswer((_) async => products);
  }

  blocTest<FavoritesBloc, FavoritesState>(
    'loads what is stored',
    setUp: () => whenStored(<Product>[product('a')]),
    build: build,
    act: (FavoritesBloc bloc) => bloc.add(const FavoritesRequested()),
    expect: () => <Matcher>[
      isA<FavoritesLoaded>().having(
        (FavoritesLoaded s) => s.contains('a'),
        'contains a',
        isTrue,
      ),
    ],
  );

  blocTest<FavoritesBloc, FavoritesState>(
    'an empty list is a normal answer',
    setUp: () => whenStored(<Product>[]),
    build: build,
    act: (FavoritesBloc bloc) => bloc.add(const FavoritesRequested()),
    expect: () => <Matcher>[
      isA<FavoritesLoaded>().having(
        (FavoritesLoaded s) => s.isEmpty,
        'isEmpty',
        isTrue,
      ),
    ],
  );

  blocTest<FavoritesBloc, FavoritesState>(
    'reports favourites it could not read',
    setUp: () => when(favorites.favorites).thenThrow(const StorageFailure()),
    build: build,
    act: (FavoritesBloc bloc) => bloc.add(const FavoritesRequested()),
    expect: () => <Matcher>[isA<FavoritesUnavailable>()],
  );

  // The heart is one control, so one event covers both directions.
  blocTest<FavoritesBloc, FavoritesState>(
    'toggling a product that is not stored saves it',
    setUp: () => whenStored(<Product>[product('a')]),
    build: build,
    act: (FavoritesBloc bloc) => bloc.add(FavoriteToggled(product('a'))),
    verify: (_) {
      verify(() => favorites.addFavorite(product('a'))).called(1);
      verifyNever(() => favorites.removeFavorite(any()));
    },
  );

  blocTest<FavoritesBloc, FavoritesState>(
    'toggling a product that is stored removes it',
    setUp: () => whenStored(<Product>[]),
    build: build,
    seed: () => FavoritesLoaded(<Product>[product('a')]),
    act: (FavoritesBloc bloc) => bloc.add(FavoriteToggled(product('a'))),
    verify: (_) {
      verify(() => favorites.removeFavorite('a')).called(1);
      verifyNever(() => favorites.addFavorite(any()));
    },
  );

  // Showing a filled heart for something that was never written would be a lie
  // the next launch exposes.
  blocTest<FavoritesBloc, FavoritesState>(
    'a heart that could not be written stays as it was',
    setUp: () {
      when(() => favorites.addFavorite(any()))
          .thenThrow(const StorageFailure());
      whenStored(<Product>[]);
    },
    build: build,
    act: (FavoritesBloc bloc) => bloc.add(FavoriteToggled(product('a'))),
    expect: () => <Matcher>[
      isA<FavoritesLoaded>().having(
        (FavoritesLoaded s) => s.contains('a'),
        'contains a',
        isFalse,
      ),
    ],
  );

  // Against a stub that always answers "empty" this would pass without the
  // toggle ever reversing, so it runs on a double that actually remembers.
  blocTest<FavoritesBloc, FavoritesState>(
    'toggling twice ends where it started',
    build: () => FavoritesBloc(_InMemoryFavorites()),
    act: (FavoritesBloc bloc) => bloc
      ..add(FavoriteToggled(product('a')))
      ..add(FavoriteToggled(product('a'))),
    expect: () => <Matcher>[
      isA<FavoritesLoaded>().having(
        (FavoritesLoaded s) => s.contains('a'),
        'saved',
        isTrue,
      ),
      isA<FavoritesLoaded>().having(
        (FavoritesLoaded s) => s.contains('a'),
        'removed again',
        isFalse,
      ),
    ],
  );
}

/// Remembers what it was told, which a stub cannot.
class _InMemoryFavorites implements FavoritesContract {
  final Map<String, Product> _stored = <String, Product>{};

  @override
  Future<List<Product>> favorites() async => _stored.values.toList();

  @override
  Future<void> addFavorite(Product product) async =>
      _stored[product.id] = product;

  @override
  Future<void> removeFavorite(String id) async => _stored.remove(id);
}
