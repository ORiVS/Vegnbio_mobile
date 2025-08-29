// lib/models/reservation.dart
import 'package:flutter/foundation.dart';

@immutable
class Reservation {
  final int id;

  /// IDs bruts (peuvent être null selon la cible)
  final int? restaurant; // si full_restaurant=true, présent
  final int? room;       // si full_restaurant=false, présent

  /// Libellés renvoyés par le serializer
  final String? restaurantName;
  final String? roomName;

  /// Date/Heures au format API (YYYY-MM-DD, HH:MM:SS)
  final String date;
  final String startTime;
  final String endTime;

  /// 'PENDING' | 'CONFIRMED' | 'CANCELLED'
  final String status;

  /// true si réservation du restaurant entier
  final bool fullRestaurant;

  /// ISO datetime (optionnel selon réponse)
  final String? createdAt;

  const Reservation({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.fullRestaurant,
    this.restaurant,
    this.room,
    this.restaurantName,
    this.roomName,
    this.createdAt,
  });

  factory Reservation.fromJson(Map<String, dynamic> j) {
    // utilitaires robustes
    int? _toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    bool _toBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v.toLowerCase() == 'true' || v == '1';
      return false;
    }

    String _str(dynamic v, [String fallback = '']) =>
        v == null ? fallback : v.toString();

    return Reservation(
      id: _toInt(j['id']) ?? 0,
      restaurant: _toInt(j['restaurant']),
      room: _toInt(j['room']),
      restaurantName: j['restaurant_name']?.toString(),
      roomName: j['room_name']?.toString(),
      date: _str(j['date']),
      startTime: _str(j['start_time']),
      endTime: _str(j['end_time']),
      status: _str(j['status'], 'PENDING'),
      fullRestaurant: _toBool(j['full_restaurant']),
      createdAt: j['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'restaurant': restaurant,
    'room': room,
    'restaurant_name': restaurantName,
    'room_name': roomName,
    'date': date,
    'start_time': startTime,
    'end_time': endTime,
    'status': status,
    'full_restaurant': fullRestaurant,
    'created_at': createdAt,
  };
}
