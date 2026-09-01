import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_history_bloc.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_history_event.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_history_state.dart';
import 'package:rekluti_test/modules/catalog/contract/catalog_contract.dart';
import 'package:rekluti_test/modules/catalog/domain/search_term.dart';
import 'package:rekluti_test/shared/errors/failure.dart';

class _MockCatalog extends Mock implements CatalogContract {}

SearchTerm term(String value) =>
    SearchTerm(term: value, searchedAt: DateTime(2026), resultCount: 860);

void main() {
  late _MockCatalog catalog;

  setUp(() => catalog = _MockCatalog());

  SearchHistoryBloc build() => SearchHistoryBloc(catalog);

  void whenRecent(List<SearchTerm> terms) {
    when(() => catalog.recentSearches(limit: any(named: 'limit')))
        .thenAnswer((_) async => terms);
  }

  blocTest<SearchHistoryBloc, SearchHistoryState>(
    'loads the stored terms',
    setUp: () => whenRecent(<SearchTerm>[term('sony'), term('nintendo')]),
    build: build,
    act: (SearchHistoryBloc bloc) => bloc.add(const SearchHistoryRequested()),
    expect: () => <Matcher>[
      isA<SearchHistoryLoaded>().having(
        (SearchHistoryLoaded s) => s.terms.map((SearchTerm t) => t.term),
        'terms',
        <String>['sony', 'nintendo'],
      ),
    ],
  );

  blocTest<SearchHistoryBloc, SearchHistoryState>(
    'an empty history is a normal answer, not a failure',
    setUp: () => whenRecent(<SearchTerm>[]),
    build: build,
    act: (SearchHistoryBloc bloc) => bloc.add(const SearchHistoryRequested()),
    expect: () => <Matcher>[
      isA<SearchHistoryLoaded>().having(
        (SearchHistoryLoaded s) => s.isEmpty,
        'isEmpty',
        isTrue,
      ),
    ],
  );

  // An unreadable history is not an empty one. Showing no chips would tell the
  // user their searches are gone.
  blocTest<SearchHistoryBloc, SearchHistoryState>(
    'reports a history it could not read',
    setUp: () => when(() => catalog.recentSearches(limit: any(named: 'limit')))
        .thenThrow(const StorageFailure()),
    build: build,
    act: (SearchHistoryBloc bloc) => bloc.add(const SearchHistoryRequested()),
    expect: () => <Matcher>[isA<SearchHistoryUnavailable>()],
  );

  blocTest<SearchHistoryBloc, SearchHistoryState>(
    'forgetting a term reloads what is left',
    setUp: () {
      when(() => catalog.forgetSearch(any())).thenAnswer((_) async {});
      whenRecent(<SearchTerm>[term('nintendo')]);
    },
    build: build,
    act: (SearchHistoryBloc bloc) =>
        bloc.add(const SearchHistoryTermForgotten('sony')),
    expect: () => <Matcher>[
      isA<SearchHistoryLoaded>().having(
        (SearchHistoryLoaded s) => s.terms.map((SearchTerm t) => t.term),
        'terms',
        <String>['nintendo'],
      ),
    ],
    verify: (_) => verify(() => catalog.forgetSearch('sony')).called(1),
  );

  blocTest<SearchHistoryBloc, SearchHistoryState>(
    'clearing empties the list',
    setUp: () {
      when(catalog.clearSearches).thenAnswer((_) async {});
      whenRecent(<SearchTerm>[]);
    },
    build: build,
    act: (SearchHistoryBloc bloc) => bloc.add(const SearchHistoryCleared()),
    expect: () => <Matcher>[
      isA<SearchHistoryLoaded>().having(
        (SearchHistoryLoaded s) => s.isEmpty,
        'isEmpty',
        isTrue,
      ),
    ],
  );

  // The delete has to land before the reload reads, or the row comes back.
  blocTest<SearchHistoryBloc, SearchHistoryState>(
    'still reloads when the delete itself failed',
    setUp: () {
      when(() => catalog.forgetSearch(any()))
          .thenThrow(const StorageFailure());
      whenRecent(<SearchTerm>[term('sony')]);
    },
    build: build,
    act: (SearchHistoryBloc bloc) =>
        bloc.add(const SearchHistoryTermForgotten('sony')),
    expect: () => <Matcher>[isA<SearchHistoryLoaded>()],
  );
}
