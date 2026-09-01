import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_theme.dart';
import 'package:rekluti_test/configs/theme/app_typography.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';
import 'package:rekluti_test/modules/catalog/presenter/catalog_formats.dart';
import 'package:rekluti_test/modules/catalog/presenter/widgets/favorite_heart.dart';
import 'package:rekluti_test/modules/catalog/presenter/widgets/product_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// Everything known about one product.
///
/// It performs no request. The exercise specifies a single service, and the
/// search response already carries the title, price, image and description this
/// screen needs, so the product travels here with the navigation. The screen
/// opens instantly and keeps working with the network down.
class ProductDetailView extends StatelessWidget {
  const ProductDetailView({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(child: _Hero(product: product)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppShapes.screenPadding,
              22,
              AppShapes.screenPadding,
              32,
            ),
            sliver: SliverList.list(children: _details(context)),
          ),
        ],
      ),
      bottomNavigationBar: _StoreBar(product: product),
    );
  }

  List<Widget> _details(BuildContext context) {
    return <Widget>[
      Text(product.title, style: AppTypography.titleLg),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Flexible(
            child: Text(
              CatalogFormats.price(product.price, product.currency),
              style: AppTypography.display.copyWith(
                color: product.price == null
                    ? AppColors.inkMuted
                    : AppColors.accent,
                fontSize: product.price == null ? 20 : 34,
              ),
            ),
          ),
          if (product.rating != null) ...<Widget>[
            const SizedBox(width: 12),
            Text(
              '★ ${CatalogFormats.rating(product.rating)}'
              '${product.reviewCount == null ? '' : ' (${product.reviewCount})'}',
              style: AppTypography.meta,
            ),
          ],
        ],
      ),
      const SizedBox(height: 20),
      Text(
        // Roughly one product in six has no description at all, so saying so is
        // a real state rather than an edge case.
        product.description ?? 'Este producto no incluye descripción.',
        style: AppTypography.body.copyWith(
          height: 1.7,
          fontStyle: product.description == null
              ? FontStyle.italic
              : FontStyle.normal,
        ),
      ),
    ];
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(42),
            ),
            child: ProductThumbnail(
              url: product.imageUrl ?? product.thumbnailUrl,
              size: double.infinity,
              radius: 0,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppShapes.screenPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Material(
                    color: AppColors.onAccent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      customBorder: const CircleBorder(),
                      child: SizedBox.square(
                        dimension: AppShapes.minTouchTarget,
                        child: Icon(
                          PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                          color: AppColors.ink,
                          size: 20,
                          semanticLabel: 'Volver',
                        ),
                      ),
                    ),
                  ),
                  FavoriteHeart(
                    product: product,
                    background: AppColors.onAccent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreBar extends StatelessWidget {
  const _StoreBar({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final String? url = product.productUrl;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppShapes.screenPadding,
        0,
        AppShapes.screenPadding,
        16,
      ),
      child: FilledButton(
        // Disabled rather than hidden when there is no link: a button that
        // comes and goes is harder to trust than one that is plainly inert.
        onPressed: url == null ? null : () => _open(context, url),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          disabledBackgroundColor: AppColors.peachDeep,
          minimumSize: const Size.fromHeight(60),
          shape: const StadiumBorder(),
        ),
        child: Text(
          'Ver en la tienda',
          style: AppTypography.label.copyWith(
            color: AppColors.onAccent,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la tienda')),
      );
    }
  }
}
