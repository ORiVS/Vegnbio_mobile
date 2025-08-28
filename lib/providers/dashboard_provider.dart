import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_service.dart';
import '../models/dashboard.dart';

final dashboardProvider = FutureProvider.family<DashboardDay, ({int restaurantId, String date})>((ref, params) async {
  final res = await ApiService.instance.dio
      .get('/api/restaurants/${params.restaurantId}/dashboard/', queryParameters: {'date': params.date});
  return DashboardDay.fromJson(res.data);
});
