import 'package:rekluti_test/modules/catalog/contract/favorites_datasource.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';
import 'package:rekluti_test/shared/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

/// [FavoritesDataSource] on the app's SQLite connection.
class SqliteFavoritesDataSource implements FavoritesDataSource {
  const SqliteFavoritesDataSource(this._database);

  static const String _table = 'favorites';

  final AppDatabase _database;

  @override
  Future<List<Product>> all() async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      _table,
      orderBy: 'saved_at DESC',
    );
    return rows.map(_toProduct).toList(growable: false);
  }

  @override
  Future<void> save(Product product) async {
    final Database db = await _database.database;
    await db.insert(_table, <String, Object?>{
      'id': product.id,
      'title': product.title,
      'price': product.price,
      'currency': product.currency,
      'image_url': product.imageUrl,
      'thumbnail_url': product.thumbnailUrl,
      'description': product.description,
      'rating': product.rating,
      'review_count': product.reviewCount,
      'product_url': product.productUrl,
      'saved_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> remove(String id) async {
    final Database db = await _database.database;
    await db.delete(_table, where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Product _toProduct(Map<String, Object?> row) {
    return Product(
      id: row['id']! as String,
      title: row['title']! as String,
      currency: row['currency']! as String,
      price: row['price'] as double?,
      imageUrl: row['image_url'] as String?,
      thumbnailUrl: row['thumbnail_url'] as String?,
      description: row['description'] as String?,
      rating: row['rating'] as double?,
      reviewCount: row['review_count'] as int?,
      productUrl: row['product_url'] as String?,
    );
  }
}
