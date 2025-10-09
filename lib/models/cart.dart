//lib/models/cart.dart
class CartItemModel {
  final int id;
  final String externalItemId;
  final String name;
  final String unitPrice; // Decimal -> string
  final int quantity;
  final String lineTotal; // string

  CartItemModel({
    required this.id,
    required this.externalItemId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> j) => CartItemModel(
    id: (j['id'] as num).toInt(),
    externalItemId: j['external_item_id'] ?? '',
    name: j['name'] ?? '',
    unitPrice: j['unit_price'].toString(),
    quantity: (j['quantity'] as num?)?.toInt() ?? 0,
    lineTotal: j['line_total'].toString(),
  );
}

class CartModel {
  final List<CartItemModel> items;
  final String total; // string

  CartModel({required this.items, required this.total});

  factory CartModel.fromJson(Map<String, dynamic> j) => CartModel(
    items: ((j['items'] as List?) ?? [])
        .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    total: j['total'].toString(),
  );

  int get itemsCount => items.fold(0, (a, b) => a + b.quantity);
}
