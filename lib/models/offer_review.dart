class OfferReview {
  final int id;
  final int offerId;
  final int rating; // 1..5
  final String? comment;
  final String author;
  final DateTime createdAt;

  OfferReview({
    required this.id,
    required this.offerId,
    required this.rating,
    required this.comment,
    required this.author,
    required this.createdAt,
  });

  factory OfferReview.fromJson(Map<String, dynamic> j) => OfferReview(
    id: (j['id'] as num).toInt(),
    offerId: (j['offer'] as num).toInt(),
    rating: (j['rating'] as num).toInt(),
    comment: j['comment'],
    author: (j['author'] is Map && j['author']['email'] != null)
        ? j['author']['email'] as String
        : (j['author']?.toString() ?? '—'),
    createdAt: DateTime.parse(j['created_at']),
  );
}
