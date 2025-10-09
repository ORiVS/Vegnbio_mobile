// lib/providers/reservations_provider.dart
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

/// ---- Créer une réservation (CLIENT) ----
/// Envoie UNIQUEMENT les champs autorisés côté API:
/// restaurant, date (YYYY-MM-DD), start_time/end_time (HH:MM:SS), party_size
Future<ApiError?> createReservation({
  required int restaurantId,
  required String date,       // YYYY-MM-DD
  required String startTime,  // HH:MM
  required String endTime,    // HH:MM
  required int partySize,     // > 0
}) async {
  try {
    final payload = {
      'restaurant': restaurantId,
      'date': date,
      'start_time': '$startTime:00',
      'end_time': '$endTime:00',
      'party_size': partySize,
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

/// ---- Assignation (restaurateur) ----
/// Affecter une salle au créneau
Future<ApiError?> assignReservationToRoom({
  required int reservationId,
  required int roomId,
}) async {
  try {
    await ApiService.instance.dio.post(
      '${ApiPaths.reservationDetail(reservationId)}assign/',
      data: {'room': roomId},
    );
    return null;
  } on DioException catch (e) {
    return ApiError.fromDio(e);
  } catch (e) {
    return ApiError(messages: [e.toString()]);
  }
}

/// Réserver tout le restaurant sur ce créneau
Future<ApiError?> assignReservationAsFull(int reservationId) async {
  try {
    await ApiService.instance.dio.post(
      '${ApiPaths.reservationDetail(reservationId)}assign/',
      data: {'full_restaurant': true},
    );
    return null;
  } on DioException catch (e) {
    return ApiError.fromDio(e);
  } catch (e) {
    return ApiError(messages: [e.toString()]);
  }
}
