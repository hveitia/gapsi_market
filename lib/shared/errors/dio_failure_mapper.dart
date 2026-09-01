import 'package:dio/dio.dart';
import 'package:rekluti_test/shared/errors/failure.dart';

/// Translates a transport level [DioException] into a domain [Failure].
///
/// Centralised here rather than duplicated in each data source so that every
/// call site classifies errors identically, and so the classification can be
/// tested without touching the network.
Failure mapDioException(DioException exception) {
  return switch (exception.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => TimeoutFailure(
      debugMessage: exception.message,
    ),
    DioExceptionType.connectionError ||
    DioExceptionType.badCertificate => NetworkFailure(
      debugMessage: exception.message,
    ),
    DioExceptionType.cancel => CancelledFailure(
      debugMessage: exception.message,
    ),
    DioExceptionType.badResponse => _mapStatusCode(exception),
    DioExceptionType.unknown => UnknownFailure(
      debugMessage: exception.message ?? exception.error?.toString(),
    ),
  };
}

/// Translates any thrown object into a [Failure].
///
/// The entry point for `catch` blocks that cannot know what they caught.
Failure mapError(Object error) {
  return switch (error) {
    final DioException exception => mapDioException(exception),
    // `strict-casts` makes an unexpected JSON shape throw instead of silently
    // yielding null, so both of these mean the payload did not match.
    final FormatException exception => ParsingFailure(
      debugMessage: exception.message,
    ),
    final TypeError typeError => ParsingFailure(
      debugMessage: typeError.toString(),
    ),
    _ => UnknownFailure(debugMessage: error.toString()),
  };
}

Failure _mapStatusCode(DioException exception) {
  final int? statusCode = exception.response?.statusCode;
  final String? message = exception.message;

  return switch (statusCode) {
    401 || 403 => UnauthorizedFailure(debugMessage: message),
    429 => RateLimitFailure(debugMessage: message),
    final int code when code >= 500 => ServerFailure(
      statusCode: code,
      debugMessage: message,
    ),
    final int code => RequestFailure(statusCode: code, debugMessage: message),
    null => UnknownFailure(debugMessage: message),
  };
}
