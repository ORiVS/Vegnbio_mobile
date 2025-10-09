//lib/models/delivery_slot.dart
class DeliverySlotModel {
  final int id;
  final DateTime start;
  final DateTime end;

  DeliverySlotModel({required this.id, required this.start, required this.end});

  factory DeliverySlotModel.fromJson(Map<String, dynamic> j) => DeliverySlotModel(
    id: (j['id'] as num).toInt(),
    start: DateTime.parse(j['start']),
    end: DateTime.parse(j['end']),
  );
}
