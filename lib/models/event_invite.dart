// lib/models/event_invite.dart
class EventLite {
  final int id;
  final String title;
  final String date;      // YYYY-MM-DD
  final String startTime; // HH:MM:SS
  final String endTime;   // HH:MM:SS
  final String status;    // PUBLISHED, FULL, ...

  EventLite({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory EventLite.fromJson(Map<String, dynamic> j) => EventLite(
    id: (j['id'] as num).toInt(),
    title: (j['title'] ?? '').toString(),
    date: (j['date'] ?? '').toString(),
    startTime: (j['start_time'] ?? '').toString(),
    endTime: (j['end_time'] ?? '').toString(),
    status: (j['status'] ?? 'DRAFT').toString(),
  );
}

class EventInviteModel {
  final int id;
  final String status; // PENDING / ACCEPTED / REVOKED
  final DateTime? expiresAt;
  final DateTime? supplierDeadlineAt;
  final EventLite event;

  EventInviteModel({
    required this.id,
    required this.status,
    required this.event,
    this.expiresAt,
    this.supplierDeadlineAt,
  });

  factory EventInviteModel.fromJson(Map<String, dynamic> j) => EventInviteModel(
    id: (j['id'] as num).toInt(),
    status: (j['status'] ?? 'PENDING').toString(),
    expiresAt: j['expires_at'] != null
        ? DateTime.tryParse(j['expires_at'] as String)?.toLocal()
        : null,
    supplierDeadlineAt: j['supplier_deadline_at'] != null
        ? DateTime.tryParse(j['supplier_deadline_at'] as String)?.toLocal()
        : null,
    event: EventLite.fromJson(j['event'] as Map<String, dynamic>),
  );
}
