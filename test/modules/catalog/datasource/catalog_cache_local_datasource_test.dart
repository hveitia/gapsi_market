import 'package:flutter_test/flutter_test.dart';
import 'package:rekluti_test/modules/catalog/contract/catalog_cache_datasource.dart';
import 'package:rekluti_test/modules/catalog/datasource/local/catalog_cache_local_datasource.dart';
import 'package:rekluti_test/modules/catalog/datasource/local/catalog_migrations.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';
import 'package:rekluti_test/modules/catalog/domain/product_page.dart';
import 'package:rekluti_test/shared/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const Duration ttl = Duration(minutes: 20);

Product product(String id, {double? price = 299}) => Product(
  id: id,
  title: 'Nintendo Switch $id',
  currency: 'USD',
  price: price,
  thumbnailUrl: 'https://example.test/$id.jpg',
  description: 'Consola',
  rating: 4.8,
  reviewCount: 8700,
  productUrl: 'https://www.walmart.com/ip/$id',
);

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase database;
  late DateTime now;
  late CatalogCacheDataSource cache;

  setUp(() {
    now = DateTime(2026, 9, 1, 12);
    database = AppDatabase(
      migrations: catalogMigrations,
      databaseFactory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    cache = SqliteCatalogCacheDataSource(database, clock: () => now);
  });

  tearDown(() => database.close());

  ProductPage page(int number, List<String> ids) => ProductPage(
    products: ids.map(product).toList(),
    page: number,
    maxPage: 14,
    totalResults: 860,
  );

  // Asserting the exact number would break every time a migration is added.
  // What matters is that the version is derived from the list, so a new step
  // can never be shipped without the upgrade it needs.
  test('the schema version follows the registered migrations', () {
    expect(database.schemaVersion, catalogMigrations.length);
  });

  test('returns nothing when the term was never cached', () async {
    expect(
      await cache.read(term: 'nintendo', page: 1, maxAge: ttl),
      isNull,
    );
  });

  test('reads back every field of a stored page', () async {
    await cache.write(term: 'nintendo', page: page(1, <String>['a', 'b']));

    final ProductPage? stored = await cache.read(
      term: 'nintendo',
      page: 1,
      maxAge: ttl,
    );

    expect(stored!.products, <Product>[product('a'), product('b')]);
    expect(stored.maxPage, 14);
    expect(stored.totalResults, 860);
    expect(stored.page, 1);
  });

  test('keeps pages of the same term apart', () async {
    await cache.write(term: 'nintendo', page: page(1, <String>['a']));
    await cache.write(term: 'nintendo', page: page(2, <String>['b']));

    final ProductPage? second = await cache.read(
      term: 'nintendo',
      page: 2,
      maxAge: ttl,
    );

    expect(second!.products.single.id, 'b');
  });

  test('treats the same word in another casing as the same search', () async {
    await cache.write(term: 'Nintendo ', page: page(1, <String>['a']));

    expect(
      await cache.read(term: 'nintendo', page: 1, maxAge: ttl),
      isNotNull,
    );
  });

  test('replaces an earlier copy instead of duplicating it', () async {
    await cache.write(term: 'nintendo', page: page(1, <String>['a']));
    await cache.write(term: 'nintendo', page: page(1, <String>['b']));

    final ProductPage? stored = await cache.read(
      term: 'nintendo',
      page: 1,
      maxAge: ttl,
    );

    expect(stored!.products.single.id, 'b');
  });

  test('survives a product with no price', () async {
    await cache.write(
      term: 'nintendo',
      page: ProductPage(
        products: <Product>[product('a', price: null)],
        page: 1,
      ),
    );

    final ProductPage? stored = await cache.read(
      term: 'nintendo',
      page: 1,
      maxAge: ttl,
    );

    expect(stored!.products.single.price, isNull);
  });

  group('expiry', () {
    test('still serves a page inside the window', () async {
      await cache.write(term: 'nintendo', page: page(1, <String>['a']));

      now = now.add(ttl - const Duration(minutes: 1));

      expect(
        await cache.read(term: 'nintendo', page: 1, maxAge: ttl),
        isNotNull,
      );
    });

    test('refuses a page past the window', () async {
      await cache.write(term: 'nintendo', page: page(1, <String>['a']));

      now = now.add(ttl + const Duration(minutes: 1));

      expect(
        await cache.read(term: 'nintendo', page: 1, maxAge: ttl),
        isNull,
      );
    });

    // Without this the table would grow for every search ever made.
    test('evicting removes what expired and keeps what did not', () async {
      await cache.write(term: 'viejo', page: page(1, <String>['a']));
      now = now.add(ttl + const Duration(minutes: 1));
      await cache.write(term: 'nuevo', page: page(1, <String>['b']));

      await cache.evictExpired(ttl);

      expect(await cache.read(term: 'viejo', page: 1, maxAge: ttl), isNull);
      expect(await cache.read(term: 'nuevo', page: 1, maxAge: ttl), isNotNull);
    });
  });
}
