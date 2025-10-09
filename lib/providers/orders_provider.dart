//lib/providers/orders_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_service.dart';
import '../core/api_paths.dart';
import '../models/order.dart';

final ordersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final res = await ApiService.instance.dio.get(ApiPaths.ordersList);
  final data = res.data as List;
  return data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
});
