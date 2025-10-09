//lib/providers/restaurants_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_service.dart';
import '../core/api_paths.dart';
import '../models/restaurant.dart';

List<dynamic> _extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map && data['results'] is List) return data['results'] as List;
  throw Exception('Réponse inattendue depuis ${ApiPaths.restaurantsList}');
}

final restaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
  print('[RESTOS] GET ${ApiPaths.restaurantsList}');
  final res = await ApiService.instance.dio.get(ApiPaths.restaurantsList);
  final list = _extractList(res.data);
  final parsed = list.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
  print('[RESTOS] loaded=${parsed.length}');
  return parsed;
});

final restaurantDetailProvider = FutureProvider.family<Restaurant, int>((ref, id) async {
  final url = ApiPaths.restaurantDetail(id);
  print('[RESTOS] GET $url');
  final res = await ApiService.instance.dio.get(url);
  final r = Restaurant.fromJson(res.data as Map<String, dynamic>);
  print('[RESTOS] detail $id loaded');
  return r;
});
