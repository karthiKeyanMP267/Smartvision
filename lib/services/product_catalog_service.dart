import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Lightweight, on-device product catalog + canonical name inference.
class ProductCatalogService {
  List<Map<String, dynamic>> _catalog = [];
  bool _loaded = false;

  Future<ProductCatalogService> load() async {
    if (_loaded) return this;
    try {
      final raw = await rootBundle.loadString('assets/data/products.json');
      final jsonMap = json.decode(raw) as Map<String, dynamic>;
      final List<dynamic> items = jsonMap['products'] ?? [];
      _catalog = items
          .whereType<Map<String, dynamic>>()
          .map((e) => e)
          .toList(growable: false);
      _loaded = true;
    } catch (_) {
      // If asset missing or parse fails, keep empty catalog.
      _catalog = [];
      _loaded = true;
    }
    return this;
  }

  /// Find product entry by barcode (exact match).
  Map<String, dynamic>? getByBarcode(String barcode) {
    String norm = _onlyDigits(barcode);
    return _catalog.firstWhere(
      (e) => _onlyDigits('${e['barcode'] ?? ''}') == norm && norm.isNotEmpty,
      orElse: () => {},
    ).isEmpty
        ? null
        : _catalog.firstWhere(
            (e) => _onlyDigits('${e['barcode'] ?? ''}') == norm,
          );
  }

  static String _onlyDigits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  /// Infer a canonical product name using OCR text and vision labels.
  /// Returns something like 'Tomato Ketchup', 'Toothpaste', 'Instant Noodles', etc.
  static String? inferCanonicalName(String text, List<String> labels) {
    final t = text.toLowerCase();
    final tokens = <String>[]
      ..addAll(_tokenize(t))
      ..addAll(labels.map((e) => e.toLowerCase()));

    bool hasAny(Iterable<String> keys) =>
        keys.any((k) => tokens.any((t) => t.contains(k)) || t.contains(k));

    // Heuristic rules for common grocery items
    if ((hasAny(['ketchup', 'snack dressing']) && hasAny(['tomato'])) ||
        (hasAny(['tomato ketchup']))) {
      return 'Tomato Ketchup';
    }
    if (hasAny(['mayonnaise', 'mayo'])) return 'Mayonnaise';
    if (hasAny(['toothpaste', 'colgate', 'pepsodent'])) return 'Toothpaste';
    if (hasAny(['handwash', 'hand wash', 'dettol', 'lifebuoy'])) return 'Hand Wash';
    if (hasAny(['noodle', 'noodles', 'maggi', 'ramen'])) return 'Instant Noodles';
    if (hasAny(['chips', 'lays', 'wafers'])) return 'Potato Chips';
    if (hasAny(['coca', 'coke', 'cola', 'pepsi', 'soft drink'])) return 'Soft Drink';
    if (hasAny(['biscuit', 'cookie', 'oreo', 'parle'])) return 'Biscuits';
    if (hasAny(['chocolate', 'cocoa', 'cadbury', 'nestle'])) return 'Chocolate';
    if (hasAny(['shampoo'])) return 'Shampoo';
    if (hasAny(['soap'])) return 'Soap';
    if (hasAny(['rice'])) return 'Rice';
    if (hasAny(['dal', 'lentil'])) return 'Lentils';
    if (hasAny(['masala', 'spice'])) return 'Spice Mix';
    if (hasAny(['sauce']) && hasAny(['tomato'])) return 'Tomato Sauce';
    if (hasAny(['sauce']) && hasAny(['chilli', 'chili'])) return 'Chilli Sauce';

    // Fallback to top label if meaningful
    if (labels.isNotEmpty) {
      final top = labels.first.toLowerCase();
      // Normalize some generic labels
      if (top.contains('food')) return 'Packaged Food';
      if (top.contains('drink') || top.contains('beverage')) return 'Beverage';
      return _titleCase(top);
    }

    // Last resort: try to use first strong token from text
    final candidates = tokens.where((w) => w.length >= 4).take(1);
    if (candidates.isNotEmpty) return _titleCase(candidates.first);

    return null;
  }

  static List<String> _tokenize(String s) {
    return s
        .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static String _titleCase(String s) => s
      .split(' ')
      .where((e) => e.isNotEmpty)
      .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''))
      .join(' ');
}
