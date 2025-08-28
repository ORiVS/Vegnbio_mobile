import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_service.dart';
import '../models/reservation.dart';

final myReservationsProvider = FutureProvider<List<Reservation>>((ref) async {
  final res = await ApiService.instance.dio.get('/api/reservations/');
  return (res.data as List).map((e) => Reservation.fromJson(e)).toList();
});

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
    final res = await ApiService.instance.dio.post('/api/reservations/', data: payload);
    return res.statusCode == 201 ? null : 'Réservation impossible';
  } catch (e) {
    // Dio renvoie souvent un message détaillé côté DRF
    return e.toString();
  }
}

Future<String?> cancelReservation(int id) async {
  try {
    await ApiService.instance.dio.post('/api/reservations/$id/cancel/');
    return null;
  } catch (e) {
    return e.toString();
  }
}

// ---- Restaurateur ----
final restoReservationsProvider = FutureProvider.family<List<Reservation>, int>((ref, restaurantId) async {
  final res =
  await ApiService.instance.dio.get('/api/restaurants/$restaurantId/reservations/');
  return (res.data as List).map((e) => Reservation.fromJson(e)).toList();
});

Future<String?> moderateReservation(int id, String newStatus) async {
  try {
    await ApiService.instance.dio.post('/api/reservations/$id/moderate/', data: {'status': newStatus});
    return null;
  } catch (e) {
    return e.toString();
  }
}
