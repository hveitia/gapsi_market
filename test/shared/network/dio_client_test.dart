import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rekluti_test/shared/errors/dio_failure_mapper.dart';
import 'package:rekluti_test/shared/errors/failure.dart';
import 'package:rekluti_test/shared/network/dio_client.dart';
import 'package:rekluti_test/shared/network/rapid_api_interceptor.dart';

/// Stands in for the real transport so the wiring can be asserted without
/// reaching the network.
class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _RecordingAdapter adapter;

  setUp(() => adapter = _RecordingAdapter());

  Dio buildClient({String apiKey = 'test-key'}) {
    final Dio dio = buildDioClient(
      baseUrl: 'https://example.test',
      apiKey: apiKey,
      apiHost: 'example.test',
      enableLogging: false,
    );
    dio.httpClientAdapter = adapter;
    return dio;
  }

  group('buildDioClient', () {
    test('resolves relative paths against the configured base url', () async {
      await buildClient().get<dynamic>('/search');

      expect(adapter.captured?.uri.toString(), 'https://example.test/search');
    });

    test('configures timeouts so a hung request cannot block the UI', () {
      final BaseOptions options = buildClient().options;

      expect(options.connectTimeout, isNotNull);
      expect(options.receiveTimeout, isNotNull);
      expect(options.sendTimeout, isNotNull);
    });
  });

  group('RapidApiInterceptor', () {
    test('attaches the RapidAPI credentials to every request', () async {
      await buildClient().get<dynamic>('/search');

      final Map<String, dynamic> headers = adapter.captured!.headers;
      expect(headers[RapidApiInterceptor.keyHeader], 'test-key');
      expect(headers[RapidApiInterceptor.hostHeader], 'example.test');
    });

    // Without a key every call is guaranteed to fail, so it is rejected before
    // it leaves the device instead of burning a round trip.
    test('rejects locally when the api key is missing', () async {
      Object? thrown;
      try {
        await buildClient(apiKey: '').get<dynamic>('/search');
      } on Object catch (error) {
        thrown = error;
      }

      expect(adapter.captured, isNull, reason: 'no request should be sent');
      expect(thrown, isA<DioException>());
      expect(mapError(thrown!), isA<UnauthorizedFailure>());
    });
  });
}
