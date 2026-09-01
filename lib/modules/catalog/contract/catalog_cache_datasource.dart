import 'package:rekluti_test/modules/catalog/domain/product_page.dart';

/// Keeps pages of results on the device so a repeated search does not wait for
/// the service again.
abstract interface class CatalogCacheDataSource {
  /// The cached page, or `null` when there is none fresh enough.
  Future<ProductPage?> read({
    required String term,
    required int page,
    required Duration maxAge,
  });

  /// Stores [page], replacing any earlier copy of it.
  Future<void> write({required String term, required ProductPage page});

  /// Deletes everything older than [maxAge], so the table stays bounded.
  Future<void> evictExpired(Duration maxAge);
}
