import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cloud-based product identification service
/// Uses OpenFoodFacts API (free, community-driven food product database)
class OnlineProductService {
  static const String _openFoodFactsApiBase = 'https://world.openfoodfacts.org/api/v2';
  
  /// Search for product by barcode (most accurate)
  Future<ProductInfo?> searchByBarcode(String barcode) async {
    try {
      final url = Uri.parse('$_openFoodFactsApiBase/product/$barcode');
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          return _parseOpenFoodFactsProduct(data['product']);
        }
      }
    } catch (e) {
      print('Barcode search error: $e');
    }
    return null;
  }

  /// Search for product by text keywords (ingredients, brand names, etc.)
  Future<ProductInfo?> searchByText(String text) async {
    if (text.trim().isEmpty) return null;
    
    try {
      // Extract meaningful keywords from OCR text - prioritize brand names
      final brandName = _extractBrandName(text);
      final keywords = _extractKeywords(text);
      
      // Build smart search query: prefer brand + category
      String searchTerm;
      if (brandName != null && brandName.isNotEmpty) {
        searchTerm = brandName;
        // Add category hint if detected
        final category = _detectCategory(text, []);
        if (category != null) searchTerm += ' $category';
      } else if (keywords.isNotEmpty) {
        searchTerm = keywords.take(3).join(' ');
      } else {
        return null;
      }
      
      // Search OpenFoodFacts
      final url = Uri.parse('$_openFoodFactsApiBase/search')
          .replace(queryParameters: {
        'search_terms': searchTerm,
        'page_size': '5',
        'fields': 'product_name,brands,categories,ingredients_text',
      });
      
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = data['products'] as List?;
        
        if (products != null && products.isNotEmpty) {
          // Return the first/best match
          return _parseOpenFoodFactsProduct(products.first);
        }
      }
    } catch (e) {
      print('Text search error: $e');
    }
    return null;
  }

  /// Intelligent product name inference using AI-like heuristics + API fallback
  Future<ProductInfo?> identifyProduct({
    String? barcode,
    String? text,
    List<String>? labels,
  }) async {
    final formattedText = _formatDetectedText(text ?? '');
    
    // 1. Try local brand + category extraction FIRST (most reliable for common brands)
    final localInferred = _inferFromLabelsAndText(text ?? '', labels ?? []);
    if (localInferred != null && localInferred != 'Unknown Product') {
      // If we have a confident local match, use it
      return ProductInfo(
        name: localInferred,
        brand: _extractBrandName(text ?? ''),
        category: _detectCategory(text ?? '', labels ?? []),
        description: formattedText,
      );
    }

    // 2. Try barcode lookup (for packaged products with visible barcodes)
    if (barcode != null && barcode.isNotEmpty) {
      final result = await searchByBarcode(barcode);
      if (result != null) {
        return ProductInfo(
          name: result.name,
          brand: result.brand,
          category: result.category,
          description: formattedText,
        );
      }
    }

    // 3. Only try text-based API search if local inference failed
    // (API can be unreliable for visual product recognition)
    if (text != null && text.isNotEmpty) {
      final result = await searchByText(text);
      // Validate API result - reject if it seems unrelated
      if (result != null && _isValidApiResult(result, text, labels ?? [])) {
        return ProductInfo(
          name: result.name,
          brand: result.brand,
          category: result.category,
          description: formattedText,
        );
      }
    }

    // 4. Last resort: return local inference even if not confident
    if (localInferred != null) {
      return ProductInfo(
        name: localInferred,
        brand: null,
        category: null,
        description: formattedText,
      );
    }

    return null;
  }

  /// Validate API results to avoid false matches
  bool _isValidApiResult(ProductInfo result, String text, List<String> labels) {
    final resultLower = result.name.toLowerCase();
    final textLower = text.toLowerCase();
    
    // Check if the API result name appears in the detected text
    final resultWords = resultLower.split(' ');
    for (final word in resultWords) {
      if (word.length >= 4 && textLower.contains(word)) {
        return true; // Found matching word
      }
    }
    
    // Check brand name match
    if (result.brand != null) {
      final brandLower = result.brand!.toLowerCase();
      if (textLower.contains(brandLower)) return true;
    }
    
    return false; // API result doesn't match detected text
  }

  ProductInfo _parseOpenFoodFactsProduct(Map<String, dynamic> product) {
    String name = product['product_name'] ?? product['generic_name'] ?? 'Unknown Product';
    String? brand = product['brands'];
    String? category = product['categories'];
    
    // Clean up category (take first main category)
    if (category != null && category.contains(',')) {
      category = category.split(',').first.trim();
    }

    return ProductInfo(
      name: name.trim(),
      brand: brand?.trim(),
      category: category?.trim(),
      description: product['ingredients_text']?.toString().trim(),
    );
  }

  List<String> _extractKeywords(String text) {
    final normalized = text.toLowerCase();
    final lines = normalized.split('\n');
    
    // Common food/product keywords to prioritize
    final meaningfulWords = <String>[];
    
    for (final line in lines) {
      final words = line
          .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
          .split(RegExp(r'\s+'))
          .where((w) => w.length >= 3)
          .toList();
      
      // Prioritize food-related keywords
      for (final word in words) {
        if (_isMeaningfulKeyword(word)) {
          meaningfulWords.add(word);
          if (meaningfulWords.length >= 5) break;
        }
      }
      if (meaningfulWords.length >= 5) break;
    }
    
    return meaningfulWords;
  }

  /// Extract brand name from OCR text (first prominent capitalized words)
  String? _extractBrandName(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    
    // Common Indian/global food brands (prioritize exact matches)
    const knownBrands = {
      'britannia', 'parle', 'nestle', 'maggi', 'lays', 'cadbury',
      'amul', 'haldiram', 'kwality', 'mother dairy',
      'good day', 'goodday', 'oreo', 'bournvita', 'horlicks',
      'dettol', 'lifebuoy', 'colgate', 'pepsodent', 'head shoulders',
      'dove', 'pantene', 'sunsilk', 'clinic plus', 'tresemme',
      'coca cola', 'pepsi', 'sprite', 'fanta', 'mountain dew',
      'mccain', 'mtr', 'mdh', 'everest', 'catch', 'aashirvaad',
      'hellmanns', 'hellmann', 'kissan', 'heinz', 'knorr', 'del monte',
    };
    
    for (final line in lines.take(7)) {
      final normalized = line.toLowerCase().trim();
      
      // Check against known brands (exact substring match)
      for (final brand in knownBrands) {
        if (normalized.contains(brand)) {
          // Special formatting for specific brands
          if (brand == 'hellmanns' || brand == 'hellmann') return "Hellmann's";
          if (brand == 'good day' || brand == 'goodday') return 'Good Day';
          if (brand == 'lays') return "Lay's";
          if (brand == 'haldiram') return "Haldiram's";
          if (brand == 'mother dairy') return 'Mother Dairy';
          if (brand == 'head shoulders') return 'Head & Shoulders';
          if (brand == 'del monte') return 'Del Monte';
          return _capitalize(brand);
        }
      }
    }
    
    // If no known brand found, extract first prominent capitalized word
    for (final line in lines.take(5)) {
      final words = line.trim().split(RegExp(r'\s+'));
      if (words.isNotEmpty && words.first.length >= 3) {
        final firstWord = words.first.toLowerCase();
        if (!_isCommonWord(firstWord)) {
          // Return up to 2 words as potential brand name
          return words.take(2).join(' ').trim();
        }
      }
    }
    
    return null;
  }

  String _capitalize(String s) {
    return s.split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Detect product category from text and labels
  String? _detectCategory(String text, List<String> labels) {
    final t = text.toLowerCase();
    final allTokens = [...labels.map((l) => l.toLowerCase()), t];
    
    bool hasAny(List<String> words) => 
        allTokens.any((token) => words.any((w) => token.contains(w)));
    
    if (hasAny(['biscuit', 'cookie', 'butter cookies'])) return 'Biscuits';
    if (hasAny(['chips', 'wafers'])) return 'Chips';
    if (hasAny(['chocolate', 'cocoa'])) return 'Chocolate';
    if (hasAny(['noodle', 'noodles', 'pasta'])) return 'Noodles';
    if (hasAny(['ketchup', 'sauce'])) return 'Sauce';
    if (hasAny(['drink', 'cola', 'juice', 'beverage'])) return 'Beverage';
    if (hasAny(['toothpaste', 'dental'])) return 'Toothpaste';
    if (hasAny(['soap', 'handwash'])) return 'Soap';
    
    return null;
  }

  bool _isCommonWord(String word) {
    const common = {
      'the', 'and', 'for', 'with', 'from', 'new', 'best',
      'premium', 'quality', 'fresh', 'pure', 'natural',
    };
    return common.contains(word);
  }

  bool _isMeaningfulKeyword(String word) {
    // Filter out nutritional info, common filler words
    const skipWords = {
      'serving', 'per', 'energy', 'kcal', 'protein', 'carbohydrate',
      'fat', 'sugar', 'salt', 'cholesterol', 'sodium', 'weight',
      'net', 'gross', 'contains', 'manufactured', 'ingredients',
      'information', 'nutritional', 'approx', 'size',
    };
    
    if (skipWords.contains(word) || word.length < 3) return false;
    if (RegExp(r'^\d+$').hasMatch(word)) return false; // Skip pure numbers
    
    return true;
  }

  /// Local fallback inference when API fails
  String? _inferFromLabelsAndText(String text, List<String> labels) {
    final t = text.toLowerCase();
    final tokens = <String>[]
      ..addAll(_tokenize(t))
      ..addAll(labels.map((e) => e.toLowerCase()));

    bool hasAny(Iterable<String> keys) =>
        keys.any((k) => tokens.any((t) => t.contains(k)) || t.contains(k));

    // Extract brand + category for better names
    final brandName = _extractBrandName(text);
    final category = _detectCategory(text, labels);

    // Priority 1: Specific product type detection (MOST IMPORTANT)
    // These rules identify WHAT the product is, not just the brand
    
    // Mayonnaise detection
    if (hasAny(['mayonnaise', 'mayo']) || t.contains('mayonnaise')) {
      return brandName != null ? '$brandName Mayonnaise' : 'Mayonnaise';
    }
    
    // Ketchup/Sauce detection
    if (hasAny(['ketchup']) || (hasAny(['tomato']) && hasAny(['sauce']))) {
      return brandName != null ? '$brandName Ketchup' : 'Tomato Ketchup';
    }
    
    if (hasAny(['snack dressing', 'dressing']) && hasAny(['tomato'])) {
      return brandName != null ? '$brandName Snack Dressing' : 'Tomato Snack Dressing';
    }
    
    // Specific branded products
    if ((hasAny(['good day', 'goodday']) || hasAny(['britannia'])) && 
        hasAny(['butter', 'biscuit', 'cookie', 'comes', 'cakes'])) {
      if (brandName != null && brandName.toLowerCase().contains('good')) {
        return 'Good Day Butter Cookies';
      }
      return 'Britannia Good Day Cookies';
    }
    
    if (hasAny(['britannia']) && hasAny(['marie', 'gold'])) {
      return 'Britannia Marie Gold Biscuits';
    }
    
    if (hasAny(['oreo']) && hasAny(['biscuit', 'cookie'])) {
      return 'Oreo Cookies';
    }
    
    if (hasAny(['parle', 'parleg']) && hasAny(['biscuit', 'cookie'])) {
      return 'Parle-G Biscuits';
    }

    // Priority 2: Build from brand + detected category
    if (brandName != null && category != null) {
      return '$brandName $category';
    }
    
    // Priority 3: Brand + inferred product type from keywords
    if (brandName != null) {
      if (hasAny(['biscuit', 'cookie', 'butter'])) return '$brandName Cookies';
      if (hasAny(['chips', 'wafers'])) return '$brandName Chips';
      if (hasAny(['chocolate'])) return '$brandName Chocolate';
      if (hasAny(['noodle', 'noodles'])) return '$brandName Noodles';
      if (hasAny(['sauce'])) return '$brandName Sauce';
      if (hasAny(['toothpaste'])) return '$brandName Toothpaste';
      if (hasAny(['handwash', 'hand wash'])) return '$brandName Hand Wash';
      if (hasAny(['shampoo'])) return '$brandName Shampoo';
      if (hasAny(['soap'])) return '$brandName Soap';
      // If we can't determine product type, just return brand
      return brandName;
    }

    // Priority 4: Enhanced heuristic rules for generic products (no brand detected)
    if (hasAny(['toothpaste', 'colgate', 'pepsodent', 'dental'])) return 'Toothpaste';
    if (hasAny(['handwash', 'hand wash', 'dettol', 'lifebuoy'])) return 'Hand Wash';
    if (hasAny(['noodle', 'noodles', 'maggi', 'ramen', 'instant'])) return 'Instant Noodles';
    if (hasAny(['lays']) || (hasAny(['chips', 'wafers']) && hasAny(['potato']))) return 'Potato Chips';
    if (hasAny(['coca', 'coke', 'cola', 'pepsi'])) return 'Soft Drink';
    if (hasAny(['biscuit', 'cookie']) && brandName == null) return 'Biscuits';
    if (hasAny(['chocolate', 'cocoa', 'cadbury'])) return 'Chocolate';
    if (hasAny(['masala', 'spice mix', 'seasoning'])) return 'Spice Mix';
    if (hasAny(['chutney']) && hasAny(['mint', 'coriander', 'tamarind'])) return 'Chutney';
    
    // Priority 5: Generic category-based fallback
    if (category != null) return category;
    
    return null;
  }

  List<String> _tokenize(String s) {
    return s
        .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((e) => e.length >= 3)
        .toList();
  }

  /// Format detected text to show meaningful content (filter noise)
  String _formatDetectedText(String text) {
    if (text.trim().isEmpty) return '';
    
    final lines = text.split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && _isMeaningfulLine(line))
        .toList();
    
    if (lines.isEmpty) return '';
    
    // Take up to 8 most relevant lines
    final relevantLines = lines.take(8).toList();
    return relevantLines.join('\n');
  }

  /// Check if a line contains meaningful product information
  bool _isMeaningfulLine(String line) {
    final lower = line.toLowerCase();
    
    // Skip very short lines (likely noise)
    if (line.length < 2) return false;
    
    // Skip lines that are mostly numbers or symbols
    final alphaCount = line.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (alphaCount < 2) return false;
    
    // Skip common noise patterns
    const skipPatterns = [
      'serving', 'per', 'energy', 'kcal', 'protein', 'carbohydrate',
      'fat', 'sugar', 'salt', 'cholesterol', 'sodium', 'fiber',
      'calcium', 'iron', 'vitamin', 'daily value', 'approx',
      'net wt', 'gross wt', 'weight', 'manufactured', 'distributor',
      'customer care', 'batch', 'expiry', 'best before', 'use by',
      'made in', 'product of', 'ingredients:', 'contains:',
      'allergen', 'warning', 'keep', 'store', 'refrigerate',
      'fl oz', 'ml', 'litre', 'kg', 'grams', 'lb',
    ];
    
    for (final pattern in skipPatterns) {
      if (lower.contains(pattern)) return false;
    }
    
    // Skip lines that are just numbers with units
    if (RegExp(r'^\d+\s*(mg|g|kg|ml|l|oz|lb|%)\s*$', caseSensitive: false).hasMatch(line)) {
      return false;
    }
    
    return true;
  }
}

/// Product information from online API
class ProductInfo {
  final String name;
  final String? brand;
  final String? category;
  final String? description;

  ProductInfo({
    required this.name,
    this.brand,
    this.category,
    this.description,
  });

  @override
  String toString() {
    final parts = <String>[name];
    if (brand != null && brand!.isNotEmpty) parts.add('by $brand');
    return parts.join(' ');
  }
}
