import 'package:equatable/equatable.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';

/// One page of search results.
class ProductPage extends Equatable {
  const ProductPage({
    required this.products,
    required this.page,
    this.maxPage,
    this.totalResults,
  });

  final List<Product> products;

  /// The page number these products came from.
  final int page;

  /// The ceiling the service reported, when it reported one.
  ///
  /// Treated as a hint, never as the end condition: the same search reports 14
  /// on its first page and 1 on its fourteenth. [hasReachedEnd] is what decides.
  final int? maxPage;

  /// Total matches the service claims. It drifts between pages, so it is only
  /// good enough to show, not to paginate with.
  final int? totalResults;

  /// Whether the catalogue has nothing more to give.
  ///
  /// Derived from the page being empty rather than from the payload's
  /// `hasMorePages` flag, which reads false even on the first page of fourteen.
  bool get hasReachedEnd => products.isEmpty;

  @override
  List<Object?> get props => <Object?>[products, page, maxPage, totalResults];
}
