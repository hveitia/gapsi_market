import 'package:flutter/material.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';

/// The two typefaces the specification calls for.
///
/// Bricolage Grotesque carries display and headings; Karla carries body and UI
/// text. Both are bundled with the app and declared in `pubspec.yaml`, so they
/// are present the first time a frame is drawn and with no connection at all.
///
/// Letter spacing is expressed in logical pixels, so the `-0.03em` of the
/// specification becomes a value proportional to each size.
abstract final class AppTypography {
  static const String _display = 'BricolageGrotesque';
  static const String _body = 'Karla';

  static const double _displayTracking = -0.03;

  /// Splash and large section headers.
  static TextStyle get display => _heading(34, height: 38 / 34);

  /// Detail title, result counters.
  static TextStyle get titleLg => _heading(28);

  /// Block headings.
  static TextStyle get titleSm => _heading(19);

  /// Default running text.
  static TextStyle get body => _text(15, height: 1.65, color: AppColors.inkSoft);

  /// Form and button labels.
  static TextStyle get label => _text(13, weight: FontWeight.w600);

  /// Secondary information.
  static TextStyle get meta => _text(11, color: AppColors.inkMuted);

  /// Small uppercase eyebrow above a heading.
  static TextStyle get kicker => _text(
    10,
    weight: FontWeight.w700,
    color: AppColors.inkMuted,
  ).copyWith(letterSpacing: 1.2);

  static TextStyle _heading(double size, {double? height}) {
    return TextStyle(
      fontFamily: _display,
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: size * _displayTracking,
      height: height,
      color: AppColors.ink,
    );
  }

  static TextStyle _text(
    double size, {
    FontWeight weight = FontWeight.w400,
    double? height,
    Color color = AppColors.ink,
  }) {
    return TextStyle(
      fontFamily: _body,
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
    );
  }
}
