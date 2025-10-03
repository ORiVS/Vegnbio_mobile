import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api_service.dart';
import '../core/api_paths.dart';
import '../models/supplier_offer.dart';

@immutable
class SupplierOfferFilters {
  final String? q;
  final bool? isBio;
  final String? region;
  final String? sort; // "price" | "-price" | null

  const SupplierOfferFilters({this.q, this.isBio, this.region, this.sort});

  Map<String, dynamic> toQuery() {
    final m = <String, dynamic>{};
    if (q != null && q!.isNotEmpty) m['q'] = q;
    if (isBio != null) m['is_bio'] = isBio.toString();
    if (region != null && region!.isNotEmpty) m['region'] = region;
    if (sort != null && sort!.isNotEmpty) m['sort'] = sort;
    return m;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SupplierOfferFilters &&
              other.q == q &&
              other.isBio == isBio &&
              other.region == region &&
              other.sort == sort;

  @override
  int get hashCode => Object.hash(q, isBio, region, sort);
}

List _extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map && data['results'] is List) return data['results'] as List;
  return const [];
}

/// Liste des offres
final supplierOffersProvider = FutureProvider.autoDispose
    .family<List<SupplierOffer>, SupplierOfferFilters>((ref, filters) async {
  final res = await ApiService.instance.dio.get(
    ApiPaths.supplierOffers,
    queryParameters: filters.toQuery(),
  );
  final list = _extractList(res.data);
  return list
      .whereType<Map<String, dynamic>>()
      .map((j) => SupplierOffer.fromJson(j))
      .toList();
});

/// Détail d’une offre
final supplierOfferDetailProvider =
FutureProvider.autoDispose.family<SupplierOffer, int>((ref, id) async {
  final res = await ApiService.instance.dio.get(ApiPaths.supplierOffer(id));
  return SupplierOffer.fromJson(res.data as Map<String, dynamic>);
});

/// Éditeur d’offres (CRUD + actions)
class SupplierOfferEditor extends StateNotifier<AsyncValue<void>> {
  SupplierOfferEditor(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  Future<int?> create(Map<String, dynamic> payload) async {
    try {
      state = const AsyncValue.loading();
      final res =
      await ApiService.instance.dio.post(ApiPaths.supplierOffers, data: payload);
      state = const AsyncValue.data(null);
      // On tente de récupérer l'id dans la réponse
      final data = res.data;
      if (data is Map && data['id'] != null) {
        final id = (data['id'] as num).toInt();
        // Invalidate toutes les listes
        ref.invalidate(supplierOffersProvider);
        return id;
      }
      ref.invalidate(supplierOffersProvider);
      return null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> update(int id, Map<String, dynamic> payload) async {
    try {
      state = const AsyncValue.loading();
      await ApiService.instance.dio.patch(ApiPaths.supplierOffer(id), data: payload);
      state = const AsyncValue.data(null);
      ref.invalidate(supplierOffersProvider);
      ref.invalidate(supplierOfferDetailProvider(id));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      state = const AsyncValue.loading();
      await ApiService.instance.dio.delete(ApiPaths.supplierOffer(id));
      state = const AsyncValue.data(null);
      ref.invalidate(supplierOffersProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> publish(int id) async {
    try {
      state = const AsyncValue.loading();
      await ApiService.instance.dio.post('${ApiPaths.supplierOffers}$id/publish/');
      state = const AsyncValue.data(null);
      ref.invalidate(supplierOffersProvider);
      ref.invalidate(supplierOfferDetailProvider(id));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> unlist(int id) async {
    try {
      state = const AsyncValue.loading();
      await ApiService.instance.dio.post('${ApiPaths.supplierOffers}$id/unlist/');
      state = const AsyncValue.data(null);
      ref.invalidate(supplierOffersProvider);
      ref.invalidate(supplierOfferDetailProvider(id));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> draft(int id) async {
    try {
      state = const AsyncValue.loading();
      await ApiService.instance.dio.post('${ApiPaths.supplierOffers}$id/draft/');
      state = const AsyncValue.data(null);
      ref.invalidate(supplierOffersProvider);
      ref.invalidate(supplierOfferDetailProvider(id));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Utilisé ailleurs (écran avis) – on le garde
  Future<bool> flagOffer(int id, {required String reason, String? details}) async {
    try {
      state = const AsyncValue.loading();
      await ApiService.instance.dio.post(
        '${ApiPaths.supplierOffers}$id/flag/',
        data: {'reason': reason, 'details': details ?? ''},
      );
      state = const AsyncValue.data(null);
      ref.invalidate(supplierOffersProvider);
      ref.invalidate(supplierOfferDetailProvider(id));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final supplierOfferEditorProvider =
StateNotifierProvider<SupplierOfferEditor, AsyncValue<void>>(
      (ref) => SupplierOfferEditor(ref),
);
