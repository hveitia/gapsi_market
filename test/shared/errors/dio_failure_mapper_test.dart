import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rekluti_test/shared/errors/dio_failure_mapper.dart';
import 'package:rekluti_test/shared/errors/failure.dart';

DioException _dioException(DioExceptionType type, {int? statusCode}) {
  final RequestOptions options = RequestOptions(
    path: '/wlm/walmart-search-by-keyword',
  );
  return DioException(
    requestOptions: options,
    type: type,
    response: statusCode == null
        ? null
        : Response<dynamic>(requestOptions: options, statusCode: statusCode),
  );
}

void main() {
  group('mapDioException', () {
    test('maps every timeout type to a retryable TimeoutFailure', () {
      const List<DioExceptionType> timeouts = <DioExceptionType>[
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
      ];

      for (final DioExceptionType type in timeouts) {
        final Failure failure = mapDioException(_dioException(type));

        expect(failure, isA<TimeoutFailure>(), reason: 'for $type');
        expect(failure.isRetryable, isTrue, reason: 'for $type');
      }
    });

    test('maps connectionError to a retryable NetworkFailure', () {
      final Failure failure = mapDioException(
        _dioException(DioExceptionType.connectionError),
      );

      expect(failure, isA<NetworkFailure>());
      expect(failure.isRetryable, isTrue);
    });

    // A debounced search cancels the in-flight request on every keystroke, so
    // a cancellation is expected behaviour and must never be retried.
    test('maps cancel to a non retryable CancelledFailure', () {
      final Failure failure = mapDioException(
        _dioException(DioExceptionType.cancel),
      );

      expect(failure, isA<CancelledFailure>());
      expect(failure.isRetryable, isFalse);
    });

    test('maps 401 and 403 to a non retryable UnauthorizedFailure', () {
      for (final int status in <int>[401, 403]) {
        final Failure failure = mapDioException(
          _dioException(DioExceptionType.badResponse, statusCode: status),
        );

        expect(failure, isA<UnauthorizedFailure>(), reason: 'for $status');
        expect(failure.isRetryable, isFalse, reason: 'for $status');
      }
    });

    test('maps 429 to a retryable RateLimitFailure', () {
      final Failure failure = mapDioException(
        _dioException(DioExceptionType.badResponse, statusCode: 429),
      );

      expect(failure, isA<RateLimitFailure>());
      expect(failure.isRetryable, isTrue);
    });

    test('maps 5xx to a retryable ServerFailure carrying the status', () {
      final Failure failure = mapDioException(
        _dioException(DioExceptionType.badResponse, statusCode: 503),
      );

      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 503);
      expect(failure.isRetryable, isTrue);
    });

    test('maps other 4xx to a non retryable RequestFailure', () {
      final Failure failure = mapDioException(
        _dioException(DioExceptionType.badResponse, statusCode: 404),
      );

      expect(failure, isA<RequestFailure>());
      expect((failure as RequestFailure).statusCode, 404);
      expect(failure.isRetryable, isFalse);
    });

    test('maps a badResponse without status to UnknownFailure', () {
      final Failure failure = mapDioException(
        _dioException(DioExceptionType.badResponse),
      );

      expect(failure, isA<UnknownFailure>());
    });
  });

  group('mapError', () {
    test('delegates DioException to mapDioException', () {
      final Failure failure = mapError(
        _dioException(DioExceptionType.connectionError),
      );

      expect(failure, isA<NetworkFailure>());
    });

    test('maps FormatException to ParsingFailure', () {
      expect(mapError(const FormatException('bad json')), isA<ParsingFailure>());
    });

    // strict-casts turns an unexpected JSON shape into a TypeError rather than
    // a silent null, so it has to be treated as a parsing problem.
    test('maps TypeError to ParsingFailure', () {
      Failure? failure;
      try {
        // ignore: unnecessary_cast
        (<String, dynamic>{'price': 'free'}['price'] as num).toDouble();
      } on TypeError catch (error) {
        failure = mapError(error);
      }

      expect(failure, isA<ParsingFailure>());
    });

    test('maps anything else to UnknownFailure', () {
      expect(mapError(Object()), isA<UnknownFailure>());
    });
  });

  group('Failure equality', () {
    test('two failures of the same type and message are equal', () {
      expect(
        const NetworkFailure(debugMessage: 'offline'),
        const NetworkFailure(debugMessage: 'offline'),
      );
    });

    test('failures of different types are never equal', () {
      expect(
        const NetworkFailure(debugMessage: 'x'),
        isNot(const TimeoutFailure(debugMessage: 'x')),
      );
    });

    test('ServerFailure distinguishes status codes', () {
      expect(
        const ServerFailure(statusCode: 500),
        isNot(const ServerFailure(statusCode: 503)),
      );
    });
  });
}
