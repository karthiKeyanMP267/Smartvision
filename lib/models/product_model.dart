class Product {
  final String id;
  final String name;
  final String description;
  final String? barcode;
  final List<String> labels;
  final DateTime scannedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    this.barcode,
    required this.labels,
    required this.scannedAt,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'barcode': barcode,
      'labels': labels,
      'scannedAt': scannedAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      barcode: json['barcode'],
      labels: List<String>.from(json['labels'] ?? []),
      scannedAt: DateTime.parse(json['scannedAt']),
    );
  }

  @override
  String toString() {
    return 'Product: $name - $description';
  }
}
