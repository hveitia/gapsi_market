import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_theme.dart';
import 'package:rekluti_test/configs/theme/app_typography.dart';
import 'package:rekluti_test/modules/auth/bloc/auth_bloc.dart';
import 'package:rekluti_test/modules/auth/bloc/auth_state.dart';
import 'package:rekluti_test/modules/auth/presenter/auth_routes.dart';

/// The way back to the landing screen for someone browsing without an account.
///
/// Choosing to explore without signing in should not be a one way door: the
/// catalogue is open to everyone, but the offer to create an account has to
/// stay reachable afterwards.
///
/// It renders nothing once there is a session, so the same slot needs no
/// condition around it.
class SignInPrompt extends StatelessWidget {
  const SignInPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    final bool signedOut = context.watch<AuthBloc>().state is AuthSignedOut;
    if (!signedOut) {
      return const SizedBox.shrink();
    }

    return TextButton.icon(
      onPressed: () => context.go(AuthRoutePaths.landing),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        backgroundColor: AppColors.peach,
        minimumSize: const Size(0, AppShapes.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: const StadiumBorder(),
      ),
      icon: Icon(
        PhosphorIcons.signIn(PhosphorIconsStyle.bold),
        size: 16,
        color: AppColors.accent,
      ),
      label: Text(
        'Iniciar sesión',
        style: AppTypography.label.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
