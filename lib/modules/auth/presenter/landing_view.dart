import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:rekluti_test/configs/router/app_router.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_theme.dart';
import 'package:rekluti_test/configs/theme/app_typography.dart';
import 'package:rekluti_test/modules/auth/presenter/auth_routes.dart';
import 'package:rekluti_test/modules/auth/presenter/widgets/auth_buttons.dart';

/// The first screen a signed out user meets.
///
/// Offers both accounts paths and a way past them: the catalogue works without
/// an account, and putting a wall in front of it would be friction with nothing
/// behind it.
class LandingView extends StatelessWidget {
  const LandingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppShapes.screenPadding,
            vertical: 24,
          ),
          child: Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 32),
                      _brand(),
                      const SizedBox(height: 26),
                      const _Highlights(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              PrimaryButton(
                label: 'Crear cuenta',
                onPressed: () => context.push(AuthRoutePaths.signUp),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Ya tengo cuenta',
                onPressed: () => context.push(AuthRoutePaths.signIn),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go(AppRoutePaths.home),
                child: Text(
                  'Explorar sin cuenta →',
                  style: AppTypography.label.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brand() {
    return Column(
      children: <Widget>[
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.peach,
            borderRadius: BorderRadius.circular(34),
          ),
          child: Icon(
            PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
            color: AppColors.accent,
            size: 42,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Mercado',
          style: AppTypography.display.copyWith(color: AppColors.accent),
        ),
        const SizedBox(height: 8),
        Text(
          'Busca millones de productos desde tu teléfono.',
          textAlign: TextAlign.center,
          style: AppTypography.body,
        ),
      ],
    );
  }
}

class _Highlights extends StatelessWidget {
  const _Highlights();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _Highlight(
          icon: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.duotone),
          label: 'Busca por marca o palabra clave',
        ),
        _Highlight(
          icon: PhosphorIcons.heart(PhosphorIconsStyle.duotone),
          label: 'Guarda tus favoritos',
        ),
        _Highlight(
          icon: PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.duotone),
          label: 'Tu historial, siempre disponible',
        ),
      ],
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.peach,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTypography.body)),
        ],
      ),
    );
  }
}
