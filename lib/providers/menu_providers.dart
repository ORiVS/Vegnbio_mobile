import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_service.dart';
import '../core/api_paths.dart';
import '../models/menu.dart';
import '../models/dish.dart';

List<dynamic> _extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map && data['results'] is List) return data['results'] as List;
  return [data];
}

/// Menus publiés pour un restaurant + date
final menusForDateProvider =
FutureProvider.family<List<Menu>, ({int restaurantId, String date})>((ref, p) async {
  final url = '${ApiPaths.menus}?restaurant=${p.restaurantId}&date=${p.date}';
  final res = await ApiService.instance.dio.get(url);
  final list = _extractList(res.data);
  return list.map((e) => Menu.fromJson(e as Map<String, dynamic>)).toList();
});

/// Ids des plats indisponibles pour restaurant + date
final unavailableDishIdsProvider =
FutureProvider.family<Set<int>, ({int restaurantId, String date})>((ref, p) async {
  final url =
      '${ApiPaths.dishAvailabilities}?restaurant=${p.restaurantId}&date=${p.date}';
  final res = await ApiService.instance.dio.get(url);
  final list = _extractList(res.data);
  final ids = <int>{};
  for (final e in list) {
    final m = e as Map<String, dynamic>;
    final available = m['is_available'] != false;
    if (!available) ids.add((m['dish'] as num).toInt());
  }
  return ids;
});

Future<Map<int, Dish>> _fetchDishesByIds(Iterable<int> ids) async {
  final dio = ApiService.instance.dio;
  final futures = ids.map((id) => dio.get(ApiPaths.dish(id)));
  final results = await Future.wait(futures, eagerError: true);
  final map = <int, Dish>{};
  for (final r in results) {
    final d = Dish.fromJson(r.data as Map<String, dynamic>);
    map[d.id] = d;
  }
  return map;
}

/// Menus où chaque item a bien un Dish (si backend renvoie seulement l’ID)
final menusWithDishesProvider =
FutureProvider.family<List<Menu>, ({int restaurantId, String date})>((ref, p) async {
  final menus = await ref.watch(menusForDateProvider(p).future);

  final missing = <int>{};
  for (final m in menus) {
    for (final it in m.items) {
      if (it.dish == null && it.dishId != null) missing.add(it.dishId!);
    }
  }
  Map<int, Dish> map = {};
  if (missing.isNotEmpty) map = await _fetchDishesByIds(missing);

  return menus
      .map((m) => Menu(
    id: m.id,
    title: m.title,
    description: m.description,
    startDate: m.startDate,
    endDate: m.endDate,
    restaurants: m.restaurants,
    isPublished: m.isPublished,
    items: m.items
        .map((it) => it.dish != null || it.dishId == null
        ? it
        : MenuItem(
      id: it.id,
      course: it.course,
      dishId: it.dishId,
      dish: map[it.dishId],
    ))
        .toList(),
  ))
      .toList();
});

/// Dispo d’un plat (true = dispo aujourd’hui ; false = rupture)
final dishAvailableTodayProvider = FutureProvider.family<bool, ({int restaurantId, int dishId, String date})>((ref, p) async {
  final url = ApiPaths.dishAvailabilityQuery(
    restaurantId: p.restaurantId,
    dishId: p.dishId,
    date: p.date,
  );
  final res = await ApiService.instance.dio.get(url);
  final list = _extractList(res.data);
  if (list.isEmpty) return true;
  final m = list.first as Map<String, dynamic>;
  return m['is_available'] != false;
});
