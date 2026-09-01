import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rekluti_test/modules/catalog/contract/catalog_remote_datasource.dart';
import 'package:rekluti_test/modules/catalog/datasource/remote/walmart_remote_datasource.dart';
import 'package:rekluti_test/modules/catalog/domain/product_page.dart';
import 'package:rekluti_test/shared/errors/failure.dart';

/// Answers with a canned payload and records what was asked for.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter({required this.body, this.statusCode = 200});

  final String body;
  final int statusCode;
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

String fixture(String name) =>
    File('test/fixtures/catalog/$name.json').readAsStringSync();

void main() {
  late _StubAdapter adapter;
  late CatalogRemoteDataSource dataSource;

  void build({String? body, int status = 200}) {
    adapter = _StubAdapter(
      body: body ?? fixture('search_page'),
      statusCode: status,
    );
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    dataSource = WalmartRemoteDataSource(dio);
  }

  setUp(build);

  test('calls the documented endpoint with the expected query', () async {
    await dataSource.search(keyword: 'nintendo', page: 3);

    final RequestOptions request = adapter.captured!;
    expect(request.path, '/wlm/walmart-search-by-keyword');
    expect(request.queryParameters, <String, Object?>{
      'keyword': 'nintendo',
      'page': 3,
      'sortBy': 'best_match',
    });
  });

  test('returns the mapped page for the page it asked for', () async {
    final ProductPage page = await dataSource.search(
      keyword: 'nintendo',
      page: 3,
    );

    expect(page.page, 3);
    expect(page.products, hasLength(5));
  });

  // The search cancels the request in flight on every keystroke, so the token
  // has to reach Dio or a stale response could overwrite a newer one.
  test('cancelling the token aborts the request', () async {
    final CancelToken token = CancelToken();
    final Future<ProductPage> pending = dataSource.search(
      keyword: 'nintendo',
      page: 1,
      cancelToken: token,
    );
    token.cancel();

    await expectLater(pending, throwsA(isA<CancelledFailure>()));
  });

  // Nothing above this layer should have to know that Dio exists.
  test('reports a service error as a Failure, not a DioException', () async {
    build(body: '{}', status: 503);

    await expectLater(
      dataSource.search(keyword: 'nintendo', page: 1),
      throwsA(isA<ServerFailure>()),
    );
  });

  test('reports an unexpected body as a ParsingFailure', () async {
    build(body: '{"unexpected": true}');

    await expectLater(
      dataSource.search(keyword: 'nintendo', page: 1),
      throwsA(isA<ParsingFailure>()),
    );
  });

  test('reads an empty page without failing', () async {
    build(body: fixture('search_page_empty'));

    final ProductPage page = await dataSource.search(
      keyword: 'nintendo',
      page: 14,
    );

    expect(page.hasReachedEnd, isTrue);
  });

  // Dio encodes a space as `+`. Both that and %20 were checked against the real
  // service and return the same results, so multi word searches are safe.
  test('sends the keyword verbatim, letting Dio encode it', () async {
    await dataSource.search(keyword: 'nintendo switch', page: 1);

    expect(adapter.captured!.queryParameters['keyword'], 'nintendo switch');
    expect(adapter.captured!.uri.query, contains('keyword=nintendo+switch'));
  });
}
