import 'package:flutter/material.dart';
import 'package:rekluti_test/configs/theme/app_colors.dart';
import 'package:rekluti_test/configs/theme/app_typography.dart';

/// Shape and elevation constants shared by every screen.
abstract final class AppShapes {
  /// Horizontal padding of a screen.
  static const double screenPadding = 22;

  /// Cards.
  static const double cardRadius = 26;

  /// Tiles and small containers.
  static const double tileRadius = 20;

  /// Pills: fields and buttons.
  static const double pillRadius = 28;

  /// Border width, as specified.
  static const double hairlineWidth = 1.5;

  /// Minimum touch target. Below this a control is hard to hit reliably.
  static const double minTouchTarget = 48;

  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(
      color: Color(0x14472F22),
      blurRadius: 22,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> primaryButton = <BoxShadow>[
    BoxShadow(
      color: Color(0x59C2410C),
      blurRadius: 30,
      offset: Offset(0, 14),
    ),
  ];
}

/// Assembles the palette and the typography into the app's theme.
///
/// Screens read from here instead of hard coding a colour or a size, so a token
/// changes in one place.
ThemeData buildAppTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    surface: AppColors.surface,
  ).copyWith(
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    error: AppColors.dangerFg,
    onError: AppColors.onAccent,
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    // Cupertino transitions on iOS, so navigation feels native on both.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
      },
    ),
    textTheme: TextTheme(
      displayLarge: AppTypography.display,
      titleLarge: AppTypography.titleLg,
      titleMedium: AppTypography.titleSm,
      bodyMedium: AppTypography.body,
      labelLarge: AppTypography.label,
      labelSmall: AppTypography.meta,
    ),
  );
}
