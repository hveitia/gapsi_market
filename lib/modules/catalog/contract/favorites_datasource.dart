import 'package:rekluti_test/modules/catalog/domain/product.dart';

/// Stores the products the user marked as favourites.
abstract interface class FavoritesDataSource {
  /// Every favourite, most recently saved first.
  Future<List<Product>> all();

  /// Saves [product], replacing any earlier copy of it.
  Future<void> save(Product product);

  /// Removes the favourite with [id]. Does nothing if there is none.
  Future<void> remove(String id);
}
