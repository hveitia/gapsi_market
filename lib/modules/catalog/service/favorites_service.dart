import 'package:rekluti_test/modules/catalog/contract/favorites_contract.dart';
import 'package:rekluti_test/modules/catalog/contract/favorites_datasource.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';
import 'package:rekluti_test/shared/errors/failure.dart';

/// Favourites on local storage.
class FavoritesService implements FavoritesContract {
  const FavoritesService(this._favorites);

  final FavoritesDataSource _favorites;

  @override
  Future<List<Product>> favorites() => _guard(_favorites.all);

  @override
  Future<void> addFavorite(Product product) =>
      _guard(() => _favorites.save(product));

  @override
  Future<void> removeFavorite(String id) =>
      _guard(() => _favorites.remove(id));

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw StorageFailure(debugMessage: error.toString());
    }
  }
}
