import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_service.dart';
import '../core/api_paths.dart';
import '../models/dashboard.dart';

final dashboardProvider = FutureProvider.family<DashboardDay, ({int restaurantId, String date})>((ref, params) async {
  final url = ApiPaths.restaurantDashboard(params.restaurantId);
  print('[DASH] GET $url?date=${params.date}');
  final res = await ApiService.instance.dio.get(url, queryParameters: {'date': params.date});
  final dash = DashboardDay.fromJson(res.data as Map<String, dynamic>);
  print('[DASH] loaded for ${params.restaurantId} date=${params.date}');
  return dash;
});
