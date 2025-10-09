// lib/providers/events_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../core/api_service.dart';
import '../core/api_paths.dart';
import '../core/api_error.dart';
import '../models/event.dart';
import '../models/event_registration.dart';

List<dynamic> _extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map && data['results'] is List) return data['results'] as List;
  if (data is Map && data['count'] is int && data['results'] is List) return data['results'] as List;
  throw Exception('Réponse inattendue depuis ${ApiPaths.events}');
}

/// Liste des évènements publiés (tous restaurants)
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final res = await ApiService.instance.dio.get(
    ApiPaths.events,
    queryParameters: {'status': 'PUBLISHED'},
  );
  final list = _extractList(res.data);
  return list.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
});

/// Détail
final eventDetailProvider = FutureProvider.family<Event, int>((ref, id) async {
  final res = await ApiService.instance.dio.get(ApiPaths.eventDetail(id));
  return Event.fromJson(res.data as Map<String, dynamic>);
});

/// Infos d’inscription (côté client : {count, me:{registered,...}})
final eventRegInfoProvider =
FutureProvider.family<EventRegistrationInfo, int>((ref, id) async {
  final res = await ApiService.instance.dio.get(ApiPaths.eventRegistrations(id));
  return EventRegistrationInfo.fromJson(res.data as Map<String, dynamic>);
});

/// S’inscrire (API publique côté back)
Future<ApiError?> registerToEvent(int id) async {
  try {
    await ApiService.instance.dio.post(ApiPaths.eventRegister(id));
    return null;
  } on DioException catch (e) {
    return ApiError.fromDio(e);
  } catch (e) {
    return ApiError(messages: [e.toString()]);
  }
}

/// Se désinscrire
Future<ApiError?> unregisterFromEvent(int id) async {
  try {
    await ApiService.instance.dio.post(ApiPaths.eventUnregister(id));
    return null;
  } on DioException catch (e) {
    return ApiError.fromDio(e);
  } catch (e) {
    return ApiError(messages: [e.toString()]);
  }
}

/// (Optionnel) Accepter une invitation par TOKEN (si besoin)
Future<ApiError?> acceptEventInviteWithToken({
  required int eventId,
  required String token,
}) async {
  try {
    await ApiService.instance.dio.post(
      ApiPaths.eventAcceptInvite(eventId),
      data: {'token': token},
    );
    return null;
  } on DioException catch (e) {
    return ApiError.fromDio(e);
  } catch (e) {
    return ApiError(messages: [e.toString()]);
  }
}
