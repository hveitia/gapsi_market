import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_history_event.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_history_state.dart';
import 'package:rekluti_test/modules/catalog/contract/catalog_contract.dart';
import 'package:rekluti_test/modules/catalog/domain/search_term.dart';
import 'package:rekluti_test/shared/errors/failure.dart';

/// Keeps the stored search terms in step with what is on screen.
class SearchHistoryBloc extends Bloc<SearchHistoryEvent, SearchHistoryState> {
  SearchHistoryBloc(this._catalog) : super(const SearchHistoryLoading()) {
    // Sequential rather than concurrent: a delete followed by a reload has to
    // happen in that order, or the reload could read the row back.
    on<SearchHistoryRequested>(_onRequested, transformer: sequential());
    on<SearchHistoryTermForgotten>(_onForgotten, transformer: sequential());
    on<SearchHistoryCleared>(_onCleared, transformer: sequential());
  }

  final CatalogContract _catalog;

  Future<void> _onRequested(
    SearchHistoryRequested event,
    Emitter<SearchHistoryState> emit,
  ) async {
    try {
      final List<SearchTerm> terms = await _catalog.recentSearches();
      emit(SearchHistoryLoaded(terms));
    } on Failure {
      emit(const SearchHistoryUnavailable());
    }
  }

  Future<void> _onForgotten(
    SearchHistoryTermForgotten event,
    Emitter<SearchHistoryState> emit,
  ) async {
    try {
      await _catalog.forgetSearch(event.term);
    } on Failure {
      // Nothing was removed, so the reload below simply shows it still there.
    }
    await _onRequested(const SearchHistoryRequested(), emit);
  }

  Future<void> _onCleared(
    SearchHistoryCleared event,
    Emitter<SearchHistoryState> emit,
  ) async {
    try {
      await _catalog.clearSearches();
    } on Failure {
      // Same reasoning as forgetting a single term.
    }
    await _onRequested(const SearchHistoryRequested(), emit);
  }
}
