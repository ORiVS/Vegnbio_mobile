// lib/providers/supplier_orders_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../core/api_service.dart';
import '../core/api_paths.dart';
import '../models/supplier_order.dart';

List _extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map && data['results'] is List) return data['results'] as List;
  return const [];
}

/// Utilitaire : message lisible pour l’utilisateur (DRF/Dio)
String friendlyError(Object error) {
  if (error is DioException) {
    final res = error.response;
    final data = res?.data;

    if (data is Map) {
      // DRF: {"detail": "..."} ou {"field": ["msg1","msg2"], ...}
      if (data['detail'] is String && (data['detail'] as String).trim().isNotEmpty) {
        return data['detail'] as String;
      }
      final parts = <String>[];
      data.forEach((k, v) {
        if (v is List) {
          parts.add('$k: ${v.map((e) => e.toString()).join(", ")}');
        } else {
          parts.add('$k: ${v.toString()}');
        }
      });
      if (parts.isNotEmpty) return parts.join('\n');
    }
    if (data is List && data.isNotEmpty) {
      return data.map((e) => e.toString()).join('\n');
    }
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }
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

/// Inbox fournisseur : liste des commandes
final supplierInboxProvider = FutureProvider.autoDispose<List<SupplierOrder>>((ref) async {
  try {
    final res = await ApiService.instance.dio.get(ApiPaths.supplierInbox);
    final list = _extractList(res.data);
    return list
        .whereType<Map<String, dynamic>>()
        .map((j) => SupplierOrder.fromJson(j))
        .toList();
  } catch (e) {
    throw Exception(friendlyError(e));
  }
});

/// Détail d’une commande fournisseur
final supplierOrderDetailProvider =
FutureProvider.autoDispose.family<SupplierOrder, int>((ref, id) async {
  try {
    final res = await ApiService.instance.dio.get(ApiPaths.purchasingOrderDetail(id));
    return SupplierOrder.fromJson(res.data as Map<String, dynamic>);
  } catch (e) {
    throw Exception(friendlyError(e));
  }
});

/// Reviewer : envoi des quantités confirmées / validation commande
class SupplierOrderReviewer extends StateNotifier<AsyncValue<void>> {
  SupplierOrderReviewer(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  String? lastError;


  Future<bool> submit(int orderId, Map<int, String> itemIdToQtyConfirmed) async {
    try {
      lastError = null;
      state = const AsyncValue.loading();

      final Map<String, String> mapped = itemIdToQtyConfirmed.map(
            (k, v) => MapEntry(k.toString(), v),
      );

      await ApiService.instance.dio.post(
        ApiPaths.purchasingOrderSupplierReview(orderId),
        data: {'items': mapped},
      );

      state = const AsyncValue.data(null);

      // rafraîchir les vues liées
      ref.invalidate(supplierInboxProvider);
      ref.invalidate(supplierOrderDetailProvider(orderId));
      return true;
    } catch (e, st) {
      lastError = friendlyError(e);
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final supplierOrderReviewerProvider =
StateNotifierProvider<SupplierOrderReviewer, AsyncValue<void>>(
      (ref) => SupplierOrderReviewer(ref),
);
