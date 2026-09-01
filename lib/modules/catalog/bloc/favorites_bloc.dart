import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rekluti_test/modules/catalog/bloc/favorites_event.dart';
import 'package:rekluti_test/modules/catalog/bloc/favorites_state.dart';
import 'package:rekluti_test/modules/catalog/contract/favorites_contract.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';
import 'package:rekluti_test/shared/errors/failure.dart';

/// Holds the favourites and the state of every heart in the app.
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  FavoritesBloc(this._favorites) : super(const FavoritesLoading()) {
    // Sequential: tapping a heart twice quickly has to be applied in order, or
    // the second write could land before the first and leave the wrong result.
    on<FavoritesRequested>(_onRequested, transformer: sequential());
    on<FavoriteToggled>(_onToggled, transformer: sequential());
  }

  final FavoritesContract _favorites;

  Future<void> _onRequested(
    FavoritesRequested event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      emit(FavoritesLoaded(await _favorites.favorites()));
    } on Failure {
      emit(const FavoritesUnavailable());
    }
  }

  Future<void> _onToggled(
    FavoriteToggled event,
    Emitter<FavoritesState> emit,
  ) async {
    final Product product = event.product;
    final bool wasFavorite = state.contains(product.id);

    try {
      if (wasFavorite) {
        await _favorites.removeFavorite(product.id);
      } else {
        await _favorites.addFavorite(product);
      }
    } on Failure {
      // The write did not happen, so the reload below leaves the heart exactly
      // as it was rather than showing a change that was never stored.
    }

    await _onRequested(const FavoritesRequested(), emit);
  }
}
