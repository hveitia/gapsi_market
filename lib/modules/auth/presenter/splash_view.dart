import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_typography.dart';

/// Shown while the stored session is being read.
///
/// Its only job is to keep the landing screen from flashing in front of a user
/// who is about to be let straight in.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[AppColors.accent, AppColors.accentDark],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.onAccent,
                  borderRadius: BorderRadius.circular(34),
                ),
                child: Icon(
                  PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
                  color: AppColors.accent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Mercado',
                style: AppTypography.display.copyWith(
                  color: AppColors.onAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Busca millones de productos',
                style: AppTypography.body.copyWith(
                  color: AppColors.onAccent.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
