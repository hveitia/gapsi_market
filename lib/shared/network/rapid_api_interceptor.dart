import 'package:dio/dio.dart';

/// Attaches the RapidAPI credentials to every outgoing request.
///
/// Living in an interceptor rather than in each data source means the headers
/// are applied in exactly one place: a new endpoint cannot forget them, and no
/// call site ever handles the key.
class RapidApiInterceptor extends Interceptor {
  RapidApiInterceptor({required this.apiKey, required this.apiHost});

  /// Header carrying the subscription key.
  static const String keyHeader = 'x-rapidapi-key';

  /// Header telling the gateway which upstream service to route to.
  static const String hostHeader = 'x-rapidapi-host';

  final String apiKey;
  final String apiHost;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (apiKey.isEmpty) {
      // Every call without a key is guaranteed to come back unauthorised, so
      // it is rejected here instead of spending a round trip to learn that.
      // A synthetic 401 keeps the outcome identical to the remote one, which
      // means the error mapping stays in a single place.
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message:
              'Missing RapidAPI key. Run the app with '
              '--dart-define=RAPIDAPI_KEY=<key>.',
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 401,
          ),
        ),
      );
      return;
    }

    options.headers[keyHeader] = apiKey;
    options.headers[hostHeader] = apiHost;
    handler.next(options);
  }
}
