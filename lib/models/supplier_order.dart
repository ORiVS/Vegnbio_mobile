// lib/models/supplier_order.dart
class SupplierOrderItem {
  final int id;
  final int offerId;
  final String productName;
  final String unit;
  final String qtyRequested;  // string pour garder la décimale exacte
  final String? qtyConfirmed; // peut être null tant que non validé
  final String unitPrice;     // prix au moment de la commande (string)

  SupplierOrderItem({
    required this.id,
    required this.offerId,
    required this.productName,
    required this.unit,
    required this.qtyRequested,
    required this.qtyConfirmed,
    required this.unitPrice,
  });

  factory SupplierOrderItem.fromJson(Map<String, dynamic> j) => SupplierOrderItem(
    id: (j['id'] as num).toInt(),
    offerId: (j['offer'] as num).toInt(),
    productName: j['product_name'] ?? '',
    unit: j['unit'] ?? '',
    qtyRequested: j['qty_requested'].toString(),
    qtyConfirmed: j['qty_confirmed']?.toString(),
    unitPrice: j['unit_price'].toString(),
  );
}

class SupplierOrder {
  final int id;
  final int restaurateurId;
  final int supplierId;
  final String status; // PENDING_SUPPLIER | CONFIRMED | PARTIALLY_CONFIRMED | REJECTED | CANCELLED
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final String? note;
  final List<SupplierOrderItem> items;

  SupplierOrder({
    required this.id,
    required this.restaurateurId,
    required this.supplierId,
    required this.status,
    required this.createdAt,
    required this.confirmedAt,
    required this.note,
    required this.items,
  });

  factory SupplierOrder.fromJson(Map<String, dynamic> j) => SupplierOrder(
    id: (j['id'] as num).toInt(),
    restaurateurId: (j['restaurateur'] as num).toInt(),
    supplierId: (j['supplier'] as num).toInt(),
    status: j['status'] ?? 'PENDING_SUPPLIER',
    createdAt: DateTime.parse(j['created_at']),
    confirmedAt: j['confirmed_at'] == null ? null : DateTime.parse(j['confirmed_at']),
    note: j['note'],
    items: ((j['items'] as List?) ?? [])
        .map((e) => SupplierOrderItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
