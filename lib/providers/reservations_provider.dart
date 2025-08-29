import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../core/api_service.dart';
import '../core/api_paths.dart';
import '../core/api_error.dart';
import '../models/reservation.dart';

List<dynamic> _extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map && data['results'] is List) return data['results'] as List;
  // on tolère aussi un objet "count/results" DRF
  if (data is Map && data['count'] is int && data['results'] is List) {
    return data['results'] as List;
  }
  throw Exception('Réponse inattendue depuis ${ApiPaths.reservationsList}');
}

/// ---- Mes réservations (client) ----
/// GET /api/restaurants/reservations/   (le ViewSet filtre côté serveur)
final myReservationsProvider = FutureProvider<List<Reservation>>((ref) async {
  final res = await ApiService.instance.dio.get(ApiPaths.reservationsList);
  final list = _extractList(res.data);
  return list.map((e) => Reservation.fromJson(e as Map<String, dynamic>)).toList();
});

/// ---- Réservations d’un restaurant (restaurateur propriétaire) ----
final restoReservationsProvider =
FutureProvider.family<List<Reservation>, int>((ref, restaurantId) async {
  final url = ApiPaths.restaurantOwnerReservations(restaurantId);
  final res = await ApiService.instance.dio.get(url);
  final list = _extractList(res.data);
  return list.map((e) => Reservation.fromJson(e as Map<String, dynamic>)).toList();
});

/// ---- Créer une réservation ----
/// Retourne `null` si OK, sinon `ApiError` prêt pour showErrorDialog(...)
Future<ApiError?> createReservation({
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
    await ApiService.instance.dio.post(ApiPaths.reservationsList, data: payload);
    return null;
  } on DioException catch (e) {
    return ApiError.fromDio(e);
  } catch (e) {
    return ApiError(messages: [e.toString()]);
  }
}

/// ---- Annuler (client ou restaurateur) ----
Future<ApiError?> cancelReservation(int id) async {
  try {
    await ApiService.instance.dio.post(ApiPaths.reservationCancel(id));
    return null;
  } on DioException catch (e) {
    return ApiError.fromDio(e);
  } catch (e) {
    return ApiError(messages: [e.toString()]);
  }
}

/// ---- Modération (restaurateur) ----
Future<ApiError?> moderateReservation(int id, String newStatus) async {
  try {
    await ApiService.instance.dio.post(
      ApiPaths.reservationModerate(id),
      data: {'status': newStatus},
    );
    return null;
  } on DioException catch (e) {
    return ApiError.fromDio(e);
  } catch (e) {
    return ApiError(messages: [e.toString()]);
  }
}
