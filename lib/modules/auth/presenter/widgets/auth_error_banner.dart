import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_theme.dart';
import 'package:rekluti_test/configs/theme/app_typography.dart';

/// The banner shown when a submission comes back rejected.
///
/// Marked as a live region so a screen reader announces it when it appears:
/// otherwise someone not looking at the screen gets no feedback at all.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.dangerBg,
          borderRadius: BorderRadius.circular(AppShapes.tileRadius + 2),
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
              child: Text(
                message,
                style: AppTypography.label.copyWith(
                  color: AppColors.dangerFg,
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
