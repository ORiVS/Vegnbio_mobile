// lib/models/offer_comment.dart
class OfferComment {
  final int id;
  final int offerId;
  final int authorId;
  final String content;
  final bool isEdited;
  final DateTime createdAt;

  OfferComment({
    required this.id,
    required this.offerId,
    required this.authorId,
    required this.content,
    required this.isEdited,
    required this.createdAt,
  });

  static int _int(dynamic v, {int def = 0}) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  static bool _bool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return false;
  }

  static DateTime _date(dynamic v) {
    if (v is String) {
      final d = DateTime.tryParse(v);
      if (d != null) return d.toLocal();
    }
    return DateTime.now();
  }

  factory OfferComment.fromJson(Map<String, dynamic> j) => OfferComment(
    id: _int(j['id']),
    offerId: _int(j['offer_id'] ?? j['offer'] ?? j['offerId']),
    authorId: _int(j['author_id'] ?? j['author'] ?? j['user'] ?? j['user_id']),
    content: (j['content'] ?? j['text'] ?? '').toString(),
    isEdited: _bool(j['is_edited'] ?? j['edited'] ?? (j['updated_at'] != null)),
    createdAt: _date(j['created_at'] ?? j['date'] ?? j['createdAt']),
  );
}
