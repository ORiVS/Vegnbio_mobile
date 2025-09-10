import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_service.dart';
import '../core/api_paths.dart';
import '../models/delivery_slot.dart';

final slotsProvider = FutureProvider<List<DeliverySlotModel>>((ref) async {
  final res = await ApiService.instance.dio.get(ApiPaths.slots);
  final data = res.data as List;
  return data.map((e) => DeliverySlotModel.fromJson(e as Map<String, dynamic>)).toList();
});
