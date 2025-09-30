// supplier_reviews_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_service.dart';
import '../core/api_paths.dart';
import '../models/offer_review.dart';

@immutable
class ReviewFilters {
  final int? offerId;
  final int? rating; // 1..5
  const ReviewFilters({this.offerId, this.rating});

  Map<String, dynamic> toQuery() {
    final m = <String, dynamic>{};
    if (offerId != null) m['offer'] = offerId;
    if (rating != null) m['rating'] = rating;
    return m;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ReviewFilters &&
              other.offerId == offerId &&
              other.rating == rating;

  @override
  int get hashCode => Object.hash(offerId, rating);
}

final supplierReviewsProvider =
FutureProvider.family<List<OfferReview>, ReviewFilters>((ref, f) async {
  final res = await ApiService.instance.dio.get(
    ApiPaths.supplierReviews,
    queryParameters: f.toQuery(),
  );
  final data = (res.data is List) ? res.data as List : (res.data['results'] as List? ?? []);
  return data.map((e) => OfferReview.fromJson(e as Map<String, dynamic>)).toList();
});
