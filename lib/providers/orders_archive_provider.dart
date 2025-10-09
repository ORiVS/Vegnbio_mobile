import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/orders_archive.dart';
import '../models/supplier_order.dart';

/// Tri utilisable depuis l’UI
enum ArchiveSort { dateDesc, dateAsc, totalConfirmedDesc, totalConfirmedAsc }

class ArchiveFilterState {
  final ArchiveSort sort;
  const ArchiveFilterState({this.sort = ArchiveSort.dateDesc});

  ArchiveFilterState copyWith({ArchiveSort? sort}) =>
      ArchiveFilterState(sort: sort ?? this.sort);
}

/// État du filtre de l’archive (tri)
final archiveFiltersProvider =
StateProvider<ArchiveFilterState>((ref) => const ArchiveFilterState());

/// Charge toutes les commandes archivées (tous statuts)
final ordersArchiveProvider = FutureProvider<List<SupplierOrder>>((ref) async {
  final rows = await OrdersArchive.instance.listAll();
  return rows
      .whereType<Map<String, dynamic>>()
      .map((j) => SupplierOrder.fromJson(j))
      .toList();
});

/// Trie/filtre l’archive selon archiveFiltersProvider
final filteredArchiveOrdersProvider = Provider<List<SupplierOrder>>((ref) {
  final list = ref.watch(ordersArchiveProvider).maybeWhen(
    data: (rows) => rows,
    orElse: () => <SupplierOrder>[],
  );
  final sort = ref.watch(archiveFiltersProvider).sort;

  int cmpNum(num a, num b) => a == b ? 0 : (a < b ? -1 : 1);

  // calcul du total confirmé
  num totalConfirmed(SupplierOrder o) {
    return o.items.fold<num>(
      0,
          (s, it) => s +
          (double.tryParse(it.unitPrice.toString()) ?? 0) *
              (double.tryParse((it.qtyConfirmed ?? '0').toString()) ?? 0),
    );
  }

  final sorted = [...list];
  switch (sort) {
    case ArchiveSort.dateDesc:
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case ArchiveSort.dateAsc:
      sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      break;
    case ArchiveSort.totalConfirmedDesc:
      sorted.sort((a, b) => -cmpNum(totalConfirmed(a), totalConfirmed(b)));
      break;
    case ArchiveSort.totalConfirmedAsc:
      sorted.sort((a, b) => cmpNum(totalConfirmed(a), totalConfirmed(b)));
      break;
  }
  return sorted;
});
