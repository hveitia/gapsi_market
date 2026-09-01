import 'package:flutter/material.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_theme.dart';
import 'package:rekluti_test/configs/theme/app_typography.dart';

/// The centred block the empty and error screens are both built from.
///
/// One widget rather than two similar ones: they differ in colour, icon and
/// wording, never in shape.
class CatalogMessage extends StatelessWidget {
  const CatalogMessage({
    required this.icon,
    required this.title,
    required this.detail,
    this.tone = CatalogMessageTone.neutral,
    this.suggestions = const <String>[],
    this.onSuggestionTap,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.code,
    super.key,
  });

  final IconData icon;
  final String title;
  final String detail;
  final CatalogMessageTone tone;

  /// Terms offered as a way out of an empty result.
  final List<String> suggestions;
  final ValueChanged<String>? onSuggestionTap;

  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Technical detail, shown small and last.
  final String? code;

  @override
  Widget build(BuildContext context) {
    final bool isError = tone == CatalogMessageTone.error;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppShapes.screenPadding,
          vertical: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: isError ? AppColors.dangerBg : AppColors.peach,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                icon,
                size: 46,
                color: isError ? AppColors.dangerFg : const Color(0xFFD99A6C),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTypography.titleLg,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              detail,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            if (suggestions.isNotEmpty) ...<Widget>[
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: suggestions
                    .map(
                      (String term) => ActionChip(
                        label: Text(term, style: AppTypography.label),
                        onPressed: () => onSuggestionTap?.call(term),
                        backgroundColor: AppColors.cream,
                        side: const BorderSide(color: AppColors.hairline),
                        // Chips sit below the 48 minimum, so the tap area is
                        // padded out to reach it.
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (onAction != null) ...<Widget>[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent,
                  minimumSize: const Size(180, 52),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  actionLabel!,
                  style: AppTypography.label.copyWith(
                    color: AppColors.onAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
            if (onSecondary != null) ...<Widget>[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onSecondary,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size(180, 52),
                  side: const BorderSide(color: AppColors.hairline),
                  shape: const StadiumBorder(),
                ),
                child: Text(secondaryLabel!, style: AppTypography.label),
              ),
            ],
            if (code != null) ...<Widget>[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Text(
                  code!,
                  style: AppTypography.meta.copyWith(color: AppColors.dangerFg),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Whether the block reads as information or as a problem.
enum CatalogMessageTone { neutral, error }
