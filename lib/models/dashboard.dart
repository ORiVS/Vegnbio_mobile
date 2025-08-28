class RDayReservation {
  final String startTime; // "HH:MM:SS"
  final String endTime;
  final String status;
  RDayReservation({required this.startTime, required this.endTime, required this.status});
  factory RDayReservation.fromJson(Map<String, dynamic> j) =>
      RDayReservation(startTime: j['start_time'], endTime: j['end_time'], status: j['status']);
}

class RDayRoom {
  final String room;
  final int capacity;
  final List<RDayReservation> reservations;
  RDayRoom({required this.room, required this.capacity, required this.reservations});
  factory RDayRoom.fromJson(Map<String, dynamic> j) => RDayRoom(
    room: j['room'],
    capacity: (j['capacity'] as num).toInt(),
    reservations: (j['reservations'] as List).map((e) => RDayReservation.fromJson(e)).toList(),
  );
}

class RDayEvent {
  final int id;
  final String title;
  final String type;
  final String startTime;
  final String endTime;
  final String status;
  final bool isPublic;
  final int? capacity;
  RDayEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.isPublic,
    this.capacity,
  });
  factory RDayEvent.fromJson(Map<String, dynamic> j) => RDayEvent(
    id: (j['id'] as num).toInt(),
    title: j['title'],
    type: j['type'],
    startTime: j['start_time'],
    endTime: j['end_time'],
    status: j['status'],
    isPublic: j['is_public'] == true,
    capacity: (j['capacity'] as num?)?.toInt(),
  );
}

class DashboardDay {
  final String date;
  final String restaurant;
  final List<RDayRoom> rooms;
  final List<RDayEvent> events;
  DashboardDay({required this.date, required this.restaurant, required this.rooms, required this.events});
  factory DashboardDay.fromJson(Map<String, dynamic> j) => DashboardDay(
    date: j['date'],
    restaurant: j['restaurant'],
    rooms: (j['rooms'] as List).map((e) => RDayRoom.fromJson(e)).toList(),
    events: (j['evenements'] as List).map((e) => RDayEvent.fromJson(e)).toList(),
  );
}
