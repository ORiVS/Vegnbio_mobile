// suppliers_offers_provider.dart
import 'dart:async'; // si tu utilises keepAlive plus bas
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_service.dart';
import '../core/api_paths.dart';
import '../models/supplier_offer.dart';

@immutable
class SupplierOfferFilters {
  final String? q;
  final String? status;     // DRAFT/PUBLISHED/UNLISTED/FLAGGED
  final String? region;
  final bool? isBio;
  final String? availableOn; // YYYY-MM-DD
  final String? sort;        // price | -price

  const SupplierOfferFilters({
    this.q,
    this.status,
    this.region,
    this.isBio,
    this.availableOn,
    this.sort,
  });

  Map<String, dynamic> toQuery() {
    final m = <String, dynamic>{};
    if (q != null && q!.isNotEmpty) m['q'] = q;
    if (status != null && status!.isNotEmpty) m['status'] = status;
    if (region != null && region!.isNotEmpty) m['region'] = region;
    if (isBio != null) m['is_bio'] = isBio! ? 'true' : 'false';
    if (availableOn != null && availableOn!.isNotEmpty) m['available_on'] = availableOn;
    if (sort != null && sort!.isNotEmpty) m['sort'] = sort;
    return m;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SupplierOfferFilters &&
              other.q == q &&
              other.status == status &&
              other.region == region &&
              other.isBio == isBio &&
              other.availableOn == availableOn &&
              other.sort == sort;

  @override
  int get hashCode => Object.hash(q, status, region, isBio, availableOn, sort);
}

// Optionnel : cache soft 2 min pour éviter des refetchs fréquents lors des navs
final supplierOffersProvider = FutureProvider.autoDispose
    .family<List<SupplierOffer>, SupplierOfferFilters>((ref, filters) async {
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 2), link.close);

  final res = await ApiService.instance.dio.get(
    ApiPaths.supplierOffers,
    queryParameters: filters.toQuery(),
  );
  final data = (res.data is List) ? res.data as List : (res.data['results'] as List? ?? []);
  return data.map((e) => SupplierOffer.fromJson(e as Map<String, dynamic>)).toList();
});

final supplierOfferDetailProvider = FutureProvider.family<SupplierOffer, int>((ref, id) async {
  final res = await ApiService.instance.dio.get(ApiPaths.supplierOffer(id));
  return SupplierOffer.fromJson(res.data as Map<String, dynamic>);
});

// suppliers_offers_provider.dart (suite)
class SupplierOfferEditor extends StateNotifier<AsyncValue<void>> {
  SupplierOfferEditor(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  Future<int?> create(Map<String, dynamic> payload) async {
    try {
      state = const AsyncValue.loading();
      final res = await ApiService.instance.dio.post(ApiPaths.supplierOffers, data: payload);
      state = const AsyncValue.data(null);

      final id = res.data['id'] as int?;
      // refresh catalogue (toutes les instances de la family) + détail si on a l'id
      ref.invalidate(supplierOffersProvider);
      if (id != null) ref.invalidate(supplierOfferDetailProvider(id));
      return id;
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
      ref.invalidate(supplierOfferDetailProvider(id));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> publish(int id) async {
    try {
      await ApiService.instance.dio.post(ApiPaths.supplierOfferPublish(id));
      ref.invalidate(supplierOffersProvider);
      ref.invalidate(supplierOfferDetailProvider(id));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unlist(int id) async {
    try {
      await ApiService.instance.dio.post(ApiPaths.supplierOfferUnlist(id));
      ref.invalidate(supplierOffersProvider);
      ref.invalidate(supplierOfferDetailProvider(id));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> draft(int id) async {
    try {
      await ApiService.instance.dio.post(ApiPaths.supplierOfferDraft(id));
      ref.invalidate(supplierOffersProvider);
      ref.invalidate(supplierOfferDetailProvider(id));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> flagOffer(int id, {required String reason, String? details}) async {
    try {
      await ApiService.instance.dio.post(ApiPaths.supplierOfferFlag(id), data: {
        'reason': reason,
        'details': details ?? '',
      });
      // pas forcément utile d’invalider ici, mais tu peux si tu affiches un badge
      // ref.invalidate(supplierOfferDetailProvider(id));
      return true;
    } catch (_) {
      return false;
    }
  }
}

final supplierOfferEditorProvider =
StateNotifierProvider<SupplierOfferEditor, AsyncValue<void>>(
      (ref) => SupplierOfferEditor(ref),
);
