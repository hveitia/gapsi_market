import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_theme.dart';
import 'package:rekluti_test/configs/theme/app_typography.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';
import 'package:rekluti_test/modules/catalog/presenter/catalog_formats.dart';
import 'package:rekluti_test/modules/catalog/presenter/widgets/favorite_heart.dart';

/// One product in the results list.
///
/// Shows the three fields the exercise asks for: title, price and thumbnail.
class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, required this.onTap, super.key});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          '${product.title}. '
          '${CatalogFormats.price(product.price, product.currency)}',
      // The title and price are already spoken by this label, so repeating the
      // children would read the same thing twice. The heart is not merged in:
      // it is a separate control and has to stay reachable on its own.
      container: true,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ProductThumbnail(url: product.thumbnailUrl, size: 82),
                const SizedBox(width: 14),
                Expanded(child: _details()),
                FavoriteHeart(product: product),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _details() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          product.title,
          style: AppTypography.label.copyWith(fontSize: 15),
          // Titles run long. Two lines with an ellipsis keeps every card the
          // same height without a fixed height that would clip larger text.
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Flexible(
              child: Text(
                CatalogFormats.price(product.price, product.currency),
                style: AppTypography.titleSm.copyWith(
                  color: product.price == null
                      ? AppColors.inkMuted
                      : AppColors.ink,
                  fontSize: product.price == null ? 13 : 19,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (product.rating != null) ...<Widget>[
              const SizedBox(width: 10),
              Text(
                '★ ${CatalogFormats.rating(product.rating)}',
                style: AppTypography.meta,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// A product image with the placeholder the design calls for.
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({
    required this.url,
    required this.size,
    this.radius = AppShapes.tileRadius,
    super.key,
  });

  final String? url;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.square(
        dimension: size,
        child: url == null
            ? const _ThumbnailPlaceholder()
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                // Both fall back to the same tile: a broken image and a missing
                // one look identical to the user, so they should look the same.
                placeholder: (BuildContext context, String _) =>
                    const _ThumbnailPlaceholder(),
                errorWidget: (BuildContext context, String _, Object _) =>
                    const _ThumbnailPlaceholder(),
              ),
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.peach, AppColors.peachDeep],
        ),
      ),
    );
  }
}
