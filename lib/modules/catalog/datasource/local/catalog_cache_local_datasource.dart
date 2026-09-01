import 'dart:convert';

import 'package:rekluti_test/modules/catalog/contract/catalog_cache_datasource.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';
import 'package:rekluti_test/modules/catalog/domain/product_page.dart';
import 'package:rekluti_test/shared/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

/// [CatalogCacheDataSource] on the app's SQLite connection.
class SqliteCatalogCacheDataSource implements CatalogCacheDataSource {
  SqliteCatalogCacheDataSource(this._database, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  static const String _table = 'cached_pages';

  final AppDatabase _database;

  /// The clock is a seam so expiry can be tested without waiting for it.
  final DateTime Function() _now;

  @override
  Future<ProductPage?> read({
    required String term,
    required int page,
    required Duration maxAge,
  }) async {
    final Database db = await _database.database;
    final int oldestAccepted = _now()
        .subtract(maxAge)
        .millisecondsSinceEpoch;

    // Freshness is part of the query rather than a check afterwards, so a stale
    // row is never even read.
    final List<Map<String, Object?>> rows = await db.query(
      _table,
      where: 'term = ? AND page = ? AND cached_at >= ?',
      whereArgs: <Object?>[_normalise(term), page, oldestAccepted],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }
    return _toPage(rows.first, page);
  }

  @override
  Future<void> write({required String term, required ProductPage page}) async {
    final Database db = await _database.database;
    await db.insert(_table, <String, Object?>{
      'term': _normalise(term),
      'page': page.page,
      'products': jsonEncode(page.products.map(_toJson).toList()),
      'max_page': page.maxPage,
      'total_results': page.totalResults,
      'cached_at': _now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> evictExpired(Duration maxAge) async {
    final Database db = await _database.database;
    await db.delete(
      _table,
      where: 'cached_at < ?',
      whereArgs: <Object?>[_now().subtract(maxAge).millisecondsSinceEpoch],
    );
  }

  /// The same word typed with different casing is the same search, so it has to
  /// be the same cache entry.
  String _normalise(String term) => term.trim().toLowerCase();

  ProductPage _toPage(Map<String, Object?> row, int page) {
    final Object? decoded = jsonDecode(row['products']! as String);
    final List<Product> products = (decoded! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(_fromJson)
        .toList(growable: false);

    return ProductPage(
      products: products,
      page: page,
      maxPage: row['max_page'] as int?,
      totalResults: row['total_results'] as int?,
    );
  }

  Map<String, Object?> _toJson(Product product) => <String, Object?>{
    'id': product.id,
    'title': product.title,
    'currency': product.currency,
    'price': product.price,
    'imageUrl': product.imageUrl,
    'thumbnailUrl': product.thumbnailUrl,
    'description': product.description,
    'rating': product.rating,
    'reviewCount': product.reviewCount,
    'productUrl': product.productUrl,
  };

  Product _fromJson(Map<String, Object?> json) => Product(
    id: json['id']! as String,
    title: json['title']! as String,
    currency: json['currency']! as String,
    price: (json['price'] as num?)?.toDouble(),
    imageUrl: json['imageUrl'] as String?,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    description: json['description'] as String?,
    rating: (json['rating'] as num?)?.toDouble(),
    reviewCount: json['reviewCount'] as int?,
    productUrl: json['productUrl'] as String?,
  );
}
