class SupplierOffer {
  final int id;
  final String productName;
  final String? description;
  final bool isBio;
  final String? producerName;
  final String region;
  final List<int> allergens; // ids (PK)
  final String unit;
  final String price;        // Decimal -> string
  final String minOrderQty;  // Decimal -> string
  final String stockQty;     // Decimal -> string
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final String status;       // DRAFT | PUBLISHED | UNLISTED | FLAGGED
  final double? avgRating;
  final DateTime createdAt;

  SupplierOffer({
    required this.id,
    required this.productName,
    required this.description,
    required this.isBio,
    required this.producerName,
    required this.region,
    required this.allergens,
    required this.unit,
    required this.price,
    required this.minOrderQty,
    required this.stockQty,
    required this.availableFrom,
    required this.availableTo,
    required this.status,
    required this.avgRating,
    required this.createdAt,
  });

  factory SupplierOffer.fromJson(Map<String, dynamic> j) => SupplierOffer(
    id: (j['id'] as num).toInt(),
    productName: j['product_name'] ?? '',
    description: j['description'],
    isBio: j['is_bio'] == true,
    producerName: j['producer_name'],
    region: j['region'] ?? '',
    allergens: ((j['allergens'] as List?) ?? []).map((e) => (e as num).toInt()).toList(),
    unit: j['unit'] ?? 'kg',
    price: j['price'].toString(),
    minOrderQty: j['min_order_qty'].toString(),
    stockQty: j['stock_qty'].toString(),
    availableFrom: j['available_from'] != null ? DateTime.parse(j['available_from']) : null,
    availableTo: j['available_to'] != null ? DateTime.parse(j['available_to']) : null,
    status: j['status'] ?? 'DRAFT',
    avgRating: j['avg_rating'] == null ? null : (j['avg_rating'] as num).toDouble(),
    createdAt: DateTime.parse(j['created_at']),
  );
}
