import 'package:equatable/equatable.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';

/// The stored favourites.
sealed class FavoritesState extends Equatable {
  const FavoritesState();

  /// Whether [id] is a favourite right now.
  ///
  /// Defined on the base class so a heart can ask without first checking which
  /// state it is looking at. Anything other than loaded answers no, which is
  /// the safe reading: an unfilled heart still toggles.
  bool contains(String id) => false;

  @override
  List<Object?> get props => <Object?>[];
}

/// Not read yet.
final class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

/// The stored products. An empty list is a normal answer.
final class FavoritesLoaded extends FavoritesState {
  FavoritesLoaded(this.products)
    : _ids = products.map((Product p) => p.id).toSet();

  final List<Product> products;

  /// Derived once, so the list of results can check every card in constant
  /// time instead of scanning the favourites for each one.
  final Set<String> _ids;

  bool get isEmpty => products.isEmpty;

  @override
  bool contains(String id) => _ids.contains(id);

  @override
  List<Object?> get props => <Object?>[products];
}

/// The favourites could not be read.
final class FavoritesUnavailable extends FavoritesState {
  const FavoritesUnavailable();
}
