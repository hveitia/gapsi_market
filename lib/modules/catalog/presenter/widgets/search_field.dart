import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_theme.dart';
import 'package:rekluti_test/configs/theme/app_typography.dart';

/// The search field.
///
/// While a search is running the clear button becomes a spinner, which is the
/// only progress indicator the results list needs while it still holds the
/// previous page.
class SearchField extends StatelessWidget {
  const SearchField({
    required this.controller,
    required this.onChanged,
    required this.onCleared,
    this.isSearching = false,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onCleared;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppTypography.label.copyWith(fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Busca un producto...',
        hintStyle: AppTypography.label.copyWith(
          fontSize: 15,
          color: AppColors.inkMuted,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        prefixIcon: Icon(
          PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
          color: AppColors.accent,
          size: 20,
        ),
        suffixIcon: _suffix(),
        border: _border,
        enabledBorder: _border,
        focusedBorder: _border,
      ),
    );
  }

  Widget? _suffix() {
    if (isSearching) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: AppColors.accent,
            backgroundColor: AppColors.peach,
          ),
        ),
      );
    }
    if (controller.text.isEmpty) {
      return null;
    }
    return IconButton(
      onPressed: onCleared,
      tooltip: 'Borrar la búsqueda',
      icon: Icon(
        PhosphorIcons.x(PhosphorIconsStyle.bold),
        size: 16,
        color: AppColors.inkSoft,
      ),
    );
  }

  static final OutlineInputBorder _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppShapes.pillRadius),
    borderSide: BorderSide.none,
  );
}
