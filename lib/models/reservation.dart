class Reservation {
  final int id;
  final bool fullRestaurant;
  final int? restaurantId;
  final String? restaurantName;
  final int? roomId;
  final String? roomName;
  final String date;      // "YYYY-MM-DD"
  final String startTime; // "HH:MM:SS"
  final String endTime;   // "HH:MM:SS"
  final String status;    // PENDING/CONFIRMED/CANCELLED

  Reservation({
    required this.id,
    required this.fullRestaurant,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.restaurantId,
    this.restaurantName,
    this.roomId,
    this.roomName,
  });

  factory Reservation.fromJson(Map<String, dynamic> j) => Reservation(
    id: (j['id'] as num).toInt(),
    fullRestaurant: j['full_restaurant'] == true,
    restaurantId: (j['restaurant'] as num?)?.toInt(),
    restaurantName: j['restaurant_name']?.toString(),
    roomId: (j['room'] as num?)?.toInt(),
    roomName: j['room_name']?.toString(),
    date: j['date']?.toString() ?? '',
    startTime: j['start_time']?.toString() ?? '',
    endTime: j['end_time']?.toString() ?? '',
    status: j['status']?.toString() ?? 'PENDING',
  );
}
