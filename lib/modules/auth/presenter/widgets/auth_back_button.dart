import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_theme.dart';

/// The peach tile that takes the user back a screen.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.peach,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox.square(
            // Larger than the 46 the specification draws, to clear the minimum
            // touch target.
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
    );
  }
}
