import 'package:rekluti_test/modules/catalog/domain/product.dart';
import 'package:rekluti_test/modules/catalog/domain/product_page.dart';
import 'package:rekluti_test/shared/errors/failure.dart';

/// Turns a Walmart search response into a [ProductPage].
///
/// The service does not answer with an API document: it returns the whole state
/// of Walmart's own search page, around a megabyte per request, with the
/// products buried several levels down. Everything this file does is about
/// surviving that.
ProductPage mapSearchResponse(Map<String, Object?> json, {required int page}) {
  final Map<String, Object?> searchResult = _searchResult(json);

  final List<Product> products = _gridItems(searchResult)
      .map(_toProduct)
      .nonNulls
      .toList(growable: false);

  return ProductPage(
    products: products,
    page: page,
    maxPage: _asInt(_at(searchResult, <String>['paginationV2', 'maxPage'])),
    totalResults: _asInt(searchResult['aggregatedCount']),
  );
}

/// Walmart's canonical urls are relative, and a relative link cannot be opened.
const String _walmartOrigin = 'https://www.walmart.com';

const String _defaultCurrency = 'USD';

/// Navigates to the search result, refusing anything that is not one.
///
/// A response with no results is normal and arrives with empty stacks. A
/// response without this node at all means the service answered with something
/// else entirely, and treating that as "no results" would hide the breakage
/// behind an empty screen.
Map<String, Object?> _searchResult(Map<String, Object?> json) {
  final Object? node = _at(json, <String>[
    'item',
    'props',
    'pageProps',
    'initialData',
    'searchResult',
  ]);

  if (node is! Map<String, Object?>) {
    throw const ParsingFailure(
      debugMessage: 'The payload carries no searchResult node',
    );
  }
  return node;
}

/// The products of the results grid.
///
/// The response also carries a "Shop trending items" carousel whose products
/// have nothing to do with the query, so the stacks cannot simply be
/// concatenated. Only the grid holds search results.
List<Map<String, Object?>> _gridItems(Map<String, Object?> searchResult) {
  final Object? stacks = searchResult['itemStacks'];
  if (stacks is! List<Object?>) {
    return const <Map<String, Object?>>[];
  }

  return stacks
      .whereType<Map<String, Object?>>()
      .where((Map<String, Object?> stack) => stack['layoutEnum'] == 'GRID')
      .expand(
        (Map<String, Object?> stack) =>
            (stack['items'] as List<Object?>? ?? const <Object?>[])
                .whereType<Map<String, Object?>>(),
      )
      .toList(growable: false);
}

/// Returns `null` for a tile that carries no product.
///
/// The grid is padded with fillers that have no id, name or image. They would
/// otherwise render as blank cards.
Product? _toProduct(Map<String, Object?> item) {
  final String? id = _asString(item['usItemId']);
  final String? title = _asString(item['name']);
  if (id == null || title == null) {
    return null;
  }

  final Map<String, Object?> priceInfo = _asMap(item['priceInfo']);
  final String? path = _asString(item['canonicalUrl']);

  return Product(
    id: id,
    title: title,
    currency:
        _asString(_at(priceInfo, <String>['priceDetails', 'currency'])) ??
        _defaultCurrency,
    price: _price(item, priceInfo),
    imageUrl: _asString(item['image']),
    thumbnailUrl:
        _asString(_at(item, <String>['imageInfo', 'thumbnailUrl'])) ??
        _asString(item['image']),
    description: plainDescription(
      _asString(item['description']) ?? _asString(item['shortDescription']),
    ),
    rating: _asDouble(item['averageRating']),
    reviewCount: _asInt(item['numberOfReviews']),
    productUrl: path == null ? null : '$_walmartOrigin$path',
  );
}

/// Resolves the price across every shape the service uses.
///
/// The same endpoint answers differently from one page to the next. On some
/// pages `priceDetails.priceLines` is populated and the formatted strings are
/// empty; on others that list is absent and the value only exists as a display
/// string. Reading either one alone leaves half the catalogue priced at zero,
/// which is exactly how the raw `price` field and `priceInfo.itemPrice` read on
/// the pages that use the other shape.
double? _price(Map<String, Object?> item, Map<String, Object?> priceInfo) {
  for (final String lineType in <String>['CURRENT_PRICE', 'DISCOUNTED_PRICE']) {
    final double? fromLine = _priceLine(priceInfo, lineType);
    if (fromLine != null) {
      return fromLine;
    }
  }

  for (final String key in <String>['linePrice', 'itemPrice']) {
    final double? fromString = _money(_asString(priceInfo[key]));
    if (fromString != null) {
      return fromString;
    }
  }

  final double? raw = _asDouble(item['price']);
  return (raw != null && raw > 0) ? raw : null;
}

