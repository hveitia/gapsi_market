import 'package:flutter/material.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_theme.dart';

/// The placeholder cards shown while the first page loads.
///
/// A skeleton rather than a spinner: it shows how many results are coming and
/// where they will land, so the list does not jump when they arrive.
class ProductSkeletonList extends StatelessWidget {
  const ProductSkeletonList({this.count = 4, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Buscando productos',
      child: Column(
        children: List<Widget>.generate(
          count,
          (int _) => const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: _SkeletonCard(),
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: AppColors.skeleton,
              borderRadius: BorderRadius.circular(AppShapes.tileRadius),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Bar(widthFactor: 1),
                SizedBox(height: 8),
                _Bar(widthFactor: 0.72),
                SizedBox(height: 14),
                _Bar(widthFactor: 0.42, height: 20, warm: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.widthFactor, this.height = 11, this.warm = false});

  final double widthFactor;
  final double height;
  final bool warm;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: warm ? AppColors.skeletonWarm : AppColors.skeleton,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}
