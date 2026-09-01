import 'package:flutter/material.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_typography.dart';
import 'package:rekluti_test/modules/catalog/domain/search_term.dart';

/// The previously searched terms, offered as one tap each.
class HistoryChips extends StatelessWidget {
  const HistoryChips({
    required this.terms,
    required this.onSelected,
    super.key,
  });

  final List<SearchTerm> terms;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: terms
          .map(
            (SearchTerm entry) => ActionChip(
              label: Text(entry.term, style: AppTypography.label),
              onPressed: () => onSelected(entry.term),
              backgroundColor: AppColors.peach,
              side: BorderSide.none,
              // Chips are drawn at 40; padding the tap target keeps them
              // reachable without changing the design.
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
          )
          .toList(),
    );
  }
}
