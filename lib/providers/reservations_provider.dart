import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_service.dart';
import '../core/api_paths.dart';
import '../models/reservation.dart';

List<dynamic> _extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map && data['results'] is List) return data['results'] as List;
  throw Exception('Réponse inattendue depuis ${ApiPaths.reservationsList}');
}

// ---- Mes réservations (client) ----
final myReservationsProvider = FutureProvider<List<Reservation>>((ref) async {
  print('[RESAS] GET ${ApiPaths.reservationsList}');
  final res = await ApiService.instance.dio.get(ApiPaths.reservationsList);
  final list = _extractList(res.data);
  final parsed = list.map((e) => Reservation.fromJson(e as Map<String, dynamic>)).toList();
  print('[RESAS] loaded=${parsed.length}');
  return parsed;
});

// ---- Créer une réservation ----
Future<String?> createReservation({
  required int? restaurantId,
  required int? roomId,
  required String date,       // YYYY-MM-DD
  required String startTime,  // HH:MM
  required String endTime,    // HH:MM
  required bool fullRestaurant,
}) async {
  try {
    final payload = {
      'date': date,
      'start_time': '$startTime:00',
      'end_time': '$endTime:00',
      'full_restaurant': fullRestaurant,
      if (fullRestaurant) 'restaurant': restaurantId,
      if (!fullRestaurant) 'room': roomId,
    };
    print('[RESAS] POST ${ApiPaths.reservationsList} payload=$payload');
    final res = await ApiService.instance.dio.post(ApiPaths.reservationsList, data: payload);
    final ok = res.statusCode == 201 || res.statusCode == 200;
    print('[RESAS] create status=${res.statusCode} ok=$ok body=${res.data}');
    return ok ? null : 'Réservation impossible';
  } catch (e) {
    print('[RESAS] create error=$e');
    return e.toString();
  }
}

// ---- Annuler (client ou restaurateur) ----
Future<String?> cancelReservation(int id) async {
  try {
    final url = ApiPaths.reservationCancel(id);
    print('[RESAS] POST $url');
    final res = await ApiService.instance.dio.post(url);
    print('[RESAS] cancel status=${res.statusCode} body=${res.data}');
    return null;
  } catch (e) {
    print('[RESAS] cancel error=$e');
    return e.toString();
  }
}

// ---- Réservations d’un restaurant (restaurateur propriétaire) ----
final restoReservationsProvider =
FutureProvider.family<List<Reservation>, int>((ref, restaurantId) async {
  final url = ApiPaths.restaurantOwnerReservations(restaurantId);
  print('[RESAS] GET $url');
  final res = await ApiService.instance.dio.get(url);
  final list = _extractList(res.data);
  final parsed = list.map((e) => Reservation.fromJson(e as Map<String, dynamic>)).toList();
  print('[RESAS] owner list loaded=${parsed.length}');
  return parsed;
});

// ---- Modération (restaurateur) ----
Future<String?> moderateReservation(int id, String newStatus) async {
  try {
    final url = ApiPaths.reservationModerate(id);
    print('[RESAS] POST $url body={status: $newStatus}');
    final res = await ApiService.instance.dio.post(url, data: {'status': newStatus});
    print('[RESAS] moderate status=${res.statusCode} body=${res.data}');
    return null;
  } catch (e) {
    print('[RESAS] moderate error=$e');
    return e.toString();
  }
}
