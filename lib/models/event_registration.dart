// lib/models/event_registration.dart
import 'package:flutter/foundation.dart';

@immutable
class EventRegistrationInfo {
  final int count;
  final bool meRegistered;
  final String? registeredAt;

  const EventRegistrationInfo({
    required this.count,
    required this.meRegistered,
    this.registeredAt,
  });

  factory EventRegistrationInfo.fromJson(Map<String, dynamic> j) {
    final me = (j['me'] as Map?) ?? const {};
    return EventRegistrationInfo(
      count: (j['count'] as num?)?.toInt() ?? 0,
      meRegistered: me['registered'] == true,
      registeredAt: me['registered_at']?.toString(),
    );
  }
}
