import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rekluti_test/configs/theme/app_theme.dart';

/// The application widget.
///
/// The router arrives through the constructor rather than being built here, so
/// a widget test can drive the app from any starting location without touching
/// production wiring.
class GapsiMarketApp extends StatelessWidget {
  const GapsiMarketApp({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gapsi Market',
      theme: buildAppTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
