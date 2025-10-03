// lib/models/user.dart
class RestaurantLite {
  final int id;
  final String name;
  final String? city;
  RestaurantLite({required this.id, required this.name, this.city});
  factory RestaurantLite.fromJson(Map<String, dynamic> j) => RestaurantLite(
    id: (j['id'] as num).toInt(),
    name: j['name'] ?? '',
    city: j['city'] as String?,
  );
}

class UserProfile {
  final String? phone;
  final String? address;
  final String? allergies;
  UserProfile({this.phone, this.address, this.allergies});
  factory UserProfile.fromJson(Map<String, dynamic>? j) => UserProfile(
    phone: j?['phone'] as String?,
    address: j?['address'] as String?,
    allergies: j?['allergies'] as String?,
  );
}

class VegUser {
  /// Identifiant utilisateur (id/pk/user_id suivant ce que renvoie l’API)
  final int? pk;

  final String email;
  final String firstName;
  final String lastName;
  final String role; // CLIENT | FOURNISSEUR | RESTAURATEUR | ADMIN
  final List<RestaurantLite> restaurants;
  final int? activeRestaurantId;
  final UserProfile? profile;

  VegUser({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.restaurants,
    this.activeRestaurantId,
    this.profile,
    this.pk,
  });

  static int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  factory VegUser.fromJson(Map<String, dynamic> j) => VegUser(
    // ✅ récupère id, sinon pk, sinon user_id
    pk: _toIntOrNull(j['id']) ??
        _toIntOrNull(j['pk']) ??
        _toIntOrNull(j['user_id']),
    email: j['email'] ?? '',
    firstName: j['first_name'] ?? '',
    lastName: j['last_name'] ?? '',
    role: j['role'] ?? 'CLIENT',
    restaurants: ((j['restaurants'] as List?) ?? [])
        .map((e) => RestaurantLite.fromJson(e as Map<String, dynamic>))
        .toList(),
    activeRestaurantId: j['active_restaurant_id'] as int?,
    profile: j['profile'] == null
        ? null
        : UserProfile.fromJson(j['profile'] as Map<String, dynamic>),
  );
}
