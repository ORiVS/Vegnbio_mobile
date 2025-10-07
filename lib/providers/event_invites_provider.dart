// lib/providers/event_invites_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api_service.dart';
import '../core/api_paths.dart';
import '../models/event_invite.dart';

List _extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map && data['results'] is List) return data['results'] as List;
  return const [];
}

String friendlyError(Object e) {
  if (e is DioException) {
    final d = e.response?.data;
    if (d is Map && d['detail'] is String && d['detail'].toString().trim().isNotEmpty) {
      return d['detail'] as String;
    }
    if (d is String && d.trim().isNotEmpty) return d;
    final c = e.response?.statusCode;
    return c != null ? 'Erreur $c' : 'Erreur réseau';
  }
  return e.toString();
}

final eventInvitesProvider =
FutureProvider.autoDispose<List<EventInviteModel>>((ref) async {
  final res = await ApiService.instance.dio.get(ApiPaths.myEventInvites);
  final list = _extractList(res.data);
  return list
      .whereType<Map<String, dynamic>>()
      .map(EventInviteModel.fromJson)
      .toList();
});

class EventInviteActions extends StateNotifier<AsyncValue<void>> {
  EventInviteActions() : super(const AsyncValue.data(null));
  String? lastError;

  Future<bool> accept(int inviteId) async {
    try {
      lastError = null;
      state = const AsyncValue.loading();
      await ApiService.instance.dio.post(ApiPaths.eventInviteAccept(inviteId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      lastError = friendlyError(e);
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> decline(int inviteId) async {
    try {
      lastError = null;
      state = const AsyncValue.loading();
      await ApiService.instance.dio.post(ApiPaths.eventInviteDecline(inviteId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      lastError = friendlyError(e);
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final eventInviteActionsProvider =
StateNotifierProvider<EventInviteActions, AsyncValue<void>>(
        (_) => EventInviteActions());