double? _priceLine(Map<String, Object?> priceInfo, String lineType) {
  final Object? lines = _at(priceInfo, <String>['priceDetails', 'priceLines']);
  if (lines is! List<Object?>) {
    return null;
  }

  for (final Map<String, Object?> line in lines
      .whereType<Map<String, Object?>>()
      .where((Map<String, Object?> line) => line['lineType'] == lineType)) {
    final Object? values = line['values'];
    if (values is! List<Object?>) {
      continue;
    }
    for (final Map<String, Object?> value in values
        .whereType<Map<String, Object?>>()
        .where((Map<String, Object?> value) => value['key'] == 'PRICE')) {
      final double? amount = _money(_asString(value['value']));
      if (amount != null) {
        return amount;
      }
    }
  }
  return null;
}

/// Pulls a number out of a display string such as `$132.30` or `From $1,299.00`.
final RegExp _amount = RegExp(r'\d[\d,]*(?:\.\d+)?');

double? _money(String? text) {
  if (text == null) {
    return null;
  }
  final RegExpMatch? match = _amount.firstMatch(text);
  if (match == null) {
    return null;
  }
  return double.tryParse(match.group(0)!.replaceAll(',', ''));
}

/// Turns a description into text a screen can render.
///
/// More than half of the descriptions the service returns are marked up, and
/// every one of them uses a single tag: `<li>`, with no list around it. Rendered
/// as they arrive they read as `<li>Nintendo</li><li>Switch</li>`.
///
/// List items become bullet lines and the sentence some products put before the
/// first item is kept as its own line. Anything else is stripped and entities
/// are decoded, none of which the payload uses today: it is handled anyway
/// because this response already changed shape once between two pages of the
/// same search, and markup leaking onto a screen is worse than a few lines that
/// never run.
String? plainDescription(String? raw) {
  if (raw == null) {
    return null;
  }

  final String withBullets = raw
      .replaceAll(RegExp(r'</li\s*>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n• ')
      .replaceAll(RegExp(r'<br\s*/?>|</p\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp('<[^>]*>'), '');

  final String decoded = _decodeEntities(withBullets);

  // Several products repeat the same bullet two or three times.
  final Set<String> seen = <String>{};
  final List<String> lines = <String>[];
  for (final String line in decoded.split('\n')) {
    final String trimmed = line.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (trimmed.isEmpty || trimmed == '•') {
      continue;
    }
    if (seen.add(trimmed)) {
      lines.add(trimmed);
    }
  }

  return lines.isEmpty ? null : lines.join('\n');
}

const Map<String, String> _entities = <String, String>{
  '&amp;': '&',
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&#39;': "'",
  '&apos;': "'",
  '&nbsp;': ' ',
};

String _decodeEntities(String text) {
  String decoded = text;
  for (final MapEntry<String, String> entity in _entities.entries) {
    decoded = decoded.replaceAll(entity.key, entity.value);
  }
  return decoded;
}

Object? _at(Map<String, Object?> root, List<String> path) {
  Object? node = root;
  for (final String key in path) {
    if (node is! Map<String, Object?>) {
      return null;
    }
    node = node[key];
  }
  return node;
}

Map<String, Object?> _asMap(Object? value) =>
    value is Map<String, Object?> ? value : const <String, Object?>{};

/// Empty strings count as absent: the payload uses them where a field has no
/// value, so `''` and `null` mean the same thing here.
String? _asString(Object? value) {
  if (value is! String) {
    return null;
  }
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? _asInt(Object? value) => switch (value) {
  final int number => number,
  final double number => number.toInt(),
  final String text => int.tryParse(text),
  _ => null,
};

double? _asDouble(Object? value) => switch (value) {
  final int number => number.toDouble(),
  final double number => number,
  final String text => double.tryParse(text),
  _ => null,
};
