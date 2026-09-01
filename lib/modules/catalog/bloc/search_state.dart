import 'package:equatable/equatable.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';
import 'package:rekluti_test/shared/errors/failure.dart';

/// Where the loading of an additional page stands.
///
/// It lives inside [SearchResults] rather than being a state of its own. That
/// is what makes the exercise's rule structural: a page that fails cannot
/// replace the results already on screen, because the failure is a field of the
/// state that holds them.
sealed class PageLoad extends Equatable {
  const PageLoad();

  @override
  List<Object?> get props => <Object?>[];
}

/// Nothing is being loaded.
final class PageIdle extends PageLoad {
  const PageIdle();
}

/// Another page is on its way.
final class PageLoading extends PageLoad {
  const PageLoading();
}

/// The last attempt at another page failed. The loaded results are untouched.
final class PageFailed extends PageLoad {
  const PageFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => <Object?>[failure];
}

/// The situations a search can be in: nothing searched yet, loading, results,
/// no results, or an error.
sealed class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => <Object?>[];
}

/// No search is active. The home screen shows history and suggestions.
final class SearchIdle extends SearchState {
  const SearchIdle();
}

/// The first page for [term] is on its way.
final class SearchLoading extends SearchState {
  const SearchLoading(this.term);

  final String term;

  @override
  List<Object?> get props => <Object?>[term];
}

/// [term] returned nothing.
final class SearchEmpty extends SearchState {
  const SearchEmpty(this.term);

  final String term;

  @override
  List<Object?> get props => <Object?>[term];
}

/// The first page failed, so there is nothing to show at all.
final class SearchFailed extends SearchState {
  const SearchFailed({required this.term, required this.failure});

  final String term;
  final Failure failure;

  @override
  List<Object?> get props => <Object?>[term, failure];
}

/// Results are on screen.
final class SearchResults extends SearchState {
  const SearchResults({
    required this.term,
    required this.products,
    required this.page,
    this.hasReachedEnd = false,
    this.pageLoad = const PageIdle(),
    this.maxPage,
    this.totalResults,
  });

  final String term;
  final List<Product> products;

  /// The last page successfully merged in.
  final int page;

  /// Whether asking for more would be pointless.
  final bool hasReachedEnd;

  /// The state of an additional page, if one was asked for.
  final PageLoad pageLoad;

  /// Ceiling the service reported, used only as a safety cap.
  final int? maxPage;

  final int? totalResults;

  /// Whether another page may be requested right now.
  ///
  /// Both conditions are the exercise's rule: never ask twice at the same time,
  /// and never ask once the results have run out.
  bool get canLoadMore => !hasReachedEnd && pageLoad is! PageLoading;

  SearchResults copyWith({
    List<Product>? products,
    int? page,
    bool? hasReachedEnd,
    PageLoad? pageLoad,
  }) {
    return SearchResults(
      term: term,
      products: products ?? this.products,
      page: page ?? this.page,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      pageLoad: pageLoad ?? this.pageLoad,
      maxPage: maxPage,
      totalResults: totalResults,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    term,
    products,
    page,
    hasReachedEnd,
    pageLoad,
    maxPage,
    totalResults,
  ];
}
