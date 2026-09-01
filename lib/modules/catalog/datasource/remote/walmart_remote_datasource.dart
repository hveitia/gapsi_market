import 'package:dio/dio.dart';
import 'package:rekluti_test/configs/environment.dart';
import 'package:rekluti_test/modules/catalog/contract/catalog_remote_datasource.dart';
import 'package:rekluti_test/modules/catalog/datasource/remote/walmart_search_mapper.dart';
import 'package:rekluti_test/modules/catalog/domain/product_page.dart';
import 'package:rekluti_test/shared/errors/dio_failure_mapper.dart';
import 'package:rekluti_test/shared/errors/failure.dart';

/// [CatalogRemoteDataSource] over the Walmart search endpoint.
///
/// Credentials are not handled here: the Dio instance carries an interceptor
/// that attaches them to every request.
class WalmartRemoteDataSource implements CatalogRemoteDataSource {
  const WalmartRemoteDataSource(this._dio);

  /// The only ordering the exercise specifies.
  static const String _sortBy = 'best_match';

  final Dio _dio;

  @override
  Future<ProductPage> search({
    required String keyword,
    required int page,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<Map<String, Object?>> response = await _dio
          .get<Map<String, Object?>>(
            EnvironmentConstants.searchByKeywordPath,
            queryParameters: <String, Object?>{
              'keyword': keyword,
              'page': page,
              'sortBy': _sortBy,
            },
            cancelToken: cancelToken,
          );

      return mapSearchResponse(
        response.data ?? const <String, Object?>{},
        page: page,
      );
    } on Failure {
      rethrow;
    } on Object catch (error) {
      // Translated here, in the one layer that knows Dio exists, so nothing
      // above has to import it to understand what went wrong.
      throw mapError(error);
    }
  }
}
