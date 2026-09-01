import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_event.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_state.dart';
import 'package:rekluti_test/modules/catalog/contract/catalog_contract.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';
import 'package:rekluti_test/modules/catalog/domain/product_page.dart';
import 'package:rekluti_test/shared/errors/failure.dart';
import 'package:stream_transform/stream_transform.dart';

/// Drives the product search: typing, paging and retrying.
///
/// Depends on [CatalogContract], so every rule below is tested without a socket
/// or a database.
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this._catalog, {Duration debounce = defaultDebounce})
    : super(const SearchIdle()) {
    on<SearchTermChanged>(
      _onTermChanged,
      // Debounce answers "avoid unnecessary requests while the user types";
      // restartable answers what happens to the one already running: the
      // handler for the previous term is abandoned rather than racing the new
      // one to emit.
      transformer: (Stream<SearchTermChanged> events, EventMapper<SearchTermChanged> mapper) =>
          restartable<SearchTermChanged>()(events.debounce(debounce), mapper),
    );
    on<SearchNextPageRequested>(
      _onNextPageRequested,
      // A scroll near the bottom fires repeatedly. Dropping events while one is
      // being handled is the first of two guards against asking twice for the
      // same page.
      transformer: droppable(),
    );
    on<SearchRetryRequested>(_onRetryRequested, transformer: droppable());
    on<SearchCleared>(_onCleared);
  }

  /// Long enough that a fast typist sends one request instead of ten, short
  /// enough that the list does not feel stuck.
  static const Duration defaultDebounce = Duration(milliseconds: 350);

  final CatalogContract _catalog;

  /// The token of the request in flight, so a new search can abandon it.
  CancelToken? _inFlight;

  @override
  Future<void> close() {
    _inFlight?.cancel();
    return super.close();
  }

  Future<void> _onTermChanged(
    SearchTermChanged event,
    Emitter<SearchState> emit,
  ) async {
    final String term = event.term.trim();

    if (term.isEmpty) {
      _abandonInFlight();
      emit(const SearchIdle());
      return;
    }

    // Retyping the term that is already on screen is not a new search. The
    // field emits on every keystroke, and correcting a character back to what
    // it was would otherwise cost a request.
    if (_alreadyShowing(term)) {
      return;
    }

    _abandonInFlight();
    emit(SearchLoading(term));
    await _loadFirstPage(term, emit);
  }

  Future<void> _onNextPageRequested(
    SearchNextPageRequested event,
    Emitter<SearchState> emit,
  ) async {
    final SearchState current = state;
    if (current is! SearchResults || !current.canLoadMore) {
      return;
    }
    await _loadNextPage(current, emit);
  }

  Future<void> _onRetryRequested(
    SearchRetryRequested event,
    Emitter<SearchState> emit,
  ) async {
    switch (state) {
      case final SearchFailed failed:
        emit(SearchLoading(failed.term));
        await _loadFirstPage(failed.term, emit);
      case final SearchResults results when results.pageLoad is PageFailed:
        await _loadNextPage(results, emit);
      case _:
        return;
    }
  }

  void _onCleared(SearchCleared event, Emitter<SearchState> emit) {
    _abandonInFlight();
    emit(const SearchIdle());
  }

  Future<void> _loadFirstPage(String term, Emitter<SearchState> emit) async {
    try {
      final ProductPage page = await _catalog.search(
        keyword: term,
        page: 1,
        cancelToken: _startRequest(),
      );

      emit(
        page.products.isEmpty
            ? SearchEmpty(term)
            : SearchResults(
                term: term,
                products: page.products,
                page: 1,
                maxPage: page.maxPage,
                totalResults: page.totalResults,
              ),
      );
    } on CancelledFailure {
      // A newer term superseded this one. Saying anything here would overwrite
      // the state that newer search has already produced.
    } on Failure catch (failure) {
      emit(SearchFailed(term: term, failure: failure));
    }
  }

  Future<void> _loadNextPage(
    SearchResults snapshot,
    Emitter<SearchState> emit,
  ) async {
    final int next = snapshot.page + 1;
    emit(snapshot.copyWith(pageLoad: const PageLoading()));

    try {
      final ProductPage page = await _catalog.search(
        keyword: snapshot.term,
        page: next,
        cancelToken: _startRequest(),
      );

      final SearchResults? current = _stillShowing(snapshot.term);
      if (current == null) {
        return;
      }

      emit(
        current.copyWith(
          products: _appendNew(current.products, page.products),
          page: next,
          // An empty page is the end. maxPage only caps the walk, because the
          // service reports it inconsistently.
          hasReachedEnd:
              page.hasReachedEnd || _reachedCeiling(next, snapshot.maxPage),
          pageLoad: const PageIdle(),
        ),
      );
    } on CancelledFailure {
      // Superseded by a new search, which owns the state now.
    } on Failure catch (failure) {
      final SearchResults? current = _stillShowing(snapshot.term);
      if (current == null) {
        return;
      }
      // The exercise's rule, made structural: the failure is recorded inside
      // the state that holds the products, so what was already loaded stays on
      // screen.
      emit(current.copyWith(pageLoad: PageFailed(failure)));
    }
  }

  /// Appends only the products not already on screen.
  ///
  /// Pages overlap: a real response repeated 14 of the 45 products from the
  /// previous page. Without this the list would show the same item twice.
  List<Product> _appendNew(List<Product> existing, List<Product> incoming) {
    final Set<String> seen = existing.map((Product p) => p.id).toSet();
    return <Product>[
      ...existing,
      ...incoming.where((Product product) => seen.add(product.id)),
    ];
  }

  bool _reachedCeiling(int page, int? maxPage) =>
      maxPage != null && page >= maxPage;

  bool _alreadyShowing(String term) => switch (state) {
    final SearchResults results => results.term == term,
    final SearchLoading loading => loading.term == term,
    _ => false,
  };

  /// The current state, but only if it is still the search this handler began.
  ///
  /// Between the request going out and the answer arriving the user may have
  /// typed something else. Emitting a stale page then would resurrect results
  /// that are no longer being asked for.
  SearchResults? _stillShowing(String term) {
    final SearchState current = state;
    return (current is SearchResults && current.term == term) ? current : null;
  }

  CancelToken _startRequest() => _inFlight = CancelToken();

  void _abandonInFlight() {
    _inFlight?.cancel();
    _inFlight = null;
  }
}
