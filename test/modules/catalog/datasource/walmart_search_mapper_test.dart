import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rekluti_test/modules/catalog/datasource/remote/walmart_search_mapper.dart';
import 'package:rekluti_test/modules/catalog/domain/product.dart';
import 'package:rekluti_test/modules/catalog/domain/product_page.dart';
import 'package:rekluti_test/shared/errors/failure.dart';

/// Fixtures are trimmed captures of real responses: the same nesting, with the
/// fields the mapper does not read removed so the file stays reviewable.
Map<String, Object?> fixture(String name) {
  final String raw = File('test/fixtures/catalog/$name.json').readAsStringSync();
  return jsonDecode(raw) as Map<String, Object?>;
}

void main() {
  late ProductPage page;

  setUp(() => page = mapSearchResponse(fixture('search_page'), page: 1));

  Product byId(String id) => page.products.firstWhere((Product p) => p.id == id);

  // The response carries a second stack titled "Shop trending items" that has
  // nothing to do with the query. Concatenating the stacks would drop unrelated
  // products into the results.
  test('reads the results grid and ignores the trending carousel', () {
    expect(page.products.map((Product p) => p.id), isNot(contains('840261578')));
    expect(page.products.map((Product p) => p.id), isNot(contains('1203950273')));
  });

  // Some tiles in the grid are fillers with no id, name or image.
  test('drops tiles that carry no product', () {
    expect(page.products, hasLength(5));
    expect(page.products.every((Product p) => p.id.isNotEmpty), isTrue);
    expect(page.products.every((Product p) => p.title.isNotEmpty), isTrue);
  });

  group('price', () {
    // The endpoint answers with two different shapes. On some pages the price
    // lives in priceDetails.priceLines; on others that list is empty and the
    // value is a formatted string in priceInfo. Reading only one of them leaves
    // half the catalogue showing nothing.
    test('reads the current price from the price lines', () {
      expect(byId('15949610846').price, 499.0);
    });

    test('falls back to the discounted line when there is no current one', () {
      expect(byId('927771478').price, 132.30);
    });

    test('reads the formatted string when the price lines are empty', () {
      expect(byId('709776123').price, 229.0);
    });

    test('resolves a price for every product in the payload', () {
      expect(page.products.where((Product p) => p.price == null), isEmpty);
    });

    test('reports the currency', () {
      expect(page.products.every((Product p) => p.currency == 'USD'), isTrue);
    });
  });

  group('fields', () {
    test('reads title, image and rating', () {
      final Product product = byId('15949610846');

      expect(product.title, isNotEmpty);
      expect(product.thumbnailUrl, startsWith('https://'));
      expect(product.rating, isNotNull);
      expect(product.reviewCount, isNotNull);
    });

    test('leaves the description null when the payload has none', () {
      expect(byId('21944233').description, isNull);
      expect(byId('15949610846').description, isNotEmpty);
    });

    // canonicalUrl is relative, and a relative link cannot be opened.
    test('turns the canonical path into an absolute url', () {
      expect(byId('15949610846').productUrl, startsWith('https://www.walmart.com/'));
    });
  });

  group('pagination', () {
    test('carries the page it was asked for and the reported ceiling', () {
      expect(page.page, 1);
      expect(page.maxPage, 14);
      expect(page.totalResults, 26914);
    });

    test('does not consider a page with products the end', () {
      expect(page.hasReachedEnd, isFalse);
    });

    // Past the last page the service answers with no stacks at all. That, not
    // the hasMorePages flag, is what actually marks the end: the flag reads
    // false even on the first page of fourteen.
    test('treats a payload with no stacks as the end of the results', () {
      final ProductPage last = mapSearchResponse(
        fixture('search_page_empty'),
        page: 14,
      );

      expect(last.products, isEmpty);
      expect(last.hasReachedEnd, isTrue);
    });
  });

  // An empty result set is normal; a payload that is not the expected document
  // is not, and must not be mistaken for one.
  test('rejects a payload that is not a search response', () {
    expect(
      () => mapSearchResponse(<String, Object?>{'unexpected': true}, page: 1),
      throwsA(isA<ParsingFailure>()),
    );
  });

  // More than half of the descriptions the service returns are marked up, and
  // every one of them uses the same single tag: <li>, with no list around it.
  // Rendered as-is they read as "<li>Nintendo</li><li>Switch</li>".
  group('description markup', () {
    test('turns list items into readable lines', () {
      expect(
        plainDescription(
          '<li>Nintendo</li><li>Switch</li><li>OLED Model</li>',
        ),
        '• Nintendo\n• Switch\n• OLED Model',
      );
    });

    test('keeps the sentence that comes before the first item', () {
      expect(
        plainDescription(
          'Nintendo Switch Console:<li>Play on your TV</li><li>Take it out</li>',
        ),
        'Nintendo Switch Console:\n• Play on your TV\n• Take it out',
      );
    });

    test('leaves plain text untouched', () {
      expect(plainDescription('Nintendo Switch 2 System'), 'Nintendo Switch 2 System');
    });

    // Several products repeat the same bullet two or three times.
    test('collapses an item repeated verbatim', () {
      expect(
        plainDescription(
          '<li>Refurbished OLED</li><li>Refurbished OLED</li><li>256 GB</li>',
        ),
        '• Refurbished OLED\n• 256 GB',
      );
    });

    // None of these appear today. They are handled anyway because the payload
    // has already changed shape once between two pages of one search.
    test('survives markup the service does not use yet', () {
      expect(
        plainDescription('<p>Uno</p><br/><b>dos</b> &amp; tres'),
        'Uno\ndos & tres',
      );
    });

    test('reports nothing left after stripping as no description', () {
      expect(plainDescription('<li></li>'), isNull);
      expect(plainDescription('   '), isNull);
      expect(plainDescription(null), isNull);
    });

    // The captured product the fixture keeps for this is the one that showed
    // the raw tags on screen.
    test('a mapped product carries clean text, not markup', () {
      expect(
        byId('910582148').description,
        '• Nintendo\n• Switch\n• OLED Model\n• With White Joy-Con',
      );

      for (final Product product in page.products) {
        expect(product.description ?? '', isNot(contains('<')));
      }
    });
  });
}
