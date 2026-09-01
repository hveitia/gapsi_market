import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_theme.dart';
import 'package:rekluti_test/configs/theme/app_typography.dart';

/// A labelled pill shaped text field, as the specification draws it.
///
/// Owns the reveal toggle for passwords so no screen has to track it.
class AuthField extends StatefulWidget {
  const AuthField({
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.validator,
    this.onSubmitted,
    this.helper,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final List<String>? autofillHints;
  final String? Function(String?)? validator;
  final VoidCallback? onSubmitted;
  final String? helper;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.pillRadius),
      borderSide: const BorderSide(
        color: AppColors.hairline,
        width: AppShapes.hairlineWidth,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 7),
          child: Text(widget.label.toUpperCase(), style: AppTypography.kicker),
        ),
        TextFormField(
          controller: widget.controller,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          // Lets a password manager fill the form instead of the user retyping.
          autofillHints: widget.autofillHints,
          validator: widget.validator,
          onFieldSubmitted: (_) => widget.onSubmitted?.call(),
          style: AppTypography.label,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTypography.label.copyWith(color: AppColors.inkMuted),
            helperText: widget.helper,
            helperStyle: AppTypography.meta,
            filled: true,
            fillColor: AppColors.surface,
            // Padding rather than a fixed height, so the field grows with the
            // system text size instead of clipping.
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
            ),
            errorBorder: border.copyWith(
              borderSide: const BorderSide(
                color: AppColors.dangerFg,
                width: AppShapes.hairlineWidth,
              ),
            ),
            focusedErrorBorder: border.copyWith(
              borderSide: const BorderSide(color: AppColors.dangerFg, width: 2),
            ),
            errorStyle: AppTypography.meta.copyWith(color: AppColors.dangerFg),
            suffixIcon: widget.obscure ? _revealToggle() : null,
          ),
        ),
      ],
    );
  }

  Widget _revealToggle() {
    return IconButton(
      onPressed: () {
        HapticFeedback.selectionClick();
        setState(() => _hidden = !_hidden);
      },
      tooltip: _hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
      icon: Icon(
        _hidden
            ? PhosphorIcons.eye(PhosphorIconsStyle.duotone)
            : PhosphorIcons.eyeSlash(PhosphorIconsStyle.duotone),
        color: AppColors.inkMuted,
        size: 20,
      ),
    );
  }
}
