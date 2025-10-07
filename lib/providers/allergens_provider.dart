// lib/providers/allergens_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../core/api_service.dart';
import '../core/api_paths.dart';
import '../models/allergen.dart';

List _extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map && data['results'] is List) return data['results'] as List;
  return const [];
}

String friendlyError(Object error) {
  if (error is DioException) {
    final res = error.response;
    final data = res?.data;
    if (data is Map && data['detail'] is String && data['detail'].toString().trim().isNotEmpty) {
      return data['detail'] as String;
    }
    if (data is List && data.isNotEmpty) {
      return data.map((e) => e.toString()).join('\n');
    }
    if (data is String && data.trim().isNotEmpty) return data;
    final code = res?.statusCode;
    final reason = res?.statusMessage;
    if (code != null) return 'Erreur $code${reason != null ? " - $reason" : ""}';
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return "Délai dépassé. Vérifiez votre connexion et réessayez.";
    }
    return "Une erreur s’est produite. Réessayez.";
  }
  return error.toString();
}

/// Liste des allergènes
final allergensProvider = FutureProvider.autoDispose<List<Allergen>>((ref) async {
  try {
    final res = await ApiService.instance.dio.get(ApiPaths.allergens);
    final list = _extractList(res.data);
    return list.whereType<Map<String, dynamic>>().map(Allergen.fromJson).toList();
  } catch (e) {
    throw Exception(friendlyError(e));
  }
});

/// Création d’un allergène
class AllergenEditor extends StateNotifier<AsyncValue<void>> {
  AllergenEditor(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;
  String? lastError;

  Future<Allergen?> create({required String label}) async {
    try {
      lastError = null;
      state = const AsyncValue.loading();

      // code auto (UPPERCASE, sans espaces)
      final code = label.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '_');

      final res = await ApiService.instance.dio.post(
        ApiPaths.allergens,
        data: {'label': label.trim(), 'code': code},
      );
      state = const AsyncValue.data(null);
      ref.invalidate(allergensProvider);
      return Allergen.fromJson(res.data as Map<String, dynamic>);
    } catch (e, st) {
      lastError = friendlyError(e);
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final allergenEditorProvider =
StateNotifierProvider<AllergenEditor, AsyncValue<void>>((ref) => AllergenEditor(ref));
