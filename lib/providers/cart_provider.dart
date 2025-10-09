// lib/providers/cart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_service.dart';
import '../core/api_paths.dart';
import '../models/cart.dart';
import '../utils/cart_link_store.dart';
import 'auth_provider.dart';

final cartProvider = FutureProvider<CartModel>((ref) async {
  final res = await ApiService.instance.dio.get(ApiPaths.cart);
  return CartModel.fromJson(res.data as Map<String, dynamic>);
});

/// Ajoute/incrémente un item (obligatoire: restaurantId)
Future<void> addToCart(
    WidgetRef ref, {
      required int restaurantId,
      required String externalItemId,
      required String name,
      required num unitPrice,
      String? restaurantNameForUi, // affichage dans le panier
      int quantity = 1,
    }) async {
  // Envoi back
  await ApiService.instance.dio.post(ApiPaths.cart, data: {
    'restaurant_id': restaurantId,
    'external_item_id': externalItemId,
    'name': name,
    'unit_price': unitPrice,
    'quantity': quantity,
  });

  // Mapping local (namespacé par user)
  final user = ref.read(authProvider).user;
  final userId = (user?.pk ?? 0).toString(); // ✅ pk (pas id)
  await CartRestaurantLink.save(
    userId: userId,
    externalItemId: externalItemId,
    restaurantId: restaurantId,
    restaurantName: restaurantNameForUi,
  );

  ref.invalidate(cartProvider);
}

/// Retire un item (passer aussi restaurantId si possible pour lever l’ambiguïté)
Future<void> removeFromCart(
    WidgetRef ref, {
      required String externalItemId,
      int? restaurantId, // si non fourni on tente de le retrouver via mapping local
    }) async {
  final user = ref.read(authProvider).user;
  final userId = (user?.pk ?? 0).toString(); // ✅ pk

  final rid = restaurantId ?? await CartRestaurantLink.getRestaurantId(
    userId: userId,
    externalItemId: externalItemId,
  );

  await ApiService.instance.dio.delete(ApiPaths.cart, data: {
    'external_item_id': externalItemId,
    if (rid != null) 'restaurant_id': rid,
  });

  // Nettoie le mapping local
  await CartRestaurantLink.remove(userId: userId, externalItemId: externalItemId);

  ref.invalidate(cartProvider);
}

/// Définit une quantité cible (implémentation: delete puis post avec targetQty)
Future<void> setQuantity(
    WidgetRef ref, {
      int? restaurantId, // ✅ rendu optionnel : lookup si null
      required String externalItemId,
      required String name,
      required num unitPrice,
      required int targetQty,
      String? restaurantNameForUi,
    }) async {
  if (targetQty <= 0) {
    await removeFromCart(ref, externalItemId: externalItemId, restaurantId: restaurantId);
    return;
  }

  // Lookup si restaurantId non fourni
  int? rid = restaurantId;
  if (rid == null) {
    final user = ref.read(authProvider).user;
    final userId = (user?.pk ?? 0).toString();
    rid = await CartRestaurantLink.getRestaurantId(userId: userId, externalItemId: externalItemId);
  }
  if (rid == null) {
    // Sécurité : si on ne peut pas résoudre le restaurant, on fait un POST direct (créera/écrasera)
    // mais idéalement on a toujours le mapping grâce à addToCart/save()
    throw Exception('restaurant_id introuvable pour $externalItemId');
  }

  // Delete précis avec restaurant_id
  await ApiService.instance.dio.delete(ApiPaths.cart, data: {
    'external_item_id': externalItemId,
    'restaurant_id': rid,
  });

  // Ré-add avec la nouvelle quantité
  await ApiService.instance.dio.post(ApiPaths.cart, data: {
    'restaurant_id': rid,
    'external_item_id': externalItemId,
    'name': name,
    'unit_price': unitPrice,
    'quantity': targetQty,
  });

  // Met à jour/garantit le mapping
  final user = ref.read(authProvider).user;
  final userId = (user?.pk ?? 0).toString();
  await CartRestaurantLink.save(
    userId: userId,
    externalItemId: externalItemId,
    restaurantId: rid,
    restaurantName: restaurantNameForUi,
  );

  ref.invalidate(cartProvider);
}
