import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:rekluti_test/configs/environment.dart';
import 'package:rekluti_test/shared/network/rapid_api_interceptor.dart';

/// Timeouts are explicit because the defaults are unbounded: without them a
/// stalled connection would leave the search spinner up forever.
const Duration _connectTimeout = Duration(seconds: 15);
const Duration _sendTimeout = Duration(seconds: 15);
const Duration _receiveTimeout = Duration(seconds: 20);

/// Builds the [Dio] instance used across the app.
///
/// Parameters default to the build time configuration and are overridable so
/// tests can exercise the wiring without touching the real service or
/// polluting their output with request logs.
Dio buildDioClient({
  String baseUrl = EnvironmentConstants.apiBaseUrl,
  String apiKey = EnvironmentConstants.rapidApiKey,
  String apiHost = EnvironmentConstants.rapidApiHost,
  bool enableLogging = kDebugMode,
}) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: _connectTimeout,
      sendTimeout: _sendTimeout,
      receiveTimeout: _receiveTimeout,
      headers: const <String, String>{'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    RapidApiInterceptor(apiKey: apiKey, apiHost: apiHost),
  );

  if (enableLogging) {
    // `requestHeader` stays false on purpose: the RapidAPI key travels in a
    // header, and logging it would print the credential to the console.
    dio.interceptors.add(
      LogInterceptor(requestHeader: false, responseHeader: false),
    );
  }

  return dio;
}
