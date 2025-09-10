import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_service.dart';
import '../core/api_paths.dart';
import '../models/cart.dart';

final cartProvider = FutureProvider<CartModel>((ref) async {
  final res = await ApiService.instance.dio.get(ApiPaths.cart);
  return CartModel.fromJson(res.data as Map<String, dynamic>);
});

/// Ajoute/incrémente une quantité pour un item
Future<void> addToCart(WidgetRef ref, {
  required String externalItemId,
  required String name,
  required num unitPrice,
  int quantity = 1,
}) async {
  await ApiService.instance.dio.post(ApiPaths.cart, data: {
    'external_item_id': externalItemId,
    'name': name,
    'unit_price': unitPrice,
    'quantity': quantity,
  });
  ref.invalidate(cartProvider);
}

/// Retire un item du panier (supprime la ligne)
Future<void> removeFromCart(WidgetRef ref, {required String externalItemId}) async {
  await ApiService.instance.dio.delete(ApiPaths.cart, data: {
    'external_item_id': externalItemId,
  });
  ref.invalidate(cartProvider);
}

/// Définit une quantité cible : on supprime puis on ré-ajoute avec la nouvelle qty
Future<void> setQuantity(WidgetRef ref, {
  required String externalItemId,
  required String name,
  required num unitPrice,
  required int targetQty,
}) async {
  if (targetQty <= 0) {
    await removeFromCart(ref, externalItemId: externalItemId);
    return;
  }
  // backend ne supporte pas decrement direct: on réécrit la ligne
  await ApiService.instance.dio.delete(ApiPaths.cart, data: {
    'external_item_id': externalItemId,
  });
  await ApiService.instance.dio.post(ApiPaths.cart, data: {
    'external_item_id': externalItemId,
    'name': name,
    'unit_price': unitPrice,
    'quantity': targetQty,
  });
  ref.invalidate(cartProvider);
}
