import 'package:dio/dio.dart';
import 'package:rekluti_test/modules/catalog/domain/product_page.dart';

/// Reads pages of products from the catalogue service.
abstract interface class CatalogRemoteDataSource {
  /// Fetches one page of results for [keyword].
  ///
  /// [cancelToken] lets the caller abandon a request that is no longer wanted,
  /// which is what a debounced search relies on: without it a slow response for
  /// an old term could land after a newer one and overwrite it.
  ///
  /// Throws a `Failure`; never a transport exception.
  Future<ProductPage> search({
    required String keyword,
    required int page,
    CancelToken? cancelToken,
  });
}
