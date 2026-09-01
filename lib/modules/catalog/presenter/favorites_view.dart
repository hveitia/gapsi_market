import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_theme.dart';
import 'package:rekluti_test/configs/theme/app_typography.dart';
import 'package:rekluti_test/modules/catalog/bloc/favorites_bloc.dart';
import 'package:rekluti_test/modules/catalog/bloc/favorites_event.dart';
import 'package:rekluti_test/modules/catalog/bloc/favorites_state.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';
import 'package:rekluti_test/modules/catalog/presenter/catalog_formats.dart';
import 'package:rekluti_test/modules/catalog/presenter/widgets/catalog_message.dart';
import 'package:rekluti_test/modules/catalog/presenter/widgets/favorite_heart.dart';
import 'package:rekluti_test/modules/catalog/presenter/widgets/product_card.dart';
import 'package:rekluti_test/shared/widgets/responsive.dart';

/// The products saved on this device.
class FavoritesView extends StatelessWidget {
  const FavoritesView({required this.onProductSelected, super.key});

  final void Function(BuildContext context, Product product) onProductSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<FavoritesBloc, FavoritesState>(
          builder: (BuildContext context, FavoritesState state) {
            return switch (state) {
              FavoritesLoading() => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              FavoritesUnavailable() => CatalogMessage(
                icon: PhosphorIcons.warningCircle(PhosphorIconsStyle.duotone),
                title: 'No pudimos leer tus favoritos',
                detail:
                    'El almacenamiento local no respondió. Tus productos '
                    'guardados siguen ahí; vuelve a intentarlo.',
                tone: CatalogMessageTone.error,
                actionLabel: 'Reintentar',
                onAction: () => context.read<FavoritesBloc>().add(
                  const FavoritesRequested(),
                ),
              ),
              final FavoritesLoaded loaded when loaded.isEmpty =>
                CatalogMessage(
                  icon: PhosphorIcons.heart(PhosphorIconsStyle.duotone),
                  title: 'Aún no guardas productos',
                  detail:
                      'Toca el corazón de cualquier producto para guardarlo. '
                      'Los favoritos se conservan al cerrar la aplicación.',
                ),
              final FavoritesLoaded loaded => _grid(context, loaded.products),
            };
          },
        ),
      ),
    );
  }

  Widget _grid(BuildContext context, List<Product> products) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverContentWidth(
          sliver: SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppShapes.screenPadding,
              8,
              AppShapes.screenPadding,
              18,
            ),
            sliver: SliverToBoxAdapter(child: _header(products.length)),
          ),
        ),
        SliverContentWidth(
          sliver: SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppShapes.screenPadding,
              0,
              AppShapes.screenPadding,
              100,
            ),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                // A maximum width rather than a fixed column count, so a wider
                // screen gets more columns instead of stretched cards.
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.68,
              ),
              itemCount: products.length,
              itemBuilder: (BuildContext context, int index) => _FavoriteCard(
                product: products[index],
                onTap: () => onProductSelected(context, products[index]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Favoritos', style: AppTypography.display),
        Text(
          count == 1
              ? '1 producto guardado en este dispositivo'
              : '$count productos guardados en este dispositivo',
          style: AppTypography.meta,
        ),
      ],
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Stack(
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: ProductThumbnail(
                      url: product.thumbnailUrl,
                      size: 104,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: FavoriteHeart(
                      product: product,
                      background: AppColors.surface,
                      onRemoved: () => _offerUndo(context, product),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  product.title,
                  style: AppTypography.label.copyWith(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                CatalogFormats.price(product.price, product.currency),
                style: AppTypography.titleSm.copyWith(
                  color: product.price == null
                      ? AppColors.inkMuted
                      : AppColors.accent,
                  fontSize: product.price == null ? 12 : 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Removing a favourite is one tap and easy to do by accident, so it comes
  /// with a way back rather than a confirmation that would slow down the times
  /// it was deliberate.
  void _offerUndo(BuildContext context, Product removed) {
    final FavoritesBloc bloc = context.read<FavoritesBloc>();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Se quitó de favoritos'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => bloc.add(FavoriteToggled(removed)),
          ),
        ),
      );
  }
}
