import 'package:flutter/foundation.dart';

class Room {
  final int id;
  final String name;
  final int capacity;
  Room({required this.id, required this.name, required this.capacity});

  factory Room.fromJson(Map<String, dynamic> j) =>
      Room(id: (j['id'] as num).toInt(), name: j['name'] ?? '', capacity: (j['capacity'] as num).toInt());
}

@immutable
class Restaurant {
  final int id;
  final String name;
  final String city;
  final String address;
  final String postalCode;
  final int capacity;

  final bool wifi;
  final bool printer;
  final bool memberTrays;
  final bool deliveryTrays;
  final bool animationsEnabled;
  final String? animationDay;

  final List<Room> rooms;

  const Restaurant({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.postalCode,
    required this.capacity,
    required this.wifi,
    required this.printer,
    required this.memberTrays,
    required this.deliveryTrays,
    required this.animationsEnabled,
    this.animationDay,
    this.rooms = const [],
  });

  factory Restaurant.fromJson(Map<String, dynamic> j) => Restaurant(
    id: (j['id'] as num).toInt(),
    name: j['name'] ?? '',
    city: j['city'] ?? '',
    address: j['address'] ?? '',
    postalCode: j['postal_code'] ?? '',
    capacity: (j['capacity'] as num?)?.toInt() ?? 0,
    wifi: j['wifi_available'] == true,
    printer: j['printer_available'] == true,
    memberTrays: j['member_trays_available'] == true,
    deliveryTrays: j['delivery_trays_available'] == true,
    animationsEnabled: j['animations_enabled'] == true,
    animationDay: j['animation_day']?.toString(),
    rooms: (j['rooms'] as List<dynamic>? ?? [])
        .map((e) => Room.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
