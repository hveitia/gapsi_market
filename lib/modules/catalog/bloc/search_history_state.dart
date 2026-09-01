import 'package:equatable/equatable.dart';
import 'package:rekluti_test/modules/catalog/domain/search_term.dart';

/// The stored search history.
sealed class SearchHistoryState extends Equatable {
  const SearchHistoryState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Not read yet.
final class SearchHistoryLoading extends SearchHistoryState {
  const SearchHistoryLoading();
}

/// The stored terms, newest first. An empty list is a valid, normal answer.
final class SearchHistoryLoaded extends SearchHistoryState {
  const SearchHistoryLoaded(this.terms);

  final List<SearchTerm> terms;

  bool get isEmpty => terms.isEmpty;

  @override
  List<Object?> get props => <Object?>[terms];
}

/// The history could not be read.
///
/// Its own state rather than an empty list: telling the user their history is
/// gone when it is only unreadable would be a lie.
final class SearchHistoryUnavailable extends SearchHistoryState {
  const SearchHistoryUnavailable();
}
