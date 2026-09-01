import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_theme.dart';
import 'package:rekluti_test/configs/theme/app_typography.dart';
import 'package:rekluti_test/modules/auth/bloc/auth_bloc.dart';
import 'package:rekluti_test/modules/auth/bloc/auth_event.dart';
import 'package:rekluti_test/modules/auth/bloc/auth_state.dart';
import 'package:rekluti_test/modules/auth/domain/user.dart';
import 'package:rekluti_test/modules/auth/presenter/auth_routes.dart';

/// The account control in the home header: a way in, or a way out.
///
/// Both ends of the session are reachable from the same place. Choosing to
/// browse without an account is not a one way door, and neither is signing in:
/// an app that can only be entered is one you have to reinstall to leave.
class AuthHeaderAction extends StatelessWidget {
  const AuthHeaderAction({super.key});

  @override
  Widget build(BuildContext context) {
    return switch (context.watch<AuthBloc>().state) {
      AuthSignedOut() => const _SignInButton(),
      final AuthSignedIn signedIn => _AccountMenu(user: signedIn.user),
      // Nothing while the stored session is still being read: offering to sign
      // in to someone who already has a session would flicker away.
      AuthUnknown() => const SizedBox.shrink(),
    };
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton();

  @override
  Widget build(BuildContext context) {
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

/// What the account menu offers.
///
/// A real value rather than `void`: PopupMenuButton reads a null selection as a
/// dismissal and never calls onSelected, so an item without one is inert.
enum _AccountAction { signOut }

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.user});

  final User user;

  /// The first word is enough to recognise yourself, and a full name would push
  /// the greeting off the header.
  String get _shortName => user.name.trim().split(' ').first;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AccountAction>(
      // A menu rather than a button that signs out on the spot: it sits next to
      // the greeting, where a mistaken tap would otherwise end the session.
      tooltip: 'Cuenta de $_shortName',
      position: PopupMenuPosition.under,
      onSelected: (_AccountAction _) =>
          context.read<AuthBloc>().add(const AuthSignOutRequested()),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<_AccountAction>>[
        PopupMenuItem<_AccountAction>(
          value: _AccountAction.signOut,
          child: Row(
            children: <Widget>[
              Icon(
                PhosphorIcons.signOut(PhosphorIconsStyle.bold),
                size: 18,
                color: AppColors.dangerFg,
              ),
              const SizedBox(width: 10),
              Text(
                'Cerrar sesión',
                style: AppTypography.label.copyWith(color: AppColors.dangerFg),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppShapes.minTouchTarget,
          maxWidth: 150,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: const BoxDecoration(
          color: AppColors.peach,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Text(
                _shortName,
                style: AppTypography.label.copyWith(
                  color: AppColors.accentDark,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
              size: 14,
              color: AppColors.accentDark,
            ),
          ],
        ),
      ),
    );
  }
}
