import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_theme.dart';
import 'package:rekluti_test/configs/theme/app_typography.dart';
import 'package:rekluti_test/modules/catalog/bloc/search_state.dart';
import 'package:rekluti_test/modules/catalog/presenter/catalog_messages.dart';

/// What sits under the last product while more are being fetched.
///
/// The failure case is a banner rather than a screen: the results above it stay
/// exactly where they were, which is the behaviour the exercise asks for.
class PaginationFooter extends StatelessWidget {
  const PaginationFooter({
    required this.state,
    required this.onRetry,
    super.key,
  });

  final SearchResults state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state.pageLoad) {
      PageLoading() => _Loading(page: state.page + 1),
      final PageFailed failed => _Failed(
        page: state.page + 1,
        detail: CatalogMessages.title(failed.failure),
        onRetry: onRetry,
      ),
      PageIdle() when state.hasReachedEnd => const _End(),
      PageIdle() => const SizedBox(height: 8),
    };
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.page});

  final int page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AppColors.accent,
              backgroundColor: AppColors.peach,
            ),
          ),
          const SizedBox(width: 12),
          Text('Cargando página $page', style: AppTypography.meta),
        ],
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({
    required this.page,
    required this.detail,
    required this.onRetry,
  });

  final int page;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.dangerBg,
          borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              PhosphorIcons.warningCircle(PhosphorIconsStyle.duotone),
              color: AppColors.dangerFg,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    CatalogMessages.pageFailed(page),
                    style: AppTypography.label.copyWith(
                      color: AppColors.dangerFg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Los resultados anteriores se conservan.',
                    style: AppTypography.meta.copyWith(
                      color: AppColors.dangerFg,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.dangerFg,
                foregroundColor: AppColors.onAccent,
                minimumSize: const Size(96, AppShapes.minTouchTarget),
                shape: const StadiumBorder(),
              ),
              child: Text(
                'Reintentar',
                style: AppTypography.label.copyWith(
                  color: AppColors.onAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _End extends StatelessWidget {
  const _End();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Center(
        child: Text(
          'No hay más resultados',
          style: AppTypography.meta,
        ),
      ),
    );
  }
}
