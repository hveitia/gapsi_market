import 'package:rekluti_test/modules/catalog/domain/search_term.dart';

/// Turns catalogue values into the strings the screens show.
///
/// Kept out of the domain so the models stay free of any language or currency
/// convention, the same rule the failure and validation models follow.
abstract final class CatalogFormats {
  /// A price, or a plain statement that there is none.
  ///
  /// Roughly one product in five comes back without a usable price, so an
  /// empty space where the number should be is a real state, not an edge case.
  static String price(double? amount, String currency) {
    if (amount == null) {
      return 'Precio no disponible';
    }
    final String symbol = currency == 'USD' ? r'$' : '$currency ';
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  static String rating(double? value) =>
      value == null ? '' : value.toStringAsFixed(1);

  /// How many results a term returned, phrased for a chip or a row.
  static String resultCount(int? count) {
    if (count == null) {
      return 'Sin datos';
    }
    return count == 1 ? '1 resultado' : '$count resultados';
  }

  /// The header above a list of results.
  static String resultsHeadline(int? total, String term) {
    final String amount = total == null ? 'Resultados' : '$total resultados';
    return '$amount para "$term"';
  }

  /// When a term was searched, in the words the history list uses.
  ///
  /// [now] is a parameter so the calendar arithmetic can be tested without
  /// waiting for midnight.
  static String searchedAt(SearchTerm entry, {DateTime? now}) {
    final DateTime today = now ?? DateTime.now();
    final DateTime at = entry.searchedAt;
    final int days = DateTime(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime(at.year, at.month, at.day)).inDays;

    return switch (days) {
      <= 0 => 'Hoy',
      1 => 'Ayer',
      < 7 => 'Hace $days días',
      _ => '${at.day} ${_months[at.month - 1]}',
    };
  }

  static const List<String> _months = <String>[
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
}
