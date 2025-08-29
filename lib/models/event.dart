// lib/models/event.dart
import 'package:flutter/foundation.dart';

@immutable
class Event {
  final int id;
  final int restaurant;
  final String? restaurantName;

  final String title;
  final String description;
  final String type;

  final String date;       // YYYY-MM-DD
  final String startTime;  // HH:MM:SS
  final String endTime;    // HH:MM:SS

  final int? capacity;
  final int? currentRegistrations;
  final bool isPublic;
  final String status;     // DRAFT|PUBLISHED|FULL|CANCELLED

  final bool isBlocking;
  final int? room;
  final String? rrule;

  final String? publishedAt;
  final String? fullAt;
  final String? cancelledAt;
  final String? createdAt;
  final String? updatedAt;

  const Event({
    required this.id,
    required this.restaurant,
    required this.restaurantName,
    required this.title,
    required this.description,
    required this.type,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isPublic,
    required this.status,
    required this.isBlocking,
    this.capacity,
    this.currentRegistrations,
    this.room,
    this.rrule,
    this.publishedAt,
    this.fullAt,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> j) {
    int _toInt(dynamic v) =>
        v is int ? v : (v is num ? v.toInt() : int.parse(v.toString()));
    int? _toIntOrNull(dynamic v) {
      if (v == null) return null;
      try { return _toInt(v); } catch (_) { return null; }
    }
    bool _toBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v.toLowerCase() == 'true' || v == '1';
      return false;
    }
    String _str(dynamic v) => v?.toString() ?? '';

    return Event(
      id: _toInt(j['id']),
      restaurant: _toInt(j['restaurant']),
      restaurantName: j['restaurant_name']?.toString(),
      title: _str(j['title']),
      description: _str(j['description']),
      type: _str(j['type']),
      date: _str(j['date']),
      startTime: _str(j['start_time']),
      endTime: _str(j['end_time']),
      capacity: _toIntOrNull(j['capacity']),
      currentRegistrations: _toIntOrNull(j['current_registrations']),
      isPublic: _toBool(j['is_public']),
      status: _str(j['status']),
      isBlocking: _toBool(j['is_blocking']),
      room: _toIntOrNull(j['room']),
      rrule: j['rrule']?.toString(),
      publishedAt: j['published_at']?.toString(),
      fullAt: j['full_at']?.toString(),
      cancelledAt: j['cancelled_at']?.toString(),
      createdAt: j['created_at']?.toString(),
      updatedAt: j['updated_at']?.toString(),
    );
  }
}
