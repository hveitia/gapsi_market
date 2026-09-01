import 'package:equatable/equatable.dart';

/// A product as the app uses it.
///
/// Flat and small on purpose: the service answers with roughly a megabyte of
/// Walmart's own page state per page, and almost none of it is needed. Mapping
/// it down here means the list, the detail screen and the cache all work with
/// the same handful of fields.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.title,
    required this.currency,
    this.price,
    this.imageUrl,
    this.thumbnailUrl,
    this.description,
    this.rating,
    this.reviewCount,
    this.productUrl,
  });

  /// Walmart's item id. Stable across pages, which is what lets the same
  /// product be recognised when it comes back on a later one.
  final String id;

  final String title;

  /// Currency of [price], reported by the payload.
  final String currency;

  /// Null when the payload carries no usable price.
  ///
  /// A number rather than a formatted string: formatting is the screen's job,
  /// and a string could not be compared or sorted.
  final double? price;

  final String? imageUrl;
  final String? thumbnailUrl;

  /// Null when the product has no description at all.
  ///
  /// Roughly one in six does not, so the detail screen has to say so rather
  /// than render an empty block.
  final String? description;

  final double? rating;
  final int? reviewCount;

  /// Absolute link to the product page, ready to open in a browser.
  final String? productUrl;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    currency,
    price,
    imageUrl,
    thumbnailUrl,
    description,
    rating,
    reviewCount,
    productUrl,
  ];
}
