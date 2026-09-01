import 'package:rekluti_test/modules/catalog/domain/product.dart';

/// What the favourites bloc is allowed to ask for.
///
/// Kept apart from the search contract rather than added to it: a screen that
/// only draws hearts has no business being handed the ability to search.
abstract interface class FavoritesContract {
  /// Every favourite, most recently saved first.
  Future<List<Product>> favorites();

  /// Marks [product] as a favourite.
  Future<void> addFavorite(Product product);

  /// Removes the favourite with [id].
  Future<void> removeFavorite(String id);
}
