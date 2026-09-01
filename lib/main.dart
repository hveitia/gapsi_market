import 'package:flutter/material.dart';
import 'package:rekluti_test/app.dart';
import 'package:rekluti_test/configs/router/app_router.dart';
import 'package:rekluti_test/shared/di/service_locator.dart';

Future<void> main() async {
  // Required before any plugin is touched: registering dependencies opens the
  // door to the SQLite platform channel.
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();

  runApp(GapsiMarketApp(router: buildAppRouter()));
}
