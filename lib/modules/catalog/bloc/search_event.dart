import 'package:equatable/equatable.dart';

/// Everything that can move a search forward.
sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The text in the search field changed.
///
/// Emitted on every keystroke. The bloc debounces it, so typing does not turn
/// into one request per character.
final class SearchTermChanged extends SearchEvent {
  const SearchTermChanged(this.term);

  final String term;

  @override
  List<Object?> get props => <Object?>[term];
}

/// The list scrolled close enough to the bottom to want more.
final class SearchNextPageRequested extends SearchEvent {
  const SearchNextPageRequested();
}

/// The user asked to try again after something failed.
final class SearchRetryRequested extends SearchEvent {
  const SearchRetryRequested();
}

/// The search field was emptied.
final class SearchCleared extends SearchEvent {
  const SearchCleared();
}
