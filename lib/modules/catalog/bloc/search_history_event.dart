import 'package:equatable/equatable.dart';

/// What can change the stored history.
sealed class SearchHistoryEvent extends Equatable {
  const SearchHistoryEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Load, or reload, the stored terms.
///
/// Dispatched on startup and again after a search, which is what keeps the
/// chips in step without the history bloc having to know the search bloc.
final class SearchHistoryRequested extends SearchHistoryEvent {
  const SearchHistoryRequested();
}

/// Remove a single term.
final class SearchHistoryTermForgotten extends SearchHistoryEvent {
  const SearchHistoryTermForgotten(this.term);

  final String term;

  @override
  List<Object?> get props => <Object?>[term];
}

/// Remove every term.
final class SearchHistoryCleared extends SearchHistoryEvent {
  const SearchHistoryCleared();
}
