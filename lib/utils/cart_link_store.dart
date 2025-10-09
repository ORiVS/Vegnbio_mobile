// lib/utils/cart_link_store.dart
import 'package:shared_preferences/shared_preferences.dart';

class CartRestaurantLink {
  static String _kId(String userId, String extId) => 'cart_link::$userId::$extId::id';
  static String _kName(String userId, String extId) => 'cart_link::$userId::$extId::name';

  /// Enregistre le lien (id + nom du resto). Appelez lors de l'ajout au panier.
  static Future<void> save({
    required String userId,
    required String externalItemId,
    required int restaurantId,
    String? restaurantName,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kId(userId, externalItemId), restaurantId);
    if (restaurantName != null && restaurantName.isNotEmpty) {
      await p.setString(_kName(userId, externalItemId), restaurantName);
    }
  }

  /// Lit le restaurantId associé à un extId (retourne null si absent)
  static Future<int?> getRestaurantId({
    required String userId,
    required String externalItemId,
  }) async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kId(userId, externalItemId));
  }

  /// Lit le nom du restaurant associé (optionnel)
  static Future<String?> getRestaurantName({
    required String userId,
    required String externalItemId,
  }) async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kName(userId, externalItemId));
  }

  /// Supprime le lien pour un extId
  static Future<void> remove({
    required String userId,
    required String externalItemId,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kId(userId, externalItemId));
    await p.remove(_kName(userId, externalItemId));
  }

  /// Supprime tous les liens d’un utilisateur (à appeler à la déconnexion si besoin)
  static Future<void> clearAllForUser(String userId) async {
    final p = await SharedPreferences.getInstance();
    final keys = p.getKeys().where((k) => k.startsWith('cart_link::$userId::')).toList();
    for (final k in keys) {
      await p.remove(k);
    }
  }
}
