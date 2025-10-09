// lib/providers/slots_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_service.dart';
import '../core/api_paths.dart';
import '../models/delivery_slot.dart';

final slotsProvider = FutureProvider<List<DeliverySlotModel>>((ref) async {
  final res = await ApiService.instance.dio.get(ApiPaths.slots);
  final list = (res.data as List).map((e) => DeliverySlotModel.fromJson(e as Map<String, dynamic>)).toList();
  return list;
});
