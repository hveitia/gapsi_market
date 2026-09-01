import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_theme.dart';
import 'package:rekluti_test/modules/catalog/bloc/favorites_bloc.dart';
import 'package:rekluti_test/modules/catalog/bloc/favorites_event.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';

/// The heart that marks a product as a favourite.
///
/// It reads the favourites bloc itself rather than taking its value as a
/// parameter, so every heart in the app agrees without each screen having to
/// thread the state down to it.
class FavoriteHeart extends StatelessWidget {
  const FavoriteHeart({
    required this.product,
    this.onRemoved,
    this.background,
    super.key,
  });

  final Product product;

  /// Called after a product stops being a favourite, so a screen can offer to
  /// undo it.
  final VoidCallback? onRemoved;

  final Color? background;

  @override
  Widget build(BuildContext context) {
    final bool isFavorite = context.watch<FavoritesBloc>().state.contains(
      product.id,
    );

    return Semantics(
      // `toggled` is what tells a screen reader this is a switch rather than a
      // button that does something new each time.
      toggled: isFavorite,
      label: isFavorite ? 'Quitar de favoritos' : 'Guardar en favoritos',
      button: true,
      excludeSemantics: true,
      child: Material(
        color: background ?? Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            context.read<FavoritesBloc>().add(FavoriteToggled(product));
            if (isFavorite) {
              onRemoved?.call();
            }
          },
          child: SizedBox.square(
            dimension: AppShapes.minTouchTarget,
            child: Icon(
              PhosphorIcons.heart(
                isFavorite
                    ? PhosphorIconsStyle.fill
                    : PhosphorIconsStyle.regular,
              ),
              size: 20,
              color: isFavorite ? AppColors.accent : AppColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
