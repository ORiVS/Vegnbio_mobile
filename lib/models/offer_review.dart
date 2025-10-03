// lib/models/offer_review.dart
class OfferReview {
  final int id;
  final int offerId;
  final int rating;      // 1..5 (peut être 0 si mauvais payload)
  final String? comment;
  final DateTime createdAt;

  OfferReview({
    required this.id,
    required this.offerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  static int _int(dynamic v, {int def = 0}) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  static DateTime _date(dynamic v) {
    if (v is String) {
      final d = DateTime.tryParse(v);
      if (d != null) return d.toLocal();
    }
    return DateTime.now();
  }

  factory OfferReview.fromJson(Map<String, dynamic> j) => OfferReview(
    id: _int(j['id']),
    offerId: _int(j['offer_id'] ?? j['offer'] ?? j['offerId']),
    rating: _int(j['rating']),
    comment: j['comment'] as String?,
    createdAt: _date(j['created_at'] ?? j['date'] ?? j['createdAt']),
  );
}
