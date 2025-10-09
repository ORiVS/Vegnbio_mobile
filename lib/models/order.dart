//lib/models/order.dart
class OrderItemModel {
  final String externalItemId;
  final String name;
  final String unitPrice; // DRF renvoie des Decimal en string
  final int quantity;
  final String lineTotal; // string

  OrderItemModel({
    required this.externalItemId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> j) => OrderItemModel(
    externalItemId: j['external_item_id'] ?? '',
    name: j['name'] ?? '',
    unitPrice: j['unit_price'].toString(),
    quantity: (j['quantity'] as num?)?.toInt() ?? 0,
    lineTotal: j['line_total'].toString(),
  );
}

class OrderModel {
  final int id;
  final String status; // PENDING | PREPARING | OUT_FOR_DELIVERY | DELIVERED | CANCELLED
  final DateTime createdAt;

  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String postalCode;
  final String? phone;

  final int slot; // id du créneau

  final String subtotal;            // string
  final int discountPointsUsed;
  final String discountEuros;       // string
  final String totalPaid;           // string

  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.postalCode,
    required this.phone,
    required this.slot,
    required this.subtotal,
    required this.discountPointsUsed,
    required this.discountEuros,
    required this.totalPaid,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
    id: (j['id'] as num).toInt(),
    status: j['status'] ?? 'PENDING',
    createdAt: DateTime.parse(j['created_at']),
    addressLine1: j['address_line1'] ?? '',
    addressLine2: j['address_line2'],
    city: j['city'] ?? '',
    postalCode: j['postal_code'] ?? '',
    phone: j['phone'],
    slot: (j['slot'] as num).toInt(),
    subtotal: j['subtotal'].toString(),
    discountPointsUsed: (j['discount_points_used'] as num?)?.toInt() ?? 0,
    discountEuros: j['discount_euros'].toString(),
    totalPaid: j['total_paid'].toString(),
    items: ((j['items'] as List?) ?? [])
        .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
