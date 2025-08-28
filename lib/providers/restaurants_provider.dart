import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_service.dart';
import '../models/restaurant.dart';

final restaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
  final res = await ApiService.instance.dio.get('/api/restaurants/');
  return (res.data as List).map((e) => Restaurant.fromJson(e)).toList();
});

final restaurantDetailProvider = FutureProvider.family<Restaurant, int>((ref, id) async {
  final res = await ApiService.instance.dio.get('/api/restaurants/$id/');
  return Restaurant.fromJson(res.data);
});
