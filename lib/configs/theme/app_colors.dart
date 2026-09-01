import 'package:flutter/material.dart';

/// The palette defined by the visual specification.
///
/// Named after their role rather than their hue, so a screen asks for
/// [hairline] instead of guessing which beige is the border one.
abstract final class AppColors {
  /// Screen background.
  static const Color cream = Color(0xFFFDF8F3);

  /// Neutral surface: inactive tiles.
  static const Color creamAlt = Color(0xFFF6EFE7);

  /// Cards.
  static const Color surface = Color(0xFFFFFFFF);

  /// Chips, tiles and soft badges.
  static const Color peach = Color(0xFFFBE8D8);
  static const Color peachDeep = Color(0xFFF5D1B4);

  /// Primary text, and the bottom navigation bar.
  static const Color ink = Color(0xFF2B1D16);

  /// Secondary text.
  static const Color inkSoft = Color(0xFF6B544A);

  /// Metadata.
  static const Color inkMuted = Color(0xFF8B7264);

  /// 1.5px borders.
  static const Color hairline = Color(0xFFE6CDB8);

  /// Terracotta: the primary action.
  static const Color accent = Color(0xFFC2410C);

  /// Pressed state, and text over [peach].
  static const Color accentDark = Color(0xFF7C2D12);

  /// Active item in the bottom navigation bar.
  static const Color accentSoft = Color(0xFFFFB27C);

  /// Text over [accent].
  static const Color onAccent = Color(0xFFFFF6EE);

  static const Color dangerBg = Color(0xFFF6DCD4);
  static const Color dangerFg = Color(0xFF8F2F1C);

  static const Color skeleton = Color(0xFFF2E6DC);
  static const Color skeletonWarm = Color(0xFFF7DDC9);
}
