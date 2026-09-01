import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rekluti_test/modules/catalog/contract/favorites_datasource.dart';
import 'package:rekluti_test/modules/catalog/datasource/local/catalog_migrations.dart';
import 'package:rekluti_test/modules/catalog/datasource/local/favorites_local_datasource.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';
import 'package:rekluti_test/shared/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
  late FavoritesDataSource favorites;

  AppDatabase open([String? path]) => AppDatabase(
    migrations: catalogMigrations,
    databaseFactory: databaseFactoryFfi,
    path: path ?? inMemoryDatabasePath,
  );

  setUp(() {
    database = open();
    favorites = SqliteFavoritesDataSource(database);
  });

  tearDown(() => database.close());

  test('saves a product and reads every field back', () async {
    await favorites.save(product('a'));

    final Product saved = (await favorites.all()).single;
    expect(saved, product('a'));
  });

  test('lists the most recently saved first', () async {
    await favorites.save(product('a'));
    await favorites.save(product('b'));

    expect(
      (await favorites.all()).map((Product p) => p.id),
      containsAll(<String>['a', 'b']),
    );
  });

  test('saving the same product twice keeps one copy', () async {
    await favorites.save(product('a'));
    await favorites.save(product('a', price: 199));

    final List<Product> saved = await favorites.all();
    expect(saved, hasLength(1));
    expect(saved.single.price, 199);
  });

  test('removes one favourite', () async {
    await favorites.save(product('a'));
    await favorites.save(product('b'));

    await favorites.remove('a');

    expect((await favorites.all()).map((Product p) => p.id), <String>['b']);
  });

  test('removing something that is not there is harmless', () async {
    await expectLater(favorites.remove('nope'), completes);
  });

  test('keeps a product with no price', () async {
    await favorites.save(product('a', price: null));

    expect((await favorites.all()).single.price, isNull);
  });

  // The exercise requires favourites to outlive the app, and since there is no
  // way to fetch a single product they have to be readable entirely from disk.
  test('survives closing and reopening the database', () async {
    final Directory dir = await Directory.systemTemp.createTemp('gapsi_fav');
    final String path = '${dir.path}/app.db';

    final AppDatabase first = open(path);
    await SqliteFavoritesDataSource(first).save(product('a'));
    await first.close();

    final AppDatabase second = open(path);
    expect((await SqliteFavoritesDataSource(second).all()).single, product('a'));

    await second.close();
    await dir.delete(recursive: true);
  });
}
