import 'package:equatable/equatable.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';

/// What can change the favourites.
sealed class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Load, or reload, what is stored.
final class FavoritesRequested extends FavoritesEvent {
  const FavoritesRequested();
}

/// Add the product if it is not a favourite, remove it if it is.
///
/// One event rather than two, because the heart is one control and the caller
/// should not have to know which way it is currently pointing.
final class FavoriteToggled extends FavoritesEvent {
  const FavoriteToggled(this.product);

  final Product product;

  @override
  List<Object?> get props => <Object?>[product];
}
